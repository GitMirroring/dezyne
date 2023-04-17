;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
(define-module (library hello)
  #:use-module (ice-9 control)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:duplicates (merge-generics)
  #:export (<library:ihello>
            <library:ihello.in>
            <library:ihello.out>
            .hello
            .goodbye
            <library:hello>
            .h
            .w
            .b
            <library:iworld>
            <library:iworld.in>
            <library:iworld.out>
            .world
            .howdy))

(define true #t)
(define false #f)

(define-class <library:ihello.in> (<dzn:port>)
  (hello #:accessor .hello #:init-keyword #:hello))

(define-class <library:ihello.out> (<dzn:port>)
  (goodbye #:accessor .goodbye #:init-keyword #:goodbye))

(define-class <library:ihello> (<dzn:interface>))


(define-class <library:iworld.in> (<dzn:port>)
  (world #:accessor .world #:init-keyword #:world))

(define-class <library:iworld.out> (<dzn:port>)
  (howdy #:accessor .howdy #:init-keyword #:howdy))

(define-class <library:iworld> (<dzn:interface>))

;; (use-modules (library:foreign))


(define-class <library:hello> (<dzn:component>)
  (b #:accessor .b #:init-form true)
  (out_h #:accessor .out_h #:init-value #f #:init-keyword #:out_h)
  (h #:accessor .h #:init-form (make <library:ihello>) #:init-keyword #:h)
  (w #:accessor .w #:init-form (make <library:iworld>) #:init-keyword #:w))

(define-method (initialize (o <library:hello>) args)
  (next-method o (cons* #:flushes? #t args))
  (set! (.h o)
        (make <library:ihello>
          #:in (make <library:ihello.in>
                 #:name "h"
                 #:self o
                 #:hello (lambda args
                           (call-in o
                                    (lambda _
                                      (apply h-hello (cons o args))
                                      (dzn:flush o)
                                      *unspecified*)
                                    `(,(.h o) "hello"))))
          #:out (make <library:ihello.out>)))
  (set! (.w o)
        (make <library:iworld>
          #:in (make <library:iworld.in>)
          #:out (make <library:iworld.out>
                  #:name "w"
                  #:self o
                  #:howdy (lambda args
                            (call-out o
                                      (lambda _
                                        (apply w-howdy (cons o args))
                                        (dzn:flush o)
                                        *unspecified*)
                                      `(,(.w o) "howdy")))))))

(define-method (h-hello (o <library:hello>))
  (cond (true
         (let ()
           *unspecified*
           (set! (.b o) false)
           (action o .w .in .world )))
        (false
         (((compose .illegal .runtime) o)))))

(define-method (w-howdy (o <library:hello>))
  (cond ((not (.b o))
         (let ()
           *unspecified*
           (set! (.b o) true)
           (action o .h .out .goodbye )))
        ((.b o)
         (((compose .illegal .runtime) o)))
        (else ((compose .illegal .runtime) o))))
