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
  #:export (asd-> make-asd-tokenizer make-parser compile-tree-il))

(define *eof-object*
  (call-with-input-string "" read-char))

(define (make-parser)
  (lalr-parser
   (driver: lr)
   (out-table: "asd.out")
   (
    lbrace rbrace lparen rparen lbracket rbracket semicolon colon dot comma
    =
    Identifier 
    in out interface component system 
    behaviour namespace on
    illegal inevitable optional
    provides requires otherwise import
    if reply
    (left: or && ! * / + -)
    (left: bool enum void int)
    (nonassoc: == !=)
    )
   
   (program
    (model-list *eoi*) : $1)

   (model-list 
    () : '()
    (model-list model-spec) : (append $1 (list $2)))

   (model-spec
    (import-list) : $1
    (interface-spec) : $1
    (component-spec) : $1)

   (import-list
    () : '(imports)
    (import-list import-spec) : (append $1 (list $2)))

   (interface-spec
    (interface Identifier lbrace type-list event-list optional-behaviour rbrace) : `(,$1 ,$2 ,$4 ,$5 ,$6))

   (component-spec
    (component Identifier lbrace port-list optional-behaviour rbrace) : `(,$1 ,$2 ,$4 ,$5))

   (import-spec
    (import Identifier semicolon) : `(,$1 ,$2))

   (event-list
    () : '(events)
    (event-list event) : (append $1 (list $2)))

   (event
    (event-direction type Identifier semicolon) : `(,$1 ,$2 ,$3))
   
   (event-direction
    (in) : 'in
    (out) : 'out)
   
   (port-list
    () : '(ports)
    (port-list port) : (append $1 (list $2)))

   (port
    (port-direction type Identifier semicolon) : `(,$1 ,$2 ,$3))
   
   (port-direction
    (provides) : 'provides
    (requires) : 'requires)
   
   (type-list 
    () : '(types) 
    (type-list type-spec) : (append $1 (list $2)))
   
   (type-spec 
    (enum-spec) : $1)
   
   (type
    (bool) : 'bool
    (int) : 'int
    (enum-identifier) : $1
    (void) : 'void)

   (enum-identifier 
    (Identifier) : $1)
   
   (enum-spec 
    (enum enum-identifier lbrace enum-value-list rbrace semicolon) : `(,$1 ,$2 ,$4))
   
   (enum-value-list 
    (enum-value) : `(,$1) 
    (enum-value-list comma enum-value) : (append $1 (list $3)))
   
   (enum-value
    (Identifier) : $1)
   
   (expression
    (lparen expression rparen) : $1
    (! expression) : `(! ,$2)
    (expression && expression) : `(&& ,$1 ,$3)
    (expression or expression) : `(logic-or ,$1 ,$3)
    (expression == expression) : `(== ,$1 ,$3)
    (expression != expression) : `(!= ,$1 ,$3)
    (compound-identifier) : $1)
   
   (type-identifier 
    (Identifier) : $1)
   
   (optional-behaviour
    () : '(behaviour)
    (behaviour lbrace type-list variable-list behaviour-statement-list rbrace) : `(,$1 #f ,$3 ,$4 ,$5)
    (behaviour Identifier lbrace type-list variable-list behaviour-statement-list rbrace) : `(,$1 ,$2 ,$4 ,$5 ,$6))

   (behaviour-statement-list 
    () : '(statements) 
    (behaviour-statement-list behaviour-statement) : (append $1 (list $2)))

   (behaviour-statement
    (guarded-statement) : $1
    (compound-behaviour-statement) : $1
    (on-event-statement) : $1 
    (illegal-statement) : $1
    (assignment-behaviour-statement) : $1
    (action-statement) : $1
    ;; (if-statement) : $1
    ;; (reply-statement) : $1
    )

   (guarded-statement
    (lbracket guard rbracket behaviour-statement) : `(guard ,$2 ,$4))
   
   (guard
    (expression) : $1
    (otherwise) : $1)
   
   (compound-behaviour-statement
    (lbrace behaviour-statement-list rbrace) : $2)

   (compound-identifier
    (Identifier) : $1 
    (Identifier dot Identifier) : `(field ,$1 ,$3))
   
   (on-event-statement
    (on trigger-spec colon behaviour-statement) : `(,$1 ,$2 ,$4))

   (trigger-spec
    (trigger-list) : $1
    (optional) : $1
    (inevitable) : $1)

   (trigger-list
    (trigger) : $1 
    (trigger-list comma trigger) : (append $1 (list $3)))

   (trigger
    (compound-identifier) : $1)

   (illegal-statement
    (illegal semicolon) : $1)
   
   (assignment-behaviour-statement
    (Identifier = expression semicolon) : `(assign ,$1 ,$3))
   
   (action-statement
    (trigger semicolon) : `(action ,$1))
   
   ;;(if-statement)

   ;;(reply-statement)

   (variable-list
    () : '(variables)
    (variable-list variable) : (append $1 (list $2)))

   (variable 
    (type Identifier = expression semicolon) : `(declare ,$1 ,$2 ,$4))))

(define (compile-tree-il exp env opts)
  (values (parse-tree-il (comp exp '())) env env))

(define (comp src e)
  ;;(format #t "MATCHING:~a\n" src)
  (match src
    (() (exit))
    (tree `(const ,tree))))

(define asd-> (@ (language asd pretty) asd->))
