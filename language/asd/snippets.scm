#! /bin/sh
# -*-scheme-*-
exec guile -e main -s $0 "$@"
!#
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
  (eval '(main (command-line)) (resolve-module '(language asd snippets))))

(define-module (language asd snippets)
  :use-module (srfi srfi-1)
  :use-module (language asd format-keys)
  :use-module (language asd misc)
  :export (gulp-snippet
           snippet?
           snippet->string
           snippet-dir
           snippets
           ))

(define snippet-dir (make-parameter '(snippets test)))
(define (gulp-snippet name)
  (gulp-text-file (string-join (map symbol->string (append (snippet-dir) (list name))) "/")))

(define (format-snippet name pairs) 
  (format-keys (gulp-snippet name) pairs))

(define snippets (make-parameter
                  `((test . ((foo . ,identity)
                             (bar . (lambda (x) "boo"))
                             (baz . "blaat"))))))

(define (snippet? x)
  (and (list? x) (pair? (assoc (car x) (snippets)))))

(define (snippet->string name . rest)
  (let ((snippet (assoc-ref (snippets) name)))
    (format-snippet name (map (lambda (x)
                                (let* ((pair (car x))
                                       (key (car pair))
                                       (func (cdr pair))
                                       (data (cadr x))
                                       (value (func data)))
                                  (cons key value)))
                              (zip snippet rest)))))

(define (main args)
  (test))
