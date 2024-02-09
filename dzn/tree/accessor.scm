;;; Snuik --- An IRC bot using guile-8sync
;;; Copyright © 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn tree accessor)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)

  #:use-module (dzn goops goops)
  #:use-module (dzn tree tree)
  #:use-module (dzn misc)

  #:export (tree:name*
            tree:name*->name
            tree:full-name
            tree:name
            tree:name+scope
            tree:scope
            tree:scoped?))

;;;
;;; Scope and name.
;;;
(define-method (tree:scoped? (o <string>))
  (string-index o #\.))

(define-method (tree:name* (o <string>))
  (string-split o #\.))

(define-method (tree:name* (o <tree:named>))
  (and=> (.name o) tree:name*))

(define-method (tree:name*->name o)
  (string-join (filter identity o) "."))

(define-method (tree:name+scope (o <string>))
  (match (string-split o #\.)
    ((scope ... name) (values name scope))))

(define-method (tree:name+scope (o <tree:named>))
  (let ((name (.name o)))
    (if name (tree:name+scope name)
        (values #f '()))))

(define-method (tree:name (o <top>))
  (tree:name+scope o))

(define-method (tree:scope (o <top>))
  (let ((name scope (tree:name+scope o)))
    scope))
