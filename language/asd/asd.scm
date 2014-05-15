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


(define-module (language asd asd)
  #:use-module (system base lalr)
  #:use-module (language tree-il)
  #:use-module (ice-9 match)
  #:export (make-asd-tokenizer make-parser compile-tree-il))

(define (make-parser)
  (lalr-parser
   (Identifier in interface 
               lbrace rbrace semicolon
               NumericLiteral
               enum int void
               (left: + -) (left: * /))
   (program (exp) : $1
            (*eoi*) : (call-with-input-string "" read)) ; *eof-object*
   (exp  (exp + term) : `(+ ,$1 ,$3)
         (exp - term) : `(- ,$1 ,$3)
         (interface Identifier lbrace identifier-block rbrace) : `(,$1 ,$2 ,$4)
         (term) : $1)
   (identifier-block (term) : $1
                     (in type Identifier semicolon) : `(,$1 ,$2 ,$3))
   (type (int) : 'int
         (void) : 'void)
   (term (term * factor) : `(* ,$1 ,$3)
         (term / factor) : `(/ ,$1 ,$3)
         (factor) : $1)
   (factor (NumericLiteral) : `(NumericLiteral ,$1))))

(define (compile-tree-il exp env opts)
  (values (parse-tree-il (comp exp '())) env env))

(define (comp src e)
  (format #t "MATCHING:~a\n" src)
  (match src
    (('NumericLiteral x) `(const ,x))
    (('in type name) `(apply (primitive list) (const in) (const ,type) (const ,name)))
    (('interface name) `(apply (primitive list) (const interface) (const ,name)))
    (('interface name block) `(apply (primitive list) (const interface) (const ,name) ,(comp block e)))
    ((op x y) `(apply (primitive ,op) ,(comp x e) ,(comp y e)))))
