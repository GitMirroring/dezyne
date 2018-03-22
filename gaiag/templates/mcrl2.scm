;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2018 Henk Katerberg <henk.katerberg@verum.com>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

(define-templates source identity newline-infix)
(define-templates model mcrl2:get-model)
(define-templates mcrl2-component-name (lambda (o) (mcrl2:model-name (car (filter (is? <component>) (.elements (parent o <root>)))))))
(define-templates mcrl2-provided-port-type mcrl2:provided-port-type)
;;(define-templates mcrl2-provided-port-name (lambda (o) (stderr "mcrl2-provided-port-name: ~a\n" o) (mcrl2:provided-port-name o)))
(define-templates mcrl2-provided-port-name mcrl2:provided-port-name)
(define-templates provided-port-type (lambda (o) (mcrl2:provided-port-type o)))
(define-templates provided-port-name (lambda (o) (mcrl2:provided-port-name (parent o <model>))))
(define-templates global-type om:globals newline-indent-infix)
(define-templates sort-interface mcrl2:interfaces newline-indent-infix)
(define-templates sort-component identity newline-indent-infix)
(define-templates action-struct (lambda (o) (map
					      (lambda (x) (make <interface-event> #:interface o #:event x))
					      ((compose .elements .events) o))) pipe-infix)
(define-templates interface-name mcrl2:interface-name)
(define-templates interfaces-allow-dillegals mcrl2:interfaces newline-indent-infix)
(define-templates map-interface-name mcrl2:interfaces newline-indent-infix)
(define-templates eqn-interface-name mcrl2:interfaces newline-indent-infix)
(define-templates eqn-allow-dillegals (lambda (o) (mcrl2:interfaces (car (filter (is? <component>) (.elements o))))) newline-indent-infix)
(define-templates global-interface-reply mcrl2:interfaces newline-indent-infix)
(define-templates interface-action-alphabet mcrl2:interfaces newline-indent-infix)
(define-templates port-action-alphabet mcrl2:ports newline-indent-infix)
(define-templates port-interface-name (compose mcrl2:model-name .type))
(define-templates event-name (compose .name .event))
(define-templates event-dir (compose .direction .event))
(define-templates integers get-ints newline-indent-suffix)
(define-templates enum-struct get-enums newline-indent-suffix)
(define-templates queue-size (lambda (_) (command-line:get 'queue_size 3)))
(define-templates mcrl2-reply-type mcrl2:reply-type)
(define-templates mcrl2-reply-expression mcrl2:reply-expression)
(define-templates mcrl2-model-name mcrl2:model-name)
(define-templates mcrl2-references-sort models-with-calls newline-infix)
(define-templates references references pipe-infix)
(define-templates resolve-reference references else-infix)
(define-templates return-types typed-functions comma-suffix)
(define-templates other-function-returns other-function-returns comma-infix)
(define-templates init-return-value (compose .type .signature))
(define-templates valued-return (lambda (o) (or (.expression o) "")))
(define-templates valued-comma (lambda (o) (or (and (.expression o) (pair? (other-function-returns o)) ",") "")))
(define-templates mcrl2-return-process
  (lambda (o)
    (let ((models (models-with-calls o)))
      (if (pair? models)
	  models
	  '()))) newline-infix)
(define-templates enum-field-struct
  (lambda (o) (map
	       (lambda (x) (clone (make <enum-name-field> #:name (.name.name o) #:field x) #:parent o))
	       ((compose .elements .fields) o))) pipe-infix)
(define-templates reply-union-struct mcrl2:reply-types pipe-infix)
(define-templates mcrl2-scope scope type-infix)
(define-templates provided-port-reply-types om:provided)
(define-templates mcrl2-reply-union-declaration)
(define-templates event-type (compose .type .signature))
(define-templates mcrl2-reply-types mcrl2:reply-types union-suffix)
(define-templates print-ast
  (lambda (o) (stderr "AST: ~a\n" o) (->string o)))
(define-templates pretty-print-dzn
  (let ((debug? (gdzn:command-line:get 'debug)))
    (if debug?
     (lambda (o)
       (string-join (string-split (string-trim-right
                                   (ast->dzn (or (and=> (as o <behaviour>) .statement) o)))
                                  #\newline) "\n     % " 'prefix))
     (const ""))))
(define-templates mcrl2-interface-process
  (lambda (o)
    (match o
      (($ <component>) (mcrl2:interfaces o))
      (($ <interface>) (.behaviour o)))))
(define-templates mcrl2-component-process .behaviour)
(define-templates assign-call-var-name (compose .variable.name .assign))
(define-templates variable-call-var-name (compose .name .variable))
(define-templates mcrl2-provided-port-type-name (compose mcrl2:expand-types car ast:event* .type car om:provided (cut parent <> <model>)))
(define-templates mcrl2-type-name mcrl2:expand-types)
(define-templates action-union-struct om:ports pipe-infix)
(define-templates mcrl2-process-name)
(define-templates function-name function-name)
(define-templates function-scope function-scope)
(define-templates mcrl2-statement
  (lambda (o)
    (match o
      (($ <behaviour>) (.statement o))
      (($ <guard>) o)
      ((_) "otherwise"))))
(define-templates next-call-reference
  (lambda (o)
    (mcrl2:process-identifier (process-continuation o))))
(define-templates mcrl2-type mcrl2-type)
(define-templates process-parameters)
(define-templates variables-in-scope variables-in-scope comma-prefix)
(define-templates variable-names-in-scope locals comma-prefix)
(define-templates call-parameters call-parameters comma-suffix)
(define-templates cont-parameter
  (lambda (o) (make <cont-parameter> #:continuation (call-continuation o))))
(define-templates process-continuation-parameters cont-locals param-list-grammar)
(define-templates next-call-context cont-locals param-list-grammar)
(define-templates other-variables-in-scope (lambda (o)
                                              (filter (negate (compose (cut eq? (.id o) <>) .id))
                                                      (cont-locals o))) comma-prefix)
(define-templates init-locals-from-cont cont-locals comma-infix)
(define-templates call-continuation .continuation)
(define-templates globals-init model-from-scope)
(define-templates global-vars-init globals-from-scope comma-prefix)
(define-templates mcrl2-statement-process mcrl2:statement-process)


(define-templates mcrl2-function-process all-referenced-functions)
(define-templates mcrl2-process-identifier mcrl2:process-identifier)
(define-templates mcrl2-port-identifier mcrl2:port-identifier)
(define-templates mcrl2-child-identifier mcrl2:child-identifier)
(define-templates mcrl2-statement-then .then)
(define-templates mcrl2-statement-else .else)
(define-templates if-else-identifier
  (lambda (o) (mcrl2:process-identifier
	       (let ((elsestmt (.else o)))
		 (match elsestmt
		   (($ <compound>) ((compose car .elements) elsestmt))
		   (_ elsestmt))))))
(define-templates component-reply-in-stmt
  (lambda (o)
    (if (and (is-a? (parent o <model>) <component>) (ast:requires? (.port o)))
	o
	"")))
(define-templates on-event-union .elements union-infix)
(define-templates on-event-process .elements)
(define-templates on-trigger separate-trigger-type)
(define-templates on-from-provided on-from-provided)
(define-templates on-from-required on-from-required)
(define-templates required-the-end-trigger)
(define-templates the-end-trigger separate-trigger-type)
(define-templates trigger-expected-reply trigger-expected-reply)
(define-templates trigger-no-expected-reply trigger-no-expected-reply)
(define-templates on-event-trigger mcrl2:on-event-trigger)
(define-templates on-event-trigger-dir mcrl2:on-event-trigger-dir)
(define-templates trigger-port trigger-port)
(define-templates trigger-port-type trigger-port-type)
(define-templates trigger-port-type-reply trigger-port-type-reply)
(define-templates required-port-the-end required-port-the-end)
(define-templates block-illegals mcrl2:block-illegals)
(define-templates illegal-type
  (lambda (o)
    (if ((is? <interface>) (parent o <model>))
        (if (and (is-a? o <illegal>) (.incomplete o))
            "incomplete . delta"
            "Illegal")
	(illegal-or-dillegal o))))
(define-templates mcrl2-constrained-behaviour)
(define-templates constraining-with-optionals (lambda (o) (if (ast:optional? o) o "")))
(define-templates constraining-without-optionals (lambda (o) (if (ast:optional? o) "" o)))
(define-templates mcrl2-optional-unconstrained)
(define-templates mcrl2-inevitable-unconstrained)
(define-templates mcrl2-optional-constrained)
(define-templates mcrl2-run2completion)
(define-templates mcrl2-implementation)
(define-templates mcrl2-component-queues)
(define-templates required-ports-completion om:required union-prefix)
(define-templates required-port-queue om:required union-suffix)
(define-templates inevitable-optional-queue (lambda (o) (if (pair? (om:required o)) o "")) union-suffix)
(define-templates required-inevitable-allow om:required union-infix)
(define-templates required-optional-allow om:required union-infix)
(define-templates mcrl2-component-rc-required-port)
(define-templates mcrl2-component-rc-provided-port)
(define-templates mcrl2-required-with-out-event required-ports-with-out)
(define-templates required-ports-run2completion (lambda (o) (if (pair? (required-ports-with-out o)) o "delta")))
(define-templates run2completion-port-with-out-event required-ports-with-out union-suffix)
(define-templates provided-run2completion-port-with-out-event required-ports-with-out union-suffix)
(define-templates rename-required-ports om:required comma-suffix)
(define-templates rename-provided-ports (compose car om:provided))
(define-templates hidden-actions)
(define-templates required-port-hidden-actions om:required comma-suffix)
(define-templates provided-port-hidden-actions (compose car om:provided))
(define-templates allowed-actions)
(define-templates required-port-allowed-actions om:required comma-suffix)
(define-templates provided-port-allowed-actions (compose car om:provided))
(define-templates communicated-actions)
(define-templates required-port-communicated-actions om:required comma-suffix)
(define-templates provided-port-communicated-actions (compose car om:provided))
(define-templates allowed-parallel-actions)
(define-templates rename-parallel-actions)
(define-templates required-port-allowed-parallel-actions om:required comma-suffix)
(define-templates required-port-rename-parallel-actions om:required comma-infix)
(define-templates provided-port-allowed-parallel-actions (compose car om:provided))
(define-templates communicated-allowed-parallel-actions)
(define-templates required-port-communicated-allowed-parallel-actions om:required comma-suffix)
(define-templates provided-port-communicated-allowed-parallel-actions (compose car om:provided))
(define-templates allowed-communicated-allowed-parallel-actions)
(define-templates required-port-allowed-communicated-allowed-parallel-actions om:required comma-suffix)
(define-templates provided-port-allowed-communicated-allowed-parallel-actions (compose car om:provided))
(define-templates required-port-parallel-communication
  (lambda (o)
    (if (pair? (om:required o))
	o
	"")))
(define-templates no-required-port-parallel-communication
  (lambda (o)
    (if (pair? (om:required o))
	""
	o)))
(define-templates communicate-required-port-actions)
(define-templates rename-in-reply-out-req-port om:required comma-infix)
(define-templates rename-required-port-actions om:required parallel-suffix)
(define-templates rename-out-reply-in-req-port om:required comma-infix)
(define-templates process-continuation process-continuation)
(define-templates range-error-normal-assign? normal-assign?)
(define-templates assign-by-call? assign-by-call?)
(define-templates assign-by-action? assign-by-action?)
(define-templates var-decl-by-call? var-decl-by-call?)
(define-templates var-decl-by-action? var-decl-by-action?)
(define-templates assign-function-name (compose .function.name .call))
(define-templates assign-action-name (compose .name .event .expression))
(define-templates var-action-name (compose .name .event .expression))
(define-templates call-function-name (compose .function.name .expression))
(define-templates action-type action-type)
(define-templates check-range-error mcrl2:range-error)
(define-templates check-range-error-call mcrl2:range-error)
(define-templates constrain-action-range constrain-action-range)
(define-templates check-integer-bounds check-integer-bounds)
(define-templates check-event-integer-bounds check-integer-bounds)
(define-templates range-from mcrl2:range-from)
(define-templates range-to mcrl2:range-to)
(define-templates mcrl2-enum-literal mcrl2:enum-literal)
(define-templates next-process-parameters process-continuation)
(define-templates variable-in-scope? mcrl2:variable-in-scope?)
(define-templates assign-in-scope? mcrl2:variable-in-scope?)
(define-templates init-type-value .type)
(define-templates mcrl2-init-reply-value mcrl2:init-reply-value)
(define-templates initial-enum-field (compose car .elements .fields))
(define-templates enum-literal dzn:enum-literal type-infix)
(define-templates expression dzn:expression)
(define-templates expression-expand dzn:expression-expand)
(define-templates left (compose dzn:expression .left))
(define-templates right (compose dzn:expression .right))
(define-templates =expression dzn:=expression)

(define-templates interface-init)
(define-templates interface-lts-init)
(define-templates component-init)
(define-templates compliance-init)
(define-templates determinism-init)
(define-templates component-deadlock-init)
