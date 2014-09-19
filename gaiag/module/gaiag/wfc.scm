;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag wfc)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

  :use-module (srfi srfi-1)

  :use-module (gaiag misc)
  :use-module (language asd parse)
  :use-module (gaiag reader)

  :use-module (oop goops)
  :use-module (gaiag gom)
  :use-module (gaiag resolve)

  :export (
           ast:wellformed?
           second-on
           mixing-declarative-imperative
           ))

(define-method (ast:wellformed? (o <ast>))
  (and-let* ((errors (append
                      (second-on o)
                      (mixing-declarative-imperative o))))
            (for-each (lambda (e)
                        (stderr "e: ~a\n" e)
                        (let* ((message (car e))
                               (properties (source-location->source-properties
                                            (source-location (cadr e))))
                               (message (format #f "~a:~a:~a: error: not well-formed: ~a\n"
                                                (assoc-ref properties 'filename)
                                                (assoc-ref properties 'line)
                                                (assoc-ref properties 'column)
                                                message)))
                          (stderr message))) errors)
            ;;(throw 'well-formed message)
            (exit 1))
  o)

(define (error message ast) (list message ast))

(define-method (second-on (o <ast>))
  ((second-on- 0) o))

(define-method (second-on- (count <integer>))
  (lambda (o)
    (match o
      (($ <root> elements) (apply append (map second-on elements)))
      (($ <system>) '())
      (($ <interface>) (second-on (.behaviour o)))
      (($ <component>) (second-on (.behaviour o)))
      (($ <behaviour>) (second-on (.statement o)))
      (($ <compound> statements)
       (filter null-is-#f (map (second-on- count) statements)))
      (($ <on> triggers statement)
       (if (>0 count) (error "second on" o) ((second-on- (1+ count)) statement)))
      (($ <guard> expression statement) ((second-on- count) statement))
      (_ '()))))

(define-method (mixing-declarative-imperative (o <ast>))
  (match o
    (($ <root> elements) (apply append (map mixing-declarative-imperative elements)))
    (($ <system>) '())
    (($ <interface>) (mixing-declarative-imperative (.behaviour o)))
    (($ <component>) (mixing-declarative-imperative (.behaviour o)))
    (($ <behaviour>) (mixing-declarative-imperative (.statement o)))
    (($ <compound> statements)
     (apply
      append
      (let ((first (first-statement statements)))
        (match first
          ((? (is? <imperative>))
           (or (and-let* ((declarative
                           (null-is-#f ((gom:filter <declarative>) statements))))
                         (list (error "mixing declarative" (car declarative))))
               '()))
          ((? (is? <declarative>))
           (or (and-let* ((imperative
                           (null-is-#f ((gom:filter <imperative>) statements))))
                         (list (error "mixing imperative" (car imperative))))
               '()))
          (_ (stderr "first: ~a\n" first)'())))
      (map mixing-declarative-imperative statements)))
    (($ <on> triggers statement) (mixing-declarative-imperative statement))
    (($ <guard> epression statement) (mixing-declarative-imperative statement))
    (($ <if> expression then else) (append (mixing-declarative-imperative then)
                                           (mixing-declarative-imperative else)))
    (_ '())))

(define-method (first-statement (o <null>))
  '())

(define-method (first-statement (o <list>))
  (let ((first (car o)))
    (or (and=> ((is? <compound>) first) first-statement)
        first)))

(define (ast-> ast)
  ((compose gom->list ast:wellformed? ast:resolve ast->gom) ast))
