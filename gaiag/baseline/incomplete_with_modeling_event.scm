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

(define-class <incomplete_with_modeling_event> (<component>)
  (p :accessor .p :init-form (make <interface:iincomplete_with_modeling_event>))
  (r :accessor .r :init-form (make <interface:iincomplete_with_modeling_event>)))

(define-method (initialize (o <incomplete_with_modeling_event>) args)
  (next-method)
  (set! (.p o)
    (make <interface:iincomplete_with_modeling_event>
      :in `((e . ,(lambda () (p-e o))))))
  (set! (.r o)
    (make <interface:iincomplete_with_modeling_event>
      :out `((a . ,(lambda () (r-a o)))))))

(define-method (p-e (o <incomplete_with_modeling_event>))
  (stderr "incomplete_with_modeling_event.p.e\n")
    #t)

(define-method (r-a (o <incomplete_with_modeling_event>))
  (stderr "incomplete_with_modeling_event.r.a\n")
    (action o .p .out 'a))


