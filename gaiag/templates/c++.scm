;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
(define-templates declare-method code:trigger)
(define-templates function-type c++:function-type)
(define-templates calls c++:void-in-triggers)
(define-templates async ast:async-out-triggers)
(define-templates rcalls ast:valued-in-triggers)
(define-templates prefix-formals-type code:formals formal-prefix)
(define-templates pump code:pump?)
(define-templates pump-include code:pump?)
(define-templates include-statement code:file-name)
(define-templates reqs ast:req-events)
(define-templates clrs ast:clr-events)
(define-templates open-namespace (lambda (o) (if (is-a? (.parent o) <root>) (map (lambda (x) (string-join (list " namespace " (symbol->string x) " {") "")) (om:scope o)) "")))
(define-templates close-namespace (lambda (o) (if (is-a? (.parent o) <root>) (map (lambda (x) "}\n") (om:scope o)) "")))
(define-templates meta identity)
(define-templates ports-meta-list (lambda (o) (filter ast:requires? (om:ports o))) meta-infix)
(define-templates check-bindings-list (lambda (o) ((->join ",") (map (lambda (port) (list "[this]{"(.name port) ".check_bindings();}")) (om:ports o)))))
(define-templates check-in-binding (lambda (o) (filter om:in? (om:events o))))
(define-templates check-out-binding (lambda (o) (filter om:out? (om:events o))))
(define-templates interface-enum-to-string c++:enum->string)
(define-templates interface-string-to-enum c++:enum->string)
(define-templates enum-field-to-string c++:enum-field->string)
(define-templates string-to-enum c++:string->enum)
(define-templates asd-voidreply (lambda (o) (if asd? "__ASD_VoidReply, " "")))
(define-templates scoped-port-name (lambda (port) (let ((scope-name ((compose .name .type) port))) (append (.scope scope-name) (list (.name scope-name))))) type-infix)
(define-templates reply-member-declare code:reply-types)
(define-templates variable-member-declare (lambda (o) (om:variables o)))
(define-templates out-binding-lambda (lambda (o) (filter ast:provides? (om:ports o))))
(define-templates provided-port-declare (lambda (o) (filter ast:provides? (om:ports o))))
(define-templates required-port-declare (lambda (o) (filter ast:requires? (om:ports o))))
(define-templates async-port-declare (lambda (o) (om:ports (.behaviour o))))
(define-templates stream-member om:variables stream-comma-infix)
(define-templates method-declare code:ons)
(define-templates function-declare code:functions)
(define-templates include-guard)
(define-templates endif)
(define-templates provided-port-reference-declare (lambda (o) (filter ast:provides? (om:ports o))))
(define-templates required-port-reference-declare (lambda (o) (filter ast:requires? (om:ports o))))
(define-templates local_locator code:injected-instances-system)
(define-templates injected-instance-declare injected-instances)
(define-templates non-injected-instance-declare non-injected-instances)
(define-templates system-rank ast:provided)
(define-templates optional-type c++:optional-type)
(define-templates provided-port-reference-initializer ast:provided)
(define-templates required-port-reference-initializer ast:required)
(define-templates constructor-meta-initializer non-injected-instances)
(define-templates shell-provided-meta-initializer ast:provided)
(define-templates shell-required-meta-initializer ast:required)
(define-templates injected-instance-meta-initializer injected-instances)
(define-templates non-injected-instance-meta-initializer non-injected-instances)
(define-templates dzn-locator code:dzn-locator)
(define-templates header-data (lambda (o) (filter (is? <data>) (.elements o))))
(define-templates model-glue (lambda (o) (filter (lambda (o) (and (dzn:glue) (is-a? o <foreign>))) (dzn:model o))))
(define-templates header-model dzn:model)

(define-templates header-model-glue (lambda (o)
                                      (filter-map (lambda (o)
                                                    (if (and (dzn:glue) (is-a? o <foreign>)) o
                                                             #f)) (dzn:model o))))

(define-templates provided-port-instance-declare (lambda (o) (filter ast:provides? (om:ports o))))
(define-templates required-port-instance-declare (lambda (o) (filter ast:requires? (om:ports o))))
(define-templates instance-meta-initializer identity)
(define-templates shell-provided-in ast:provided-in-triggers)
(define-templates shell-required-out ast:required-out-triggers)
(define-templates shell-provided-out ast:provided-out-triggers)
(define-templates shell-required-in ast:required-in-triggers)
(define-templates capture-list identity)
(define-templates capture c++:capture-arguments capture-prefix)
(define-templates shell-non-injected-instance-meta non-injected-instances)
(define-templates declare-method code:trigger)
(define-templates declare-pure-virtual-method ast:in-triggers)
(define-templates main-out-arg-define code:main-out-arg-define)
(define-templates main-out-arg-define-formal identity)
(define-templates main-event-map-flush-asd (if (and #f asd?) ast:required (const '())) event-map-prefix)
(define-templates prefix-arguments-n c++:argument_n argument-prefix)
(define-templates c++:type-ref c++:type-ref)
(define-templates construction-include c++:construction-include)
(define-templates construction-signature c++:construction-signature)
(define-templates construction-parameters c++:construction-parameters)
(define-templates construction-parameters-locator-set c++:construction-parameters-locator-set)
(define-templates construction-parameters-locator-get c++:construction-parameters-locator-get)

;; glue
(define-templates foreign-header)
(define-templates glue-top-header)
(define-templates glue-top-source)
(define-templates glue-bottom-header)
(define-templates glue-bottom-source)
(define-templates asd-constructor c++:asd-constructor)
(define-templates asd-api-instance-declaration c++:asd-api-instance-declaration)
(define-templates asd-api-instance-init c++:asd-api-instance-init)
(define-templates asd-api-definition c++:asd-api-definition)
(define-templates asd-cb-definition c++:asd-cb-definition)
(define-templates asd-cb-instance-declaration c++:asd-cb-instance-declaration)
(define-templates asd-cb-instance-init c++:asd-cb-instance-init)
(define-templates asd-cb-event-init c++:asd-cb-event-init)
(define-templates asd-get-api c++:asd-get-api)
(define-templates asd-register-cb c++:asd-register-cb)
(define-templates asd-register-st c++:asd-register-st)
(define-templates asd-method-declaration c++:asd-method-declaration)
(define-templates asd-method-definition c++:asd-method-definition)
(define-templates asd-cb-method-definition c++:asd-cb-method-definition)
(define-templates asd-get-api-definition c++:asd-get-api-definition)
(define-templates asd-register-cb-definition c++:asd-register-cb-definition)
