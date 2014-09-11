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

  :use-module (oop goops)
  :use-module (oop goops describe)

  :use-module (gaiag gom gom)
  :use-module (gaiag gom display)

  :export (gom:map))

;; (define ((map f) o) (gom:map f o))
;; (define-generic map)
;; (define ((ref-slot name) o) (slot-ref o name))

(define-method (gom:map f)
  (lambda (o) (gom:map f o)))

(define-method (gom:map f o) (f o))

(define-method (gom:map f (o <ast>))
  (define ((make-initializer o) name)
    (let ((element (slot-ref o name)))
      (list (symbol->keyword name)
            (if (list? element)
                (map (gom:map f) element)
                (gom:map f element)))))
  (f (let* ((class (class-of o))
            (slots (class-slots class))
            (names (map slot-definition-name slots))
            (initializers (map (make-initializer o) names))
            (arguments (cons class (apply append initializers))))
       (apply make arguments))))
