;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014  "Mu Lei" known as "NalaGinrut" <NalaGinrut@gmail.com>
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

(define-module (language dezyne spec)
  #:use-module (system base language)
  #:use-module (language dezyne parse)
  #:use-module (language dezyne tokenize)
  #:export (dezyne))

(define-language dezyne
  #:title       "dezyne"
  #:reader      (lambda (port env)
                  ((make-parser) (make-tokenizer port) error))
  #:compilers   `((tree-il . ,compile-tree-il))
  #:printer     write)
