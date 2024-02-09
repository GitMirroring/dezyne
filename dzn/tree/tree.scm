;;; Snuik --- An IRC bot using guile-8sync
;;; Copyright © 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn tree tree)
  #:use-module (dzn goops goops))

;;;
;;; Generic tree types.
;;;
(define-class*-public <tree> (<object>)
  (comment))
(define-class*-public <tree:root> (<tree>))

(define-class*-public <tree:location> (<tree>)
  (file-name)
  (line)
  (column)
  (end-line)
  (end-column)
  (offset)
  (length))

(define-class*-public <tree:locationed> (<tree>)
  (location))                           ;<tree:location>

(define-class*-public <tree:comment> (<tree:locationed>)
  (string))
(define-class*-public <tree:named> (<tree:locationed>)
  (name))
(define-class*-public <tree:reference> (<tree:named>))
(define-class*-public <tree:scope> (<tree>))
