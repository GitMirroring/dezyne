;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)

  #:use-module (gaiag misc)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)

  #:export (
           eval-expression
           true?
           ))

(define-method (expr:equal? (left <enum-literal>) (right <enum-literal>))
  (and (eq? (.node (.type left)) (.node (.type right)))
       (eq? (.field left) (.field right))))

(define-method (expr:equal? (left <literal>) (right <literal>))
  (eq? (.value left) (.value right)))

(define-method (true? (o <literal>))
  (eq? (.value o) 'true))

(define-method (literal value)
      (match value
      (#t (make <literal> #:value 'true))
      (#f (make <literal> #:value 'false))
      ((? number?) (make <literal> #:value value))))

(define-method (eval-expression (state <list>) (o <expression>))
  (match o
    (($ <literal>) o)
    ((and ($ <var>) (= .variable.name name)) (eval-expression state (assoc-ref state name)))
    ((and ($ <not>) (= .expression expression)) (literal (not (true? (eval-expression state expression)))))
    ((and ($ <equal>) (= .left left) (= .right right)) (literal (expr:equal? (eval-expression state left) (eval-expression state right))))
    ((and ($ <not-equal>) (= .left left) (= .right right)) (literal (not (expr:equal? (eval-expression state left) (eval-expression state right)))))
    ((and ($ <and>) (= .left left) (= .right right)) (literal (and (true? (eval-expression state left)) (true? (eval-expression state right)))))
    ((and ($ <or>) (= .left left) (= .right right)) (literal (or (true? (eval-expression state left)) (true? (eval-expression state right)))))
    ((and ($ <field-test>) (= .variable left) (= .field right)) (literal (eq? (.field (eval-expression state (make <var> #:variable.name (.name left)))) right)))
    ((and ($ <plus>) (= .left left) (= .right right)) (literal (+ (.value (eval-expression state left)) (.value (eval-expression state right)))))
    ((and ($ <minus>) (= .left left) (= .right right)) (literal (- (.value (eval-expression state left)) (.value (eval-expression state right)))))
    ((and ($ <less>) (= .left left) (= .right right)) (literal (< (.value (eval-expression state left)) (.value (eval-expression state right)))))
    ((and ($ <less-equal>) (= .left left) (= .right right)) (literal (<= (.value (eval-expression state left)) (.value (eval-expression state right)))))
    ((and ($ <greater>) (= .left left) (= .right right)) (literal (> (.value (eval-expression state left)) (.value (eval-expression state right)))))
    ((and ($ <greater-equal>) (= .left left) (= .right right)) (literal (>= (.value (eval-expression state left)) (.value (eval-expression state right)))))
    ((and ($ <otherwise>) (= .value value)) (eval-expression state value))
    ((and ($ <group>) (= .expression expression)) (eval-expression state expression))
    (_ o)))
