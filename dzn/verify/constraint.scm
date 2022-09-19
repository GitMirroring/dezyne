;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn verify constraint)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-43)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 string-fun)

  #:use-module (dzn ast display)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn lts)
  #:use-module (dzn misc)
  #:use-module (dzn verify pipeline)
  #:use-module (dzn vm normalize)

  #:export (interface->constraint))

(define (lts->makreel model lts)
  "Print constraint proces in makreel code for MODEL's deterministic LTS
to current-output-port."

  (define (illegal? o)
    (match o
      ((trigger action rest ...) (illegal? action))
      ((or "<illegal>" "<declarative-illegal>"
           "illegal" "declarative_illegal") #t)
      (_ #f)))

  (define (rtc? o)
    (cond
     ((node? o)
      (any rtc? (node-edges o)))
     ((edge? o)
      (let ((label (edge-label o)))
        (or (trigger? label) (modeling-event? label))))))

  (define (next edge)
    (let ((next (vector-ref lts (edge-to edge))))
      (if (rtc? next) '()
          (node-edges next))))

  (define (transition-illegal? edge)
    (or (illegal? (edge-label edge))
        (let* ((next (next edge)))
          (any transition-illegal? next))))

  (define (trigger? o)
    (and (string? o)
         (string-contains o "'in(")))

  (define (action? o)
    (and (string? o)
         (string-contains o "'out(")
         o))

  (define (reply? o)
    (and (string? o)
         (string-contains o "'reply(")))

  (define (modeling-event? o)
    (and (string? o)
         (string-contains o "'internal(")))

  (define (error? o)
    (and (string? o)
         (member o '("range_error"))))

  (define (state? o)
    (and (string? o)
         (string-contains o "'state(")))

  (define (full-name o)
    (apply string-append (ast:full-name o)))

  (define (model-actions)
    (let ((name (full-name model))
          (actions (map .name (ast:out-event* model))))
      (map (cute format #f "~aout(~aaction(~aout'~a))"
                 name name name <>)
           actions)))

  (define (value->string o)
    (match o
      (($ <enum-literal>)
       (string-append (full-name (.type.name o)) (.field o)))
      (_ (.value o))))

  (define (type->string o)
    (let ((name (full-name model)))
      (match o
        (($ <void>) (string-append name "Void"))
        (($ <bool>) (string-append name "Bool"))
        (($ <int>) (string-append name "Int"))
        (($ <enum>) (full-name o)))))

  (define (model-replies)
    (let* ((values (append-map
                    (cute ast:return-values <> (make <literal>))
                    (ast:in-event* model)))
           (values (delete-duplicates values ast:equal?))
           (root (ast:parent model <root>))
           (values (map (cute clone <> #:parent root) values))
           (types (map ast:type values))
           (values (map value->string values))
           (types (map type->string types))
           (name (full-name model)))
      (map (cute format #f "~areply(~a(~a))"
                 name <> <>)
           types values)))

  (let ((name (full-name model))
        (root (ast:parent model <root>))
        (initial (initial lts))
        (actions (model-actions))
        (replies (model-replies)))

    (define (print-transitions transitions)
      (define (print-illegal-transition transition)
        (let ((trigger (edge-label transition)))
          (format #t
                  " + ~a . Constrained_Illegal\n"
                  trigger)))

      (define* (print-tree transitions #:key first? (seen '()))
        (let* ((transition (car transitions))
               (events (map edge-label transitions))
               (transitions (cdr transitions))
               (event (edge-label transition))
               (action-events (filter action? events))
               (reply-events (filter reply? events))
               (events (lset-union equal? seen events))
               (action? (action? event))
               (reply? (reply? event))
               (replies (if (> (length reply-events) 1) '()
                            replies))
               (actions (if (> (length action-events) 1) '()
                            actions))
               (actions+replies (append actions replies))
               (actions+replies
                (filter (negate (cute member <> events))
                        actions+replies))
               (any? (and (not (command-line:get 'no-non-compliance))
                          (not first?)
                          (or action? reply?)))
               (fork? (or any? (pair? transitions)))
               (error? (error? event)))
          (when first?
            (format #t " + "))
          (when fork?
            (format #t "("))
          (unless error?
            (format #t "~a . " event))
          (when (and first? (trigger? event))
            (format #t "constrained_legal . "))
          (let ((next (next transition)))
            (cond (error?
                   (format #t "delta"))
                  ((null? next)
                   (let ((to (edge-to transition)))
                     (format #t "~aconstraint~a" name to)))
                  (else
                   (print-tree next))))
          (when any?
            (for-each
             (cute format #t "\n + ~a . ~aconstraint_any" <> name)
             actions+replies))
          (when (pair? transitions)
            (format #t "\n")
            (when (not first?)
              (format #t " + "))
            (print-tree transitions #:first? first? #:seen (cons event seen)))
          (when fork?
            (format #t ")"))
          (when first?
            (format #t "\n"))))

      (define (strip-modeling transition transitions)
        (let ((label (edge-label transition)))
          (if (not (modeling-event? label)) (cons transition transitions)
              (append (next transition) transitions))))

      (let* ((illegals transitions (partition transition-illegal? transitions))
             (transitions (fold strip-modeling '() transitions))
             (top-actions (filter-map (compose action? edge-label) transitions))
             (actions (filter (negate (cute member <> top-actions)) actions))
             (any? (not (command-line:get 'no-non-compliance))))
        (for-each print-illegal-transition illegals)
        (when (pair? transitions)
          (print-tree transitions #:first? #t))
        (when any?
          (for-each
           (cute format #t " + ~a . ~aconstraint_any\n" <> name)
           actions))))

    (define (print-node i node)
      (let* ((transitions (node-edges node))
             (labels (map edge-label transitions)))
        (when (or (= i initial)
                  (any (disjoin trigger? modeling-event?) labels))
          (format #t "\n~aconstraint~a\n = delta\n" name (node-state node))
          (when (pair? (node-edges node))
            (print-transitions transitions))
          (format #t ";\n"))))

    (format #t "~aconstraint_start = ~aconstraint~a;\n" name name initial)
    (vector-for-each print-node lts)))


;;;
;;; Entry point.
;;;
(define (interface->constraint root model)
  "Return constraint process as mCRL2 string from MODEL."
  (let* ((root (vm:normalize root))
         (model (ast:get-model root (ast:dotted-name model)))
         (aut (verify-pipeline "maut-weak-trace+hide" root model))
         (debugity (dzn:debugity))
         (lts (aut-text->lts aut)))
    (when (> debugity 0)
      (let ((stats (substring aut 0 (string-index aut #\newline))))
        (format (current-error-port) "# constraint: ~a\n" stats)))
    (when (> debugity 2)
      (display "lts:\n" (current-error-port))
      (for-each (cute write-line <> (current-error-port))
                (string-split aut #\newline)))
    (let ((makreel (with-output-to-string
                     (cute lts->makreel model lts))))
      (when (> debugity 2)
        (display "makreel:\n" (current-error-port))
        (display makreel (current-error-port)))
      makreel)))
