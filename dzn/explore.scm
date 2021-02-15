;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (dzn explore)
  #:use-module (ice-9 match)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (dzn command-line)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)

  #:use-module (dzn ast)
  #:use-module (dzn display)
  #:use-module (dzn misc)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm normalize)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm report)
  #:use-module (dzn vm run)
  #:use-module (dzn vm util)
  #:export (state-diagram))

;;; Commentary:
;;;
;;; ’explore’ implements a state diagram.
;;;
;;; Code:


;;;
;;; State diagram
;;;

(define (trace->string-trail trace)
  (let ((labels (map cdr (trace->trail trace))))
    (match labels
      ((trigger action ...)
       (string-join (cons* trigger "------" action) "\n"))
      (() "------"))))

(define (run-to-completion** pc event)
  (let* ((pc (clone pc #:instance #f #:reply #f #:trail '())))
    (cond
     ((is-a? (%sut) <runtime:port>)
      (run-to-completion pc event))
     ((requires-trigger? event)
      (run-requires pc event))
     ((provides-trigger? event)
      (run-to-completion pc event)))))

(define (explore pc)
  "Explore the state space of (%SUT).  Start by running all (labels) on
PC, and recurse until no new PCs are found.  Return the graph as

   ((from from-label transition to trigger-location)
    ...)
"
  (define (trigger-location trace)
    (let ((pc (find (conjoin (compose (is? <on>) .statement)
                             (disjoin (const (is-a? (%sut) <runtime:port>))
                                      (compose (is? <runtime:component>) .instance)))
                    (reverse trace))))
      (and pc (and=> (.statement pc) ast:location))))
  (define (graph pc)
    (let* ((labels (labels))
           (explored (make-hash-table)))
      (let loop ((pc pc))
        (let ((from (pc->hash pc)))
          (if (equal? (hash-ref explored from) (pc->string pc)) '()
              (let* ((pc (clone pc #:instance #f #:trail '()))
                     (traces (append-map (cute run-to-completion** pc <>) labels))
                     (traces (filter (compose not .status car) traces))
                     (pcs (map car traces))
                     (transition (map trace->string-trail traces))
                     (from-label (pc->string pc))
                     (to (map pc->hash pcs))
                     (trigger-location (map trigger-location traces)))
                (hash-set! explored from (pc->string pc))
                (append (map (cut list from from-label <> <> <>)
                             transition
                             to
                             trigger-location)
                        (append-map loop pcs))))))))
  (let ((graph (graph pc)))
    (if (null? graph) `((,(pc->hash pc) ,(pc->string pc) #f #f #f))
        graph)))

(define (graph->dot graph)
  "Return a diagram in DOT format from GRAPH produced by EXPLORE."
  (define (preamble title)
    (format #f
            "digraph G {
label=~s begin[shape=\"circle\" width=0.3 fillcolor=\"black\" style=\"filled\" label=\"\"]
node[shape=\"rectangle\" style=\"rounded\"]
begin -> " title))

  (define postamble
    "
}
")
  (let ((start (match graph (((from from-label label to trigger-location) transition ...)
                             from))))
    (string-append
     (preamble (ast:dotted-name (.type (.ast (%sut)))))
     (string-append (number->string start) "\n")
     (string-join
      (map (match-lambda ((from from-label label to trigger-location)
                          (string-append
                           (format #f "~s [label=~s]\n" from from-label)
                           (if (and to label)
                               (format #f "~s -> ~s [label=~s]" from to label)
                               ""))))
           graph)
      "\n")
     postamble)))


;;;
;;; Entry point.
;;;

(define* (state-diagram root #:key format model-name)
  "Entry-point for dzn explore --state-diagram."
  (let ((root (vm:normalize root)))
    (when (> (dzn:debugity) 0)
      (set! %debug? #t))
    (parameterize ((%exploring? #t)
                   (%sut (runtime:get-sut root (ast:get-model root model-name))))
      (parameterize ((%instances (runtime:system* (%sut))))
        (let* ((pc (make-pc))
               (graph (explore pc)))
          (display (graph->dot graph)))))))
