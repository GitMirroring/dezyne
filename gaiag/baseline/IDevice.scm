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


(define-class <IDevice.in> (<port-base>)
  (name :accessor .name :init-value (symbol) :init-keyword :name)
  (self :accessor .self :init-value #f :init-keyword :self)
  (initialize :accessor .initialize :init-value #f :init-keyword :initialize)
  (calibrate :accessor .calibrate :init-value #f :init-keyword :calibrate)
  (perform_action1 :accessor .perform_action1 :init-value #f :init-keyword :perform_action1)
  (perform_action2 :accessor .perform_action2 :init-value #f :init-keyword :perform_action2))
(define-class <IDevice.out> (<port-base>)
  (name :accessor .name :init-value (symbol) :init-keyword :name)
  (self :accessor .self :init-value #f :init-keyword :self))
(define-class <IDevice> (<interface>))

(define-method (initialize (o <IDevice>) args)
  (set! (.in o) (make <IDevice.in>))
  (set! (.out o) (make <IDevice.out>))
  (next-method))
