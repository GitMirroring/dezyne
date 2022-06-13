;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-templates version (const %package-version))
(define-templates header)

(define-templates calling-context-type-name c++ew:calling-context-type-name)

(define-templates system-wrapper c++ew:ast-system*)

(define-templates provides-port-initializer ast:provides-port* newline-infix)
(define-templates requires-port-initializer ast:requires-port* newline-infix)
(define-templates provides-port-event-wrappers ast:provides-port* newline-infix)
(define-templates requires-port-event-wrappers ast:requires-port* newline-infix)
(define-templates provides-port-in-event-wrapper c++ew:port-to-in-trigger* newline-infix)
(define-templates provides-port-out-event-wrapper c++ew:port-to-out-trigger* newline-infix)
(define-templates requires-port-in-event-wrapper c++ew:port-to-in-trigger* newline-infix)
(define-templates requires-port-out-event-wrapper c++ew:port-to-out-trigger* newline-infix)

(define-templates formals c++ew:formals formal-grammar)
(define-templates formals-anonymous c++ew:formals formal-grammar)
(define-templates formals-type c++ew:formals formal-grammar)

(define-templates formal-names c++ew:formal-names comma-infix)
(define-templates formal-names-prefix c++ew:formal-names comma-prefix)
(define-templates formals-prefix c++ew:formals comma-prefix)

(define-templates port-type-upcase c++ew:port-type-upcase)
(define-templates port-wrapper ast:port* newline-infix)
(define-templates wrapped-port-inst ast:port* newline-infix)

(define-templates valued-event-wrapper c++ew:valued-event?)
(define-templates valued-event-return c++ew:valued-event?)
(define-templates valued-requires-in-return c++ew:valued-event?)
(define-templates ew-trigger-type-base c++ew:trigger-type-base type-infix)
(define-templates file-name-upcase c++ew:file-name-upcase)
