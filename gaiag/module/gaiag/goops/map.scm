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

(define-module (gaiag goops map)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)

  :use-module (language dezyne location)
  
  :use-module (gaiag reader)

  :use-module (oop goops)

  :use-module (gaiag goops om)
  :use-module (gaiag goops display)
  :use-module (gaiag goops util)

  :export (
           om:clone
           om:collect
           om:for-each
           om:identity-initializer
           om:map
           om:map*
           om:map-initializer
           om:map*-initializer
           ))

(define (((om:map-initializer f) o) name)
  (list (symbol->keyword name) (f (slot-ref o name))))

(define (((om:map*-initializer f) o) name)
  (list (symbol->keyword name) (om:map* f (slot-ref o name))))

(define ((om:identity-initializer o) name)
  (om:map-initializer identity))

(define-method (om:clone (o <ast>))
  (om:clone o om:identity-initializer))

(define-method (om:clone (o <ast>) make-initializer)
 (let* ((class (class-of o))
        (slots (class-slots class))
        (names (map slot-definition-name slots))
        (initializers (map (make-initializer o) names))
        (arguments (cons class (apply append initializers))))
   (retain-source-properties o (apply make arguments))))

(define ((ref-slot o) name) (slot-ref o name))

(define-method (om:for-each f) (lambda (o) (om:for-each f o)))
(define-method (om:for-each f (o <top>)) (f o))
(define-method (om:for-each f (o <list>)) (for-each (om:for-each f) o) (f o))

(define-method (om:for-each f (o <ast>))
  (let* ((class (class-of o))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (elements (map (ref-slot o) names)))
    (for-each (om:for-each f) elements)
    (f o)))

(define-method (om:map f) (lambda (o) (om:map f o)))
(define-method (om:map f (o <top>)) (f o))
(define-method (om:map f (o <list>)) (map (om:map f) o))

;; (define-method (om:map f (o <ast>))
;;   (f (om:clone o (om:map-initializer f))))

(define-method (om:map f (o <ast>))
  (om:clone o (om:map-initializer f)))

(define-method (om:map f (o <list>))
  (map (om:map f) o))

(define-method (om:map f (o <ast>) make-initializer)
  (f (om:clone o make-initializer)))

(define-method (om:map* f) (lambda (o) (om:map* f o)))
(define-method (om:map* f (o <top>)) (f o))
(define-method (om:map* f (o <list>)) (map (om:map* f) o))

(define-method (om:map* f (o <ast>))
  (f (om:clone o (om:map*-initializer f))))

(define-method (om:map* f (o <ast>) make-initializer)
  (f (om:clone o make-initializer)))

(define-method (om:collect (predicate <procedure>) (o <ast>))
  (let* ((collect '())
         (add (lambda (item) (set! collect (cons item collect)) collect)))
    (om:for-each (lambda (x) (if (predicate x) (add x)) x) o)
    (reverse collect)))

(define-method (om:collect (predicate <procedure>) (o <list>))
  (apply append (map (lambda (o) (om:collect predicate o)) o)))

(define-method (om:collect (predicate <procedure>))
  (lambda (o) (om:collect predicate o)))

(define-method (om:collect (class <class>))
  (om:collect (is? class)))

(define-method (om:collect:variables (o <ast>)) ;;this also gets locals
  (om:collect <variable> o))

(define-method (om:collect:functions (o <ast>))
  (om:collect <variable> o))
