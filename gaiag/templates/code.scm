;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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
(define-templates model dzn:model)
(define-templates header- code:x-header-)
(define-templates async-member-initializer (lambda (o) (ast:port* (.behaviour o))))
;;for mcrl2
;;(define-templates scope scope type-infix)
(define-templates scope (compose .scope .name) name-infix)
(define-templates scope-type-scope code:scope-type-scope type-infix)
(define-templates scope-type-name code:scope-type-name type-infix)
(define-templates enum-name code:enum-name name-infix)
(define-templates scope-prefix (compose .scope .name) name-suffix)
(define-templates scope+name code:scope+name name-infix)
(define-templates scoped-model-name code:scope+name name-infix);; c++ compat, junk me
(define-templates type-name code:type-name type-infix)
(define-templates port-name code:port-name)
(define-templates port-type code:port-type type-infix)
(define-templates interface-include code:interface-include)
(define-templates model2file-interface-include code:model2file-interface-include)
(define-templates component-include code:component-include)
(define-templates scope::name code:scope+name type-infix)
(define-templates code-enum-literal code:enum-literal type-infix)
(define-templates enum-scope code:enum-scope type-infix)
(define-templates reply code:reply)
(define-templates decapitalize-model-name (compose (cut string-downcase <> 0 1) symbol->string om:name (lambda (o) (parent o <model>))))
(define-templates upcase-model-name (compose string-upcase (->join "_") om:scope+name (lambda (o) (parent o <model>))))
(define-templates method code:trigger)
(define-templates parameters code:parameters formal-infix)
(define-templates formals code:formals formal-infix)
(define-templates formals-type code:formals formal-infix)
(define-templates methods code:ons)
(define-templates functions code:functions)
(define-templates reply-type code:reply-type name-infix)
(define-templates variable-name code:variable-name)
(define-templates assign-reply code:assign-reply)
(define-templates meta-child om:instances meta-child-infix)
(define-templates block)
(define-templates port-release (lambda (o) (if (om:blocking-compound? (parent o <model>)) o "")))
(define-templates expand-on code:expand-on)
(define-templates all-ports-meta-list om:ports meta-infix)
(define-templates in-event-definer (lambda (o) (filter om:in? (om:events o))) event-definer-infix)
(define-templates out-event-definer (lambda (o) (filter om:out? (om:events o))) event-definer-infix)
(define-templates enum-definer code:enum-definer)
(define-templates global-enum-definer code:global-enum-definer)
(define-templates enum-field-definer (lambda (o) (map (symbol->enum-field o) ((compose .elements .fields) o))) comma-infix)
(define-templates variable-member-initializer om:variables)
(define-templates reply-member-initializer code:reply-types)
(define-templates injected-member-initializer (lambda (o) (filter .injected (om:ports o))))
(define-templates provided-member-initializer (lambda (o) (filter ast:provides? (om:ports o))))
(define-templates required-member-initializer (lambda (o) (filter (conjoin (negate .injected) ast:requires?) (om:ports o))))
(define-templates instance-name code:instance-name)
(define-templates instance-port-name code:instance-port-name)
(define-templates injected-instance-initializer code:injected-instances)
(define-templates non-injected-instance-initializer non-injected-instances)
(define-templates injected-binding-initializer injected-bindings)
(define-templates instance-initializer om:instances)
(define-templates bind-connect code:non-injected-bindings)
(define-templates bind-provided code:bind-provided)
(define-templates bind-required code:bind-required)
(define-templates binding-name code:instance-name)
(define-templates component-port code:component-port)
(define-templates injected-instance-system-initializer code:injected-instances-system)
(define-templates system-port-connect (lambda (o) (filter (negate om:port-bind?) ((compose .elements .bindings) o))))
(define-templates code-arguments code:arguments argument-infix)
(define-templates out-arguments code:out-argument argument-prefix)
(define-templates return code:return)
(define-templates main)
(define-templates main-port-connect-in ast:out-triggers-in-events)
(define-templates main-port-connect-in-void ast:out-triggers-void-in-events)
(define-templates main-port-connect-in-valued ast:out-triggers-valued-in-events)
(define-templates main-port-connect-out ast:out-triggers-out-events)
(define-templates main-provided-port-init ast:provided)
(define-templates main-required-port-init ast:required)
(define-templates main-provided-flush-init om:provided)
(define-templates main-required-flush-init om:required)
(define-templates main-out-arg code:main-out-arg argument-infix)
(define-templates main-event-map-void ast:void-in-triggers event-map-prefix)
(define-templates main-event-map-valued ast:valued-in-triggers event-map-prefix)
(define-templates main-event-map-flush ast:required event-map-prefix)
(define-templates flush-provides ast:provided)
(define-templates main-event-map-match-return code:main-event-map-match-return)
(define-templates main-required-port-name ast:required main-port-name-infix)
