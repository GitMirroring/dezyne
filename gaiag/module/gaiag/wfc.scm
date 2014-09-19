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
            (report-errors errors))
  o)

(define-method (wfc-error (o <ast>) (message <string>))
  (make <error> :ast o :message (string-append "not well-formed: " message)))

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
       (if (>0 count) (wfc-error o "second on")
           ((second-on- (1+ count)) statement)))
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
                           (null-is-#f ((gom:filter <declarative>) statements)))
                          (ast (car declarative)))
                         (list (wfc-error ast "mixing declarative")))
               '()))
          ((? (is? <declarative>))
           (or (and-let* ((imperative
                           (null-is-#f ((gom:filter <imperative>) statements)))
                          (ast (car imperative)))
                         (list (wfc-error ast "mixing imperative")))
               '()))
          (_ '())))
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
