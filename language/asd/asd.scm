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
   (Identifier in out
               component interface 
               lbrace rbrace semicolon
               NumericLiteral
               enum int void
               (left: + -) (left: * /))
   (program (modelDeclList) : $1
            (*eoi*) : (call-with-input-string "" read)) ; *eof-object*
   (modelDeclList () : '()
                  (modelDeclList modelDecl) : (append $1 (list $2)))
   (modelDecl (interface-decl) : $1)
   (interface-decl (interface Identifier lbrace identifier-block rbrace) : `(,$1 ,$2 ,$4)
    )
   (identifier-block (event-declaration-list) : $1)
   (event-declaration-list () : '()
                           (event-declaration-list event-declaration) : (append $1 (list $2)))
   (event-declaration (event-direction type Identifier semicolon) : `(,$1 ,$2 ,$3))
   (event-direction (in) : 'in
                    (out) : 'out)
   (type (int) : 'int
         (void) : 'void)))

(define (compile-tree-il exp env opts)
  (values (parse-tree-il (comp exp '())) env env))

(define (comp src e)
  (format #t "MATCHING:~a\n" src)
  (match src
    (tree `(const tree))
    (('interface name block) `(apply (primitive list) (const interface) (const ,name) ,(comp block e)))
        (('in type name) `(apply (primitive list) (const in) (const ,type) (const ,name)))
    (('out type name) `(apply (primitive list) (const out) (const ,type) (const ,name)))))
