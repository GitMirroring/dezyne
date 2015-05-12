;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define (main . args)
  (eval '(main (command-line)) (resolve-module '(g hash))))

(define-module (g hash)
  :use-module (srfi srfi-10)

  :use-module (g misc)
  :use-module (g pretty-print)
  :use-module (g reader)
  :re-export (hash define-reader-ctor))

(define-reader-ctor 'hash
       (lambda elems
         (let ((table (make-hash-table)))
           (for-each (lambda (elem)
                       (apply hash-set! table elem))
                     elems)
           table)))

(eval-when (expand)
  (define-reader-ctor 'hash
    (lambda elems
      (let ((table (make-hash-table)))
        (for-each (lambda (elem)
                    (apply hash-set! table elem))
                  elems)
        table))))

(define-syntax build-hash-table
  (syntax-rules ()
    ((_ table (key value) rest ...)
     (begin
       (hash-set! table key value)
       (build-hash-table table rest ...)))
    ((_ table)
     table)))

(define-syntax-rule (hash-table (key value) ...)
  (let ((table (make-hash-table)))
    (build-hash-table table (key value) ...)))

(eval-when (expand)
  (define-reader-ctor 'chash
    (lambda elems
      `(hash-table ,@elems))))
