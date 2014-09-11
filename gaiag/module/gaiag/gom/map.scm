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
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)

  :use-module (srfi srfi-1)

  :use-module (oop goops)
  :use-module (oop goops describe)

  :use-module (gaiag gom gom)
  :use-module (gaiag gom display)

  :export (map-statements))

;;(define-generic map)
(define-method (gom:map f (o <ast>)) (f o))

(define-method (gom:map f (o <top>))
  (or (f o)) o)

(define ((gom:map f) o)
  (gom:map f o))

(define-method (gom:map f (o <root>))
  (or (f o)
      (make <root> :elements (map f (.elements o)))))

(define-method (gom:map f (o <interface>))
  (or (f o)
      (make <interface>
        :name (.name o)
        :types (.types o)
        :events (.events o)
        :behaviour (and=> (.behaviour o) (map-statements f)))))

(define-method (gom:map f (o <component>))
  (or (f o)
      (make <component>
        :name (.name o)
        :ports (.ports o)
        :behaviour (and=> (.behaviour o) (map-statements f)))))

(define-method (gom:map f (o <behaviour>))
  (or (f o)
      (make <behaviour>
        :name (.name o)
        :types (.types o)
        :variables (.variables o)
        :functions (gom:map f (.functions o))
        :statement (and=> (.statement o) (map-statements f)))))

(define-method (gom:map f (o <functions>))
  (or (f o)
      (make <functions> :elements (map f (.elements o)))))

(define-method (gom:map f (o <function>))
  (or (f o)
      (make <function>
        :name (.name o)
        :signature (.signature o)
        :recursive (.recursive o)
        :statement (gom:map f (.statement o)))))

(define-method (gom:map f (o <if>))
  (or (f o)
      (make <if>
        :expression (.expression o)
        :then (gom:map f (.then o))
        :else (and=> (.else o) (map-statements f)))))

(define ((ref-slot name) o) (slot-ref o name))

(define-method (has-method? (o <top>) f)
  (and-let* (((is-a? f <generic>))
             (fs (generic-function-methods f))
             (signatures (map (ref-slot 'specializers) fs)))
            (find (lambda (x) (equal? x (list (class-of o)))) signatures)))

(define-method (hairy-map-statements (o <compound>) f)
  (if (has-method? o f)
      (f o)
      (or (and (not (is-a? f <generic>))
               (f o))
          (make <compound> :elements (map f (.elements o))))))

;; (define-method (gom:map (o <compound>) f)
;;   (f (make <compound> :elements (map (gom:map f) (.elements o)))))

(define-method (gom:map (o <compound>) f)
  (or (f o)
      (make <compound> :elements (map (gom:map f) (.elements o)))))

(define-method (gom:map f (o <guard>))
  (or (f o)
      (make <guard>
        :expression (.expression o)
        :statement (gom:map f (.statement o)))))

(define-method (gom:map f (o <on>))
  (or (f o)
      (make <on>
        :triggers (.triggers o)
        :statement (gom:map f (.statement o)))))
