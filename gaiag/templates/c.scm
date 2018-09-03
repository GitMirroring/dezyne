;;; Dezyne --- Dezyne command line tools
;;;
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

(define-templates header-model c:models)
(define-templates source-model c:models)
(define-templates header)
(define-templates source)

;; naming stuff
(define-templates model-parent-name c:model-parent-name type-infix)
(define-templates name c:name type-infix)

(define-templates provided-event-tracing-initialization ast:provided)
(define-templates required-event-tracing-initialization ast:required)
(define-templates variable-member-initialization c:extract-variables-with-respect-to-enums)
(define-templates initialize)

(define-templates to-string c:enum-trigger-void)
(define-templates trigger-reply c:enum-trigger-void)

(define-templates main-log-event-return c:enum-or-trigger)

(define-templates port-type c:get-trigger-port-type type-infix)
(define-templates formal-data-type c:formal-data-type)

;; event-arguments stuff
(define-templates event-arguments c:trigger-formals)
(define-templates closure-struct-args c:trigger-formals)
(define-templates method-params c:trigger-formals)
(define-templates call-in-function-extra-arguments c:trigger-formals)
(define-templates helper-function-extra-arguments c:trigger-formals)
(define-templates closure-variable-definition c:trigger-formals newline-infix)

(define-templates closure-struct c:get-incoming-triggers-from-model)
(define-templates helper-in-trigger-prototype c:get-incoming-triggers-from-model)
(define-templates helper-in-trigger c:get-incoming-triggers-from-model)

(define-templates provided-port-initialization ast:provided)
(define-templates required-port-initialization ast:required)
(define-templates trigger-initialization ast:in-triggers)

(define-templates call-in-trigger-prototype ast:provided-in-triggers newline-infix)
(define-templates call-out-trigger-prototype ast:required-out-triggers newline-infix)
(define-templates call-in-trigger ast:provided-in-triggers)
(define-templates call-out-trigger ast:required-out-triggers)
(define-templates formal-handler ast:formal* newline-infix)



(define-templates method-prototype (lambda (o) (map code:trigger (code:ons o))) newline-infix)
(define-templates method code:trigger)
(define-templates methods code:ons)
(define-templates self-or-not c:is-global)
(define-templates enum-cast (lambda (o)(if (is-a? (ast:type o) <enum>) o '())))

(define-templates functions-declarations code:functions newline-infix)
(define-templates functions code:functions)

(define-templates header-data (lambda (o) (filter (is? <data>) (.elements o))))
(define-templates event-function-ptr)

;; main@component stuff
(define-templates main-header)
(define-templates main-includes)
(define-templates main-fill-event-map)
(define-templates main-illegal-print)
(define-templates main-content)

(define-templates port-initialization-provided ast:provided)
(define-templates port-initialization-required ast:required)
(define-templates main-log-event-out-trigger ast:out-triggers)
(define-templates in-trigger-initialization ast:in-triggers)
(define-templates out-trigger-initialization ast:out-triggers)
(define-templates main-log-event-void-return c:void-trigger)
(define-templates main-log-event-non-void-return c:non-void-trigger)

(define-templates type-name c:type-name name-infix)
(define-templates type-name-different c:type-name-different name-infix)
(define-templates function-return-type (lambda (o) ((compose c:name .type .signature) o)) name-infix)
(define-templates formals ast:formal*)
(define-templates in-event-definer c:filter-in)
(define-templates out-event-definer c:filter-out)
(define-templates include-guard)

;; system stuff

(define-templates instance-declaration (lambda (o) ( (compose .elements .instances) o)))
(define-templates instance-init (lambda (o) ( (compose .elements .instances) o)) newline-infix)
(define-templates instance-init-dzn-tracing (lambda (o) ( (compose .elements .instances) o)) newline-infix)
(define-templates instance-declare-dzn-tracing (lambda (o) ( (compose .elements .instances) o)) newline-infix)
(define-templates system-port-connect (lambda (o) ((compose .elements .bindings) o)))
(define-templates connect-internal-ports c:evaluate-internal-bind)
(define-templates bind-provided (lambda (o) (.left o)))
(define-templates bind-required (lambda (o) (.right o)))
(define-templates connect-port-name-right (lambda (o) ((compose .port.name .right) o)))
(define-templates connect-port-name-left (lambda (o) ((compose .port.name .left) o)))
(define-templates connect-instance-name-right (lambda (o) ((compose .instance.name .right) o)))
(define-templates connect-instance-name-left (lambda (o) ((compose .instance.name .left) o)))
(define-templates port-declaration ast:port*)
(define-templates port-declare ast:port*)
(define-templates binding-instance c:binding-instance)

;; foreign binding stuff
(define-templates base-or-not c:base-or-not)
(define-templates base-or-not-left c:base-or-not-left)
(define-templates base-or-not-right c:base-or-not-right)

;; enum stuff
(define-templates enum-name-global-local c:global-or-local-enum-name type-infix)
(define-templates enum-field-switch-case c:get-enum-fields-of-enum)
(define-templates enum-field-else-if c:get-enum-fields-of-enum)
(define-templates source-enum-string-function-definition c:get-all-enums)
(define-templates header-enum-string-wrapper (lambda (o) (if (pair? (c:get-all-enums o)) o '())))
(define-templates source-enum-string-wrapper (lambda (o) (if (pair? (c:get-all-enums o)) o '())))
(define-templates global-enum-wrapper (lambda (o) (if (pair? (c:get-all-enums o)) o '())))
(define-templates file-name-identifier-upcase c:file-name-identifier-upcase)
(define-templates header-enum-string-function-prototype c:get-all-enums newline-infix)
(define-templates enum-name c:enum-name type-infix)

;; namespace stuff
(define-templates namespace-upcase c:namespace-upcase type-infix)
(define-templates enum-complete-name-upcase c:enum-complete-name-upcase type-infix)

;; foreign stuff
(define-templates method-prototypes ast:in-triggers newline-infix)
(define-templates call-in-trigger-foreign ast:provided-in-triggers)

;; in out events of interfaces
(define-templates in-event-struct-declare c:in-events?)
(define-templates out-event-struct-declare c:out-events?)
