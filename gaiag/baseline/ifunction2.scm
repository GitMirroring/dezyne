;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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


(define-class <ifunction2.in> (<port-base>)
  (name :accessor .name :init-value (symbol) :init-keyword :name)
  (self :accessor .self :init-value #f :init-keyword :self)
  (a :accessor .a :init-value #f :init-keyword :a)
  (b :accessor .b :init-value #f :init-keyword :b))
(define-class <ifunction2.out> (<port-base>)
  (name :accessor .name :init-value (symbol) :init-keyword :name)
  (self :accessor .self :init-value #f :init-keyword :self)
  (c :accessor .c :init-value #f :init-keyword :c)
  (d :accessor .d :init-value #f :init-keyword :d))
(define-class <ifunction2> (<interface>))

(define-method (initialize (o <ifunction2>) args)
  (set! (.in o) (make <ifunction2.in>))
  (set! (.out o) (make <ifunction2.out>))
  (next-method))
