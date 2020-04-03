;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2018 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018, 2019, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2021, 2022 Paul Hoogendijk <paul@dezyne.org>
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

;; dzn overrides
(define-templates makreel:enum-literal makreel:enum-literal type-infix)
(define-templates makreel-enum-fields makreel:enum-fields newline-pipe-infix)

(define-templates interface-reorder makreel:interface-reorder)
(define-templates reorder-end (compose makreel:interface-reorder car makreel:continuation))

(define-templates source)
(define-templates model makreel:get-model)
(define-templates init makreel:init)

(define-templates enum-name makreel:enum-name type-infix)
(define-templates type-constructor makreel:type-constructor)
(define-templates basic-type ast:type)
(define-templates port-type-name ast:port-type-name)
(define-templates event-prefix makreel:event-prefix)

(define-templates makreel:interface-name makreel:interface-name)
(define-templates makreel:model-name makreel:model-name)
(define-templates makreel:function-name makreel:function-name)

(define-templates action-sort makreel:action-sort action-sort-grammar)
(define-templates action-sort-event makreel:action-sort-event action-sort-grammar)

(define-templates modeling-sort makreel:modeling-sort)

(define-templates enum-sort makreel:enum-sort action-sort-grammar)
(define-templates reply-sort makreel:action-sort action-sort-grammar)
(define-templates reply-type-sort makreel:reply-type-sort)
(define-templates reply-type-sort-item makreel:type-constructor)
(define-templates reply-values ast:provides-port* newline-comma-infix)
(define-templates event-sort makreel:action-sort action-sort-grammar)

(define-templates requires-sort-construct ast:requires+async-port* newline-pipe-prefix)
(define-templates provides-port-construct ast:provides-port* newline-pipe-prefix)
(define-templates requires-port-construct ast:requires-port* newline-pipe-prefix)

(define-templates makreel:queue-length makreel:queue-length)

(define-templates event-act makreel:event-act action-sort-grammar)
(define-templates event-act-provides makreel:event-act-provides action-sort-grammar)
(define-templates event-act-requires makreel:event-act-requires action-sort-grammar)

(define-templates stack-sort makreel:call-continuation-sort newline-pipe-prefix)
(define-templates call-stack-arguments makreel:stack-parameters comma-suffix)
(define-templates stack-parameters makreel:locals comma-suffix)
(define-templates stack-destructor makreel:stack-destructor comma-infix)
(define-templates process-argument-stack makreel:process-argument-stack?)

(define-templates stack makreel:stack?)
(define-templates stack-empty makreel:stack-empty?)

(define-templates return-type-sort makreel:return-type-sort)
(define-templates return-type makreel:return-type newline-pipe-infix)

(define-templates call-continuation-sort makreel:call-continuation-sort)
(define-templates call-continuation-sort-function makreel:call-continuation-sort newline-pipe-infix)

(define-templates pretty-print-dzn pretty-print-dzn)

(define-templates interface-proc makreel:interface-proc)
(define-templates behavior-proc .behavior)

(define-templates function makreel:called-function*)
(define-templates function-return-proc makreel:function-return-proc)
(define-templates function-return makreel:function-return newline-union-infix)
(define-templates recurse makreel:recurse?)
(define-templates return-process-parameter makreel:non-recurse?)

(define-templates global-state-type members pair-grammar)
(define-templates state-sum members sum-grammar)
(define-templates members-name members members-name-grammar)

;; statement process
(define-templates proc makreel:proc)
(define-templates proc-assign makreel:proc-assign)
(define-templates proc-variable makreel:proc-variable)
(define-templates variable-parameter makreel:variable-parameter)
(define-templates variable-parameters makreel:continuation-haakjes)
(define-templates reply-synchronization makreel:reply-synchronization)
(define-templates trigger-name makreel:trigger-name)
(define-templates process-id)
(define-templates process-identifier)
(define-templates statement-process-identifier .statement)
(define-templates process-parameters makreel:process-parameters parameters-grammar)
(define-templates process-parameters-return makreel:process-parameters-return parameters-grammar)

(define-templates argument->formal ast:argument->formal)
(define-templates makreel-arguments ast:argument* comma-suffix)
(define-templates process-haakjes makreel:process-haakjes)

(define-templates process-index makreel:process-index)
(define-templates event (compose car ast:trigger*))

(define-templates continuation makreel:continuation newline-union-infix)
(define-templates then-continuation makreel:then-continuation newline-union-infix)
(define-templates continuation-identifier makreel:continuation)
(define-templates continuation-process-identifier identity)
(define-templates else-continuation makreel:else-continuation newline-union-infix)

;; statement helpers
(define-templates assign)
(define-templates assign-call .parent)
(define-templates assign-call-parameter makreel:assign-call-parameter)
(define-templates return-value makreel:return-value)
(define-templates reply-expression .expression)
(define-templates reply-constructor makreel:type-constructor)
(define-templates switch-context makreel:switch-context)
(define-templates type-bound makreel:type-bound)
(define-templates type-check makreel:type-check)

(define-templates interface-action-proc makreel:interface-action-proc)
(define-templates rename-flush-provides makreel:rename-flush-provides)
(define-templates rename-flush-requires makreel:rename-flush-requires)
(define-templates allow-tau makreel:allow-tau newline-comma-infix)
(define-templates member-init makreel:member-init parameters-grammar)

(define-templates sum-helper-params makreel:sum-helper-params parameters-grammar)

(define-templates makreel:line-column makreel:line-column)

;; interface
(define-templates provides-port-parallel-proc ast:provides-port* newline-parallel-infix)
(define-templates requires-port-parallel-proc ast:non-external-port* newline-parallel-prefix)
(define-templates external-port-parallel-proc ast:external-port* newline-parallel-prefix)

;; q process
(define-templates queue-proc ast:have-requires+async?)
(define-templates no-queue-proc ast:have-no-requires+async?)
(define-templates queue-proc-requires ast:requires+async-port* newline-union-prefix)
(define-templates queue-comm-requires ast:requires+async-port* newline-comma-infix)
(define-templates queue-allow-requires ast:requires+async-port* newline-comma-prefix)
(define-templates queue-rename-requires ast:requires+async-port* newline-comma-infix)

(define-templates external-proc ast:external-port*)

(define-templates async-parallel ast:async-port*?)
(define-templates async-parallel-port ast:async-port* newline-union-prefix)

;;comonent behavior
(define-templates component-behavior-allow-provides ast:provides-port* newline-comma-prefix)
(define-templates component-behavior-allow-requires ast:requires+async-port* newline-comma-prefix)
(define-templates component-behavior-rename-requires ast:requires+async-port* newline-comma-prefix)

;;defer
(define-templates defer-semantics ast:provides-port* newline-union-infix)
(define-templates defer (lambda (o) (if (pair? (makreel:behavior->defer-qout o)) o '())))
(define-templates defer-qout makreel:behavior->defer-qout newline-union-infix)
(define-templates defer-process-haakjes)
(define-templates defer-process-argument makreel:locals comma-infix)
(define-templates defer-proc makreel:behavior->defer-qout)
(define-templates provides-flush (lambda (o) (if (ast:provides? o) o '())))
(define-templates requires-reply (lambda (o) (if (ast:requires? o) o '())))
(define-templates defer-skip (lambda (o) (if (parent o <component>) o '())))
(define-templates defer-locals-sort (cute tree-collect (is? <defer>) <>) pipe-prefix)
(define-templates defer-local-arguments-sort (lambda (o) (if (pair? (makreel:locals o)) o '())))
(define-templates deferred-locals-sort makreel:locals comma-infix)
(define-templates defer-locals)
(define-templates defer-local-arguments (lambda (o) (if (pair? (makreel:locals o)) o '())))
(define-templates deferred-locals makreel:locals comma-infix)
(define-templates defer-process-index (compose makreel:process-index .statement))

(define-templates state-vector (lambda (o) (let ((behavior (.behavior o))) (if (pair? (ast:variable* behavior)) behavior '()))))
(define-templates state-member ast:variable* comma-infix)
(define-templates construct-state-vector (lambda (o) (let ((behavior (.behavior (parent o <component>)))) (if (pair? (ast:variable* behavior)) behavior '()))))
(define-templates state-var ast:variable* comma-infix)

(define-templates defer-select-member ast:variable* pipe-prefix)
(define-templates defer-select-variable ast:defer-variable* comma-infix)
(define-templates defer-predicate ast:variable* and-infix)
(define-templates defer-predicate-true (lambda (o) (if (null? (ast:variable* o)) o '())) and-infix)

;;semantics
(define-templates semantics-main)
(define-templates semantics-provides ast:provides-port* newline-union-infix)
(define-templates semantics-provides-flush ast:requires-port* newline-union-prefix)
(define-templates semantics-provides-reply-init ast:provides-port* comma-infix)
(define-templates semantics-provides-reset-reply-pair makreel:provides-pair* comma-infix)
(define-templates semantics-provides-reset-reply makreel:provides-reset-reply comma-infix)
(define-templates semantics-provides-reply-pair makreel:provides-pair* comma-infix)
(define-templates semantics-provides-reply makreel:provides-reply comma-infix)
(define-templates semantics-provides-unblocked ast:provides-port* newline-union-infix)
(define-templates semantics-provides-unblocked-missing-replies ast:provides-port* and-infix)
(define-templates semantics-provides-unblocked-replies ast:provides-port* newline-union-prefix)
(define-templates semantics-provides-unblocked-modeling ast:requires-port* newline-union-prefix)
(define-templates semantics-provides-unblocked-switch-context ast:requires-port* newline-union-prefix)
(define-templates semantics-async-defer)
(define-templates semantics-async-defer-flush)
(define-templates semantics-async ast:provides-port* newline-union-prefix)
(define-templates semantics-async-requires ast:requires-port* newline-union-prefix)
(define-templates semantics-async-modeling ast:requires-port* newline-union-prefix)
(define-templates semantics-async-flush ast:provides-port* newline-union-prefix)
(define-templates semantics-async-requires-flush ast:provides-port* newline-union-prefix)
(define-templates semantics-async-qin ast:async-port* newline-union-infix)
(define-templates semantics-async-qout ast:async-port* newline-union-prefix)
(define-templates semantics-async-allow-ack (lambda (o) (let ((a (ast:async-port* o))) (if (pair? a) o '()))))
(define-templates semantics-no-async (lambda (o) (let ((a (ast:async-port* o))) (if (pair? a) '() o))))
(define-templates semantics-provides-blocking-defer)
(define-templates semantics-provides-blocking-provides ast:provides-port* newline-union-prefix)
(define-templates semantics-provides-blocking-requires ast:requires-port* newline-union-prefix)
(define-templates semantics-provides-skip-blocked-defer)
(define-templates semantics-provides-skip-blocked-replies ast:provides-port* newline-union-infix)
(define-templates semantics-provides-skip-blocked-requires ast:requires-port* newline-union-prefix)
(define-templates semantics-port-in-released-or ast:provides-port* or-infix)
(define-templates semantics-provides-blocked-defer)
(define-templates semantics-provides-blocked-provides ast:provides-port* newline-union-prefix)
(define-templates semantics-provides-blocked-replies ast:provides-port* newline-union-prefix)
(define-templates semantics-provides-blocked-ports ast:provides-port* newline-union-prefix)
(define-templates semantics-provides-blocked-async ast:async-port* newline-union-prefix)
(define-templates semantics-provides-blocked-requires ast:requires-port* newline-union-prefix)
(define-templates semantics-reply ast:provides-port* newline-union-infix)
(define-templates semantics-blocked-rtc-defer)
(define-templates semantics-blocked-rtc-provides ast:provides-port* newline-union-infix)
(define-templates semantics-blocked-rtc-requires ast:requires-port* newline-union-prefix)
(define-templates semantics-requires ast:requires-port* newline-union-prefix)
(define-templates semantics-comm-provides ast:provides-port* newline-comma-prefix)
(define-templates semantics-comm-requires ast:requires+async-port* newline-comma-prefix)
(define-templates semantics-allow-provides ast:provides-port* newline-comma-prefix)
(define-templates semantics-allow-requires ast:requires+async-port* newline-comma-prefix)
(define-templates semantics-allow-async ast:async-port* newline-comma-prefix)
(define-templates semantics-rename-provides ast:provides-port* newline-comma-prefix)
(define-templates semantics-rename-requires ast:requires+async-port* newline-comma-prefix)
(define-templates semantics-provides-action ast:provides-port* newline-union-prefix)

;; component
(define-templates component-comm-requires ast:requires+async-port* newline-comma-prefix)
(define-templates component-comm-async ast:async-port* newline-comma-prefix)
(define-templates component-allow-provides ast:provides-port* newline-comma-prefix)
(define-templates component-allow-requires ast:requires-port* newline-comma-prefix)
(define-templates component-allow-async ast:async-port* newline-comma-prefix)
(define-templates component-rename-provides ast:provides-port* newline-comma-prefix)
(define-templates component-rename-requires ast:requires+async-port* newline-comma-prefix)
(define-templates component-rename-async ast:async-port* newline-comma-prefix)
(define-templates component-hide-provides ast:provides-port* newline-comma-prefix)
(define-templates component-hide-requires ast:requires-port* newline-comma-prefix)
(define-templates component-hide-async ast:async-port* newline-comma-prefix)
(define-templates reordered ast:provides-port* union-infix)

;; provides
(define-templates provides-r2c-blocking-proc (lambda (o) (if (any ast:blocking? (ast:provides-port* o)) (makreel:provides-proc o) '())) newline-union-infix)
(define-templates provides-r2c-proc (lambda (o) (if (not (any ast:blocking? (ast:provides-port* o))) (makreel:provides-proc o) '())) newline-union-infix)
(define-templates provides-out makreel:provides-proc newline-union-infix)
(define-templates provides-comm ast:provides-port* newline-comma-infix)
(define-templates provides-allow ast:provides-port* newline-comma-prefix)
(define-templates provides-rename ast:provides-port* newline-comma-infix)
