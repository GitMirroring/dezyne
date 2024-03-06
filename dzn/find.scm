;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2023 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn find)
  #:use-module (ice-9 format)
  #:use-module ((srfi srfi-1)
                ;; maybe a toplevel name `find' isn't the best idea
                #:select (append-map
                          delete-duplicates
                          drop-right
                          drop-while
                          last
                          lset-difference
                          (find . srfi-1:find)))
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-43)
  #:use-module (srfi srfi-71)

  #:use-module (dzn ast ast)
  #:use-module (dzn code language makreel)
  #:use-module (dzn command-line)
  #:use-module (dzn lts)
  #:use-module (dzn pipe)
  #:use-module (dzn stitch)
  #:export (find))

(define (trace->transitions trace trace-events)
  (define (expand-label i label)
    (append
      (list (format #f "(~d,\"tau\",~d)" (1+ i) 0))
      (map
        (lambda (e)
          (format #f "(~d,~s,~d)" (1+ i) e (1+ i)))
        (delete label trace-events))
      (list (format #f "(~d,~s,~d)" (1+ i) label (+ 2 i)))))
  (apply append
    (vector->list
      (vector-map expand-label (list->vector trace)))))

(define (trace->spec trace trace-events)
  (let* ((transitions (trace->transitions trace trace-events))
         (des (format #f "des (1,~d,~d)" (1+ (length transitions)) (+ 4 (length trace))))
         (found (format #f "(~d,\"<found>\",~d)" (+ 1 (length trace)) (+ 2 (length trace)))))
    (string-join (append (list des) transitions (list found)) "\n")))

(define (display-aut+aut lts spec)
  (cute display
    (string-append
      (with-output-to-string (cute display-lts lts))
      "\n\x04\n"
      spec)))

(define (aut+aut->compliance taus)
  (let* ((taus (string-join taus ","))
         (taus (if (string-null? taus) '()
                   (list (string-append "--tau=" taus)))))
    `("ltscompare" "--quiet" "--counter-example" "--structured-output" "-pweak-failures"
      ,@taus
      "--in1=aut" "--in2=aut" "-" "-")))

(define (perform-compliance lts spec taus)
  (let* ((commands (list (display-aut+aut lts spec) (aut+aut->compliance taus)))
         (result status (pipeline->string commands)))
  (values result status)))

(define (model-name->model model-name models)
  (srfi-1:find
   (compose (cute equal? <> model-name) makreel:unticked-dotted-name)
   models))

(define (hide-internal-labels trace)
  (filter
    (lambda (event)
      (and (not (member event '("inevitable" "optional" "tau" "<blocking>")))
           (not (string-contains event ".qout."))
           (not (string-contains event "<state>"))
           (not (string-contains event "tag("))
           (not (srfi-1:find (cute string-suffix? <> event)
                             '(".optional" ".inevitable" ".<flush>")))))
    trace))

(define (collect-labels lts)
  (let ((labels (append-map (compose (cute map edge-label <>) node-edges)
                            (vector->list lts))))
    (delete-duplicates labels eq?)))

(define* (find root models model-name trace lts #:key verbose?)
  (let* ((model (or (and model-name (model-name->model model-name models))
                    (srfi-1:find (cute is-a? <> <system>) (reverse models))
                    (srfi-1:find (cute is-a? <> <component>) (reverse models))))
         (lts (if lts lts (model->lts root model verbose?)))
         (lts (remove-state-loops lts))
         (lts-events (collect-labels lts))
         (trace-events (delete-duplicates trace))
         (not-lts-events (lset-difference equal? trace-events lts-events))
         (hide-events (lset-difference equal? lts-events trace-events))
         (spec (trace->spec trace trace-events))
         (output status (perform-compliance lts spec hide-events))
         (lines (and output (string-split output #\newline)))
         (result (and lines (srfi-1:find (cute string-prefix? "result: " <>) lines)))
         (match (string-suffix? "false" result))
         (acceptance (and lines
                          (srfi-1:find (cute string-prefix? "right-acceptance: " <>) lines)))
         (last-event (last trace))
         (trace (and lines
                     (srfi-1:find (cute string-prefix? "counter_example_weak_failures_refinement: " <>) lines)))
         (trace (or (and trace (substring trace (1+ (string-index trace #\:)))) ""))
         (trace (string-split (string-trim-both trace) #\;))
         (trace (hide-internal-labels trace))
         (trace (if acceptance trace (drop-right trace 1)))
         (trace (reverse (drop-while (negate (cute equal? last-event <>)) (reverse trace)))))
  (when (pair? not-lts-events)
    (format
      (current-error-port)
      "warning: the following events are not present in the LTS: ~a\n"
      (string-join not-lts-events ",")))
  (and match (string-join trace "\n" 'suffix))))
