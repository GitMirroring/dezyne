;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018, 2019, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2018, 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
;;; Entry points
;;;

(define-templates header)
(define-templates source)
(define-templates model code:model double-newline-infix)


;;;
;;; Names
;;;

(define-templates file-name code:file-name)
(define-templates function-type code:function-type)
(define-templates port-name code:port-name)
(define-templates port-type code:port-type type-infix)
(define-templates reply-type code:reply-type name-infix)
(define-templates type-name code:type-name type-infix)
(define-templates upcase-model-name code:upcase-model-name name-infix)
(define-templates variable-name code:variable-name)


;;;
;;; Interface
;;;
(define-templates in-event-definer ast:in-event* event-definer-infix)
(define-templates out-event-definer ast:out-event* event-definer-infix)


;;;
;;; Component
;;;
(define-templates all-ports-meta-list ast:port* meta-infix)
(define-templates meta-child code:instance* meta-child-infix)

(define-templates reply-member-declare code:reply-types)
(define-templates variable-member-declare ast:variable*)

(define-templates methods code:ons double-newline-infix)
(define-templates expand-on code:expand-on)
(define-templates method code:trigger)

(define-templates async-member-initializer (lambda (o) (ast:port* (.behavior o))))
(define-templates variable-member-initializer ast:variable*)
(define-templates reply-member-initializer code:reply-types)

(define-templates injected-require-initializer ast:injected-port*)
(define-templates injected-port-require-override ast:injected-port*)

(define-templates event-slot (lambda (o) (filter (negate ast:async?) (ast:void-in-triggers o))))
(define-templates flush (lambda (o) (if (ast:in? o) o '())))
(define-templates valued-event-slot ast:valued-in-triggers)
(define-templates async-event-slot ast:async-out-triggers)
(define-templates async-req-event-slot ast:req-events)
(define-templates async-clr-event-slot ast:clr-events)
(define-templates trace-q-out code:trace-q-out)

(define-templates functions code:functions double-newline-infix)


;;;
;;; Statements
;;;
(define-templates assign-reply code:assign-reply)
(define-templates block)
(define-templates foreign-reply (compose code:reply ast:type))
(define-templates foreign-return (compose code:reply ast:type))
(define-templates port-release code:port-release)
(define-templates reply code:reply)
(define-templates return code:return)


;;;
;;; Formals, parameters, arguments
;;;
(define-templates code-arguments code:arguments argument-grammar)
(define-templates out-arguments code:out-argument out-argument-grammar)
(define-templates formals code:formals formal-grammar)
(define-templates formals-anonymous code:formals formal-grammar)
(define-templates formals-type code:formals formal-grammar)


;;;
;;; Enums
;;;
(define-templates enum-scope code:enum-scope type-infix)
(define-templates enum-name code:enum-name name-infix)
(define-templates enum-short-name code:enum-short-name name-infix)
(define-templates enum-definer code:enum-definer)
(define-templates enum-field-definer code:enum-field-definer enum-definer-grammar)
(define-templates global-enum-definer code:global-enum-definer)
(define-templates code-enum-literal code:enum-literal type-infix)


;;;
;;; System
;;;
(define-templates injected-instance-declare code:injected-instances)
(define-templates non-injected-instance-declare code:non-injected-instances)

(define-templates injected-member-initializer ast:injected-port*)
(define-templates provided-member-initializer ast:provides-port*)
(define-templates required-member-initializer (lambda (o) (filter (conjoin (negate ast:injected?) ast:requires?) (ast:port* o))))
(define-templates instance-name code:instance-name)
(define-templates instance-port-name code:instance-port-name)
(define-templates injected-instance-initializer code:injected-instances)
(define-templates non-injected-instance-initializer code:non-injected-instances)
(define-templates injected-binding-initializer code:injected-bindings)

;; Bindings
(define-templates bind-connect code:non-injected-bindings)
(define-templates bind-provided code:bind-provided)
(define-templates bind-required code:bind-required)
(define-templates binding-name code:instance-name)
(define-templates component-port code:component-port)
(define-templates injected-instance-system-initializer code:injected-instances-system)
(define-templates system-port-connect (lambda (o) (filter (negate code:port-bind?) (ast:binding* o))))
(define-templates system-rank ast:provides-port*)


;;;
;;; Generated main
;;;
(define-templates main)
(define-templates main-port-connect-in ast:out-triggers-in-events)
(define-templates main-port-connect-in-void ast:out-triggers-void-in-events)
(define-templates main-port-connect-in-valued ast:out-triggers-valued-in-events)
(define-templates main-port-connect-out ast:out-triggers-out-events)
(define-templates main-provided-port-init ast:provides-port*)
(define-templates main-required-port-init ast:requires-port*)
(define-templates main-provided-flush-init ast:provides-port*)
(define-templates main-required-flush-init ast:requires-port*)
(define-templates main-out-arg-define code:main-out-arg-define)
(define-templates main-out-arg-define-formal identity)
(define-templates main-out-arg code:main-out-arg main-out-arg-grammar)
(define-templates main-event-map-void ast:void-in-triggers event-map-prefix)
(define-templates main-event-map-valued ast:valued-in-triggers event-map-prefix)
(define-templates main-event-map-flush ast:requires-port* event-map-prefix)
(define-templates main-event-map-match-return code:main-event-map-match-return)
(define-templates main-required-port-name ast:requires-port* comma-infix)


;;;
;;; Misc
;;;
(define-templates version-assert)
(define-templates interface-include code:interface-include)
(define-templates component-include code:component-include)
