;;; Snuik --- An IRC bot using guile-8sync
;;; Copyright © 2020, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Snuik.
;;;
;;; Snuik is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Snuik is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Snuik.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn goops unserialize)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (oop goops)

  #:use-module (dzn goops util)

  #:export (define-unserialize-class
             unzip))

(define (unzip lst)
  "Split list LST into pairs."
  (unfold (compose (cute < <> 3) length) ;p
          (cute take <> 2)               ;f
          (cute drop <> 2)               ;g
          lst                            ;seed
          list))            ;tail-gen

(define-class <test> ()
  (one #:accessor .one #:init-value 1 #:init-keyword #:one)
  (two #:accessor .two #:init-value 2 #:init-keyword #:two)
  (three #:accessor .three #:init-value 3 #:init-keyword #:three))

(define (make-object class . symbol+values)
  "Make GOOPS object of type CLASS using SYMBOL+VALUES initializers."

  (define (symbol+values->keyword+values symbol+values)
    (map (match-lambda (((and (? symbol?) name) value)
                        (let ((keyword (symbol->keyword name)))
                          `(,keyword ,value)))
                       (((and (? symbol?) name) values ...)
                        (let ((keyword (symbol->keyword name)))
                          `(,keyword ,values)))
                       (x
                        (throw 'invalid-value x)))
         symbol+values))

  (let* ((keyword+values (symbol+values->keyword+values symbol+values))
         (keyword+values (apply append keyword+values)))
    (apply make class keyword+values)))

(define-syntax define-unserialize-class
  (lambda (x)
    "Define macro to unserialize objects of type CLASS."
    (syntax-case x ()
      ((_ class)
       (let ((name (constructor-name (syntax->datum #'class))))
         (with-syntax ((name (datum->syntax x name)))
           #`(begin
               (export name)
               (define-syntax name
                 (lambda (x)
                   (with-ellipsis
                    :::
                    (syntax-case x ()
                      ((_)
                       (make-object class))
                      ((_ (symbol value))
                       (with-syntax
                           ((symbol+values (datum->syntax x 'symbol+values)))
                         #'(let ((symbol+values (list 'symbol value)))
                             (make-object class symbol+values))))
                      ((_ (symbol value) :::)
                       (with-syntax
                           ((symbol+values (datum->syntax x 'symbol+values)))
                         #'(let ((symbol+values (list (list 'symbol value) :::)))
                             (apply make-object class symbol+values))))
                      ((_ (symbol value :::))
                       (with-syntax
                           ((symbol+values (datum->syntax x 'symbol+values)))
                         #'(let ((symbol+values (list 'symbol value :::)))
                             (make-object class symbol+values)))))))))))))))
