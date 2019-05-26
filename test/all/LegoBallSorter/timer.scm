;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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


(define-class <dzn:timer> (<dzn:component>)
  (port :accessor .port :init-value #f))
(define-method (initialize (o <dzn:timer>) args)
  (next-method)
  (set! (.port o)
    (make <dzn:itimer>
       :in (make <dzn:itimer.in>
              :name 'port
              :self o
              :create (lambda (. args) (call-in o (lambda () (apply port-create (cons o args))) `(,(.port o) create)))
              :cancel (lambda (. args) (call-in o (lambda () (apply port-cancel (cons o args))) `(,(.port o) cancel))))
       :out (make <dzn:itimer.out>))))

(define-method (port-create (o <dzn:timer>) ms)
    #t)

(define-method (port-cancel (o <dzn:timer>) )
    #t)
