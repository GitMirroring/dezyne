;;; dzn-runtime -- Dezyne runtime library
;;;
;;; Copyright © 2017, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of dzn-runtime.
;;;
;;; dzn-runtime is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Lesser General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; dzn-runtime is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Lesser General Public License for more details.
;;;
;;; You should have received a copy of the GNU Lesser General Public
;;; License along with dzn-runtime.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn locator)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module (oop goops)
  #:export (<dzn:locator>
            dzn:clone
            dzn:get
            dzn:set!
            stderr))

(define (stderr . args)
  (apply format (cons* (current-error-port) args)))

(define-class <dzn:locator> ()
  (services #:accessor .services #:init-form (list) #:init-keyword #:services))

(define-method (initialize (o <dzn:locator>) args)
  (next-method)
  (dzn:set! o stderr "trace"))

(define-method (locator-key)
  "")

(define-method (locator-key (o <string>))
  o)

(define-method (locator-key (o <symbol>))
  (symbol->string o))

(define-method (dzn:set! (o <dzn:locator>) (x <top>) (key <string>))
  (let* ((<type> (class-of x))
         (rest (filter
                (match-lambda ((k . o) (or (not (equal? k key))
                                           (not (is-a? o <type>)))))
                (.services o))))
    (set! (.services o) (acons key x rest)))
  o)

(define-method (dzn:set! (o <dzn:locator>) (x <top>) key)
  (dzn:set! o x (locator-key key)))

(define-method (dzn:set! (o <dzn:locator>) (x <top>))
  (dzn:set! o x (locator-key)))

(define-method (dzn:get (o <dzn:locator>) (key <string>))
  (assoc-ref (.services o) (locator-key key)))

(define-method (dzn:get (o <dzn:locator>) (type <class>) (key <string>))
  (let ((named (filter-map
                (match-lambda ((k . o) (and (equal? k key) o)))
                (.services o))))
    (or (find (compose (cute eq? <> type) class-of) named)
        (find (cute is-a? <> type) named))))

(define-method (dzn:get (o <dzn:locator>) (type <class>) key)
  (dzn:get o type (locator-key key)))

(define-method (dzn:get (o <dzn:locator>) (type <class>))
  (dzn:get o type (locator-key)))

(define-method (dzn:get (o <dzn:locator>) (x <top>) key)
  (dzn:get o (class-of x) key))

(define-method (dzn:get (o <dzn:locator>) (type <top>))
  (dzn:get o (class-of type)))

(define-method (dzn:clone (o <dzn:locator>))
  (make <dzn:locator> #:services (list-copy (.services o))))
