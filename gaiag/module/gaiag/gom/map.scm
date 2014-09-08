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

(define-method (map-statements (procedure <top>))
  (lambda (o) (map-statements o procedure)))

(define-method (map-statements (o <top>) (procedure <top>))
  (or (procedure o)) o)

(define-method (map-statements (o <root>) (procedure <top>))
  (or (procedure o)
      (make <root> :elements (map (map-statements procedure) (.elements o)))))

(define-method (map-statements (o <interface>) (procedure <top>))
  (or (procedure o)
      (make <interface>
        :name (.name o)
        :types (.types o)
        :events (.events o)
        :behaviour (and=> (.behaviour o) (map-statements procedure)))))

(define-method (map-statements (o <component>) (procedure <top>))
  (or (procedure o)
      (make <component>
        :name (.name o)
        :ports (.ports o)
        :behaviour (and=> (.behaviour o) (map-statements procedure)))))

(define-method (map-statements (o <behaviour>) (procedure <top>))
  (or (procedure o)
      (make <behaviour>
        :name (.name o)
        :types (.types o)
        :variables (.variables o)
        :functions (map-statements (.functions o) procedure)
        :statement (and=> (.statement o) (map-statements procedure)))))

(define-method (map-statements (o <functions>) (procedure <top>))
  (or (procedure o)
      (make <functions> :elements (map (map-statements procedure) (.elements o)))))

(define-method (map-statements (o <function>) (procedure <top>))
  (or (procedure o)
      (make <function>
        :name (.name o)
        :signature (.signature o)
        :recursive (.recursive o)
        :statement (map-statements (.statement o) procedure))))

(define-method (map-statements (o <if>) (procedure <top>))
  (or (procedure o)
      (make <if>
        :expression (.expression o)
        :then (map-statements (.then o) procedure)
        :else (and=> (.else o) (map-statements procedure)))))

(define ((ref-slot name) o) (slot-ref o name))

(define-method (has-method? (o <top>) procedure)
  (and-let* (((is-a? procedure <generic>))
             (procedures (generic-function-methods procedure))
             (signatures (map (ref-slot 'specializers) procedures)))
            (find (lambda (x) (equal? x (list (class-of o)))) signatures)))

(define-method (hairy-map-statements (o <compound>) (procedure <top>))
  (if (has-method? o procedure)
      (procedure o)
      (or (and (not (is-a? procedure <generic>))
               (procedure o))
          (make <compound> :elements (map (map-statements procedure) (.elements o))))))

(define-method (map-statements (o <compound>) (procedure <top>))
  (or (procedure o)
      (make <compound> :elements (map (map-statements procedure) (.elements o)))))

(define-method (map-statements (o <guard>) (procedure <top>))
  (or (procedure o)
      (make <guard>
        :expression (.expression o)
        :statement (map-statements (.statement o) procedure))))

(define-method (map-statements (o <on>) (procedure <top>))
  (or (procedure o)
      (make <on>
        :triggers (.triggers o)
        :statement (map-statements (.statement o) procedure))))
