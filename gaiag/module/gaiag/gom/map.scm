;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

  :use-module (gaiag reader)

  :use-module (oop goops)
  :use-module (oop goops describe)

  :use-module (gaiag gom gom)
  :use-module (gaiag gom display)
  :use-module (gaiag gom ast)

  :export (gom:for-each gom:map))

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

(define-method (gom:map f (o <ast>))
  (define ((make-initializer o) name)
    (list (symbol->keyword name) (gom:map f (slot-ref o name))))
  (f (let* ((class (class-of o))
            (slots (class-slots class))
            (names (map slot-definition-name slots))
            (initializers (map (make-initializer o) names))
            (arguments (cons class (apply append initializers))))
       (apply make arguments))))

(define ((gom:collect class) ast)
  (let* ((collect '())
         (add (lambda (item) (set! collect (cons item collect)) collect)))
    (gom:for-each (lambda (x) (if (is-a? x class) (add x)) x) ast)
    collect))

(define (gom:collect:variables ast) ;;this also gets locals
  ((gom:collect <variable>) ast))

(define (gom:collect:functions ast)
  ((gom:fcollect <variable>) ast))
