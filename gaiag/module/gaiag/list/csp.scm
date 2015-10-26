;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

(read-set! keywords 'prefix)

(define-module (gaiag list csp)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)  
  :use-module (gaiag list om)
  :export (
           <skip>
           <voidreply>
           <the-end>           
           <the-end-blocking>           
           
           make-<skip>
           make-<the-end>           
           make-<the-end-blocking>           
           make-<voidreply>
           ))

(define csp-classes
  '(
    skip
    the-end           
    the-end-blocking           
    voidreply
 ))

(let ((module (current-module)))
  (for-each (lambda (x) (module-define! module (symbol->class x) x))
            (append csp-classes)))

(define (make-<skip> . args)
  '(skip))

(define (make-<the-end> . args)
  '(the-end))

(define (make-<the-end-blocking> . args)
  '(the-end-blocking))

(define (make-<voidreply> . args)
  '(voidreply))
