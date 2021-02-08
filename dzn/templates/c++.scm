;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018, 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-templates name c++:name)
(define-templates declare-method code:trigger newline-infix)
(define-templates prefix-formals-type code:formals formal-prefix)
(define-templates pump code:pump?)
(define-templates pump-include code:pump?)
(define-templates include-statement code:file-name)
(define-templates meta identity)
(define-templates ports-meta-list ast:requires-port* meta-infix)
(define-templates check-bindings-list (lambda (o) ((->join ",") (map (lambda (port) (list "[this]{"(.name port) ".check_bindings();}")) (ast:port* o)))))
(define-templates check-in-binding (lambda (o) (filter ast:in? (ast:event* o))) newline-infix)
(define-templates check-out-binding (lambda (o) (filter ast:out? (ast:event* o))) newline-infix)
(define-templates interface-enum-to-string c++:enum->string newline-infix)
(define-templates interface-string-to-enum c++:enum->string newline-infix)
(define-templates enum-field-to-string c++:enum-field->string newline-infix)
(define-templates enum-field-type c++:enum-field-type type-infix)
(define-templates type-name c++:type-name type-infix)
(define-templates enum-literal c++:enum-literal type-infix)
(define-templates string-to-enum c++:string->enum newline-infix)
(define-templates out-binding-lambda ast:provides-port*)
(define-templates provided-port-declare ast:provides-port* newline-infix)
(define-templates required-port-declare ast:requires-port* newline-infix)
(define-templates async-port-declare ast:async-port* newline-infix)
(define-templates stream-member ast:variable* stream-comma-infix)
(define-templates method-declare code:ons newline-infix)
(define-templates function-declare code:functions newline-infix)
(define-templates include-guard)
(define-templates endif)
(define-templates provided-port-reference-declare ast:provides-port* newline-infix)
(define-templates required-port-reference-declare ast:requires-port* newline-infix)
(define-templates local_locator code:injected-instances-system)
(define-templates injected-instance-declare injected-instances newline-infix)
(define-templates optional-type c++:optional-type)
(define-templates provided-port-reference-initializer ast:provides-port* newline-infix)
(define-templates required-port-reference-initializer ast:requires-port* newline-infix)
(define-templates constructor-meta-initializer non-injected-instances newline-infix)
(define-templates shell-provided-meta-initializer ast:provides-port* newline-infix)
(define-templates shell-required-meta-initializer ast:requires-port* newline-infix)
(define-templates injected-instance-meta-initializer injected-instances newline-infix)
(define-templates non-injected-instance-meta-initializer non-injected-instances newline-infix)
(define-templates dzn-locator code:dzn-locator)
(define-templates header-data ast:data*)
(define-templates header-model c++:model)

(define-templates provided-port-instance-declare ast:provides-port* newline-infix)
(define-templates required-port-instance-declare ast:requires-port* newline-infix)
(define-templates instance-meta-initializer identity)
(define-templates shell-provided-in ast:provided-in-triggers newline-infix)
(define-templates shell-required-out ast:required-out-triggers newline-infix)
(define-templates shell-provided-out ast:provided-out-triggers newline-infix)
(define-templates shell-required-in ast:required-in-triggers newline-infix)
(define-templates capture-list identity)
(define-templates capture c++:capture-arguments capture-prefix)
(define-templates shell-non-injected-instance-meta non-injected-instances)
(define-templates declare-method code:trigger newline-infix)
(define-templates declare-pure-virtual-method ast:in-triggers)
(define-templates prefix-arguments-n c++:argument_n prefix-arguments-grammar)
(define-templates c++:type-ref c++:type-ref)
