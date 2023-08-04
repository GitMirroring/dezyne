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
  #:use-module (ice-9 regex)
  #:use-module (oop goops)
  #:export (constructor-name))

;;;
;;; Utilities.
;;;
(define-method (constructor-name (o <string>))
  (match:substring (string-match "^<(.*)>$" o) 1))

(define-method (constructor-name (o <symbol>))
  (string->symbol (constructor-name (symbol->string o))))

(define-method (constructor-name (o <class>))
  (constructor-name (class-name o)))

(define-method (constructor-name (o <object>))
  (constructor-name (class-of o)))
