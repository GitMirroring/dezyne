;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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
;;; Compile-time configuration of dzn.  When adding a substitution
;;; variable here, make sure to have configure substitute it.
;;;
;;; Code:

(define-module (dzn hash)
  #:use-module (srfi srfi-71)
  #:use-module (rnrs bytevectors)
  #:use-module (gcrypt hash)
  #:use-module (dzn parse)
  #:export (dzn-hash))

(define* (dzn-hash file-name #:key (algorithm (hash-algorithm sha1))
                   (imports '()))
  "Compute the hash of FILE-NAME with ALGORITHM."
  (let ((port get-hash (open-hash-port algorithm)))
    (set-port-encoding! port "UTF-8")
    (display (parse:file->stream file-name
                                 #:imports imports
                                 #:file-directives? #f)
             port)
    (force-output port)
    (get-hash)))
