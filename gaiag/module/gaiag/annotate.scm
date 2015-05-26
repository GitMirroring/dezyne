;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag annotate)
  :use-module (ice-9 pretty-print)

  :use-module (gaiag list match)
  :use-module (ice-9 and-let-star)
  :use-module (srfi srfi-9)  

;;  :use-module (system base lalr)

  :use-module (language dezyne location)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :export (ast:annotate ast->annotate extract-locations))

(define (annotate-locations o)
  (match o
    (('root t ... ('locations locations ...)) (annotate-locations- o (car locations)) (cons 'root t))
    (_ o)))

(define (ast:annotate o)
  ((compose
    annotate-imported
    annotate-locations   
    ) o))

(define ast->annotate ast:annotate)

(define (loc? o)
  (match o (('location t ...) o) (_ #f)))

(define (annotate-locations- root locations)
  (let loop ((o root) (locations locations))
    (if (not (pair? locations))
        '()
        (let* ((head (car o))
               (head-l (car locations))
               (loc (loc? head-l))
               (locations (if loc (cdr locations) locations))
               (head-l (car locations)))
          (if loc
              (annotate-location o loc))
          (if (list? head)
              (loop head head-l))
          (loop (cdr o) (cdr locations)))))
  root)

(define (null-is-#f o) (if (null? o) #f o))

(define (annotate-location o loc)
  (and-let* ((loc (null-is-#f (cdr loc)))
             (loc (apply make-source-location loc)))
            (set-source-property! o 'loc loc)))

(define (extract-locations o)
  (match o
    (('root t ...) (cons 'locations (list (map extract-locations o))))
    ((h t ...)
     (or (and-let* ((loc (extract-location o)))
                   (cons loc (map extract-locations o)))
         (map extract-locations o)))
    (_ o)))

(define (extract-location o)
  (and-let* (((supports-source-properties? o))
             (loc (source-property o 'loc))
             ((source-location? loc))
             (properties (source-location->system-source-properties loc)))
            (let ((file (assoc-ref properties 'filename))
                  (line (assoc-ref properties 'line))
                  (column (assoc-ref properties 'column))
                  (offset (assoc-ref properties 'offset))
                  (length (assoc-ref properties 'length)))
              (and-let* (((or file line column)))
                        (list 'location file line column offset length)))))

(define (mark-imported o imported?)
  (set-source-property! o 'imported? imported?)
  o)

(define (annotate-imported o)
  (match o
    (('root models ...) (cons 'root (map annotate-imported models)))
    (('interface body ... (and ('imported . imported)))
     (mark-imported (cons 'interface body) imported))
    (('component body ... (and ('imported . imported)))
     (mark-imported (cons 'component body) imported))
    (('system body ... (and ('imported . imported)))
     (mark-imported (cons 'system body) imported))    
    (('enum body ... (and ('imported . imported)))
     (mark-imported (cons 'enum body) imported))
    (('extern body ... (and ('imported . imported)))
     (mark-imported (cons 'enum body) imported))    
    (('int body ... (and ('imported . imported)))
     (mark-imported (cons 'enum body) imported))    
    (_ o)))

(define (ast-> ast)
  (let ((annotated (ast->annotate ast)))
    (pretty-print (append annotated ((compose list extract-locations) ast))))
  "")
