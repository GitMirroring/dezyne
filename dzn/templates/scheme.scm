;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019,2020,2021 Jan Nieuwenhuizen <janneke@gnu.org>
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


;;;
;;; Module
;;;
(define-templates scheme:export scheme:export)
(define-templates scheme:re-export scheme:re-export re-export-grammar)
(define-templates use-module scheme:use-module)


;;;
;;; Top
;;;
(define-templates header-data ast:data*)


;;;
;;; Names
;;;
(define-templates class-name scheme:class-name type-infix)
(define-templates enum-name scheme:enum-name type-infix)
(define-templates reply-name scheme:reply-name name-infix)
(define-templates module-name scheme:module-name)


;;;
;;; Statements
;;;
(define-templates let-variable scheme:let-variable)
(define-templates out-binding-initializer ast:provides-port*)
(define-templates set! scheme:set!)
(define-templates statement scheme:statement)


;;;
;;; Component
;;;
(define-templates provided-port-instance-declare ast:provides-port*)
(define-templates required-port-instance-declare ast:requires-port*)
(define-templates injected-port-instance-declare  ast:injected-port*)
(define-templates async-port-instance-declare ast:async-port*)

(define-templates injected-member-initializer ast:injected-port*)

(define-templates expand-on scheme:expand-on)
(define-templates declare-method code:trigger double-newline-infix)
(define-templates declare-async-method code:trigger double-newline-infix)

(define-templates declare-async-req-method scheme:async-req double-newline-infix)
(define-templates declare-async-clr-method scheme:async-clr double-newline-infix)


;;;
;;; System
;;;
(define-templates non-injected-instance-declare code:non-injected-instances)
(define-templates provided-port-reference-declare ast:provides-port*)
(define-templates required-port-reference-declare ast:requires-port*)

(define-templates provided-port-reference-initializer ast:provides-port*)
(define-templates required-port-reference-initializer ast:requires-port*)
