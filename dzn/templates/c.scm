;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-templates provided-event-tracing-initialization ast:provides-port*)
(define-templates required-event-tracing-initialization ast:requires-port*)
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

(define-templates provided-port-initialization ast:provides-port*)
(define-templates required-port-initialization ast:requires-port*)
(define-templates trigger-initialization ast:in-triggers)

(define-templates call-in-trigger-prototype ast:provided-in-triggers)
(define-templates call-out-trigger-prototype ast:required-out-triggers)
(define-templates call-in-trigger ast:provided-in-triggers)
(define-templates call-out-trigger ast:required-out-triggers)
(define-templates formal-handler ast:formal*)



(define-templates method-prototype ast:in-triggers)
(define-templates method code:trigger)
(define-templates methods code:ons)
(define-templates enum-cast (lambda (o)(if (is-a? (ast:type o) <enum>) o '())))

(define-templates functions-declarations code:functions)
(define-templates functions code:functions)

(define-templates header-data (lambda (o) (filter (is? <data>) (.elements o))))
(define-templates event-function-ptr)


;;;
;;; Enums
;;;
(define-templates enum-field-switch-case c:get-enum-fields-of-enum)
(define-templates enum-field-else-if c:get-enum-fields-of-enum)
(define-templates source-enum-string-function-definition c:get-all-enums)
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
(define-templates instance-declaration (lambda (o) ( (compose .elements .instances) o)))
(define-templates instance-init (lambda (o) ( (compose .elements .instances) o)))
(define-templates instance-init-dzn-tracing (lambda (o) ( (compose .elements .instances) o)))
(define-templates instance-declare-dzn-tracing (lambda (o) ( (compose .elements .instances) o)))
(define-templates system-port-connect c:external-binding)
(define-templates connect-internal-ports c:internal-binding)
(define-templates binding-provided c:binding-provided)
(define-templates binding-required c:binding-required)
(define-templates connect-port-name-right (lambda (o) ((compose .port.name .right) o)))
(define-templates connect-port-name-left (lambda (o) ((compose .port.name .left) o)))
(define-templates connect-instance-name-right (lambda (o) ((compose .instance.name .right) o)))
(define-templates connect-instance-name-left (lambda (o) ((compose .instance.name .left) o)))
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

(define-templates port-initialization-provided ast:provides-port*)
(define-templates port-initialization-required ast:requires-port*)
(define-templates main-log-event-out-trigger ast:out-triggers)
(define-templates in-trigger-initialization ast:in-triggers)
(define-templates out-trigger-initialization ast:out-triggers)
(define-templates main-log-event-return c:enum-or-trigger)
(define-templates main-log-event-void-return c:void-trigger)
(define-templates main-log-event-non-void-return c:non-void-trigger)

(define-templates type-name c:type-name name-infix)
(define-templates type-name-different c:type-name-different name-infix)
(define-templates function-return-type (lambda (o) ((compose c:name .type .signature) o)) name-infix)
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
(define-templates call-in-trigger-foreign ast:provided-in-triggers)
