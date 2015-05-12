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

(define-module (g table-event)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 match)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (language dezyne location)
  :use-module (g g)
  :use-module (g ast-colon)
  :use-module (g json-table)
  :use-module (g misc)
  :use-module (g norm-event)
  :use-module (g pretty)
  :use-module (g reader)
  :use-module (g resolve)
  :use-module (g table-state)

  :use-module (gaiag annotate)

  :export (ast-> table-event))

;; FIMXE C&P
(define (table-event o)
  (match o
    (('root models ...)
     (let ((name
            (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                        string->symbol))))
       (or (and-let* ((models (null-is-#f (filter ast:model? models)))
                      (models (null-is-#f (filter (compose null-is-#f ast:behaviour) models)))
                      ;;(models (null-is-#f (filter (negate gom:imported?) models)))
                      (models (null-is-#f (if name (and=> (find (ast:named name) models) list) models)))
                      )
                     (cons 'root (filter identity (map table-event models)))))))
    (('import _ ...) #f)
    (('enum _ ...) #f)
    (('extern _ ...) #f)
    (('int _ ...) #f)

    (('interface name types events ('behaviour b btypes variables functions statement))
     (let* ((statement (table-event-statement o statement)))
       (list 'interface name types events
             (list 'behaviour b btypes variables functions statement))))
    (('component name ports ('behaviour b types variables functions statement))
     (let* ((statement (table-event-statement o statement)))
       (list 'component name ports
             (list 'behaviour b types variables functions statement))))
    (('system _ ...) #f)
    (('locations _ ...) #f)    
    (_ (throw 'match-error (format #f "~a:right: no match: ~a\n" (current-source-location) o)))))

(define (table-event-statement model o)
  (norm-event (table-state-statement model o)))

;; FIXME
(define (mangle-table o)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (match o
      (('root models ...)
       (if json?
           (map mangle-table models)
           (cons 'root (map mangle-table models))))
      ((or
        ;;('interface types events behaviour)
        ;;('component ports behaviour)
        (? ast:interface?)
        (? ast:component?)
        )
       (let ((statement ((compose ast:statement ast:behaviour) o)))
         (if json?
             (alist->hash-table
              (append
               (json-init o)
               ((json-table-event o) statement)))
             o)))
      ((h t ...) (map mangle-table o))
      ((or #t #f) (and json? (list (make-hash-table)))))))

(define (ast-> ast)
  ((compose
    pretty-table
    mangle-table
    table-event
    ast:resolve
    ast:annotate) ast))
