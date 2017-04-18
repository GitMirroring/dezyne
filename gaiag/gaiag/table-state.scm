;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag table-state)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 match)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)
  #:use-module (srfi srfi-1)

  #:use-module (language dezyne location)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast2om)
  #:use-module (gaiag om)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)

  #:use-module (gaiag dzn)
  #:use-module (gaiag evaluate)
  #:use-module (gaiag gaiag)
  #:use-module (gaiag json-table)
  #:use-module (gaiag misc)
  #:use-module (gaiag norm)
  #:use-module (gaiag norm-event)
  #:use-module (gaiag norm-state)
  #:use-module (gaiag reader)
  #:use-module (gaiag resolve)

  #:export (ast->
           mangle-table prepend-guards dzn-table remove-initial simplify table table-state))

;;(define debug stderr)
(define (debug . args) #t)

(define ((table table-statement) o)
  (match o
    (($ <root> (models ...))
     (let ((name
            (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                        string->symbol))))
       (or (and-let* ((models (.elements o))
                      ((pair? models))
                      (models (null-is-#f (filter (negate om:imported?) models)))
                      (models (null-is-#f (if name (and=> (find (om:named name) models) list) models))))
                     (make <root> #:elements (map (table table-statement) models))))))
    (($ <interface>)
     (let* ((statement (table-statement o ((compose .statement .behaviour) o)))
            (statement (remove-initial statement)))
       (make <interface>
         #:name (.name o)
         #:types (.types o)
         #:events (.events o)
         #:behaviour
         (make <behaviour>
           #:name ((compose .name .behaviour) o)
           #:types ((compose .types .behaviour) o)
           #:ports ((compose .ports .behaviour) o)
           #:variables ((compose .variables .behaviour) o)
           #:functions ((compose .functions .behaviour) o)
           #:statement statement))))
    (($ <component>)
     (or (and-let* ((behaviour (.behaviour o))
                    (statement (table-statement o ((compose .statement .behaviour) o)))
                    (statement (remove-initial statement)))
                   (make <component>
                     #:name (.name o)
                     #:ports (.ports o)
                     #:behaviour
                     (make <behaviour>
                       #:name ((compose .name .behaviour) o)
                       #:types ((compose .types .behaviour) o)
                       #:ports ((compose .ports .behaviour) o)
                       #:variables ((compose .variables .behaviour) o)
                       #:functions ((compose .functions .behaviour) o)
                       #:statement statement)))
         o))
    (_ o)))

(define (remove-initial o)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (or (and-let* (((not json?))
                   ((is-a? o <compound>))
                   (statements (.elements o))
                   ((=1 (length statements)))
                   (statement (car statements))
                   ((is-a? statement <guard>))
                   (field ((compose .value .expression) statement))
                   ((is-a? field <field>))
                   ((eq? (.name (.variable field)) '<state>))
                   ((eq? (.field field) '<Initial>)))
                  (make <compound>
                    #:elements (list
                               (make <guard>
                                 #:expression (make <expression> #:value 'true)
                                 #:statement (.statement statement)))))
        o)))


(define (var-bool? x) (and (is-a? x <variable>) (is-a? (.type x) <bool>)))

(define ((var? model) identifier) (om:variable model identifier))
(define (bool? x)
    (and (is-a? x <variable>) (is-a? (.type x) <bool>)))
(define (int? x)
    (and (is-a? x <variable>) (is-a? (.type x) <int>)))
(define ((int-var? model) x)
  (let ((v ((var? model) x)))
    (and (is-a? v <variable>) (is-a? (.type v) <int>))))

(define ((prepend-guards model) o)
  (let* ((variables ((compose .elements .variables .behaviour) model))
         (variable (find (lambda (v) (not (is-a? (.type v) <extern>))) variables))
         (type (and=> variable .type))
         (variable (or variable (make <variable> #:name '<state>)))
         (fields
          (match type
            (($ <enum>) (.elements (.fields type)))
            (($ <int>)
             (let ((range (.range type)))
               (iota (- (.to range) (.from range) -1) (.from range))))
            (($ <bool>) '(false true))
            (_  '(<Initial>))))
         (states (map (lambda (field) (make <field> #:variable variable #:field field)) fields))
         (guards (filter identity
                         (map (lambda (field)
                                (prepend-guard model variable field o))
                              fields))))
    (retain-source-properties o (make <compound> #:elements guards))))

(define ((prepend-guards-- model) o)
  (let* ((variables ((compose .elements .variables .behaviour) model))
         (types (map (om:type model) variables))
         (type (find (lambda (t) (negate (is? <extern>))) types))
         (enum
          (match type
            (($ <enum>) type)
            (($ <int>)
             (let* ((var (find int-var? variables))
                    (range (.range type)))
               (make <enum> #:name var #:fields (make <fields> #:elements (iota (- (.to range) (.from range) -1) (.from range))))))
            (($ <bool>)
             (let ((var (find var-bool? variables)))
               (make <enum> #:name var #:fields (make <fields> #:elements '(false true)))))
            (_  (make <enum> #:name (make <scope.name> #:name '<Temp>) #:fields (make <fields> #:elements '(<Initial>))))))
         (fields ((compose .elements .fields) enum))
         (states (map (lambda (field)
                        (make <literal>
                          #:type enum
                          #:field field)) fields))
         (guards (filter identity
                         (map (lambda (state)
                                (prepend-guard model state o))
                              states))))
    (retain-source-properties o (make <compound> #:elements guards))))

(define (prepend-guard model variable field o)
  (and-let* ((statement o)
             (statement (flatten-compound ((simplify model variable field #t) (flatten-compound o))))
             (var (make <var> #:variable variable))
             (expression
              (match (.type variable)
                (($ <bool>)
                 (match field
                   ('true (make <expression> #:value var))
                   ('false (make <expression> #:value (list '! var)))))
                (($ <int>) (make <expression> #:value (list '== var field)))
                (_ (make <expression> #:value (make <field> #:variable variable #:field field))))))
            (retain-source-properties
             (salvage-source-location model variable expression field o)
             (make <guard> #:expression expression #:statement statement))))

(define (salvage-source-location model variable expression field o)
  (let* ((expression2 (make <expression>
                        #:value (list '== (make <var> #:variable variable) field)))
         (guards (filter (lambda (g)
                           (let ((e (.expression g)))
                             (and (source-location g)
                                  (or (om:equal? e expression)
                                      (om:equal? e expression2)))))
                         ((om:collect <guard>) o))))
    (and (pair? guards) (car guards))))

(define (state-var model state)
  (define (type? v) (equal? (.type v) (.type state)))
  (find (lambda (v)
          (type? v)) ((compose .elements .variables .behaviour) model)))

(define (state-identifier model state)
  (or (and=> (state-var model state) .name) '<state>))

(define (make-state-field model state)
  (make <field> #:variable (or (state-var model state) '<state>) #:field (.field state)))

(define* ((simplify model variable field #:optional (top? #f)) o)
  (let ((r ((simplify- model variable field top?) o)))
    ;;(stderr "simplify ~a with variable:~a, field:~a=> ~a\n" o variable field r)
    r))

(define* ((simplify- model variable field #:optional (top? #f)) o)
  (match o
    (($ <compound> (statements ...))
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
              (not (null? (.elements o)))
              (om:declarative? o))
         #f)
        (else
         (retain-source-properties o (make <compound>
                                       #:elements
                                       ((simplify model variable field) statements)))))))

    (($ <on> triggers ($ <guard> ($ <expression> #t) statement)) (=> failure)
     (if field
         (retain-source-properties
          o
          (make <on>
            #:triggers triggers
            #:statement ((simplify model variable field) statement)))
         (failure)))

    (($ <guard> expression1 ($ <guard> expression2 statement))
     (and-let*
      ((statement ((simplify model variable field) statement))
       (value (simplify-literal model variable field (list 'and (.value expression1) (.value expression2))))
       (expression (cond ((and (om:equal? (.value expression1) value)
                               (is-a? expression1 <otherwise>))
                          expression1)
                         ((and (om:equal? (.value expression2) value)
                               (is-a? expression2 <otherwise>))
                          expression2)
                         (else (make <expression> #:value value))))
       (guard (retain-source-properties o (make <guard> #:expression expression #:statement statement))))
      ((simplify model variable field) guard)))

    (($ <guard> expression statement)
     (and-let* ((value (simplify-literal model variable field expression))
                (expression (if (is-a? value <otherwise>)
                                value
                                (make <expression> #:value value)))
                (statement ((simplify model variable field) statement)))
               (retain-source-properties
                o
                (match value
                  (#t (if (om:declarative? statement)
                          statement
                          (make <guard> #:expression expression #:statement statement)))
                  (($ <literal>)
                   (and (om:equal? value state)
                        (if (om:declarative? statement)
                            statement
                            (make <guard> #:expression expression #:statement statement))))
                  (_ (make <guard> #:expression expression #:statement statement))))))

    (($ <on> triggers statement)
     (and-let* ((statement ((simplify model variable field) statement)))
               (make <on> #:triggers triggers #:statement statement)))

    (($ <if> expression then #f)
     (or (and-let* ((value (simplify-literal model variable field expression))
                    (expression (make <expression> #:value value))
                    (then ((simplify model variable field) then)))
                   (match value
                     (#t then)
                     (($ <literal>) (and (om:equal? value field) then))
                     (_ (retain-source-properties o (make <if> #:expression expression #:then then)))))
         (make <compound>)))

    (($ <if> expression then else)
     (or (and-let* ((value (simplify-literal model variable field expression))
                    (expression (make <expression> #:value value)))
                   (let ((then ((simplify model variable field) then))
                         (else ((simplify model variable field) else)))
                     (match value
                       (#t then)
                       (($ <literal>) (and (om:equal? value field) then))
                       (_ (retain-source-properties o (make <if> #:expression expression #:then then #:else else))))))
         (and-let* ((then ((simplify model variable field) else))
                    (expression (list '! (.value expression))))
                   (retain-source-properties o (make <if> #:expression expression #:then then)))
         (make <compound>)))

    ((and (? (negate (is? <ast>))) (h t ...)) (map (simplify model variable field) o))
    (_ o)))

(define (simplify-literal model variable field o)
  (let* ((state (append `((,variable . ,field)) '())))
    (simplify-expression model state o)))

(define ((mangle-table json-table) o)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (match o
      (($ <root> (models ...))
       (if json?
           (map (mangle-table json-table) models)
           (make <root> #:elements (map (mangle-table json-table) models))))
      (($ <system>) (and (not json?) o))
      ((? (is? <model>))
       (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
         (if json?
             (and-let* ((behaviour (.behaviour o))
                        (statement (.statement behaviour)))
               (append
                (json-init o)
                ((json-table o) statement)))
             o)))
      ;;(#f (if (not json?) o (list (make-hash-table))))
      ;;((or #t #f) (and json? (list (make-hash-table))))
      (#f '())
      (_ (and (not json?) o)))))

(define (dzn-table o)
  (match o
    (($ <root> (t ...)) ((ast->dzn) o))
    (_ o)))

(define (switch-norm-event o)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (if json?
        (norm-event o)
        (table-norm-event o))))

(define (table-state model o)
  ((compose
    flatten-compound
    (aggregate-on norm:on-statement-equal?)
    (prepend-guards model)
    switch-norm-event
    (annotate-otherwise)
    ) o))

(define (ast-> ast)
  ((compose
    dzn-table
    (lambda (x) (if (is-a? x <ast>) (make <root> #:elements (om:filter identity x))
                    (filter identity x)))
    (mangle-table json-table-state)
    (table table-state)
    ast:resolve
    ast->om
    ) ast))
