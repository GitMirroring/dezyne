;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2019, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
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
(define-templates in-event-signature (lambda (o) (filter ast:in? (ast:event* o))) newline-infix)
(define-templates out-event-signature (lambda (o) (filter ast:out? (ast:event* o))) newline-infix)


;;;
;;; Component
;;;
(define-templates meta)
(define-templates port-declaration ast:port*)
(define-templates async-port-declare ast:async-port*)
(define-templates async-port-init ast:async-port*)

(define-templates variable-member-initializer (lambda (o) (filter (compose ast:typed? .expression) (ast:variable* o))))
(define-templates provided-port-init ast:provides-port*)
(define-templates required-port-init (compose (cut filter (negate .injected) <>) ast:requires-port*))
(define-templates required-port-meta ast:requires-port* newline-comma-infix)

(define-templates method code:ons)
(define-templates on-trigger (compose car .elements .triggers))
(define-templates function code:functions)

(define-templates formal-binding cs:formal-binding newline-infix)
(define-templates formal-binding-temporary cs:formal-binding newline-infix)
(define-templates formal-binding-assign-temporary cs:formal-binding newline-infix)
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
(define-templates illegal-out-assign cs:illegal-out-assign newline-infix)
(define-templates return-statement cs:return-statement)
(define-templates statement cs:statement)


;;;
;;; Generated main
;;;
(define-templates main-formal-assign (lambda (o) (filter (negate ast:in?) (cs:formals o))) newline-infix)
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
(define-templates shell-provided-meta-initializer ast:provides-port*)
(define-templates shell-required-meta-initializer ast:requires-port*)
(define-templates shell-provided-in ast:provided-in-triggers)
(define-templates shell-required-out ast:required-out-triggers)
(define-templates shell-provided-out ast:provided-out-triggers)
(define-templates shell-required-in ast:required-in-triggers)
(define-templates return-temporary-assign cs:return-temporary-assign)
(define-templates return-temporary cs:return-temporary)


;;;
;;; Misc
;;;
(define-templates formal-parameter cs:formals comma-infix)
(define-templates direction cs:direction)
(define-templates non-primitive cs:non-primitive)
