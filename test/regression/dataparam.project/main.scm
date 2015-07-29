;;; Dezyne --- Dezyne command line tools
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

(define (main . args)
  (let* ((loc (make <dezyne:locator>))
         (rt (make <dezyne:runtime>))
         (d (make <dezyne:Datasystem>
              :locator (set loc rt)
              :name 'd
              :port.out (make <dezyne:IDataparam.out>
                          :name 'port
                          ;;:self d ;; hmm
                          :a0 a0
                          :a a
                          :aa aa
                          :a6 a6)))
         (i (make <v> :v 0))
         (j (make <v> :v 0)))
    ;;(set! (.self (.out d .port)) d) ;;hmm

    (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action d .port .in .e0r)))
    (action d .port .in .e0)
    (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action d .port .in .er 123)))
    (action d .port .in .e 123)
    (assert (eq? (assoc-ref IDataparam-Status-alist 'No) (action d .port .in .eer 123 345)))

    (action d .port .in .eo i)
    (assert (= (.v i) 234))

     (action d .port .in .eoo i j)
     (assert (and (= (.v i) 123) (= (.v j) 456)))

     (action d .port .in .eio (.v i) j)
     (assert (and (= (.v i) 123) (= (.v j) (.v i))))

     (action d .port .in .eio2 i)
     (assert (= (.v i) 246))


     (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action d .port .in .eor i)))
     (assert (= (.v i) 234))

     (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action d .port .in .eoor i j)))
     (assert (and (= (.v i) 123) (= (.v j) 456)))

     (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action d .port .in .eior (.v i) j)))
     (assert (and (= (.v i) 123) (= (.v j) (.v i))))

     (assert (eq? (assoc-ref IDataparam-Status-alist 'Yes) (action d .port .in .eio2r i)))
     (assert (= (.v i) 246)) ))
