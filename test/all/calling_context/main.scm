;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 rdelim)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (calling_context)
  #:duplicates (merge-generics)
  #:export (main))

(define (log-in prefix event)
  (stderr "<external>.~a~a -> sut.~a~a\n" prefix event prefix event)
  #f)

(define (log-out prefix event)
  (stderr "<external>.~a~a <- sut.~a~a\n" prefix event prefix event)
  #f)

(define (main . args)
  (let* ((print-illegal (lambda () (stderr "illegal\n") (exit 0)))
         (locator (make <dzn:locator>))
         (runtime (make <dzn:runtime> #:illegal print-illegal))
         (locator (dzn:set! locator runtime))
         (sut (make <calling_context> #:locator locator #:name 'sut)))

    (set! (.name (.out (.h sut))) 'h)
    (set! (.name (.in (.w sut))) 'w)
    (set! (.world (.in (.w sut)))
          (lambda (cc i)
            (log-in 'w. 'world)
            (if (zero? (cdr cc)) (set-cdr! cc 123)
                (begin
                  (unless (= (cdr cc) 123)
                    (throw 'assert "cc != 123; " cc))
                  (set-cdr! cc 456)))
            (log-out 'w. 'return)))

    (let ((cc '(v . 0)))
      (action sut .h .in .hello cc 123)
      (unless (= (cdr cc) 456)
        (throw 'assert "cc != 456; " cc)))))
