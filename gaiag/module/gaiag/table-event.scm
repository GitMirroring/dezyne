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
    (or (and-let* ((models (null-is-#f (gom:models-with-behaviour o)))
                   (models (null-is-#f (filter (negate gom:imported?) models)))
                   (models (null-is-#f (if name (and=> (find (gom:named name) models) list) models))))
                  (map table-event models)))))

(define-method (table-event (o <model>))
  (let ((statement (table-event o ((compose .statement .behaviour) o))))
    (make (class-of o)
      :name (.name o)
      :behaviour
      (make <behaviour>
        :name ((compose .name .behaviour) o)
        :functions ((compose .functions .behaviour) o)
        :statement statement))))

(define-method (table-event (o <import>))
  #f)

(define-method (table-event (o <type>))
  #f)

(define-method (table-event (model <model>) (o <boolean>)) #f)

(define-method (table-event (model <model>) (o <compound>))
  (norm-event o))

;;; shared with table
(define-method (mangle-table (o <list>))
  (map mangle-table o))

(define-method (mangle-table (o <boolean>))
  (if (option-ref (parse-opts (command-line)) 'json #f)
      (list (make-hash-table))))

(define-method (mangle-table (o <model>))
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f))
        (statement ((compose .statement .behaviour) o)))
    (if json?
        (alist->hash-table
         (append
          (json-init o)
          ((json-table o) statement)))
        (demo-table statement))))

(define-method (demo-table (o <compound>))
  (gom:map demo-table o))

(define-method (demo-table (o <list>))
  (map demo-table o))

(define-method (demo-table (o <guard>))
  o)

(define-method (demo-table (o <on>))
  o)

(define-method (pretty (o <ast>)) (ast->dezyne o))
(define-method (pretty (o <list>))
  (match o
    (((? (is? <ast>)) ...) (string-join (map ast->dezyne o)))
    (_ o)))
(define-method (pretty o) o)

(define (ast-> ast)
  ((compose
    pretty
    mangle-table
    table-event
    ast:resolve) ast))
