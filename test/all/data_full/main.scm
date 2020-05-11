;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2016, 2019, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (data_full)
  #:duplicates (merge-generics)
  #:export (main))

(define (assert x)
  (unless x
    (throw 'assert-fail x)))

(define (a0)
  (format #t "a0()\n")
  (stderr "sut.p.bottom.a0 -> <external>.port.a0\n"))

(define (a i)
  (format #t "a(~a)\n" i)
  (stderr "sut.p.bottom.a -> <external>.port.a\n"))

(define (aa i j)
  (format #t "aa(~a,~a)\n" i j)
  (stderr "sut.p.bottom.aa -> <external>.port.aa\n")
  (assert (= j 123)))

(define (a6 i0 i1 i2 i3 i4 i5)
  (format #t "a6(~a,~a,~a,~a,~a,~a)\n" i0 i1 i2 i3 i4 i5)
  (stderr "sut.p.bottom.a6 -> <external>.port.a6\n")
  (assert (= i0 0))
  (assert (= i1 1))
  (assert (= i2 2))
  (assert (= i3 3))
  (assert (= i4 4))
  (assert (= i5 5)))

;; FIXME: export
(define Idata_full:Status:alist (@@ (data_full) Idata_full:Status:alist))

(define (main . args)
  (let* ((locator (make <dzn:locator>))
         (runtime (make <dzn:runtime>))
         (locator (dzn:set! locator runtime))
         (sut (make <data_full> #:locator locator #:name "sut"))
         (i '(v . 0))
         (j '(v . 0)))

    (set! (.out (.port sut))
          (make <Idata_full.out>
            #:name "port"
            #:a0 a0
            #:a a
            #:aa aa
            #:a6 a6))

    (assert (eq? (assoc-ref Idata_full:Status:alist 'Yes) (action sut .port .in .e0r)))
    (action sut .port .in .e0)
    (assert (eq? (assoc-ref Idata_full:Status:alist 'Yes) (action sut .port .in .er 123)))

    (action sut .port .in .e 123)
    (assert (eq? (assoc-ref Idata_full:Status:alist 'No) (action sut .port .in .eer 123 345)))

    (action sut .port .in .eo i)
    (assert (= (cdr i) 234))

    (action sut .port .in .eoo i j)
    (assert (and (= (cdr i) 123) (= (cdr j) 456)))

    (action sut .port .in .eio (cdr i) j)
    (assert (and (= (cdr i) 123) (= (cdr j) (cdr i))))

    (action sut .port .in .eio2 i)
    (assert (= (cdr i) 246))


    (assert (eq? (assoc-ref Idata_full:Status:alist 'Yes) (action sut .port .in .eor i)))
    (assert (= (cdr i) 234))

    (assert (eq? (assoc-ref Idata_full:Status:alist 'Yes) (action sut .port .in .eoor i j)))
    (assert (and (= (cdr i) 123) (= (cdr j) 456)))

    (assert (eq? (assoc-ref Idata_full:Status:alist 'Yes) (action sut .port .in .eior (cdr i) j)))
    (assert (and (= (cdr i) 123) (= (cdr j) (cdr i))))

    (assert (eq? (assoc-ref Idata_full:Status:alist 'Yes) (action sut .port .in .eio2r i)))
    (assert (= (cdr i) 246))))
