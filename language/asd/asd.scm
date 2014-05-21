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

(define *eof-object*
  (call-with-input-string "" read-char))

(define (make-parser)
  (lalr-parser
   (out-table: "asd.out")
   (
    lbrace rbrace lparen rparen lbracket rbracket dot semicolon comma
    !
    ;;(left: * /)
    ;; (left: + -) 
    =
    behaviour
    bool
    component
    enum
    illegal
    in
    inevitable
    int
    interface 
    on
    optional
    out
    void
    Identifier 
    NumericLiteral
    )

   (program
    (model-list *eoi*) : $1
    )

   (model-list 
    () : '()
    (model-list model) : (append $1 (list $2)))

   (model
    (interface-spec) : $1)

   (interface-spec
    (interface Identifier lbrace type-list event-list optional-behaviour rbrace) : `(,$1 ,$2 ,$4 ,$5 ,$6))

   (event-list
    () : '(events)
    (event-list event) : (append $1 (list $2)))

   (event
    (event-direction type Identifier semicolon) : `(,$1 ,$2 ,$3))
   
   (event-direction
    (in) : 'in
    (out) : 'out)
   
   (type-list () : '(types) (type-list type-spec) : (append $1 (list $2)))
   
  (type-spec (enum-spec) : $1)
  
   (type
    (bool) : 'bool
    (int) : 'int
    (enum-identifier) : $1
    (void) : 'void)

   (enum-identifier 
    (Identifier) : $1)
  
  (optional-behaviour
   () : '(behaviour)
   (behaviour Identifier lbrace type-list variable-list behaviour-statement-list rbrace) : `(,$1 ,$2 ,$4 ,$5 ,$6))

  (enum-spec 
   (enum enum-identifier lbrace enum-value-list rbrace semicolon) : `(,$1 ,$2 ,$4))
  
  (enum-value-list (enum-value) : `(,$1) (enum-value-list comma enum-value) : (append $1 (list $3)))
   
  (enum-value (Identifier) : $1)
  
  (expression (compound-identifier) : $1)
  
  (type-identifier (Identifier) : $1)
  
  (behaviour-statement-list () : '(statements) (behaviour-statement-list behaviour-statement) : (append $1 $2))

   ;;(inevitable-statement) : $1
   ;;(optional-statement) : $1

  (behaviour-statement (illegal-statement) : $1 (behaviour-statement-list) : $1 (guarded-statement) : $1)

  (guarded-statement (lbracket compound-identifier rbracket behaviour-statement) : `(guard ,$2 ,$4))

  (compound-identifier (Identifier) : $1 (Identifier dot Identifier) : `(dot ,$1 ,$3))

  (illegal-statement (illegal semicolon) : $1)
  
  (variable-list () : '(variables) (variable-list variable) : (append $1 $2))

  (variable (type Identifier = expression semicolon) : `(= ,$1 ,$2 ,$4))

  ))

(define (compile-tree-il exp env opts)
  (values (parse-tree-il (comp exp '())) env env))

(define (comp src e)
  (format #t "MATCHING:~a\n" src)
  (match src
    (() (exit))
    (tree `(const ,tree))))
