;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019,2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-templates scheme-namespace-setup scheme:namespace-setup)
(define-templates constructor-parameters scheme:constructor-parameters space-infix)
(define-templates scheme:export scheme:export newline-infix)
(define-templates scheme:re-export scheme:re-export re-export-grammar)
(define-templates class-name scheme:class-name type-infix)
(define-templates enum-name scheme:enum-name type-infix)
(define-templates reply-name scheme:reply-name name-infix)
(define-templates let-variable scheme:let-variable newline-infix)
(define-templates use-module scheme:use-module newline-infix)
(define-templates module-name scheme:module-name)
(define-templates set! scheme:set!)
(define-templates declare-method code:trigger newline-infix)
(define-templates declare-async-req-method scheme:async-req newline-infix)
(define-templates declare-async-clr-method scheme:async-clr newline-infix)

(define-templates expand-on scheme:expand-on newline-infix)
(define-templates main-event-map-flush-provides ast:provides-port* event-map-prefix)

;; c&p c++
(define-templates injected-port-instance-declare  ast:injected-port* newline-infix)
(define-templates injected-member-initializer ast:injected-port* newline-infix)

(define-templates provided-port-instance-declare ast:provides-port* newline-infix)
(define-templates required-port-instance-declare ast:requires-port* newline-infix)
(define-templates async-port-instance-declare ast:async-port* newline-infix)
(define-templates non-injected-instance-declare non-injected-instances newline-infix)
(define-templates provided-port-reference-declare ast:provides-port* newline-infix)
(define-templates required-port-reference-declare ast:requires-port* newline-infix)
(define-templates provided-port-reference-initializer ast:provides-port* newline-infix)
(define-templates required-port-reference-initializer ast:requires-port* newline-infix)
(define-templates header-data ast:data* newline-infix)
(define-templates out-binding-initializer ast:provides-port* newline-infix)

;; c&p dzn
(define-templates statement scheme:statement newline-infix)
