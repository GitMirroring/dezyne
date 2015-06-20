;;; Dezyne --- Dezyne command line tools
;;;
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

(define-module (gaiag evaluate)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)
  :use-module (gaiag list match)
  :use-module (srfi srfi-1)

  :use-module (gaiag ast)
  :use-module (gaiag misc)

  :export (
           eval-expression
           simplify-expression
           variable-state
           undefined-state-vector
           state-vector
           var
           var!
           ))


(define* ((variable-state model :optional (init .expression)) variable)
  (cons
   (.name variable)
   (eval-expression model '() (init variable))))

(define (state-vector model)
  (map (variable-state model) (om:variables model)))

(define* ((undefined-variable-state model :optional (init .expression)) variable)
  (cons
   (.name variable)
   ;;(eval-expression model '() (init variable))
   (init variable)
   ))

(define (undefined-state-vector model)
  (map (undefined-variable-state model (init-undefined model)) (om:variables model)))

(define* ((undefined-variable-state model :optional (init .expression)) variable)
  (cons
   (.name variable)
   ;;(eval-expression model '() (init variable))
   (init variable)
   ))

(define ((init-undefined model) o)
  (let* ((type ((om:type model) o)))
    (match type
      (_ (make <var> :name (.name o)))

      (_ *unspecified*)
      (($ <enum> name scope field) (make <literal> :scope scope :type name :field *unspecified*))
      (($ <int> name scope range) *unspecified*)
      ;;(($ <type> 'bool) *unspecified*)
      (($ <type> 'bool) (make <var> :name (.name o)))
      (_ (stderr "FIXME: INIT VAR: a\n" o))
      )))

(define (var state identifier) (assoc-ref state identifier))

(define (var! state identifier value)
  (assoc-set!
   (map (lambda (x) (if (eq? identifier (car x)) (cons (car x) (cdr x)) x)) state)
   identifier value))

(define ((var? model) identifier) (om:variable model identifier))

(define (bool? x) (and (is-a? x <*type*>) (eq? (.name x) 'bool)))
(define ((bool-var? model) x) (let ((v ((var? model) x)))
                                (and (is-a? v <variable>) (bool? (.type v)))))
(define ((int? model) x)
  (is-a? ((om:type model) x) <int>))
(define ((int-var? model) x)
  (let ((v ((var? model) x)))
    (and (is-a? v <variable>) ((int? model) v))))

(define (eval-expression model state o)
  (match o
    (($ <expression> value) (eval-expression model state value))
    (($ <otherwise> value) (eval-expression model state value))
    (#t #t)
    ('false #f)
    ('true #t)
    (($ <var> identifier) (var state identifier))
    (($ <field> (and (? (var? model)) (get! identifier)) field)
     (eq? (.field (var state (identifier))) field))
    (($ <literal> scope type value) o)
    (('! expr) (not (eval-expression model state expr)))
    (('and x y) (and (eval-expression model state x)
                     (eval-expression model state y)))
    (('or x y) (or (eval-expression model state x)
                   (eval-expression model state y)))
    ((== x y)
     (let* ((lhs (eval-expression model state x))
            (rhs (eval-expression model state y))
            (r (equal? lhs rhs)))
     r))
    (('group expression)
     (eval-expression model state expression))
    ((? symbol?) (eval-expression model state (var state o)))
    ((? boolean?) o)
    ((? number?) o)))

(define (simplify-expression model state o)
  (let ((e (simplify-expression- model state o)))
    (match e
      ((? boolean?) e)
      (($ <var> name) e)
      (($ <literal>) e)
      (_ e))))

(define (simplify-expression- model state o)
  (define (unspec v f) (if (is-a? v <var>) o (f v)))
  (match o
    (#f #f)
    (#t #t)
    ('false #f)
    ('true #t)

    (($ <expression> value) (simplify-expression model state value))

    (($ <otherwise> expression)
     (let ((value (simplify-expression model state expression)))
       (match value
         (#t #t)
         (#f #f)
         (_ o))))

    (($ <var> (and (? (bool-var? model)) (get! identifier)))
     (let ((var (var state (identifier))))
       (match var
         (($ <literal> scope type field) (eq? field 'true))
         (#f o)
         (_ var))))

    (($ <var> (and (? (int-var? model)) (get! identifier)))
     (let ((var (var state (identifier))))
       (match var
         (($ <literal> scope type field) field)
         ((? number?) var)
         (_ var))))

    (($ <var> identifier)
     (or (var state identifier) o))

    (($ <field> (and (? (var? model)) (get! identifier)) field)
     (let ((v (var state (identifier))))
       (if (is-a? v <literal>)
           (eq? (.field v) field)
           o)))

    (($ <literal> scope type value) o)

    (('== a b)
     (let ((a (simplify-expression model state a))
           (b (simplify-expression model state b)))
       (or (om:equal? a b)
           (match (cons a b)
             ((($ <literal>) . ($ <literal>)) #f)
             (((? number?) . (? number?)) (eq? a b))
             (_ (list '== a b))))))

    (('!= a b)
     (let ((a (simplify-expression model state a))
           (b (simplify-expression model state b)))
       (or (not (om:equal? a b))
           (list '!= a b))))

    (('and a b)
     (let ((a (simplify-expression model state a))
           (b (simplify-expression model state b)))
       (and a b (cond
                     ((and (eq? a #t) (eq? b #t)) #t)
                     ((eq? a #t) b)
                     ((eq? b #t) a)
                     (else (list 'and a b))))))

    (('or a b)
     (let ((a (simplify-expression model state a))
           (b (simplify-expression model state b)))
       (and (or a b) (cond
                          ((or (eq? a #t) (eq? b #t)) #t)
                          ((om:equal? (list '! a) b) #t)
                          ((om:equal? (list '! b) a) #t)
                          ((om:equal? (simplify-expression model state (list '! a)) b) #t)
                          ((om:equal? (simplify-expression model state (list '! b)) a) #t)
                          ((eq? a #f) b)
                          ((eq? b #f) a)
                          ((om:equal? a b) a)
                          (else (list 'or a b))))))

    (('! expression)
     (let ((expression (simplify-expression model state expression)))
       (cond
        ((eq? expression #t) #f)
        ((eq? expression #f) #t)
        (else (list '! expression)))))

    (('group expression)
     (let ((expression (simplify-expression model state expression)))
       (cond
        ((eq? expression #t) #t)
        ((eq? expression #f) #f)
        (else (list 'group expression)))))

    (_ o)))
