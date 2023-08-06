;;; Snuik --- An IRC bot using guile-8sync
;;; Copyright © 2020, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Snuik.
;;;
;;; Snuik is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Snuik is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Snuik.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn goops util)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 regex)
  #:use-module (dzn goops goops)
  #:export (as
            constructor-name
            is?))

;;;
;;; Utilities.
;;;
(define-method (constructor-name (o <string>))
  (match:substring (string-match "^<(.*)>$" o) 1))

(define %class->constructor-alist
  `((and . -and-)
    (if . -if-)
    (not . -not-)
    (or . -or-)))

(define-method (constructor-name (o <symbol>))
  (let ((name (string->symbol (constructor-name (symbol->string o)))))
    (or (assq-ref %class->constructor-alist name)
        name)))

(define-method (constructor-name (o <class>))
  (constructor-name (class-name o)))

(define-method (constructor-name (o <object>))
  (constructor-name (class-of o)))

(define-method (as (o <object>) (c <class>))
  (and (is-a? o c) o))

(define ((is? class) o)
  (and (is-a? o class) o))
