;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

;; dzn overrides
(define-templates makreel:enum-literal makreel:enum-literal type-infix)
(define-templates makreel:enum-fields makreel:enum-fields newline-pipe-infix)


(define-templates source identity newline-infix)
(define-templates model makreel:get-model)

(define-templates scope+name om:scope+name)
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
(define-templates event-sort makreel:action-sort action-sort-grammar)

(define-templates requires-sort-construct ast:requires+async-ports newline-pipe-prefix)
(define-templates provides-port-construct ast:provides-ports newline-pipe-prefix)

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

(define-templates call-continuation-sort makreel:call-continuation-sort newline-infix)
(define-templates call-continuation-sort-function makreel:call-continuation-sort newline-pipe-infix)

(define-templates pretty-print-dzn pretty-print-dzn)

(define-templates interface-proc makreel:interface-proc newline-infix)
(define-templates behaviour-proc .behaviour)
(define-templates behaviour-with-optional-proc makreel:behaviour-with-optional-proc)
(define-templates behaviour-without-optional-proc makreel:behaviour-without-optional-proc)

(define-templates non-optional-proc makreel:non-optional-proc newline-infix)
(define-templates optional-proc makreel:optional-proc newline-infix)

(define-templates function makreel:called-function*)
(define-templates function-return-proc makreel:function-return-proc)
(define-templates function-return makreel:function-return newline-union-infix)
(define-templates recurse makreel:recurse?)
(define-templates return-process-parameter makreel:non-recurse?)


;; statement process
(define-templates proc makreel:proc newline-infix)
(define-templates proc-assign makreel:proc-assign)
(define-templates proc-variable makreel:proc-variable)
(define-templates variable-parameter makreel:variable-parameter)
(define-templates reply-synchronization makreel:reply-synchronization)
(define-templates trigger-name makreel:trigger-name)
(define-templates process-id)
(define-templates process-identifier)
(define-templates process-parameters makreel:process-parameters parameters-grammar)
(define-templates process-parameters-return makreel:process-parameters-return parameters-grammar)

(define-templates argument->formal ast:argument->formal)
(define-templates makreel:arguments ast:argument* comma-suffix)
(define-templates process-haakjes makreel:process-haakjes)

(define-templates process-index makreel:process-index)
(define-templates event (compose car ast:trigger*))

(define-templates continuation makreel:continuation newline-union-infix)
(define-templates then-continuation makreel:then-continuation newline-union-infix)
(define-templates continuation-identifier makreel:continuation) ;;ASSUME list of one
(define-templates else-continuation makreel:else-continuation newline-union-infix)

;; statement helpers
(define-templates assign)
(define-templates assign-call .parent)
(define-templates return-value makreel:return-value)
(define-templates reply-expression .expression)
(define-templates reply-constructor makreel:type-constructor)
(define-templates type-bound makreel:type-bound)
(define-templates type-check makreel:type-check)

(define-templates interface-action-proc makreel:interface-action-proc newline-infix)
(define-templates rename-flush-provides makreel:rename-flush-provides)
(define-templates rename-flush-requires makreel:rename-flush-requires)
(define-templates allow-touw makreel:allow-touw newline-comma-infix)
(define-templates action-proc makreel:action-proc newline-infix)
(define-templates member-init makreel:member-init parameters-grammar)

;; interface
(define-templates provides-port-parallel-proc ast:provides-ports newline-parallel-infix)
(define-templates requires-port-parallel-proc ast:non-external-ports newline-parallel-prefix)
(define-templates external-port-parallel-proc ast:external-ports newline-parallel-prefix)

;; q process
(define-templates queue-proc ast:have-requires+async?)
(define-templates no-queue-proc ast:have-no-requires+async?)
(define-templates queue-proc-requires ast:requires+async-ports newline-union-prefix)
(define-templates queue-comm-requires ast:requires+async-ports newline-comma-infix)
(define-templates queue-allow-requires ast:requires+async-ports newline-comma-prefix)
(define-templates queue-rename-requires ast:requires+async-ports newline-comma-infix)

(define-templates external-proc ast:external-ports)

(define-templates async-parallel ast:async-ports?)
(define-templates async-parallel-port ast:async-ports newline-union-prefix)

;; reorder
(define-templates reorder-provides ast:provides-ports newline-union-infix)
(define-templates reorder-blocking ast:blocking?)
(define-templates reorder-flush ast:provides-ports)
(define-templates reorder-block ast:provides-ports newline-union-infix)

(define-templates reorder-comm-provides ast:provides-ports newline-comma-prefix)
(define-templates reorder-allow-provides ast:provides-ports newline-comma-prefix)
(define-templates reorder-allow-requires ast:requires+async-ports newline-comma-prefix)
(define-templates reorder-rename-provides ast:provides-ports newline-comma-prefix)
(define-templates reorder-rename-requires ast:requires+async-ports newline-comma-prefix)

;;semantics
(define-templates semantics-provides ast:provides-ports newline-union-infix)
(define-templates semantics-provides-flush ast:requires-ports newline-union-prefix)
(define-templates semantics-provides-unblocked ast:provides-ports newline-union-infix)
(define-templates semantics-provides-unblocked-replies ast:provides-ports newline-union-infix)
(define-templates semantics-async ast:provides-ports newline-union-prefix)
(define-templates semantics-async-requires ast:requires-ports newline-union-prefix)
(define-templates semantics-async-flush ast:provides-ports newline-union-prefix)
(define-templates semantics-async-q ast:async-ports?)
(define-templates semantics-async-qin ast:async-ports newline-union-infix)
(define-templates semantics-async-qout ast:async-ports newline-union-prefix)
(define-templates semantics-provides-blocked-provides ast:provides-ports newline-union-prefix)
(define-templates semantics-provides-blocked-requires ast:requires-ports newline-union-prefix)
(define-templates semantics-provides-blocked-async ast:async-ports newline-union-prefix)
(define-templates semantics-provides-blocked-internal ast:have-requires?)
(define-templates semantics-provides-blocked-qmt ast:requires-ports newline-union-prefix)
(define-templates semantics-provides-replies ast:provides-ports newline-union-infix)
(define-templates semantics-requires ast:requires-ports newline-union-prefix)
(define-templates semantics-requires-flush-provides ast:provides-ports)
(define-templates semantics-requires-flush-provides-provides makreel:flush-provides-ports newline-union-infix)
(define-templates semantics-requires-flush-requires ast:requires-ports newline-union-prefix)


(define-templates semantics-requires-provides ast:provides-ports newline-union-infix)
(define-templates semantics-requires-requires ast:requires-ports newline-union-prefix)
(define-templates semantics-requires-flush ast:provides-ports newline-union-prefix)


(define-templates semantics-flush-provides makreel:flush-provides-ports newline-union-prefix)
(define-templates semantics-qmt-flush-provides ast:provides-ports newline-union-infix)
(define-templates semantics-flush-requires ast:requires-ports newline-union-prefix)

(define-templates semantics-comm-provides ast:provides-ports newline-comma-prefix)
(define-templates semantics-comm-requires ast:requires+async-ports newline-comma-prefix)
(define-templates semantics-allow-provides ast:provides-ports newline-comma-prefix)
(define-templates semantics-allow-requires ast:requires+async-ports newline-comma-prefix)
(define-templates semantics-allow-async ast:async-ports newline-comma-prefix)
(define-templates semantics-rename-provides ast:provides-ports newline-comma-prefix)
(define-templates semantics-rename-requires ast:requires+async-ports newline-comma-prefix)

;; component
(define-templates component-comm-requires ast:requires+async-ports newline-comma-prefix)
(define-templates component-comm-async ast:async-ports newline-comma-prefix)
(define-templates component-allow-provides ast:provides-ports newline-comma-prefix)
(define-templates component-allow-requires ast:requires-ports newline-comma-prefix)
(define-templates component-allow-async ast:async-ports newline-comma-prefix)
(define-templates component-rename-provides ast:provides-ports newline-comma-prefix)
(define-templates component-rename-requires ast:requires+async-ports newline-comma-prefix)
(define-templates component-rename-async ast:async-ports newline-comma-prefix)
(define-templates component-hide-provides ast:provides-ports newline-comma-prefix)
(define-templates component-hide-requires ast:requires-ports newline-comma-prefix)
(define-templates component-hide-async ast:async-ports newline-comma-prefix)

;; provides
(define-templates provides-r2c-proc makreel:provides-proc newline-union-infix)
(define-templates provides-out-proc)
(define-templates provides-out-proc-provides makreel:provides-proc newline-union-infix)
(define-templates provides-comm ast:provides-ports newline-comma-infix)
(define-templates provides-allow ast:provides-ports newline-comma-prefix)
(define-templates provides-rename ast:provides-ports newline-comma-infix)
(define-templates provides-hide ast:provides-ports newline-comma-infix)
