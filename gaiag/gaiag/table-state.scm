;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

(define-module (gaiag table-state)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 match)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)
  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag ast)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)

  #:use-module (gaiag dzn)
  #:use-module (gaiag evaluate)
  #:use-module (gaiag command-line)
  #:use-module (gaiag json-table)
  #:use-module (gaiag misc)
  #:use-module (gaiag norm)
  #:use-module (gaiag norm-event)
  #:use-module (gaiag norm-state)
  #:use-module (gaiag parse)
  #:use-module (gaiag resolve)

  #:export (ast->
            ast->table-state
            mangle-table
            prepend-guards
            remove-initial
            simplify
            table
            table-state))

;;(define debug stderr)
(define (debug . args) #t)

(define (table-filter o)
  (let ((name (and (and=> (gdzn:command-line:get 'model #f) string->symbol))))
    (and (is-a? o <model>)
         (not (ast:imported? o))
         (or (not name) ((om:named name) o)))))

(define ((table table-statement) o)
  (match o
    (($ <root>)
     (receive (table-models rest) (partition table-filter (ast:top* o))
              (clone o #:elements (append (map (table table-statement) table-models) rest))))
    (($ <interface>)
     (let* ((statement (table-statement o ((compose .statement .behaviour) o)))
            (statement (remove-initial statement)))
       (clone o #:behaviour (clone (.behaviour o) #:statement statement))))
    (($ <component>)
     (or (and-let* ((behaviour (.behaviour o))
                    (statement (table-statement o ((compose .statement .behaviour) o)))
                    (statement (remove-initial statement)))
                   (clone o #:behaviour (clone (.behaviour o) #:statement statement)))
         o))
    (_ o)))

(define (remove-initial o)
  (let ((json? (gdzn:command-line:get 'json #f)))
    (or (and-let* (((not json?))
                   ((is-a? o <compound>))
                   (statements (ast:statement* o))
                   ((=1 (length statements)))
                   (statement (car statements))
                   ((is-a? statement <guard>))
                   (field (.expression statement))
                   ((is-a? field <field-test>))
                   ((eq? (.variable.name field) '<state>))
                   ((eq? (.field field) '<Initial>)))
                  (make <compound>
                    #:elements (list
                               (make <guard>
                                 #:expression (make <literal> #:value 'true)
                                 #:statement (.statement statement)))))
        o)))


(define (var-bool? x) (and (is-a? x <variable>) (is-a? (.type x) <bool>)))

(define ((var? model) identifier) (resolve:variable model identifier))
(define (bool? x)
    (and (is-a? x <variable>) (is-a? (.type x) <bool>)))
(define (int? x)
    (and (is-a? x <variable>) (is-a? (.type x) <int>)))
(define ((int-var? model) x)
  (let ((v ((var? model) x)))
    (and (is-a? v <variable>) (is-a? (.type v) <int>))))

(define ((prepend-guards model) o)
  (let* ((variables ((compose ast:variable* .behaviour) model))
         (variable (find (lambda (v) (not (is-a? (.type v) <extern>))) variables))
         (type (and=> variable .type))
         (variable (or variable (clone (make <variable> #:name '<state> #:type.name (make <scope.name> #:name '<Initial>)) #:parent o)))
         (fields
          (match type
            (($ <enum>) (ast:field* type))
            (($ <int>)
             (let ((range (.range type)))
               (iota (- (.to range) (.from range) -1) (.from range))))
            (($ <bool>) '(false true))
            (_  '(<Initial>))))
         (guards (filter identity
                         (map (lambda (field)
                                (prepend-guard model variable field o))
                              fields)))
         (compound (make <compound> #:elements guards #:location (ast:location o))))
    (clone compound #:parent (.parent o))))

(define (prepend-guard model variable field o)
;;  (stderr "prepend-guard ~a --- ~a --- ~a\n" variable field o)
  (and-let* ((statement o)
             (statement (flatten-compound ((simplify model variable field #t) (flatten-compound o))))
             (var (clone (make <var> #:variable.name (.name variable)) #:parent o))
             (expression
              (match (.type variable)
                (($ <bool>)
                 (match field
                   ('true var)
                   ('false (make <not> #:expression var))))
                (($ <int>) (make <equal> #:left var #:right (make <literal> #:value field)))
                (_ (make <field-test> #:variable.name (.name variable) #:field field))))
             (guard
                 (let ((location (salvage-source-location model variable expression field o)))
                   (make <guard> #:expression expression #:statement statement #:location location))))
            (clone guard #:parent (.parent o))))

(define (salvage-source-location model variable expression field o)
  (let* ((expression2 (make <equal> #:left (make <var> #:variable.name (.name variable)) #:right (make <literal> #:value field)))
         (guards (filter (lambda (g)
                           (let ((e (.expression g)))
                             (and (ast:location g)
                                  (or (ast:equal? e expression)
                                      (ast:equal? e expression2)))))
                         ((om:collect <guard>) o))))
    (and (pair? guards) (ast:location (car guards)))))

(define (state-var model state)
  (define (type? v) (ast:equal? (.type v) (.type state)))
  (find (lambda (v) (type? v)) ((compose ast:variable* .behaviour) model)))

(define (state-identifier model state)
  (or (and=> (state-var model state) .name) '<state>))

(define (make-state-field model state)
  (make <field-test> #:variable.name (or (state-identifier model state) '<state>) #:field (.field state)))

(define* ((simplify model variable field #:optional (top? #f)) o)
  (let ((r ((simplify- model variable field top?) o)))
    r))

(define* ((simplify- model variable field #:optional (top? #f)) o)
  (match o
    ((and ($ <compound>) (= ast:statement* statements))
     (let* ((statements
             (let loop ((statements statements))
               (if (null? statements)
                   '()
                   (let* ((statement ((simplify model variable field) (car statements))))
                     (if statement
                         (cons statement (loop (cdr statements)))
                         (loop (cdr statements))))))))
       (cond
        ((and (not top?) (=1 (length statements))) (car statements))
        ((and (null? statements)
              (not (null? (ast:statement* o)))
              (om:declarative? o))
         #f)
        (else
         (clone o #:elements ((simplify model variable field) statements))))))

    ((and ($ <on>) (= .statement ($ <guard>)) (= (compose .expression .statement) #t)) (=> failure)
     (let ((statement ((compose .statement .statement) 0)))
       (if field
         (clone o #:statement ((simplify model variable field) statement))
         (failure))))

    ((and ($ <guard>) (= .statement ($ <guard>)))
     (and-let*
         ((expression1 (.expression o))
          (expression2 ((compose .expression .statement) o))
          (statement ((compose .statement .statement) o))
          (statement ((simplify model variable field) statement))
          (value (simplify-literal model variable field (make <and> #:left expression1 #:right expression2)))
          (expression (cond ((and (ast:equal? expression1 value)
                                  (is-a? expression1 <otherwise>))
                             expression1)
                            ((and (ast:equal? expression2 value)
                                  (is-a? expression2 <otherwise>))
                             expression2)
                            (else value)))
          (guard (clone o #:expression expression #:statement statement)))
       ((simplify model variable field) guard)))

    ((and ($ <guard>) (= .expression expr) (= .statement statement))
     (and-let* ((value (simplify-literal model variable field expr))
                (statement ((simplify model variable field) statement)))
       (match value
         ((and ($ <literal>) (= .value 'false)) #f)
         ((and ($ <literal>) (= .value 'true))
          (if #t ;;(om:declarative? statement) FIXME...
              (clone statement #:location (ast:location o))
              (clone o #:expression value #:statement statement)))
         (($ <enum-literal>)
          (and (ast:equal? value field)
               (if (om:declarative? statement)
                   (clone statement #:location (ast:location o))
                   (clone o #:expression value #:statement statement))))
         (_ (clone o #:expression value #:statement statement)))))

    ((and ($ <on>) (= .statement statement))
     (and-let* ((statement ((simplify model variable field) statement)))
       (clone o #:statement statement)))

    ((and ($ <if>) (= .expression expression) (= .then then) (= .else #f))
     (or (and-let* ((value (simplify-literal model variable field expression))
                    (then ((simplify model variable field) then)))
           (match value
             ((and ($ <literal>) (= .value 'true)) then)
             ((and ($ <literal>) (= .value 'false)) #f)
             (($ <enum-literal>) (and (ast:equal? value field) then))
             (_ (clone o #:expression value #:then then))))
         (make <compound>)))

    ((and ($ <if>) (= .expression expression) (= .then then) (= .else else))
     (or (and-let* ((value (simplify-literal model variable field expression)))
           (let ((then ((simplify model variable field) then))
                 (else ((simplify model variable field) else)))
             (match value
               ((and ($ <literal>) (= .value 'true)) then)
               ((and ($ <literal>) (= .value 'false)) else)
               (($ <enum-literal>) (and (ast:equal? value field) then)) ;; TODO
               (_ (clone o #:expression value #:then then #:else else)))))
         (and-let* ((then ((simplify model variable field) (.else o)))
                    (expression (make <not> #:expression (.expression o))))
           (clone o #:expression expression #:then then))
         (make <compound>)))

    ((and (? (negate (is? <ast>))) (h t ...)) (map (simplify model variable field) o))
    (_ o)))

(define (simplify-literal model variable field o)
  (let* ((state (acons (om->list variable) field '()))
         (simple (simplify-expression model state o)))
    (match simple
      ((? (is? <expression>)) simple)
      (#t (make <literal> #:value 'true))
      (#f (make <literal> #:value 'false))
      (_ (make <literal> #:value simple)))))

(define ((mangle-table json-table) o)
  (match o
      ((and ($ <root>) (= ast:top* elements))
       (filter-map (mangle-table json-table) (filter table-filter elements)))
      (($ <system>) #f)
      (($ <foreign>) #f)
      ((? (is? <model>))
       (and-let* ((behaviour (.behaviour o))
                  (statement (.statement behaviour)))
                 (append
                  (json-init o)
                  ((json-table o) statement))))
      (_ #f)))

(define (switch-norm-event o)
  (let ((json? (gdzn:command-line:get 'json #f)))
    (if json?
        (norm-event o)
        (table-norm-event o))))

(define (table-state model o)
  ((compose
;;    (lambda (o) (pke 'flatten-compound o))
    flatten-compound
;;    (lambda (o) (pke 'aggregate-on o))
    (aggregate-on norm:on-statement-equal?)
;;    (lambda (o) (pke 'prepend-guards o))
    (prepend-guards model)
;;    (lambda (o) (pke 'switch-norm-event o))
    switch-norm-event
;;    (lambda (o) (pke 'annotate-otherwise o))
    (annotate-otherwise)
    ) o))

(define (ast->table-state ast)
  ((compose
    (table table-state)
    ast:resolve)
   ast))

(define (root->table o)
  (let ((json? (gdzn:command-line:get 'json #f)))
    (if json?
        ((mangle-table json-table-state) o)
        (ast->dzn o)))
  )

(define (ast-> ast)
  ((compose
    root->table
    ast->table-state)
   ast))
