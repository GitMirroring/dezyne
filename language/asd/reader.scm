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

(define-module (language asd reader)
  :use-module (system base language)

  :use-module (language asd asd)
  :use-module (language asd tokenize)
  :export (read-asd))

(define (read-and-parse lang port cenv)
  (let ((exp ((language-reader lang) port cenv)))
    (cond
     ((eof-object? exp) exp)
     ((language-parser lang) => (lambda (parse) (parse exp)))
     (else exp))))

(define (asd-reader port env)
  ((make-parser) (make-tokenizer port) error))

(define (read-asd file-name)
  (asd-reader (open-file file-name "r") (current-module)))
