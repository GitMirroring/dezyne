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

(define-module (gaiag table-state)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 match)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (oop goops)

  :use-module (language dezyne location)
  :use-module (gaiag gaiag)
  :use-module (gaiag json-table)
  :use-module (gaiag misc)
  :use-module (gaiag norm)
  :use-module (gaiag pretty)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :use-module (gaiag gom)

  :export (ast-> table-state))

(define-method (table-state (o <list>))
  (filter identity (map table-state o)))

(define-method (table-state (o <root>))
  ;; FIXME: c&p csp.scm
  (let ((name
         (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                     string->symbol))))
    (or (and-let* ((models (null-is-#f (gom:models-with-behaviour o)))
                   (models (null-is-#f (filter (negate gom:imported?) models)))
                   (models (null-is-#f (if name (and=> (find (gom:named name) models) list) models))))
                  (map table-state models)))))

(define (has-enum? o)
  (null-is-#f (gom:enums (.behaviour o))))

(define-method (table-state (o <model>))
  (let ((statement (table-state o ((compose .statement .behaviour) o))))
    (make (class-of o)
      :name (.name o)
      :behaviour
      (make <behaviour>
        :name ((compose .name .behaviour) o)
        :functions ((compose .functions .behaviour) o)
        :statement statement))))

(define-method (table-state (o <import>))
  #f)

(define-method (table-state (o <type>))
  #f)

(define-method (table-state (model <model>) (o <boolean>)) #f)

(define-method (table-state (model <model>) (o <compound>))
  (or (and-let* ((variables ((compose .elements .variables .behaviour) model))
                 (types (map (gom:type model) variables))
                 (enum (or (find (is? <enum>) types)
                           (make <enum> :fields (make <fields> :elements '(Initial)))))
                 (fields ((compose .elements .fields) enum))
                 (states (map (lambda (field)
                                (make <literal>
                                  :type (.name enum)
                                  :field field)) fields))
                 (guards (filter identity
                                 (map (lambda (state)
                                        (table-state model state o))
                                      states))))
                (retain-source-properties o (make <compound> :elements guards)))
      o))

(define-method (table-state (model <model>) (state <literal>) (o <compound>))
  (and-let* ((statement (flatten-compound (evaluate model state (flatten-compound o)))))
            (let* ((field (make-field model state))
                   (expression (make <expression> :value (make-field model state)))
                   (expression2 (make <expression>
                                  :value (list '== (make <var>
                                                     :name (.identifier field))
                                               state)))
                   (guards (filter (lambda (g) (let ((e (.expression g)))
                                                 (or (equal? e expression)
                                                     (equal? e expression2))))
                                   ((gom:collect <guard>) o)))
                   (location (and (pair? guards) (car guards))))
              (retain-source-properties
               location (make <guard>
                          :expression expression
                          :statement statement)))))

(define-method (state-var (o <model>) (state <literal>))
  (define (type? v) (eq? ((compose .name .type) v) (.type state)))
  (find type? (gom:variables o)))

(define-method (state-identifier (o <model>) (state <literal>))
  (or (and=> (state-var o state) .name) 'state))

(define-method (make-field (model <model>) (state <literal>))
  (make <field> :identifier (state-identifier model state) :field (.field state)))

(define-method (declarative? (o <statement>))
  (or (is-a? o <guard>)
      (is-a? o <on>)
      (and (is-a? o <compound>)
           (>0 (length (.elements o)))
           (declarative? (car (.elements o))))))

(define-method (evaluate (model <model>) (state <literal>) o)
  (match o
    (($ <compound> statements)
     (let* ((statements
             (let loop ((statements (.elements o)))
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

    (($ <guard> expression ($ <on> triggers (and ($ <compound> (($ <guard> e s) ..1)) (get! compound))))
     (let ((ons
            (map (lambda (e s)
                   (let ((e (annotate-otherwise (compound) e)))
                     (evaluate model state
                               (make <on>
                                 :triggers triggers
                                 :statement (make <guard> :expression e :statement s)))))
                 e s)))
       (evaluate model state (make <guard>
                               :expression expression
                               :statement (retain-source-properties (compound) (make <compound> :elements ons))))))

    (($ <guard> expression ($ <on> triggers statement))
     (and-let*
      ((guard (make <guard> :expression expression :statement statement))
       (guard (evaluate model state guard)))
      (evaluate model state (make <on> :triggers triggers :statement guard))))

    (($ <guard> expression (and ($ <compound> (and (($ <on>) ..1) (get! ons))) (get! compound)))
     (and-let*
      ((guards (null-is-#f (filter identity (map (lambda (on) (make <guard> :expression expression :statement on)) (ons)))))
       (guards (null-is-#f (filter identity (map (lambda (guard) (evaluate model state guard)) guards)))))
      (if (=1 (length guards))
          (car guards)
          (retain-source-properties 
           (compound) 
           (evaluate model state (make <compound> :elements guards))))))

    (($ <guard> expression1 ($ <guard> expression2 statement))
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
     (and-let* ((guard (.statement o))
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
     (and-let* ((statement (evaluate model state statement)))
               (make <on> :triggers triggers :statement statement)))

    (($ <if> expression then #f)
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

(define-method (annotate-otherwise (o <compound>) (guard <guard>))
  (or (and-let* ((expression (.expression guard))
                 ((is-a? expression <otherwise>))
                 (expression (annotate-otherwise o expression))
                 (statement (.statement guard)))
                (retain-source-properties
                 guard
                 (make <guard> :expression expression :statement statement)))
      guard))

(define-method (annotate-otherwise (o <compound>) (expression <expression>))
  (or (and-let* ((guards ((gom:filter <guard>) (.elements o)))
                 ((is-a? expression <otherwise>))
                 (value (.value (guards-not-or guards))))
                (make <otherwise> :value value))
      expression))

(define-method (annotate-otherwise (o <compound>) (statement <statement>))
  statement)

(define-method (annotate-otherwise (o <compound>) (statement <boolean>))
  statement)

(define-method (eval-expression (model <model>) (state <literal>) o)

  (define (state-var? identifier) (eq? identifier (state-identifier model state)))

  (match o

    (($ <expression> expression) (eval-expression model state expression))

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
     ;;(stderr "eval-expression: TODO: ~a\n" o)
     o
     )))

;; shared with table-event
(define-method (mangle-table (o <list>))
  (map mangle-table o))

(define-method (mangle-table (o <boolean>))
  (if (option-ref (parse-opts (command-line)) 'json #f)
      (list (make-hash-table))))

(define-method (mangle-table (o <model>))
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f))
        (statement ((compose .statement .behaviour) o)))
    (if json?
        (alist->hash-table
         (append
          (json-init o)
          ((json-table o) statement)))
        (demo-table statement))))

(define-method (demo-table (o <compound>))
  (gom:map demo-table o))

(define-method (demo-table (o <list>))
  (map demo-table o))

(define-method (demo-table (o <guard>))
  o)

(define-method (demo-table (o <on>))
  o)

(define-method (pretty (o <ast>)) (ast->dezyne o))
(define-method (pretty (o <list>))
  (match o
    (((? (is? <ast>)) ...) (string-join (map ast->dezyne o)))
    (_ o)))
(define-method (pretty o) o)

(define (ast-> ast)
  ((compose
    pretty
    mangle-table
    table-state
    ast:resolve) ast))
