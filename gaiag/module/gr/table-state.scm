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

(define-module (gr table-state)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)  
  :use-module (ice-9 match)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (language dezyne location)
  :use-module (gaiag misc)
  
  :use-module (gr om)
  :use-module (gr gaiag)
  :use-module (gr json-table)
  :use-module (gr norm)
  :use-module (gr norm-state)
  :use-module (gaiag reader)
  :use-module (gr resolve)
  :use-module (gr pretty)

  :export (ast-> mangle-table pretty-table remove-initial table table-state-statement))

(cond-expand
 (goops-om
  (use-modules (oop goops)))
 (else #t))

;;(define debug stderr)
(define (debug . args) #t)

(define ((table table-statement) o)
  (match o
    (($ <root> models)
     (let ((name
            (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                        string->symbol))))
       (or (and-let* ((models (.elements o))
                      (models (null-is-#f (filter (negate om:imported?) models)))
                      (models (null-is-#f (if name (and=> (find (om:named name) models) list) models))))
                     (make <root> :elements (map (table table-statement) models))))))
    (($ <interface>)
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
    (($ <component>)
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

(define (handle-initial statement)
  (or (and-let* (((is-a? statement <guard>))
                 (field ((compose .value .expression) statement))
                 ((is-a? field <field>))
                 ((eq? (.identifier field) '<state>))
                 ((eq? (.field field) '<Initial>)))
                (.statement statement))
      (and-let* (((is-a? statement <on>)))
                (make <on>
                  :triggers (.triggers statement)
                  :statement (handle-initial (.statement statement))))
      (and-let* (((is-a? statement <compound>)))
                (make <compound>
                  :elements (map handle-initial (.elements statement))))
      statement))

(define (remove-initial statement)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (or (and-let* (((not json?))
                   ((is-a? statement <compound>))
                   (elements (map handle-initial (.elements statement))))
                  (make <compound> :elements elements))
     statement)))

(define (table-state-statement model o)
  (match o
    (($ <compound>)
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
                                           (table-state-state model state o))
                                         states))))
                   (retain-source-properties o (make <compound> :elements guards)))
         o))
    (_ o)
    ))

(define (table-state-state model state o)
  (and-let* ((statement (flatten-compound (evaluate model state (flatten-compound o)))))
            (let* ((field (make-state-field model state))
                   (expression (make <expression> :value (make-state-field model state)))
                   (expression2 (make <expression>
                                  :value (list '== (make <var>
                                                     :name (.identifier field))
                                               state)))
                   (guards (filter (lambda (g) (let ((e (.expression g)))
                                                 (or (equal? e expression)
                                                     (equal? e expression2))))
                                   ((om:collect <guard>) o)))
                   (location (and (pair? guards) (car guards))))
              (retain-source-properties
               location (make <guard>
                          :expression expression
                          :statement statement)))))

(define (state-var o state)
  (define (type? v) (eq? ((compose .name .type) v) (.type state)))
  (find type? ((compose .elements .variables .behaviour) o)))

(define (state-identifier o state)
  (or (and=> (state-var o state) .name) '<state>))

(define (make-state-field model state)
  (make <field> :identifier (state-identifier model state) :field (.field state)))

(define (declarative? o)
  (or (is-a? o <guard>)
      (is-a? o <on>)
      (and (is-a? o <compound>)
           (>0 (length (.elements o)))
           (declarative? (car (.elements o))))))

(define (evaluate model state o)
  (debug "evaluate\n")
  ;;(pretty-print (om->list o));;-goeps
  (match o
    (($ <compound> statements)
     (let* ((statements
             (let loop ((statements (.elements o)))
               (debug "loop\n")
               (if (null? statements)
                   '()
                   (let* ((statement (annotate-otherwise o (car statements)))
                          (statement (evaluate model state statement)))
                     (if statement
                         (cons statement (loop (cdr statements)))
                         (loop (cdr statements))))))))
       (cond
        ((=1 (length statements)) (car statements))
        ((and (null? statements) 
              (not (null? (.elements o)))
              (is-a? (car (.elements o)) <guard>))
         #f)
        (else
         (retain-source-properties o (make <compound> :elements 
                                           (map (lambda (o) (evaluate model state o)) statements)))))))

    (
     ($ <guard> expression ($ <on> triggers (and ($ <compound> (($ <guard> e s) ..1)) (get! compound)))) ;;-goeps
     ;;+goeps ($ <guard> expression ($ <on> triggers (and ($ <compound> ($ <guard>) ..1) (get! compound)))) 
     (debug "GUARD: 1\n")
     (let ((ons
            (map (lambda (e s)
                   (let ((e (annotate-otherwise (compound) e)))
                     (evaluate model state
                               (make <on>
                                 :triggers triggers
                                 :statement (make <guard> :expression e :statement s)))))
                 e s;;-goeps
                 ;;+goeps (map .expression (.elements (compound)))
                 ;;+goeps (map .statement (.elements (compound)))
                 )))
       (evaluate model state (make <guard>
                               :expression expression
                               :statement (retain-source-properties (compound) (make <compound> :elements ons))))))

    (($ <guard> expression ($ <on> triggers statement))
     (debug "GUARD: 2\n")
     (and-let*
      ((guard (make <guard> :expression expression :statement statement))
       (guard (evaluate model state guard)))
      (evaluate model state (make <on> :triggers triggers :statement guard))))

    (
     ($ <guard> expression (and ($ <compound> (and (($ <on>) ..1) (get! ons))) (get! compound))) ;;-goeps
     ;;+goeps ($ <guard> expression (and ($ <compound> ($ <on>) ..1) (get! compound)))
     (debug "GUARD: 3\n")
     (and-let*
      ((guards (null-is-#f (filter identity (map (lambda (on) (make <guard> :expression expression :statement on))
                                                 (ons) ;;-goeps
                                                 ;;+goeps (.elements (compound))
                                                 ))))
       (guards (null-is-#f (filter identity (map (lambda (guard) (evaluate model state guard)) guards)))))
      (if (=1 (length guards))
          (car guards)
          (retain-source-properties 
           (compound) 
           (evaluate model state (make <compound> :elements guards))))))

    (($ <guard> expression1 ($ <guard> expression2 statement))
     (debug "GUARD: 4\n")
     (and-let*
      ((statement (evaluate model state statement))
       (value (eval-expression model state (list 'and (.value expression1) (.value expression2))))
       (expression (cond ((and (equal? (.value expression1) value)
                               (is-a? expression1 <otherwise>))
                          expression1)
                         ((and (equal? (.value expression2) value) 
                               (is-a? expression2 <otherwise>))
                          expression2)
                         (else (make <expression> :value value))))
       (guard (make <guard> :expression expression :statement statement)))
      (evaluate model state guard)))

    (($ <guard> expression statement)
     (debug "GUARD: 5\n")
     (and-let* ((value (eval-expression model state expression))
                (expression (if (is-a? value <otherwise>)
                                value
                                (make <expression> :value value)))
                (statement (evaluate model state statement)))
               (match value
                 (#t (if (declarative? statement) 
                         statement
                         (make <guard> :expression expression :statement statement)))
                 (($ <literal>) (and (equal? value state) 
                                     (if (declarative? statement) 
                                         statement
                                         (make <guard> :expression expression :statement statement))))
                 (_ (make <guard> :expression expression :statement statement)))))

    (($ <on> triggers ($ <guard> expression statement))
     (debug "ON: 1\n")
     (and-let* ((guard (.statement o))
                ((debug "VAL: ~a\n"(eval-expression model state expression) ))
                (value (eval-expression model state expression)))
               (match value
                 (#t (evaluate model state (make <on> :triggers triggers :statement statement)))
                 (($ <literal>) (and (equal? value state)
                                     (evaluate model state
                                               (make <on>
                                                 :triggers triggers
                                                 :statement statement))))
                 (_ (make <on> :triggers triggers :statement (evaluate model state guard))))))

    (($ <on> triggers statement)
     (debug "ON: 2\n")
     (and-let* ((statement (evaluate model state statement)))
               (make <on> :triggers triggers :statement statement)))

    (
     ($ <if> expression then #f) ;;-goeps
      ;;+goeps ($ <if> expression then)
     (and-let* ((value (eval-expression model state expression))
                (expression (make <expression> :value value))
                (then (evaluate model state then)))
               (match value
                 (#t then)
                 (($ <literal>) (and (equal? value state) then))
                 (_ (retain-source-properties o (make <if> :expression expression :then then))))))

    (($ <if> expression then else)
     (or (and-let* ((value (eval-expression model state expression))
                    (expression (make <expression> :value value)))
                   (let ((then (evaluate model state then))
                         (else (evaluate model state else)))
                     (match value
                       (#t then)
                       (($ <literal>) (and (equal? value state) then))
                       (_ (retain-source-properties o (make <if> :expression expression :then then :else else))))))
         (and-let* ((then (evaluate model state else))
                    (expression (list '! (.value expression))))
                   (retain-source-properties o (make <if> :expression expression :then then)))))

    (_ o)))

(define (annotate-otherwise compound o)
  (match o
    (($ <guard>)
     (or (and-let* ((expression (.expression o))
                    ((is-a? expression <otherwise>))
                    (expression (annotate-otherwise compound expression))
                    (statement (.statement o)))
                   (retain-source-properties
                    o
                    (make <guard> :expression expression :statement statement)))
         o))
    (($ <otherwise>)
     (or (and-let* ((guards ((om:filter <guard>) (.elements compound)))
                    (value (.value (guards-not-or guards))))
                   (make <otherwise> :value value))
         o))
    (_ o)))

(define (eval-expression model state o)

  (define (state-var? identifier) (eq? identifier (state-identifier model state)))

  (match o

    (
     ($ <expression> expression) ;;-goeps
     ;;+goeps ;;($ <expression> expression)
     ;;+goeps ('expression expression)
     (eval-expression model state expression))

    (($ <otherwise> expression)
     (let ((value (eval-expression model state expression)))
       (match value
         (#t #t)
         (#f #f)
         (_ o))))

    (($ <literal>) o)

    (($ <field> (? state-var?) field)
     (eq? field (.field state)))

    (($ <field>) o)

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

    (($ <var> (? state-var?)) state)

    (($ <var>) o)

    ('false #f)
    ('true #t)

    (_
     ;;(debug "eval-expression: TODO: ~a\n" o)
     o
     )))

(define ((mangle-table json-table) o)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (match o
      (($ <root> models)
       (if json?
           (map (mangle-table json-table) models)
           (make <root> :elements (map (mangle-table json-table) models))))
      (($ <system>) (and (not json?) o))
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
    (($ <root>) (ast->dzn o))
    (_ o)))

(define (ast-> ast)
  ((compose
    pretty-table
    (mangle-table json-table-state)
    (table table-state-statement)
    ast:resolve) ast))
