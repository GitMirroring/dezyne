;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (language dezyne location)
  #:use-module (system base lalr)

  #:use-module (ice-9 match)
  #:use-module (ice-9 and-let-star)
  #:use-module (srfi srfi-9)

  #:export (
            note-location
            retain-source-properties
            rsp
            source-file
            source-location
            source-location->user-source-properties
            source-location->system-source-properties
            syntax-error-handler
            )
  #:re-export (make-source-location source-location?))


(define (stderr string . rest)
  (apply format (cons* (current-error-port) string rest)))

(define (retain-source-properties o t)
  (and-let* (((supports-source-properties? o))
             ((supports-source-properties? t)))
            (set-source-properties! t (source-properties o)))
  t)

(define rsp retain-source-properties)

(define (source-file o)
  (and-let* (((supports-source-properties? o))
             (loc (source-property o 'loc))
             (properties (source-location->user-source-properties loc))
             (file-name (assoc-ref properties 'filename)))
            (string->symbol file-name)))

(define* (syntax-error-handler message #:optional token)
  (if (lexical-token? token)
      (throw 'syntax-error #f message
             (and=> (lexical-token-source token)
                    source-location->user-source-properties)
             (or (lexical-token-value token)
                 (lexical-token-category token))
             #f)
      (throw 'syntax-error #f message #f token #f)))

(define (note-location ast loc)
  (when (supports-source-properties? ast)
    (set-source-property! ast 'loc loc))
  ast)

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

(define (source-location->system-source-properties loc)
  `((filename . ,(source-location-input loc))
    (line . ,(source-location-line loc))
    (column . ,(source-location-column loc))
    (offset . ,(source-location-offset loc))
    (length . ,(source-location-length loc))))
