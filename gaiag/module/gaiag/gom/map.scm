;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(read-set! keywords 'prefix)

(define-module (gaiag gom map)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)

  :use-module (language dezyne location)
  
  :use-module (gaiag reader)

  :use-module (oop goops)
  :use-module (oop goops describe)

  :use-module (gaiag gom gom)
  :use-module (gaiag gom display)
  :use-module (gaiag gom ast)
  :use-module (gaiag gom util)

  :export (
           gom:clone
           gom:collect
           gom:for-each
           gom:identity-initializer
           gom:map
           gom:map*
           gom:map-initializer
           gom:map*-initializer
           ))

(define (((gom:map-initializer f) o) name)
  (list (symbol->keyword name) (f (slot-ref o name))))

(define (((gom:map*-initializer f) o) name)
  (list (symbol->keyword name) (gom:map* f (slot-ref o name))))

(define ((gom:identity-initializer o) name)
  (gom:map-initializer identity))

(define-method (gom:clone (o <ast>))
  (gom:clone o gom:identity-initializer))

(define-method (gom:clone (o <ast>) make-initializer)
 (let* ((class (class-of o))
        (slots (class-slots class))
        (names (map slot-definition-name slots))
        (initializers (map (make-initializer o) names))
        (arguments (cons class (apply append initializers))))
   (retain-source-properties o (apply make arguments))))

(define ((ref-slot o) name) (slot-ref o name))

(define-method (gom:for-each f) (lambda (o) (gom:for-each f o)))
(define-method (gom:for-each f (o <top>)) (f o))
(define-method (gom:for-each f (o <list>)) (for-each (gom:for-each f) o) (f o))

(define-method (gom:for-each f (o <ast>))
  (let* ((class (class-of o))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (elements (map (ref-slot o) names)))
    (for-each (gom:for-each f) elements)
    (f o)))

(define-method (gom:map f) (lambda (o) (gom:map f o)))
(define-method (gom:map f (o <top>)) (f o))
(define-method (gom:map f (o <list>)) (map (gom:map f) o))

;; (define-method (gom:map f (o <ast>))
;;   (f (gom:clone o (gom:map-initializer f))))

(define-method (gom:map f (o <ast>))
  (gom:clone o (gom:map-initializer f)))

(define-method (gom:map f (o <list>))
  (map (gom:map f) o))

(define-method (gom:map f (o <ast>) make-initializer)
  (f (gom:clone o make-initializer)))

(define-method (gom:map* f) (lambda (o) (gom:map* f o)))
(define-method (gom:map* f (o <top>)) (f o))
(define-method (gom:map* f (o <list>)) (map (gom:map* f) o))

(define-method (gom:map* f (o <ast>))
  (f (gom:clone o (gom:map*-initializer f))))

(define-method (gom:map* f (o <ast>) make-initializer)
  (f (gom:clone o make-initializer)))

(define-method (gom:collect (predicate <procedure>) (o <ast>))
  (let* ((collect '())
         (add (lambda (item) (set! collect (cons item collect)) collect)))
    (gom:for-each (lambda (x) (if (predicate x) (add x)) x) o)
    (reverse collect)))

(define-method (gom:collect (predicate <procedure>) (o <list>))
  (apply append (map (lambda (o) (gom:collect predicate o)) o)))

(define-method (gom:collect (predicate <procedure>))
  (lambda (o) (gom:collect predicate o)))

(define-method (gom:collect (class <class>))
  (gom:collect (is? class)))

(define-method (gom:collect:variables (o <ast>)) ;;this also gets locals
  (gom:collect <variable> o))

(define-method (gom:collect:functions (o <ast>))
  (gom:collect <variable> o))
