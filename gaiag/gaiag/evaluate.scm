;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define (var-field state variable) (assoc-ref state (om2list variable)))

(define (var! state variable value)
  ;;; FIXME (map (lambda (x) (if (eq? identifier (car x)) (cons (car x) (cdr x)) x)) state)
  (assoc-set! (copy-tree state) (om2list variable) value))

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
    (($ <value> value) (eval-expression model state value))
    (($ <otherwise> 'otherwise)
     (let* ((guard (om:parent model o))
            (compound (om:parent model guard))
            (guards (filter (is? <guard>) compound)))
       (eval-expression model state (guards-not-or guards))))
    (($ <otherwise> value) (eval-expression model state value))
    (#t #t)
    ('false #f)
    ('true #t)
    ((and ($ <var>) (= .variable.name identifier)) (var-field state identifier))
    (($ <field> (and (? var?) (get! identifier)) field)
     (eq? (.field (var-field state (identifier))) field))
    (($ <literal> type field) o)
    (($ <not> expr) (not (eval-expression model state expr)))
    (($ <and> a b) (and (eval-expression model state a)
                        (eval-expression model state b)))
    (($ <or> a b) (or (eval-expression model state a)
                      (eval-expression model state b)))
    (($ <equal> a b)
     (let* ((lhs (eval-expression model state a))
            (rhs (eval-expression model state b))
            (r (equal? lhs rhs)))
       r))
    (($ <not-equal> a b)
     (let* ((lhs (eval-expression model state a))
            (rhs (eval-expression model state b))
            (r (not (equal? lhs rhs))))
     r))
    (($ <group> expression)
     (eval-expression model state expression))
    (($ <plus> a b)
;;(stderr "+: state = ~a;   a = ~a; b = ~a\n" state a b)
     (+ (eval-expression model state a)
                       (eval-expression model state b)))
    (($ <minus> a b)
     (- (eval-expression model state a)
        (eval-expression model state b)))
    (($ <less> a b) (< (eval-expression model state a)
                       (eval-expression model state b)))
    (($ <less-equal> a b) (<= (eval-expression model state a)
                              (eval-expression model state b)))
    (($ <greater> a b) (> (eval-expression model state a)
                          (eval-expression model state b)))
    (($ <greater-equal> a b) (>= (eval-expression model state a)
                                 (eval-expression model state b)))
    ((? symbol?) (eval-expression model state (var-field state o)))
    ((? boolean?) o)
    ((? number?) o)
    (($ <data> value) o)
    ((? unspecified?) o))
  )

(define (simplify-expression model state o)
  (let ((e (simplify-expression- model state o)))
;;    (stderr "simplify-expression ~a => ~a\n" o e)
    e))

(define (simplify-expression- model state o)
  (define (unspec v f) (if (is-a? v <var>) o (f v)))
  (match o
    (#f #f)
    (#t #t)
    ('false #f)
    ('true #t)

    (($ <value> value) (simplify-expression model state value))

    (($ <otherwise> expression)
     (let ((value (simplify-expression model state expression)))
       (match value
         (#t #t)
         (#f #f)
         (_ o))))

    ((and ($ <var>) (= .variable (? bool-var?)))
     (let ((field (var-field state (.variable o))))
       (match field
         (#f o)
         (_ (eq? field 'true)))))

    ((and ($ <var>) (and (= .variable (? int-var?))))
     (let ((field (var-field state (.variable o))))
       (match field
         (#f o)
         (_ field))))

    ((and ($ <var>) (= .variable variable))
     (let ((field (var-field state (.variable o))))
       (match field
         (#f o)
         (_ (make <literal> #:type (.type (.variable o)) #:field field)))))

    (($ <field> (and (? var?) (get! variable)) field)
     (let ((f (var-field state (variable))))
       (match f
         (#f o)
         (_ (eq? f field)))))

    (($ <literal> type field) o)

    (($ <equal> a b)
     (let* ((a1 (simplify-expression model state a))
           (b1 (simplify-expression model state b))
           (a a1) (b b1))
       (or (om:equal? a b)
           (match (cons a b)
             ((($ <literal>) . ($ <literal>)) #f)
             (((? number?) . (? number?)) (eq? a b))
             (_ (clone o #:left a #:right b))))))

    (($ <not-equal> a b)
     (let ((a (simplify-expression model state a))
           (b (simplify-expression model state b)))
       (or (not (om:equal? a b))
           (clone o #:left a #:right b))))

    (($ <and> a b)
     (let ((a (simplify-expression model state a))
           (b (simplify-expression model state b)))
       (and a b (cond
                     ((and (eq? a #t) (eq? b #t)) #t)
                     ((eq? a #t) b)
                     ((eq? b #t) a)
                     (else (clone o #:left a #:right b))))))

    (($ <or> a b)
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

    (($ <not> expression)
     (let ((expression (simplify-expression model state expression)))
       (cond
        ((eq? expression #t) #f)
        ((eq? expression #f) #t)
        (else (clone o #:expression expression)))))

    (($ <group> expression)
     (let ((expression (simplify-expression model state expression)))
       (cond
        ((eq? expression #t) #t)
        ((eq? expression #f) #f)
        (else (clone o #:expression expression)))))

    (_ o)))
