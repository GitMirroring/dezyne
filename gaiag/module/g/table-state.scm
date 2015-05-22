;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (g table-state)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)    
  :use-module (ice-9 match)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (language dezyne location)
  :use-module (gaiag misc)
  
  :use-module (g om)
  :use-module (g gaiag)
  :use-module (g json-table)
  :use-module (g norm)
  :use-module (g norm-event)
  :use-module (g norm-state)  
  :use-module (gaiag reader)
  :use-module (g resolve)
  :use-module (g pretty)

  :export (ast->
           ;;annotate-otherwise
           mangle-table prepend-guards pretty-table remove-initial simplify table table-state))

(cond-expand
 (goops-om
  (use-modules (oop goops)))
 (else #t))

;;(define debug stderr)
(define (debug . args) #t)

(define ((table table-statement) o)
  (match o
    (('root models ___)
     (let ((name
            (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                        string->symbol))))
       (or (and-let* ((models (.elements o))
                      (models (null-is-#f (filter (negate om:imported?) models)))
                      (models (null-is-#f (if name (and=> (find (om:named name) models) list) models))))
                     (make <root> :elements (map (table table-statement) models))))))
    (('interface _ ___)
     (let* ((statement (table-statement o ((compose .statement .behaviour) o)))
            (statement (remove-initial statement)))
       (make <interface>
         :name (.name o)
         :types (.types o)
         :events (.events o)
         :behaviour
         (make <behaviour>
           :name ((compose .name .behaviour) o)
           :types ((compose .types .behaviour) o)
           :variables ((compose .variables .behaviour) o)
           :functions ((compose .functions .behaviour) o)
           :statement statement))))
    (('component _ ___)
     (or (and-let* ((behaviour (.behaviour o))
                    (statement (table-statement o ((compose .statement .behaviour) o)))
                    (statement (remove-initial statement)))
                   (make <component>
                     :name (.name o)
                     :ports (.ports o)
                     :behaviour
                     (make <behaviour>
                       :name ((compose .name .behaviour) o)
                       :types ((compose .types .behaviour) o)
                       :variables ((compose .variables .behaviour) o)
                       :functions ((compose .functions .behaviour) o)
                       :statement statement)))
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
                   ((eq? (.identifier field) '<state>))
                   ((eq? (.field field) '<Initial>)))
                  (make <compound>
                    :elements (list
                               (make <guard>
                                 :expression (make <expression> :value 'true)
                                 :statement (.statement statement)))))
        o)))

(define ((prepend-guards model) o)
  (or (and-let* ((variables ((compose .elements .variables .behaviour) model))
                 (types (map (om:type model) variables))
                 (enum (or (find (is? <enum>) types)
                           (make <enum> :fields (make <fields> :elements '(<Initial>)))))
                 (fields ((compose .elements .fields) enum))
                 (states (map (lambda (field)
                                (make <literal>
                                  :type (.name enum)
                                  :field field)) fields))
                 (guards (filter identity
                                 (map (lambda (state)
                                        (prepend-guard model state o))
                                      states))))
                (retain-source-properties o (make <compound> :elements guards)))
      o))

(define (prepend-guard model state o)
  (and-let* ((statement o)
             (statement (flatten-compound ((simplify model state #t) (flatten-compound o))))
             (field (make-state-field model state))
             (expression (make <expression> :value (make-state-field model state))))
            (retain-source-properties
             (salvage-source-location model state expression field o)
             (make <guard> :expression expression :statement statement))))

(define (salvage-source-location model state expression field o)
  (let* ((expression2 (make <expression>
                        :value (list '== (make <var>
                                           :name (.identifier field))
                                     state)))
                   (guards (filter (lambda (g) (let ((e (.expression g)))
                                                 (or (equal? e expression)
                                                     (equal? e expression2))))
                                   ((om:collect <guard>) o))))
    (and (pair? guards) (car guards))))

(define (state-var o state)
  (define (type? v) (eq? ((compose .name .type) v) (.type state)))
  (find type? ((compose .elements .variables .behaviour) o)))

(define (state-identifier o state)
  (or (and=> (state-var o state) .name) '<state>))

(define (make-state-field model state)
  (make <field> :identifier (state-identifier model state) :field (.field state)))

(define* ((simplify model :optional (state (make <literal>)) (top? #f)) o)
  (debug "simplify: ~a\n" o)
  (match o
    (('compound statements ___)
     (let* ((statements
             (let loop ((statements (.elements o)))
               (debug "loop\n")
               (if (null? statements)
                   '()
                   (let* ((statement ((simplify model state) (car statements))))
                     (if statement
                         (cons statement (loop (cdr statements)))
                         (loop (cdr statements))))))))
       (cond
        ((and (not top?) (=1 (length statements))) (car statements))
        ((and (null? statements) 
              (not (null? (.elements o)))
              (om:declarative? o)
              ;;#f
              )
         #f)
        (else
         (retain-source-properties o (make <compound>
                                       :elements 
                                       ((simplify model state) statements)))))))

    (('on triggers ('guard ('expression #t) statement)) (=> failure)
     (if (.field state)
         (retain-source-properties o (make <on>
                                       :triggers triggers
                                       :statement statement))
         (failure)))
    
    (('guard expression1 ('guard expression2 statement))
     (and-let*
      ((statement ((simplify model state) statement))
       (value (eval-expression model state (list 'and (.value expression1) (.value expression2))))
       (expression (cond ((and (equal? (.value expression1) value)
                               (is-a? expression1 <otherwise>))
                          expression1)
                         ((and (equal? (.value expression2) value) 
                               (is-a? expression2 <otherwise>))
                          expression2)
                         (else (make <expression> :value value))))
       (guard (make <guard> :expression expression :statement statement)))
      ((simplify model state) guard)))

    (('guard expression statement)
     (and-let* ((value (eval-expression model state expression))
                (expression (if (is-a? value <otherwise>)
                                value
                                (make <expression> :value value)))
                (statement ((simplify model state) statement)))
               (match value
                 (#t (if (om:declarative? statement) 
                         statement
                         (make <guard> :expression expression :statement statement)))
                 (('literal _ ___) (and (equal? value state) 
                                     (if (om:declarative? statement) 
                                         statement
                                         (make <guard> :expression expression :statement statement))))
                 (_ (make <guard> :expression expression :statement statement)))))

    (('on triggers statement)
     (debug "ON: 2\n")
     (and-let* ((statement ((simplify model state) statement)))
               (make <on> :triggers triggers :statement statement)))

    (
       ('if expression then) ;; FIXOZOR ME
     (or (and-let* ((value (eval-expression model state expression))
                    (expression (make <expression> :value value))
                    (then ((simplify model state) then)))
                   (match value
                     (#t then)
                     (('literal _ ___) (and (equal? value state) then))
                     (_ (retain-source-properties o (make <if> :expression expression :then then)))))
         (make <compound>)))

    (('if expression then else)
     (or (and-let* ((value (eval-expression model state expression))
                    (expression (make <expression> :value value)))
                   (let ((then ((simplify model state) then))
                         (else ((simplify model state) else)))
                     (match value
                       (#t then)
                       (('literal _ ___) (and (equal? value state) then))
                       (_ (retain-source-properties o (make <if> :expression expression :then then :else else))))))
         (and-let* ((then ((simplify model state) else))
                    (expression (list '! (.value expression))))
                   (retain-source-properties o (make <if> :expression expression :then then)))
         (make <compound>)))

    ((h t ...) (map (simplify model state) o))
    (_ o)))

(define (eval-expression model state o)

  (define (state-var? identifier) (eq? identifier (state-identifier model state)))

  (match o

    (('expression expression)
     (eval-expression model state expression))

    (('otherwise expression)
     (let ((value (eval-expression model state expression)))
       (match value
         (#t #t)
         (#f #f)
         (_ o))))

    (('literal _ ___) o)

    (('field (? state-var?) field)
     (eq? field (.field state)))

    (('field _ ___) o)

    (('== lhs rhs)
     (let ((lhs (eval-expression model state lhs))
           (rhs (eval-expression model state rhs)))
       (or (equal? lhs rhs)
           (if (and (is-a? lhs <literal>) (is-a? rhs <literal>))
               #f
               (list '== lhs rhs)))))

    (('!= lhs rhs)
     (let ((lhs (eval-expression model state lhs))
           (rhs (eval-expression model state rhs)))
       (or (not (equal? lhs rhs))
           (list '!= lhs rhs))))

    (('and lhs rhs)
     (let ((lhs (eval-expression model state lhs))
           (rhs (eval-expression model state rhs)))
       (and lhs rhs (cond
                     ((and (eq? lhs #t) (eq? rhs #t)) #t)
                     ((eq? lhs #t) rhs)
                     ((eq? rhs #t) lhs)
                     (else (list 'and lhs rhs))))))

    (('or lhs rhs)
     (let ((lhs (eval-expression model state lhs))
           (rhs (eval-expression model state rhs)))
       (and (or lhs rhs) (cond
                          ((or (eq? lhs #t) (eq? rhs #t)) #t)
                          ((equal? (list '! lhs) rhs) #t)
                          ((equal? (list '! rhs) lhs) #t)
                          ((eq? lhs #f) rhs)
                          ((eq? rhs #f) lhs)
                          (else (list 'or lhs rhs))))))

    (('! expression)
     (let ((expression (eval-expression model state expression)))
       (cond
        ((eq? expression #t) #f)
        ((eq? expression #f) #t)
        (else (list '! expression)))))

    (('group expression)
     (let ((expression (eval-expression model state expression)))
       (cond
        ((eq? expression #t) #t)
        ((eq? expression #f) #f)
        (else (list 'group expression)))))

    (('var (? state-var?)) state)

    (('var _ ___) o)

    ('false #f)
    ('true #t)

    (_
     ;;(debug "eval-expression: TODO: ~a\n" o)
     o
     )))

(define ((mangle-table json-table) o)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (match o
      (('root models ___)
       (if json?
           (map (mangle-table json-table) models)
           (make <root> :elements (map (mangle-table json-table) models))))
      (('system _ ___) (and (not json?) o))
      ((? (is? <model>))
       (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
         (if json?
             (and-let* ((behaviour (.behaviour o))
                        (statement (.statement behaviour)))
                       (alist->hash-table
                        (append
                         (json-init o)
                         ((json-table o) statement))))
             o)))
      ((or #t #f) (and json? (list (make-hash-table))))
      (_ (and (not json?) o)))))

(define (pretty-table o)
  (match o
    (('root _ ___) (ast->dzn o))
    (_ o)))

(define (table-state model o)
  ((compose
    flatten-compound
    (aggregate-on)
    (prepend-guards model)
    norm-event
    (annotate-otherwise)
    ) o))

(define (ast-> ast)
  ((compose
    pretty-table
    (mangle-table json-table-state)
    (table table-state)
    ast:resolve) ast))
