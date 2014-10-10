;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Gaiag.
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

(define-class <interface_component_overload> (<component>)
  (reply-interface_component_overload-R :accessor .reply-interface_component_overload-R :init-value #f)
  (interface_component_overload :accessor .interface_component_overload :init-form (make <interface:interface_component_overload>)))

(define-method (initialize (o <interface_component_overload>) args)
  (next-method)
  (set! (.interface_component_overload o)
    (make <interface:interface_component_overload>
      :in `((e . ,(lambda () (interface_component_overload-e o)))))))

(define-method (interface_component_overload-e (o <interface_component_overload>))
  (stderr "interface_component_overload.interface_component_overload.e\n")
    (set! (.reply-interface_component_overload-R o) '(R V))
    (.reply-interface_component_overload-R o))


