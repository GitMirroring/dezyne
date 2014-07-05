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

(define (main . args)
  (eval '(main (command-line)) (resolve-module '(language asd hash))))

(define-module (language asd hash)
  :use-module (srfi srfi-10)

  :use-module (language asd misc)
  :use-module (language asd pretty-print)
  :use-module (language asd reader)
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
