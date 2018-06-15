;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-templates source dzn:model newline-infix)
(define-templates global dzn:global newline-infix)
(define-templates model-name (compose om:name (cut parent <> <model>)))
(define-templates asd-interface-name (compose string->symbol (lambda (o) (if (eq? #\I (string-ref o 0)) (substring o 1) o)) symbol->string om:name .type car om:ports (cut parent <> <model>)))
(define-templates =expression dzn:=expression)
(define-templates type dzn:type type-infix)
(define-templates external dzn:external)
(define-templates injected dzn:injected)
(define-templates expression dzn:expression)
(define-templates left (compose dzn:expression .left))
(define-templates right (compose dzn:expression .right))
(define-templates expression-expand dzn:expression-expand)
(define-templates enum-literal dzn:enum-literal type-infix)
(define-templates then .then)
(define-templates else (lambda (o) (or (.else o) '())))
(define-templates data (compose dzn:->string .value))
(define-templates arguments ast:argument* argument-infix)
(define-templates define-type ast:type* newline-infix)
(define-templates field ast:field* field-infix)
(define-templates in-event (lambda (o) (filter om:in? (om:events o))) newline-infix)
(define-templates out-event (lambda (o) (filter om:out? (om:events o))) newline-infix)
(define-templates provided-port (lambda (o) (filter ast:provides? (om:ports o))) newline-infix)
(define-templates required-port (lambda (o) (filter ast:requires? (om:ports o))) newline-infix)
(define-templates behaviour .behaviour)
(define-templates async-port ast:port* newline-infix)
(define-templates declare-variable ast:variable* newline-infix)
(define-templates from dzn:from)
(define-templates to dzn:to)
(define-templates define-function ast:function* newline-infix)
(define-templates trigger ast:trigger* comma-infix)
(define-templates formal-type dzn:formal-type)
(define-templates direction dzn:direction)
(define-templates port-prefix dzn:port-prefix port-suffix)
(define-templates signature dzn:signature space-infix)
(define-templates formal ast:formal* formal-infix)
(define-templates trigger-signature (lambda (o) (if (not (.port.name o)) "" o)))
(define-templates trigger-formal (lambda (o) (ast:formal* o)) formal-infix)
(define-templates argument ast:argument* argument-infix)
(define-templates action-arguments dzn:action-arguments argument-grammar)
(define-templates statement dzn:statement)
(define-templates expand-statement dzn:expand-statement)
(define-templates out-bindings .elements)
(define-templates reply-port dzn:reply-port dot-suffix)
(define-templates expand-blocking dzn:expand-blocking)
(define-templates system)
(define-templates declare-instance ast:instance* newline-infix)
(define-templates instance (lambda (o) (if (not (.instance.name o)) "" (list (.instance o)))) dot-suffix)
(define-templates binding ast:binding* newline-infix)
