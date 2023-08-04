;;; Snuik --- An IRC bot using guile-8sync
;;; Copyright © 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn goops display)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 pretty-print)

  #:use-module (oop goops)
  #:use-module (dzn goops serialize)
  #:use-module (dzn goops util)

  #:export (display:pretty-print
            display:serialize)
  #:re-export (write))

(define-method (display:constructor-name (o <object>))
  "Identify objects with an asterisk."
  (symbol-append (constructor-name o) '*))

(define-method (write (o <object>) port)
  (parameterize ((%serialize:constructor-name display:constructor-name)
                 ;; Use concise position-based format.  As "empty"
                 ;; values are also skipped this is for human
                 ;; consumption only.
                 (%serialize:skip-field-name? (const #t)))
    (serialize o port)))

(define goops:display write)


;;;
;;; Entry points.
;;;
(define (display:serialize o)
  (with-input-from-string
      (with-output-to-string (cute write o))
    read))

(define* (display:pretty-print o #:optional (port (current-output-port)))
  "Recursively print O to PORT in a user-friendly debug format."
  (pretty-print (display:serialize o) port))
