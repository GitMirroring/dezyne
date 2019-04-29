;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-templates model cs:model)
(define-templates meta)
(define-templates port-declaration ast:port*)
(define-templates async-port-declare ast:async-port*)
(define-templates async-port-init ast:async-port*)
(define-templates provided-port-init ast:provided)
(define-templates required-port-init (compose (cut filter (negate .injected) <>) ast:required))
(define-templates required-port-meta ast:required newline-comma-infix)
(define-templates port-check-bindings ast:port* newline-comma-infix)
(define-templates method code:ons)
(define-templates function code:functions)

(define-templates return-type return-type)
(define-templates delegate-type return-type)
(define-templates func-return-type (lambda (o) (let ((type (return-type o)))
                                                 (if (is-a? type <void>) '() o))))

(define-templates return-statement (lambda (o) (let ((type (return-type o)))
                                                        (if (is-a? type <void>) '() o))))

(define-templates return-temporary-assign (lambda (o) (let ((type (return-type o)))
                                                        (if (is-a? type <void>) '() o))))
(define-templates return-temporary (lambda (o) (let ((type (return-type o)))
                                                 (if (is-a? type <void>) '() o))))

(define-templates on-trigger (compose car .elements .triggers))
(define-templates statement cs:statement)
(define-templates check-in-binding (lambda (o) (filter om:in? (om:events o))))
(define-templates check-out-binding (lambda (o) (filter om:out? (om:events o))))
(define-templates instance-declaration ast:instance*)
(define-templates port-initializer ast:port*)
(define-templates check-bindings-list ast:port* newline-comma-infix)
(define-templates event-type ast:type)
(define-templates variable-member-initializer (lambda (o) (filter (compose ast:typed? .expression) (ast:variable* o))))
(define-templates scope_name code:scope+name name_infix)
(define-templates delegate-signature (lambda (o) (if (or (ast:typed? o) (pair? (cs:formals o))) o '())))
(define-templates signature cs:formals)

(define-templates formal-type (lambda (o) (append (cs:formals o) (if (ast:typed? o) (list (ast:type o)) '()))) comma-infix)

(define-templates formal-parameter cs:formals comma-infix)

(define-templates direction cs:direction)
(define-templates delegate-formal-type cs:delegate-formal-type comma-infix)

(define-templates main-arg cs:formals comma-infix)
(define-templates main-arg-define cs:formals)

(define-templates main-port-connect-return (lambda (o) (if (ast:typed? o) o '())))

(define-templates global-enum-definer cs:global-enum-definer)
(define-templates enum-name code:enum-name identifier-infix)
(define-templates reply-type code:reply-type identifier-infix)

(define-templates global-type-name)
(define-templates non-primitive (lambda (o) (if (or (is-a? (ast:type o) <enum>)
                                                    (is-a? (ast:type o) <interface>)) o '())))
(define-templates bind-interface-name (compose .type .port .left))

(define-templates data (lambda (o) (cond ((is-a? o <root>) (filter (is? <data>) (.elements o)))
                                         ((is-a? o <data>) o)
                                         (else '()))))

(define-templates shell-provided-in ast:provided-in-triggers)
(define-templates shell-required-out ast:required-out-triggers)
(define-templates shell-provided-out ast:provided-out-triggers)
(define-templates shell-required-in ast:required-in-triggers)


(define-templates in-event-signature (lambda (o) (filter ast:in? (ast:event* o))) newline-infix)
(define-templates out-event-signature (lambda (o) (filter ast:out? (ast:event* o))) newline-infix)

(define-templates code-arguments cs:arguments argument-infix)

(define-method (out-ref-local (o <trigger>))
  (filter (negate ast:in?) (cs:formals o)))
(define-templates out-ref-local out-ref-local)
(define-templates assign-out-ref out-ref-local)

(define-method (dzn-prefix (o <formal>))
  (if (ast:in? o) '() o))
(define-templates dzn-prefix dzn-prefix)

(define-method (default-ref (o <formal>))
  (if (ast:inout? o) o '()))
(define-templates default-ref default-ref)

(define-method (default-out (o <formal>))
  (if (ast:out? o) o '()))
(define-templates default-out default-out)

(define-templates main-formal-assign (lambda (o) (filter (negate ast:in?) (cs:formals o))) newline-infix)

(define-method (cs:formal-binding (o <on>))
  (filter (is? <formal-binding>) (cs:formals (car (ast:trigger* o)))))

(define-method (cs:formal-binding (o <blocking-compound>))
  (cs:formal-binding (parent o <on>)))

(define-templates formal-binding cs:formal-binding newline-infix)
(define-templates formal-binding-temporary cs:formal-binding newline-infix)
(define-templates formal-binding-assign-temporary cs:formal-binding newline-infix)
(define-templates formal-binding-lambda (lambda (o) (filter ast:provides? (om:ports o))))

(define-method (=expression (o <variable>))
  (let ((e (.expression o)))
    (if (and (is-a? e <literal>) (eq? 'void (.value e))) o
        e)))
(define-templates =expression =expression)

(define-templates illegal-out-assign cs:illegal-out-assign newline-infix)
(define-templates scoped-port-name (lambda (port) (let ((scope-name ((compose .name .type) port))) (append (.scope scope-name) (list (.name scope-name))))) type-infix)


(define-templates shell-provided-meta-initializer ast:provided)
(define-templates shell-required-meta-initializer ast:required)
