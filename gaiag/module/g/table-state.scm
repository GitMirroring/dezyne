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
  :use-module (ice-9 match)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (language dezyne location)
  :use-module (g g)
  :use-module (g ast-colon)
  :use-module (g json-table)
  :use-module (g misc)
  :use-module (g norm)
  :use-module (g pretty)
  :use-module (g reader)
  :use-module (g resolve)

  :use-module (gaiag annotate)

  :export (ast-> ;;;mangle-table
                 pretty-table remove-initial table-state table-state-statement))

(define (table-state o)
  (match o
    (('root models ...)
     (let ((name
            (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                        string->symbol))))
       (or (and-let* ((models (null-is-#f (filter (negate ast:imported?) models)))
                      (models (null-is-#f (if name (and=> (find (ast:named name) models) list) models))))
                     (cons 'root (filter identity (map table-state models)))))))
    (('interface name types events ('behaviour b btypes variables functions statement))
     (let* ((statement (table-state-statement o statement))
            (statement (remove-initial statement)))
       (list 'interface name types events
             (list 'behaviour b btypes variables functions statement))))
    (('component name ports ('behaviour b types variables functions statement))
     (let* ((statement (table-state-statement o statement))
            (statement (remove-initial statement)))
       (list 'component name ports
             (list 'behaviour b types variables functions statement))))
    (('component name ports) o)
    (((or 'enum 'extern 'int 'import 'system) _ ...) o)
    (_ (throw 'match-error (format #f "~a:table-state: no match: ~a\n" (current-source-location) o)))))

(define (remove-initial o)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (if json?
        o
        (match o
          (('compound statements ...)
           (cons 'compound  (map remove-initial statements)))
          (('on t s) (list 'on t (remove-initial s)))
          (('guard ('expression ('field '<state> '<Initial>)) s) s)
          (_ o)))))

(define (retain-source-properties o t)
  (and-let* (((supports-source-properties? o))
             ((supports-source-properties? t)))
            (set-source-properties! t (source-properties o)))
  t)

(define (table-state-statement model o)
  (or (and-let* ((variables ((compose ast:variables ast:behaviour) model))
                 (types (map (ast:def model) variables))
                 (enum (or (find (ast:is? 'enum) types)
                           (list 'enum #f '(<Initial>))))
                 (fields (ast:fields enum))
                 (states (map (lambda (field)
                                (list 'literal
                                      #f
                                      (ast:name enum)
                                      field)) fields))
                 (guards (filter identity
                                 (map (lambda (state)
                                        (table-state-state model state o))
                                      states))))
                (retain-source-properties o (cons 'compound guards)))
      o))

(define (table-state-state model state o)
  (and-let* ((statement (flatten-compound (evaluate model state (flatten-compound o)))))

            (let* ((field (make-field model state))
                   (expression (list 'expression (make-field model state)))
                   (expression2 (list 'expression (list '== (list 'var (ast:identifier field)) state)))
                   (guards (filter (lambda (g) (let ((e (ast:expression g)))
                                                 (or (equal? e expression)
                                                     (equal? e expression2))))
                                   (filter (ast:is? 'guard) o)))
                   (location (and (pair? guards) (car guards))))
              (retain-source-properties location (list 'guard expression statement)))))

(define (make-field model state)
  (list 'field (state-identifier model state) (ast:field state)))

(define (state-identifier model state)
  (or (and=> (state-var model state) ast:name) '<state>))

(define (state-var model state)
  (define (type? v) (eq? ((compose ast:name ast:type) v) (ast:type state)))
  (find type? (ast:variables model)))

(define (declarative? o)
  (or (ast:is-a? o 'guard)
      (ast:is-a? o 'on)
      (and (ast:is-a? o 'compound)
           (>0 (length (cdr o)))
           (declarative? (car (cdr o))))))

(define (evaluate model state o)
  (match o
    (('compound statements ...)
     (let* ((statements
             (let loop ((statements statements))
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
              (not (null? (cdr o)))
              (ast:is-a? (car (cdr o)) 'guard))
         #f)
        (else
         (retain-source-properties o (cons 'compound (map (lambda (o) (evaluate model state o)) statements)))))))

    (;;('guard expression ('on triggers (and ('compound (('guard e s) ..1)) (get! compound))))
     ('guard expression ('on triggers (and ('compound ('guard _ _) ..1) (get! compound))))     
     (let ((ons
            (map (lambda (e s)
                   (let ((e (annotate-otherwise (compound) e)))
                     (evaluate model state
                               (list 'on
                                 triggers
                                 (list 'guard e s)))))
                 ;;e s
                 (map ast:expression (cdr (compound)))
                 (map ast:statement (cdr (compound)))                 
                 )))
       (evaluate model state (list 'guard
                               expression
                               (retain-source-properties (compound) (cons 'compound  ons))))))

    (('guard expression ('on triggers statement))
     (and-let*
      ((guard (list 'guard expression statement))
       (guard (evaluate model state guard)))
      (evaluate model state (list 'on triggers guard))))

    (;;('guard expression ('compound (and (('on t s) ...) (get! ons))))
     ('guard expression (and ('compound ('on _ ...) ..1) (get! compound)))
     (and-let*
      ((guards (null-is-#f (filter identity (map (lambda (on) (list 'guard expression on)) (cdr (compound))))))
       (guards (null-is-#f (filter identity (map (lambda (guard) (evaluate model state guard)) guards)))))
      (if (=1 (length guards))
          (car guards)
          (retain-source-properties 
           (compound) 
           (evaluate model state (cons 'compound guards))))))

    (('guard expression1 ('guard expression2 statement))
     (and-let*
      ((statement (evaluate model state statement))
       (value (eval-expression model state (list 'and (ast:value expression1) (ast:value expression2))))
       (expression (cond ((and (equal? (ast:value expression1) value)
                               (ast:is-a? expression1 'otherwise))
                          expression1)
                         ((and (equal? (ast:value expression2) value) 
                               (ast:is-a? expression2 'otherwise))
                          expression2)
                         (else (list 'expression value))))
       (guard (list 'guard expression statement)))
      (evaluate model state guard)))

    (('guard expression statement)
     (and-let* ((value (eval-expression model state expression))
                (expression (if (ast:is-a? value 'otherwise)
                                value
                                (list 'expression value)))
                (statement (evaluate model state statement)))
               (match value
                 (#t (if (declarative? statement) 
                         statement
                         (list 'guard expression statement)))
                 (('literal) (and (equal? value state) 
                                     (if (declarative? statement) 
                                         statement
                                         (list 'guard expression statement))))
                 (_ (list 'guard expression statement)))))

    (('on triggers ('guard expression statement))
     (and-let* ((guard (ast:statement o))
                (value (eval-expression model state expression)))
               (match value
                 (#t (evaluate model state (list 'on triggers statement)))
                 (('literal) (and (equal? value state)
                                     (evaluate model state
                                               (list 'on
                                                 triggers
                                                 statement))))
                 (_ (list 'on triggers (evaluate model state guard))))))

    (('on triggers statement)
     (and-let* ((statement (evaluate model state statement)))
               (list 'on triggers statement)))

    (('if expression then #f ...)
     (and-let* ((value (eval-expression model state expression))
                (expression (list 'expression value))
                (then (evaluate model state then)))
               (match value
                 (#t then)
                 (('literal) (and (equal? value state) then))
                 (_ (retain-source-properties o (list 'if expression then))))))

    (('if expression then else)
     (or (and-let* ((value (eval-expression model state expression))
                    (expression (list 'expression value)))
                   (let ((then (evaluate model state then))
                         (else (evaluate model state else)))
                     (match value
                       (#t then)
                       (('literal) (and (equal? value state) then))
                       (_ (retain-source-properties o (list 'if expression then else))))))
         (and-let* ((then (evaluate model state else))
                    (expression (list '! (ast:value expression))))
                   (retain-source-properties o (list 'if expression then)))))

    (_ o)))

(define (annotate-otherwise compound o)
  (match o
    (('guard expression statement)
     (or (and-let* (((ast:is-a? expression 'otherwise))
                    (expression (annotate-otherwise compound expression)))
                   (retain-source-properties o (list 'guard expression statement)))
         o))
    (('otherwise value ...)
     (or (and-let* ((guards (filter (ast:is? 'guard) compound))
                    (value (ast:value (guards-not-or guards))))
                   (list 'otherwise value))
         o))
    (_ o)))

(define (eval-expression model state o)

  (define (state-var? identifier) (eq? identifier (state-identifier model state)))

  (match o

    (('expression expression) (eval-expression model state expression))

    (('otherwise expression)
     (let ((value (eval-expression model state expression)))
       (match value
         (#t #t)
         (#f #f)
         (_ o))))

    (('literal t ...) o)

    (('field (? state-var?) field)
     (eq? field (ast:field state)))

    (('field t ...) o)

    (('== lhs rhs)
     (let ((lhs (eval-expression model state lhs))
           (rhs (eval-expression model state rhs)))
       (or (equal? lhs rhs)
           (if (and (ast:is-a? lhs 'literal) (ast:is-a? rhs 'literal))
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

    (('var t ...) o)

    ('false #f)
    ('true #t)

    ('#f #f)
    ('#t #t)

    (_
     ;; (stderr "eval-expression: TODO: ~a\n" o)
     o
     )))

(define (mangle-table o)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (match o
      (('root models ...)
       (if json?
           (map mangle-table models)
           (cons 'root (map mangle-table models))))
      ((or
        (? ast:interface?)
        (? ast:component?)
        )
       (if json?
           (and-let* ((behaviour (null-is-#f (ast:behaviour o)))
                      (statement (ast:statement behaviour)))
                     (alist->hash-table
                      (append
                       (json-init o)
                       ((json-table-state o) statement))))
           o))
      (((or 'enum 'extern 'int 'import 'system) _ ...) (and (not json?) o))
      ;; ((h t ...) (map mangle-table o))
      ((or #t #f) (and json? (list (make-hash-table)))))))

(define (pretty-table o)
  (match o
    ((? ast:ast?) (ast->dzn o))
    (((? ast:ast?) ...) (string-join (map ast->dzn o) "\n"))
    (_ o)))

(define (ast-> ast)
  ((compose
    pretty-table
    mangle-table
    table-state
    ast:reorder-for-gaiag-equiv
    ast:resolve
    ast:annotate) ast))
