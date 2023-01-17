;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018, 2020, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
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
(define-templates header-model c++:model)
(define-templates include-guard c++:include-guard)
(define-templates pump-include code:pump?)
(define-templates endif c++:include-guard)


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
(define-templates provides-port-declare ast:provides-port*)
(define-templates requires-port-declare ast:requires-no-injected-port*)
(define-templates injected-port-declare ast:injected-port*)
(define-templates declare-method code:trigger)
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
(define-templates formals-cast-void ast:formal*)


;;;
;;; Enums
;;;
(define-templates model-enum-to-string c++:enum->string)
(define-templates enum-field-to-string c++:enum-field->string)
(define-templates enum-field-type c++:enum-field-type type-infix)
(define-templates enum-literal c++:enum-literal type-infix)
(define-templates enum-to-string identity)
(define-templates string-to-enum identity)
(define-templates string-to-enum-field c++:string->enum-field*)


;;;
;;; Foreign
;;;
(define-templates declare-pure-virtual-method ast:in-triggers)
(define-templates foreign-event-slot ast:in-triggers)


;;;
;;; System
;;;
(define-templates provides-port-reference-declare ast:provides-port*)
(define-templates requires-port-reference-declare ast:requires-port*)
(define-templates provides-port-reference-initializer ast:provides-port*)
(define-templates requires-port-reference-initializer ast:requires-port*)


;;;
;;; Shell
;;;
(define-templates shell-non-injected-instance-meta code:non-injected-instances)
(define-templates shell-provides-in ast:provides-in-triggers)
(define-templates shell-requires-out ast:requires-out-triggers)
(define-templates shell-provides-out ast:provides-out-triggers)
(define-templates shell-requires-in ast:requires-in-triggers)
(define-templates capture c++:capture-arguments capture-prefix)
(define-templates capture-list identity)
(define-templates provides-port-instance-declare ast:provides-port*)
(define-templates requires-port-instance-declare ast:requires-port*)
(define-templates local_locator code:injected-instances-system)
(define-templates injected-instance-declare code:injected-instances)
(define-templates constructor-meta-initializer code:non-injected-instances)
(define-templates shell-provides-meta-initializer ast:provides-port*)
(define-templates shell-requires-meta-initializer ast:requires-port*)
(define-templates injected-instance-meta-initializer code:injected-instances)
(define-templates non-injected-instance-meta-initializer code:non-injected-instances)
(define-templates dzn-locator c++:dzn-locator)
