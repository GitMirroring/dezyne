;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Gaiag.
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag json)
  :use-module (ice-9 and-let-star)

  :use-module (srfi srfi-1)
  :use-module (oop goops)

  :use-module (gaiag gom)
  :use-module (gaiag misc)
  :use-module (language asd location)
  :use-module (gaiag reader)

  :export (
           json-location
           ))

(define-method (json-location (o <ast>))
  (alist->hash-table
   (or (and-let* ((loc (source-location o))
                  (properties (source-location->user-source-properties loc)))
                 `((file . ,(assoc-ref properties 'filename))
                   (line . ,(assoc-ref properties 'line))
                   (column . ,(assoc-ref properties 'column))
                   (offset . ,(assoc-ref properties 'offset))
                   (length . ,(assoc-ref properties 'length))))
      '())))

(define-method (json-location (o <boolean>))
  '())
