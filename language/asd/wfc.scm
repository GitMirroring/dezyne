;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (language asd wfc)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

  :use-module (language asd ast)
  :use-module (language asd misc)
  :use-module (language asd asd)
  :use-module (language asd gaiag)

  :export (ast-wellformed?))

(define (asd-> ast)
  (ast-wellformed? ast)
  "")

(define (ast-wellformed? ast)
  (and-let* ((errors (apply append 
                            (filter null-is-#f (verify-on ast))
                            (filter null-is-#f (verify-mixing ast)))))
            (for-each (lambda (e) 
                        (let ((message (car e))
                              (properties (source-location->source-properties (cadr e))))
                          (stderr "~a:~a:~a: error: not well-formed: ~a\n" 
                                  (assoc-ref properties 'filename) 
                                  (assoc-ref properties 'line) 
                                  (assoc-ref properties 'column)
                                  message))) errors)
            ;; (throw 'well-formed "not well-formed")
            (exit 1)
            )
  "")

(define (error message lst) (list message (source-location lst)))

(define (verify-on ast)
  (and-let* ((statements (behaviour-statements (interface-behaviour (interface ast))))
             (error-locations (null-is-#f (filter identity (map statement-on statements)))))
            error-locations))

(define* (statement-on src :key (count 0))
  (match src
         (('on e s) (if (>0 count) (error "double on" src) (statement-on s :count (1+ count))))
         (('guard expr s) (statement-on s :count count))
         (('statements s ...) (null-is-#f
                               (filter identity (map (lambda (x) (statement-on x :count count)) s))))
         (('assign x ...) #f)
         (_ (throw "programming error"))))

(define (verify-mixing ast)
  (let ((statements (behaviour-statements (interface-behaviour (interface ast)))))
    '()))

(define (mixing x) '())
