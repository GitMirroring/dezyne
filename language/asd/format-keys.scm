#! /bin/sh
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
  (eval '(main (command-line)) (resolve-module '(language asd format-keys))))

(define-module (language asd format-keys)
  :use-module (ice-9 regex)
  :use-module (ice-9 and-let-star)
  :use-module (language asd misc)
  :export (format-keys format-at-keys map-format-keys string-map-format-keys))

(define (format-keys string pairs)
  (if (null? pairs)
      string
      (let ((key (format #f "%\\{~a\\}"  (caar pairs)))
            (value (format #f "~a" (cdar pairs))))
        (format-keys (regexp-substitute/global #f key string 'pre value 'post) (cdr pairs)))))

(define (replace-at string key value)
  (stderr "REPLACE-AT: snippet:~a\n" string)
  (stderr "REPLACE-AT: key:~a\n" key)
  (or (and-let* ((index (string-contains string key))
                 (end (string-contains string key (1+ index)))
                 (key-length (string-length key))
                 (snippet-begin (+ index key-length))
                 (snippet-end (+ end key-length))
                 (snippet (string-copy string snippet-begin snippet-end)))
                (apply string-append (list (string-take string index)
                                           (string-map-format-keys snippet pairs variables)
                                           (string-drop string snippet-end)))))
  string)

(define (format-at-keys string pairs)
  (stderr "format-at-keys: pairs: ~a" pairs)
  (if (null? pairs)
      string
      (let ((key (format #f "@{~a}" (caar pairs)))
            (value (cdr pairs)))
        (format-at-keys
         (replace-at string key value) (cdr pairs)))))

(define (map-format-keys string pairs variables)
  (map (lambda (x)
         (format-keys string
                      (map (lambda (y) (cons (car y) ((cdr y) x))) pairs)))
       variables))

(define (string-map-format-keys string pairs variables)
  (string-join (map-format-keys string pairs variables) ""))

(define (test)
  (define (get-bar x) (format #f "BAR~a" x))
  (define (get-foo x) (format #f "FOO~a" x))

  (stdout (format-keys "%{foo} %{bar}\n" '((foo . "xxx") (bar . "yyy"))))
  (stdout
   (map (lambda (x)
          (let ((foo (get-foo x)) (bar (get-bar x)))
            (format-keys "%{foo} %{bar}" `((foo . ,foo) (bar . ,bar)))))
        '(a b c)))
  (stdout
   (map-format-keys "%{foo} %{bar}" 
                    `((foo . ,get-foo) (bar . ,get-bar)) '(a b c)))
  (stdout 
   (map-format-keys "%{foo} %{bar}" 
                    `((foo . ,(lambda (x) (format #f "~a.~a" x x))) 
                      (bar . ,(lambda (x) (format #f "~a-~a" x x))))
                    '(a b c))))

(define (main args)
  (test))
