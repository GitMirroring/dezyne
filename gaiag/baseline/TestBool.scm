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


(define-class <TestBool.in> (<port-base>)
  (name :accessor .name :init-value (symbol) :init-keyword :name)
  (self :accessor .self :init-value #f :init-keyword :self)
  (evt :accessor .evt :init-value #f :init-keyword :evt))
(define-class <TestBool.out> (<port-base>)
  (name :accessor .name :init-value (symbol) :init-keyword :name)
  (self :accessor .self :init-value #f :init-keyword :self))
(define-class <TestBool> (<interface>))

(define-method (initialize (o <TestBool>) args)
  (set! (.in o) (make <TestBool.in>))
  (set! (.out o) (make <TestBool.out>))
  (next-method))
