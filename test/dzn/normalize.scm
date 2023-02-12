;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
;;; Tests for the makreel module.
;;;
;;; Code:

(use-modules (dzn ast goops)
             (dzn ast))
(define-generic equal?)
(define-method (equal? (a <ast>) (b <ast>))
  (ast:equal? a b))

(define-module (test dzn normalize)
  #:use-module (srfi srfi-64)
  #:use-module (test dzn automake)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast normalize)
  #:use-module (dzn ast))

(define simplify-expression (@@ (dzn ast normalize) simplify-expression))

(test-begin "normalize")

(test-assert "dummy"
  #t)

(let* ((false (make <literal> #:value "false"))
       (true (make <literal> #:value "true"))
       (b (make <var> #:name "b"))
       (gb (make <group> #:expression b))
       (!b (make <not> #:expression b))
       (!!b (make <not> #:expression !b))
       (g!b (make <group> #:expression !b))
       (!g!b (make <not> #:expression g!b))
       (gg!b (make <group> #:expression g!b))
       (!gg!b (make <not> #:expression gg!b))
       (b&&b (make <and> #:left b #:right b))
       (b||b (make <or> #:left b #:right b))
       (b&&!b (make <and> #:left b #:right !b))
       (b||!b (make <or> #:left b #:right !b))
       (!b&&!!b (make <and> #:left !b #:right !!b))
       (action-a (make <action> #:function.name "a"))
       (action-a&&action-a (make <and> #:left action-a #:right action-a))
       (action-a||action-a (make <or> #:left action-a #:right action-a))
       (action-a&&false (make <and> #:left action-a #:right false))
       (action-a||true (make <or> #:left action-a #:right true))
       (false&&action-a (make <and> #:left false #:right action-a))
       (false||action-a (make <or> #:left false #:right action-a))
       (true&&action-a (make <and> #:left true #:right action-a))
       (true||action-a (make <or> #:left true #:right action-a))
       (call-a (make <call> #:function.name "a"))
       (call-a&&call-a (make <and> #:left call-a #:right call-a))
       (call-a||call-a (make <or> #:left call-a #:right call-a)))

  (test-begin "simplify")

  (test-equal "!!b"
    b
    (simplify-expression !!b))

  (test-equal "!g!b"
    b
    (simplify-expression !g!b))

  (test-equal "!gg!b"
    b
    (simplify-expression !gg!b))

  (test-equal "b||b"
    b
    (simplify-expression b||b))

  (test-equal "b&&b"
    b
    (simplify-expression b&&b))

  (test-equal "b||!b"
    true
    (simplify-expression b||!b))

  (test-equal "b&&!b"
    false
    (simplify-expression b&&!b))

  (test-equal "!b&&!!b"
    false
    (simplify-expression !b&&!!b))

  (test-equal "action-a&&action-a"
    action-a&&action-a
    (simplify-expression action-a&&action-a))

  (test-equal "action-a&&false"
    action-a&&false
    (simplify-expression action-a&&false))

  (test-equal "action-a||true"
    action-a||true
    (simplify-expression action-a||true))

  (test-equal "false&&action-a"
    false
    (simplify-expression false&&action-a))

  (test-equal "false||action-a"
    action-a
    (simplify-expression false||action-a))

  (test-equal "true&&action-a"
    action-a
    (simplify-expression true&&action-a))

  (test-equal "true||action-a"
    true
    (simplify-expression true||action-a))

  (test-equal "call-a&&call-a"
    call-a&&call-a
    (simplify-expression call-a&&call-a))

  (test-equal "call-a||call-a"
    call-a||call-a
    (simplify-expression call-a||call-a)))

(test-end)
(test-end)
