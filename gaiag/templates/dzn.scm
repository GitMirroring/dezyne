;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

;;;
;;; Entry points
;;;
(define-templates source dzn:model newline-infix)


;;;
;;; Top
;;;
(define-templates global dzn:global newline-infix)
(define-templates open-namespace dzn:open-namespace)
(define-templates close-namespace dzn:open-namespace)


;;;
;;; Names
;;;

(define-templates model-name dzn:model-name)
(define-templates model-full-name dzn:model-full-name type-infix)


;;;
;;; Interface
;;;
(define-templates define-type ast:type* newline-infix)
(define-templates direction dzn:direction)
(define-templates in-event (lambda (o) (filter ast:in? (ast:event* o))) newline-infix)
(define-templates out-event (lambda (o) (filter ast:out? (ast:event* o))) newline-infix)
(define-templates signature dzn:signature space-infix)
(define-templates formal-type dzn:formal-type)
(define-templates formal ast:formal* formal-grammar)
(define-templates behaviour .behaviour)
(define-templates define-function ast:function* newline-infix)
(define-templates trigger ast:trigger* comma-infix)


;;;
;;; Component
;;;
(define-templates provided-port (lambda (o) (filter ast:provides? (ast:port* o))) newline-infix)
(define-templates required-port (lambda (o) (filter ast:requires? (ast:port* o))) newline-infix)
(define-templates external dzn:external)
(define-templates injected dzn:injected)
(define-templates async-port ast:port* newline-infix)

(define-templates trigger-signature (lambda (o) (if (not (.port.name o)) "" o)))
(define-templates trigger-formal (lambda (o) (ast:formal* o)) formal-grammar)
(define-templates port-prefix dzn:port-prefix port-suffix)


;;;
;;; Statements
;;;
(define-templates argument ast:argument* argument-grammar)
(define-templates action-arguments dzn:action-arguments action-argument-grammar)
(define-templates statement dzn:statement newline-infix)
(define-templates expand-statement dzn:expand-statement newline-infix)
(define-templates out-bindings ast:formal*)
(define-templates then .then)
(define-templates else (lambda (o) (or (.else o) '())))
(define-templates arguments ast:argument* argument-grammar)
(define-templates declare-variable ast:variable* newline-infix)
(define-templates reply-port dzn:reply-port dot-suffix)
(define-templates expand-blocking dzn:expand-blocking)


;;;
;;; Types
;;;
(define-templates type dzn:type type-infix)

;; data
(define-templates data dzn:data)

;; enum
(define-templates enum-literal dzn:enum-literal type-infix)
(define-templates field ast:field* field-infix)

;; int
(define-templates from dzn:from)
(define-templates to dzn:to)


;;;
;;; Expressions
;;;
(define-templates =expression dzn:=expression)
(define-templates expression dzn:expression)
(define-templates subexpression .expression)
(define-templates left .left)
(define-templates right .right)
(define-templates expression-expand dzn:expression-expand)


;;;
;;; System
;;;
(define-templates system)
(define-templates declare-instance ast:instance* newline-infix)
(define-templates instance (lambda (o) (if (not (.instance.name o)) "" (list (.instance o)))) dot-suffix)
(define-templates binding ast:binding* newline-infix)


;;;
;;; Misc
;;;
(define-templates version (const %version))
(define-templates version-major (const %version-major))
(define-templates version-minor (const %version-minor))
(define-templates version-patch (const %version-patch))
