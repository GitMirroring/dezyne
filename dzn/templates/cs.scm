;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2019, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
(define-templates model cs:model)
(define-templates global-type-name)
(define-templates data cs:data)
(define-templates global-enum-definer cs:global-enum-definer)


;;;
;;; Names
;;;
(define-templates enum-name code:enum-name identifier-infix)

(define-templates function-return-type cs:function-return-type)
(define-templates reply-type code:reply-type identifier-infix)
(define-templates return-type return-type)


;;;
;;; Interface
;;;
(define-templates in-event-signature (lambda (o) (filter ast:in? (ast:event* o))))
(define-templates out-event-signature (lambda (o) (filter ast:out? (ast:event* o))))


;;;
;;; Foreign
;;;
(define-templates foreign-event-slot ast:void-in-triggers)
(define-templates foreign-valued-event-slot ast:valued-in-triggers)


;;;
;;; Component
;;;
(define-templates meta)
(define-templates port-declaration ast:port*)
(define-templates async-port-declare ast:async-port*)
(define-templates async-port-init ast:async-port*)
(define-templates async-port-declare-delegate cs:async-interface*)
(define-templates async-signature-name cs:async-signature-name name_infix)

(define-templates variable-member-initializer (lambda (o) (filter (compose ast:typed? .expression) (ast:variable* o))))
(define-templates provides-port-init ast:provides-port*)
(define-templates requires-port-init (compose (cut filter (negate .injected?) <>) ast:requires-port*))
(define-templates requires-port-meta ast:requires-port* newline-comma-infix)

(define-templates method code:ons)
(define-templates on-trigger (compose car .elements .triggers))
(define-templates function code:functions)

(define-templates formal-bindings cs:formal-bindings)
(define-templates formal-binding cs:formal-binding)
(define-templates formal-binding-temporary cs:formal-binding)
(define-templates formal-binding-assign-temporary cs:formal-binding)
(define-templates formal-binding-lambda ast:provides-port*)

(define-templates out-ref-local out-ref-local)
(define-templates assign-out-ref out-ref-local)
(define-templates dzn-prefix dzn-prefix)
(define-templates default-ref default-ref)
(define-templates default-out default-out)

;; check-bindings
(define-templates check-bindings-list ast:port* newline-comma-infix)
(define-templates check-in-binding ast:in-event*)
(define-templates check-out-binding ast:out-event*)
(define-templates port-check-bindings ast:port* newline-comma-infix)


;;;
;;; Statements
;;;
(define-templates =expression =expression)
(define-templates code-arguments cs:arguments argument-infix)
(define-templates illegal-out-assign cs:illegal-out-assign)
(define-templates return-statement cs:return-statement)
(define-templates statement cs:statement)


;;;
;;; defer
;;;
(define-templates capture-member-variable cs:capture-variable*)
(define-templates capture-member-value cs:capture-variable*)
(define-templates member-equality cs:member-equality-variable* and-infix)


;;;
;;; Formals, parameters, arguments
;;;
(define-templates direction cs:direction)
(define-templates formal-parameter cs:formals comma-infix)


;;;
;;; Generated main
;;;
(define-templates main-formal-assign (lambda (o) (filter (negate ast:in?) (cs:formals o))))
(define-templates main-arg cs:formals comma-infix)
(define-templates main-arg-define cs:formals)
(define-templates main-port-connect-return (lambda (o) (if (ast:typed? o) o '())))


;;;
;;; System
;;;
(define-templates scoped-port-name (lambda (port) ((compose .ids .name .type) port)) type-infix)
(define-templates port-initializer ast:port*)


;;;
;;; Shell
;;;
(define-templates bind-interface-name (compose ast:full-name .type .port .left) type-infix)
(define-templates shell-provides-meta-initializer ast:provides-port*)
(define-templates shell-requires-meta-initializer ast:requires-port*)
(define-templates shell-provides-in ast:provides-in-triggers)
(define-templates shell-requires-out ast:requires-out-triggers)
(define-templates shell-provides-out ast:provides-out-triggers)
(define-templates shell-requires-in ast:requires-in-triggers)
(define-templates return-temporary-assign cs:return-temporary-assign)
(define-templates return-temporary cs:return-temporary)


;;;
;;; Misc
;;;
(define-templates non-primitive cs:non-primitive)
