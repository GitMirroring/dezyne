;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022, 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2022, 2023, 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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

  #:use-module (dzn ast ast)
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn lts)
  #:use-module (dzn misc)
  #:use-module (dzn verify pipeline)

  #:export (interface->constraint
            interface->constraint-lts))

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
    (any (compose state? edge-label) (node-edges o)))

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

  (define (flush? o)
    (and (string? o)
         (string-contains o "'flush")
         o))

  (define (reply? o)
    (and (string? o)
         (string-contains o "'reply(")))

  (define (error? o)
    (and (string? o)
         (member o '("range_error"
                     "missing_reply"
                     "second_reply"))))

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

  (define (root-scope-enum value)
    (if (not (is-a? value <enum-literal>)) value
        (let* ((enum (.type value))
               (type-name (make <scope.name> #:ids (ast:full-name enum))))
          (clone value #:type.name type-name))))

  (define (model-replies)
    (let* ((values (append-map
                    (cute ast:return-values <> (make <literal>))
                    (ast:in-event* model)))
           (values (delete-duplicates values ast:equal?))
           (values (map root-scope-enum values))
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

      (define* (print-tree transitions #:key first? (seen '()) trigger-p?)
        (let* ((transition (car transitions))
               (events (map edge-label transitions))
               (transitions (cdr transitions))
               (event (edge-label transition))
               (action-events (filter action? events))
               (reply-events (filter reply? events))
               (events (lset-union equal? seen events))
               (action? (action? event))
               (replies (if (> (length reply-events) 1) '()
                            (filter (negate (cute member <> events)) replies)))
               (actions (if (> (length action-events) 1) '()
                            (filter (negate (cute member <> events)) actions)))
               (any? (and (not first?)
                          (or action? (reply? event))))
               (fork? (or any? (pair? transitions)))
               (error? (error? event)))
          (when first?
            (format #t " + "))
          (when fork?
            (format #t "("))
          (unless error?
            (format #t "~a . ~a" event (if (or (trigger? event)
                                               (state? event)
                                               (flush? event)) ""
                                               "compliance . ")))
          (when (and first? (trigger? event))
            (format #t "constrained_legal . "))
          (let ((next (next transition)))
            (cond (error?
                   (format #t "delta"))
                  ((null? next)
                   (let ((to (edge-to transition)))
                     (format #t "~aconstraint~a" name to)))
                  (else
                   (print-tree next #:trigger-p? (or trigger-p? (trigger? event))))))
          (when any?
            (for-each
             (cute format #t "\n + ~a . Non_Compliance" <>)
             actions)
            (for-each
             (cute format #t "\n + ~a . Non_Compliance" <>)
             replies))
          (when (pair? transitions)
            (format #t "\n")
            (when (not first?)
              (format #t " + "))
            (print-tree transitions #:first? first? #:seen (cons event seen)))
          (when fork?
            (format #t ")"))
          (when first?
            (format #t "\n"))))

      (let* ((illegals transitions (partition transition-illegal? transitions))
             (top-actions (filter-map (compose action? edge-label) transitions))
             (actions (filter (negate (cute member <> top-actions)) actions)))
        (for-each print-illegal-transition illegals)
        (when (pair? transitions)
          (print-tree transitions #:first? #t))
        (for-each
         (cute format #t " + ~a . Non_Compliance\n" <>)
         actions)))

    (define (print-node i node)
      (let* ((transitions (node-edges node))
             (labels (map edge-label transitions)))
        (when (or (= i initial)
                  (any state? labels))
          (format #t "\nproc ~aconstraint~a\n = delta\n"
                  name (node-state node))
          (when (pair? (node-edges node))
            (print-transitions transitions))
          (format #t ";\n"))))

    (format #t "proc ~aconstraint_start = ~aconstraint~a;\n" name name initial)
    (vector-for-each print-node lts)))


;;;
;;; Entry points.
;;;
(define (interface->constraint-lts-unmemoized model)
  "Return constraining LTS from MODEL."
  (let* ((root (ast:parent model <root>))
         (aut (verify-pipeline "maut-weak-trace+hide" root model))
         (debugity (dzn:debugity))
         (lts (aut-text->lts aut)))
    (when (> debugity 0)
      (let ((stats (substring aut 0 (string-index aut #\newline))))
        (format (current-error-port) "# constraint: ~a\n" stats)))
    (when (> debugity 0)
      (let ((stats (substring aut 0 (string-index aut #\newline))))
        (format (current-error-port) "# constraint: ~a\n" stats)))
    (when (> debugity 2)
      (display "lts:\n" (current-error-port))
      (for-each (cute write-line <> (current-error-port))
                (string-split aut #\newline)))
    lts))

(define (interface->constraint-lts o)
  ((ast:perfect-funcq interface->constraint-lts-unmemoized) o))

(define (interface->constraint model)
  "Return constraint process as mCRL2 string from MODEL."
  (let* ((lts (interface->constraint-lts model))
         (debug? (> (dzn:debugity) 2)))
    (when debug?
      (display "makreel:\n" (current-error-port)))
    (let ((makreel (with-output-to-string
                     (cute lts->makreel model lts))))
      (when debug?
        (display makreel (current-error-port)))
      makreel)))
