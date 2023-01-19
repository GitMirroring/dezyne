;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
;;; Copyright © 2019, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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

(define-templates header-model c:models double-newline-infix)
(define-templates source-model c:components double-newline-infix)
(define-templates header)
(define-templates source)


;;;
;;; Names
;;;

(define-templates model-parent-name c:model-parent-name type-infix)
(define-templates name c:name type-infix)

(define-templates provides-event-tracing-initialization ast:provides-port*)
(define-templates requires-event-tracing-initialization ast:requires-port*)
(define-templates variable-member-initialization c:extract-variables-with-respect-to-enums)
(define-templates initialize)

(define-templates to-string c:enum-trigger-void)
(define-templates trigger-reply c:enum-trigger-void)

(define-templates port-type c:get-trigger-port-type type-infix)
(define-templates formal-data-type c:formal-data-type)


;;;
;;; Formals, parameters, arguments
;;;
(define-templates c-comma c:comma)
(define-templates closure-struct-args code:arguments)
(define-templates method-parameters code:arguments formal-grammar)
(define-templates helper-function-arguments code:arguments argument-grammar)
(define-templates closure-variable-definition code:arguments argument-grammar)

(define-templates closure-struct c:get-incoming-triggers-from-model)
(define-templates helper-in-trigger-prototype c:get-incoming-triggers-from-model)
(define-templates helper-in-trigger c:get-incoming-triggers-from-model)

(define-templates provides-port-initialization ast:provides-port*)
(define-templates requires-port-initialization ast:requires-port*)
(define-templates trigger-initialization ast:in-triggers)

(define-templates call-in-trigger-prototype ast:provides-in-triggers)
(define-templates call-out-trigger-prototype ast:requires-out-triggers)
(define-templates call-in-trigger ast:provides-in-triggers)
(define-templates call-out-trigger ast:requires-out-triggers)
(define-templates formal-handler ast:formal*)



(define-templates method-prototype ast:in-triggers)
(define-templates method code:trigger)
(define-templates methods code:ons)
(define-templates enum-cast (lambda (o)(if (is-a? (ast:type o) <enum>) o '())))

(define-templates functions-declarations code:functions)
(define-templates functions code:functions)

(define-templates event-function-ptr)


;;;
;;; Enums
;;;
(define-templates enum-field-switch-case c:get-enum-fields-of-enum)
(define-templates enum-field-else-if c:get-enum-fields-of-enum)
(define-templates source-enum-string-function-definition c:get-all-local-enums)
(define-templates header-enum-string-wrapper (lambda (o) (if (pair? (c:get-all-enums o)) o '())))
(define-templates source-enum-string-wrapper (lambda (o) (if (pair? (c:get-all-enums o)) o '())))
(define-templates global-enum-wrapper (lambda (o) (if (pair? (c:get-all-enums o)) o '())))
(define-templates file-name-identifier-upcase c:file-name-identifier-upcase)
(define-templates header-enum-string-function-prototype c:get-all-enums)
(define-templates enum-name c:enum-name type-infix)
(define-templates enum-literal c:enum-literal type-infix)


;;;
;;; System
;;;
(define-templates instance-declaration (compose .elements .instances))
(define-templates instance-init (compose .elements .instances))
(define-templates instance-init-dzn-tracing (compose .elements .instances))
(define-templates instance-declare-dzn-tracing (compose .elements .instances))
(define-templates system-port-connect c:external-binding)
(define-templates connect-internal-ports c:internal-binding)
(define-templates binding-provides c:binding-provides)
(define-templates binding-requires c:binding-requires)
(define-templates connect-port-name-right (compose .port.name .right))
(define-templates connect-port-name-left (compose .port.name .left))
(define-templates connect-instance-name-right (compose .instance.name .right))
(define-templates connect-instance-name-left (compose .instance.name .left))
(define-templates port-declaration ast:port*)
(define-templates system-port-declaration ast:port*)
(define-templates port-declare ast:port*)
(define-templates binding-instance c:binding-instance)


;;;
;;; Generated main
;;;
(define-templates main-header)
(define-templates main-includes)
(define-templates main-fill-event-map)
(define-templates main-illegal-print)
(define-templates main-content)

(define-templates port-initialization-provides ast:provides-port*)
(define-templates port-initialization-requires ast:requires-port*)
(define-templates main-log-event-out-trigger ast:out-triggers)
(define-templates in-trigger-initialization ast:in-triggers)
(define-templates out-trigger-initialization ast:out-triggers)
(define-templates main-log-event-return c:enum-or-trigger)
(define-templates main-log-event-void-return c:void-trigger)
(define-templates main-log-event-non-void-return c:non-void-trigger)

(define-templates type-name c:type-name name-infix)
(define-templates type-name-different c:type-name-different name-infix)
(define-templates function-return-type (compose c:type-name .type .signature) name-infix)
(define-templates formals ast:formal*)
(define-templates in-event-definer ast:in-event*)
(define-templates out-event-definer ast:out-event*)
(define-templates include-guard)

;; foreign binding stuff
(define-templates foreign-instance c:foreign-instance)

;; namespace stuff
(define-templates namespace-upcase c:namespace-upcase type-infix)
(define-templates enum-complete-name-upcase c:enum-complete-name-upcase type-infix)

;; foreign stuff
(define-templates formal-method-prototype ast:in-triggers)
(define-templates call-in-trigger-foreign ast:provides-in-triggers)
