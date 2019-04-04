;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2016, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (main)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (Dataparam)
  #:duplicates (merge-generics)
  #:export (main))

(define (assert x)
  (unless x
    (throw 'assert-fail x)))

(define (a0)
  (stderr "a0()\n"))

(define (a i)
  (stderr "a(~a)\n" i))

(define (aa i j)
  (stderr "aa(~a,~a)\n" i j)
  (assert (= j 123)))

(define (a6 i0 i1 i2 i3 i4 i5)
  (stderr "a6(~a,~a,~a,~a,~a,~a)\n" i0 i1 i2 i3 i4 i5)
  (assert (= i0 0))
  (assert (= i1 1))
  (assert (= i2 2))
  (assert (= i3 3))
  (assert (= i4 4))
  (assert (= i5 5)))

;; FIXME: export
(define IDataparam-Status-alist (@@ (Dataparam) IDataparam-Status-alist))

(define (main . args)
  (let* ((locator (make <dzn:locator>))
         (runtime (make <dzn:runtime>))
         (locator (dzn:set! locator runtime))
         (sut (make <Dataparam> #:locator locator #:name 'sut))
         (i '(v . 0))
         (j '(v . 0)))

    (set! (.out (.port sut))
          (make <IDataparam.out>
            #:name 'port
            #:a0 a0
            #:a a
            #:aa aa
            #:a6 a6))

    (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action sut .port .in .e0r)))
    (action sut .port .in .e0)
    (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action sut .port .in .er 123)))

    (action sut .port .in .e 123)
    (assert (eq? (assoc-ref IDataparam-Status-alist 'No) (action sut .port .in .eer 123 345)))

    (action sut .port .in .eo i)
    (assert (= (cdr i) 234))

    (action sut .port .in .eoo i j)
    (assert (and (= (cdr i) 123) (= (cdr j) 456)))

    (action sut .port .in .eio (cdr i) j)
    (assert (and (= (cdr i) 123) (= (cdr j) (cdr i))))

    (action sut .port .in .eio2 i)
    (assert (= (cdr i) 246))


    (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action sut .port .in .eor i)))
    (assert (= (cdr i) 234))

    (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action sut .port .in .eoor i j)))
    (assert (and (= (cdr i) 123) (= (cdr j) 456)))

    (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action sut .port .in .eior (cdr i) j)))
    (assert (and (= (cdr i) 123) (= (cdr j) (cdr i))))

    (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action sut .port .in .eio2r i)))
    (assert (= (cdr i) 246))))
