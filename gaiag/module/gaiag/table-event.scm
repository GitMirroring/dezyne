;;; Dezyne --- Dezyne command line tools
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

(define-module (gaiag table-event)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 match)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (oop goops)

  :use-module (language dezyne location)
  :use-module (gaiag gaiag)
  :use-module (gaiag json-table)
  :use-module (gaiag misc)
  :use-module (gaiag norm-event)
  :use-module (gaiag pretty)
  :use-module (gaiag table-state)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :use-module (gaiag gom)

  :export (ast-> table-event))

(define-method (table-event (o <list>))
  (filter identity (map table-event o)))

(define-method (table-event (o <root>))
  ;; FIXME: c&p csp.scm
  (let ((name
         (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                     string->symbol))))
    (or (and-let* ((models (.elements o))
                   (models (null-is-#f (filter (negate gom:imported?) models)))
                   (models (null-is-#f (if name (and=> (find (gom:named name) models) list) models))))
                  (make <root> :elements (map table-event models))))))

(define-method (table-event o) o)

(define-method (table-event (o <interface>))
  (let* ((statement (table-event o ((compose .statement .behaviour) o)))
         (statement (remove-initial statement)))
    (make (class-of o)
      :name (.name o)
      :types (.types o)
      :events (.events o)
      :behaviour
      (make <behaviour>
        :name ((compose .name .behaviour) o)
        :types ((compose .types .behaviour) o)
        :variables ((compose .variables .behaviour) o)
        :functions ((compose .functions .behaviour) o)
        :statement statement))))

(define-method (table-event (o <component>))
  (or (and-let* ((behaviour (.behaviour o))
                 (statement (table-event o (.statement behaviour)))
                 (statement (remove-initial statement)))
                (make (class-of o)
                  :name (.name o)
                  :ports (.ports o)
                  :behaviour
                  (make <behaviour>
                    :name ((compose .name .behaviour) o)
                    :types ((compose .types .behaviour) o)
                    :variables ((compose .variables .behaviour) o)
                    :functions ((compose .functions .behaviour) o)
                    :statement statement)))
      o))

(define-method (table-event (model <model>) (o <compound>))
  (norm-event (table-state-statement model o)))

(define-method (mangle-table o)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (and (not json?) o)))

(define-method (mangle-table (o <system>))
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (and (not json?) o)))

(define-method (mangle-table (o <list>))
  (map mangle-table o))

(define-method (mangle-table (o <boolean>))
  (if (option-ref (parse-opts (command-line)) 'json #f)
      (list (make-hash-table))))

(define-method (mangle-table (o <model>))
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (if json?
        (and-let* ((behaviour (.behaviour o))
                   (statement (.statement behaviour)))
         (alist->hash-table
          (append
           (json-init o)
           ((json-table-event o) statement))))
        o)))

(define (ast-> ast)
  ((compose
    pretty-table
    mangle-table
    table-event
    ast:resolve) ast))
