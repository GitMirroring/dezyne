;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
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

;;;
;;; Top
;;;
(define-templates header-data ast:data*)
(define-templates header-model c++:model)
(define-templates include-guard)
(define-templates pump-include code:pump?)
(define-templates endif)


;;;
;;; Names
;;;
(define-templates c++:type-ref c++:type-ref)
(define-templates type-name c++:type-name type-infix)


;;;
;;; Component
;;;
(define-templates meta identity)
(define-templates ports-meta-list ast:requires-port* meta-infix)
(define-templates provided-port-declare ast:provides-port*)
(define-templates required-port-declare ast:requires-port*)
(define-templates async-port-declare ast:async-port*)
(define-templates declare-method code:trigger)
(define-templates pump code:pump?)
(define-templates method-declare code:ons)
(define-templates declare-method code:trigger)
(define-templates stream-member ast:variable* stream-comma-infix)
(define-templates function-declare code:functions)

;; check-bindings
(define-templates check-bindings-list (lambda (o) (map (lambda (port) (string-append "[this]{" (.name port) ".check_bindings();}")) (ast:port* o))) comma-infix)
(define-templates check-in-binding (lambda (o) (filter ast:in? (ast:event* o))))
(define-templates check-out-binding (lambda (o) (filter ast:out? (ast:event* o))))


;;;
;;; Statements
;;;
(define-templates out-binding-lambda ast:provides-port*)


;;;
;;; Formals, parameters, arguments
;;;
(define-templates formal-type c++:formal-type comma-infix)


;;;
;;; Enums
;;;
(define-templates interface-enum-to-string c++:enum->string)
(define-templates interface-string-to-enum c++:enum->string)
(define-templates enum-field-to-string c++:enum-field->string)
(define-templates enum-field-type c++:enum-field-type type-infix)
(define-templates enum-literal c++:enum-literal type-infix)
(define-templates string-to-enum c++:string->enum)


;;;
;;; Foreign
;;;
(define-templates declare-pure-virtual-method ast:in-triggers)
(define-templates foreign-event-slot ast:in-triggers)


;;;
;;; System
;;;
(define-templates provided-port-reference-declare ast:provides-port*)
(define-templates required-port-reference-declare ast:requires-port*)
(define-templates provided-port-reference-initializer ast:provides-port*)
(define-templates required-port-reference-initializer ast:requires-port*)


;;;
;;; Shell
;;;
(define-templates shell-non-injected-instance-meta code:non-injected-instances)
(define-templates shell-provided-in ast:provides-in-triggers)
(define-templates shell-required-out ast:required-out-triggers)
(define-templates shell-provided-out ast:provided-out-triggers)
(define-templates shell-required-in ast:requires-in-triggers)
(define-templates capture c++:capture-arguments capture-prefix)
(define-templates capture-list identity)
(define-templates provided-port-instance-declare ast:provides-port*)
(define-templates required-port-instance-declare ast:requires-port*)
(define-templates local_locator code:injected-instances-system)
(define-templates injected-instance-declare code:injected-instances)
(define-templates constructor-meta-initializer code:non-injected-instances)
(define-templates shell-provided-meta-initializer ast:provides-port*)
(define-templates shell-required-meta-initializer ast:requires-port*)
(define-templates injected-instance-meta-initializer code:injected-instances)
(define-templates non-injected-instance-meta-initializer code:non-injected-instances)
(define-templates dzn-locator c++:dzn-locator)
