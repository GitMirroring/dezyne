;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module
  (gaiag json) ;;-goeps
  ;;+goeps (g json)
  :use-module (srfi srfi-1)

  :use-module (ice-9 and-let-star)
  :use-module (ice-9 match)  

  :use-module (language dezyne location)
  :use-module (gaiag misc)

  :use-module (gaiag om) ;;-goeps
  :use-module (gaiag reader) ;;-goeps
  ;;+goeps :use-module (g om)
  ;;+goeps :use-module (g reader)

  :export (
           json-location
           ))

(cond-expand
 (goops-om
  (use-modules (oop goops)))
 (else #t))

(use-modules (system base lalr))
(define (source-location src)
  (and-let* (((supports-source-properties? src))
	     (loc (source-property src 'loc)))
	    (if (source-location? loc)
		loc
		(source-location loc))))

(define (source-location->user-source-properties loc)
  (if (not (source-location? loc))
      (begin
        (stderr "programming error: not a source location: ~a\n" loc)
        '((filename . "unknown") (line . 0 )))
      `((filename . ,(source-location-input loc))
        (line . ,(+ 1 (source-location-line loc)))
        (column . ,(+ 1 (source-location-column loc)))
        (offset . ,(source-location-offset loc))
        (length . ,(source-location-length loc)))))

(define (json-location o)
  (match o
    ((? (is? <ast>))
     (alist->hash-table
      (or (and-let* ((loc (source-location o))
                     (properties (source-location->user-source-properties loc)))
                    `((file . ,(assoc-ref properties 'filename))
                      (line . ,(assoc-ref properties 'line))
                      (column . ,(assoc-ref properties 'column))
                      (offset . ,(assoc-ref properties 'offset))
                      (length . ,(assoc-ref properties 'length))))
          '())))
    (_ '())))
