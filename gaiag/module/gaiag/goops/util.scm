;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (gaiag goops util)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 match)

  :use-module (srfi srfi-1)

  :use-module (language dezyne location)

  :use-module (gaiag gaiag)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :use-module (gaiag goops ast)
  :use-module (gaiag goops compare)
  :use-module (gaiag goops om)
  :use-module (gaiag goops display)

  :export (
           is?
           goops:clone
           om->list
           om2list
           om:map
           ))

(define ((is? class) o)
  (and (is-a? o class) o))

(define (om->list om)
  (with-input-from-string
      (with-output-to-string (lambda () (write om)))
    read))

(define* (om2list o :optional (marker null-symbol))
  (match o
    ((and (? (is? <ast>)) (? (negate (is? <ast-list>)))) (cons (symbol-append (ast-name o) marker) (map om2list (om:children o))))
    ((h t ...) (map om2list o))
    (_ o)))

(define-method (om:children (o <ast>))
  (map (lambda (slot) (slot-ref o (slot-definition-name slot))) ((compose class-slots class-of) o)))

(define (om:map f o)
  (match o
    ((? (is? <ast-list>)) (rsp o (cons (car o) (map f (.elements o)))))
    ((h t ...) (map f o))
    ((? (is? <ast>)) (goops:clone o (om:map-initializer f)))
    (_ o)))

(define (((om:map-initializer f) o) name)
  (list (symbol->keyword name) (f (slot-ref o name))))

(define ((om:identity-initializer o) name)
  (om:map-initializer identity))

(define-method (goops:clone (o <ast>))
  (goops:clone o om:identity-initializer))

(define-method (goops:clone (o <ast>) make-initializer)
 (let* ((class (class-of o))
        (slots (class-slots class))
        (names (map slot-definition-name slots))
        (initializers (map (make-initializer o) names))
        (arguments (cons class (apply append initializers))))
   (retain-source-properties o (apply make arguments))))
