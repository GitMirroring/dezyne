;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2018, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-templates header)
(define-templates source)
(define-templates file-name code:file-name)
(define-templates model code:model)
(define-templates header- code:x-header-)
(define-templates name code:name)
(define-templates async-member-initializer (lambda (o) (ast:port* (.behaviour o))))
(define-templates async ast:async-out-triggers)
(define-templates reqs ast:req-events)
(define-templates clrs ast:clr-events)

;; FIXME
(define-templates scope (compose scope .name) name-infix)
(define-templates code:type-scope ast:full-scope type-infix)
(define-templates scope-type-name code:scope-type-name type-infix)
(define-templates scope-prefix (compose scope .name) name-suffix)
(define-templates scope+name code:scope+name name-infix)
(define-templates scoped-model-name code:scope+name name-infix);; c++ compat, junk me
(define-templates scope::name code:scope+name type-infix)
(define-templates enum-scope code:enum-scope type-infix)

(define-templates enum-name code:enum-name name-infix)
(define-templates enum-short-name code:enum-short-name name-infix)
(define-templates type-name code:type-name type-infix)
(define-templates port-name code:port-name)
(define-templates port-type code:port-type type-infix)
(define-templates interface-include code:interface-include)
(define-templates component-include code:component-include)
(define-templates code-enum-literal code:enum-literal type-infix)
(define-templates reply code:reply)
(define-templates upcase-model-name code:upcase-model-name name-infix)
(define-templates method code:trigger)
(define-templates parameters code:parameters formal-grammar)
(define-templates formals code:formals formal-grammar)
(define-templates formals-anonymous code:formals formal-grammar)
(define-templates formals-type code:formals formal-grammar)
(define-templates methods code:ons)
(define-templates function-type code:function-type)
(define-templates functions code:functions)
(define-templates reply-member-declare code:reply-types)
(define-templates reply-type code:reply-type name-infix)
(define-templates variable-name code:variable-name)
(define-templates assign-reply code:assign-reply)
(define-templates meta-child code:instance* meta-child-infix)
(define-templates block)
(define-templates port-release code:port-release)
(define-templates expand-on code:expand-on)
(define-templates all-ports-meta-list ast:port* meta-infix)
(define-templates in-event-definer ast:in-event* event-definer-infix)
(define-templates out-event-definer ast:out-event* event-definer-infix)
(define-templates enum-definer code:enum-definer)
(define-templates global-enum-definer code:global-enum-definer)
(define-templates enum-field-definer code:enum-field-definer enum-definer-grammar)
(define-templates variable-member-declare ast:variable*)
(define-templates variable-member-initializer ast:variable*)
(define-templates reply-member-initializer code:reply-types)
(define-templates injected-member-initializer ast:injected-port*)
(define-templates provided-member-initializer ast:provides-port*)
(define-templates required-member-initializer (lambda (o) (filter (conjoin (negate ast:injected?) ast:requires?) (ast:port* o))))
(define-templates instance-name code:instance-name)
(define-templates instance-port-name code:instance-port-name)
(define-templates injected-instance-declare code:injected-instances)
(define-templates injected-instance-initializer code:injected-instances)
(define-templates non-injected-instance-declare non-injected-instances)
(define-templates non-injected-instance-initializer non-injected-instances)
(define-templates injected-binding-initializer injected-bindings)
(define-templates instance-initializer code:instance*)
(define-templates bind-connect code:non-injected-bindings)
(define-templates bind-provided code:bind-provided)
(define-templates bind-required code:bind-required)
(define-templates binding-name code:instance-name)
(define-templates component-port code:component-port)
(define-templates injected-instance-system-initializer code:injected-instances-system)
(define-templates system-port-connect (lambda (o) (filter (negate om:port-bind?) (ast:binding* o))))
(define-templates system-rank ast:provides-port*)
(define-templates code-arguments code:arguments argument-grammar)
(define-templates out-arguments code:out-argument out-argument-grammar)
(define-templates return code:return)
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
(define-templates version-assert)
(define-templates calls (lambda (o) (filter (negate ast:async?) (ast:void-in-triggers o))))
(define-templates rcalls ast:valued-in-triggers)

;; set state
(define-templates non-injected-instance-set-state non-injected-instances)
(define-templates instance-set-state-argument code:set-state-argument)
(define-templates variable-member-setter ast:variable*)

(define-templates trace-q-out code:trace-q-out)
