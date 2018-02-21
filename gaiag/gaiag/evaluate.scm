;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag evaluate)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 match)
  #:use-module (system foreign)
  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag resolve)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag ast)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)

  #:use-module (gaiag misc)
  #:use-module (gaiag norm)
  #:use-module (gaiag parse)

  #:export (
           eval-expression
           simplify-expression
           variable-state
           undefined-state-vector
           undefined-variable-state
           state-vector
           var
           var!
           ))


(define* ((variable-state model #:optional (init .expression)) variable)
  (cons
   variable
   (eval-expression model '() (init variable))))

(define (state-vector model)
  (map (variable-state model) (om:variables model)))

(define* ((undefined-variable-state model #:optional (init .expression)) variable)
  (cons
   variable
   ;;(eval-expression model '() (init variable))
   (init variable)
   ))

(define (undefined-state-vector model)
  (map (undefined-variable-state model (init-undefined model)) (om:variables model)))

(define ((init-undefined model) o)
  (let ((type ((om:type model) o)))
    (make <var> #:variable o)))

(define (var-field state variable) (assoc-ref state (om->list variable)))

(define (var! state variable value)
  ;;; FIXME (map (lambda (x) (if (eq? identifier (car x)) (cons (car x) (cdr x)) x)) state)
  (assoc-set! (copy-tree state) (om->list variable) value))

(define (var? variable) (is-a? variable <variable>))

(define (bool-var? v) (and (is-a? v <variable>) (is-a? (.type v) <bool>)))

(define (int-var? v) (and (is-a? v <variable>) (is-a? (.type v) <int>)))

(define (unspecified? x) (eq? x *unspecified*))

(define (eval-expression model state o)
  (let ((r (eval-expression- model state o)))
    ;;(stderr "eval-expression ~a => ~a\n" o r)
    r))

(define (om:id o) ((compose pointer-address scm->pointer) o))

(define (om:parent o t)
  (match o
    (($ <system>) #f)
    (($ <foreign>) #f)
    ((? (is? <model>))
     (om:parent ((compose .statement .behaviour) o) t))
    (($ <blocking>) (or (and (eq? (om:id (.statement o)) (om:id t)) o)
                        (om:parent (.statement o) t)))
    (($ <guard>) (or (and (eq? (om:id (.statement o)) (om:id t)) o)
                     (and (eq? (om:id (.expression o)) (om:id t)) o)
                     (om:parent (.statement o) t)))
    (($ <on>) (or (and (eq? (om:id (.statement o)) (om:id t)) o)
                  (om:parent (.statement o) t)))
    ((? (is? <ast-list>))
     (if (member (om:id t) (map om:id (.elements o)))
         o
         (let loop ((elements (.elements o)))
           (if (null? elements)
               #f
               (let ((parent (om:parent (car elements) t)))
                 (if parent parent
                     (loop (cdr elements))))))))
    (_ #f)))

(define (eval-expression- model state o)
  (match o
    ((and ($ <literal>) (= .value value)) (eval-expression model state value))
    ((and ($ <otherwise>) (= .value 'otherwise))
     (let* ((guard (om:parent model o))
            (compound (om:parent model guard))
            (guards (filter (is? <guard>) compound)))
       (eval-expression model state (guards-not-or guards))))
    ((and ($ <otherwise>) (= .value value)) (eval-expression model state value))
    (#t #t)
    ('false #f)
    ('true #t)
    ((and ($ <var>) (= .variable.name identifier)) (var-field state identifier))
    ((and ($ <field-test>) (= .variable.name (? var?)) (= .field field) (= .variable.name identifier))
     (eq? (.field (var-field state (identifier))) field))
    (($ <enum-literal>) o)
    ((and ($ <not>) (= .expression expr)) (not (eval-expression model state expr)))
    ((and ($ <and>) (= .left a) (= .right b)) (and (eval-expression model state a)
                          (eval-expression model state b)))
    ((and ($ <or>) (= .left a) (= .right b)) (or (eval-expression model state a)
                        (eval-expression model state b)))
    ((and ($ <equal>) (= .left a) (= .right b))
     (let* ((lhs (eval-expression model state a))
            (rhs (eval-expression model state b))
            (r (equal? lhs rhs)))
       r))
    ((and ($ <not-equal>) (= .left a) (= .right b))
     (let* ((lhs (eval-expression model state a))
            (rhs (eval-expression model state b))
            (r (not (equal? lhs rhs))))
     r))
    ((and ($ <group>) (= .expression expression))
     (eval-expression model state expression))
    ((and ($ <plus>) (= .left a) (= .right b))
     ;;(stderr "+: state = ~a;   a = ~a; b = ~a\n" state a b)
     (+ (eval-expression model state a)
        (eval-expression model state b)))
    ((and ($ <minus>) (= .left a) (= .right b))
     (- (eval-expression model state a)
        (eval-expression model state b)))
    ((and ($ <less>) (= .left a) (= .right b))
     (< (eval-expression model state a)
        (eval-expression model state b)))
    ((and ($ <less-equal>) (= .left a) (= .right b))
     (<= (eval-expression model state a)
         (eval-expression model state b)))
    ((and ($ <greater>) (= .left a) (= .right b))
     (> (eval-expression model state a)
        (eval-expression model state b)))
    ((and ($ <greater-equal>) (= .left a) (= .right b))
     (>= (eval-expression model state a)
         (eval-expression model state b)))
    ((? symbol?) (eval-expression model state (var-field state o)))
    ((? boolean?) o)
    ((? number?) o)
    (($ <data>) o)
    ((? unspecified?) o))
  )

(define (simplify-expression model state o)
  (let ((e (simplify-expression- model state o)))
    ;;(stderr "simplify-expression ~a => ~a\n" o e)
    e))

(define (simplify-expression- model state o)
  (define (unspec v f) (if (is-a? v <var>) o (f v)))
  (match o
    (#f #f)
    (#t #t)
    ('false #f)
    ('true #t)

    ((and ($ <literal>) (= .value value)) (simplify-expression model state value))

    ((and ($ <otherwise>) (= .value expression))
     (let ((value (simplify-expression model state expression)))
       (match value
         (#t #t)
         (#f #f)
         (_ o))))

    ((and ($ <var>) (= .variable.name (? bool-var?)))
     (let ((field (var-field state (.variable o))))
       (match field
         (#f o)
         (_ (eq? field 'true)))))

    ((and ($ <var>) (and (= .variable.name (? int-var?))))
     (let ((field (var-field state (.variable o))))
       (match field
         (#f o)
         (_ field))))

    ((and ($ <var>) (= .variable.name variable))
     (let ((field (var-field state (.variable.name o))))
       (match field
         (#f o)
         (_ (make <enum-literal> #:type (.type (.variable o)) #:field field)))))

    (($ <field-test> (and (? var?) (get! variable)) field)
     (let ((f (var-field state (variable))))
       (match f
         (#f o)
         (_ (eq? f field)))))

    (($ <enum-literal>) o)

    ((and ($ <equal>) (= .left a) (= .right b))
     (let* ((a1 (simplify-expression model state a))
           (b1 (simplify-expression model state b))
           (a a1) (b b1))
       (or (om:equal? a b)
           (match (cons a b)
             ((($ <enum-literal>) . ($ <enum-literal>)) #f)
             (((? number?) . (? number?)) (eq? a b))
             (_ (clone o #:left a #:right b))))))

    ((and ($ <not-equal>) (= .left a) (= .right b))
     (let ((a (simplify-expression model state a))
           (b (simplify-expression model state b)))
       (or (not (om:equal? a b))
           (clone o #:left a #:right b))))

    ((and ($ <and>) (= .left a) (= .right b))
     (let ((a (simplify-expression model state a))
           (b (simplify-expression model state b)))
       (and a b (cond
                     ((and (eq? a #t) (eq? b #t)) #t)
                     ((eq? a #t) b)
                     ((eq? b #t) a)
                     (else (clone o #:left a #:right b))))))

    ((and ($ <or>) (= .left a) (= .right b))
     (let ((a (simplify-expression model state a))
           (b (simplify-expression model state b)))
       (and (or a b) (cond
                          ((or (eq? a #t) (eq? b #t)) #t)
                          ((om:equal? (make <not> #:expression a) b) #t)
                          ((om:equal? (make <not> #:expression b) a) #t)
                          ((om:equal? (simplify-expression model state (make <not> #:expression a)) b) #t)
                          ((om:equal? (simplify-expression model state (make <not> #:expression b)) a) #t)
                          ((eq? a #f) b)
                          ((eq? b #f) a)
                          ((om:equal? a b) a)
                          (else (clone o #:left a #:right b))))))

    ((and ($ <not>) (= .expression expression))
     (let ((expression (simplify-expression model state expression)))
       (cond
        ((eq? expression #t) #f)
        ((eq? expression #f) #t)
        (else (clone o #:expression expression)))))

    ((and ($ <group>) (= .expression expression))
     (let ((expression (simplify-expression model state expression)))
       (cond
        ((eq? expression #t) #t)
        ((eq? expression #f) #f)
        (else (clone o #:expression expression)))))

    (_ o)))
