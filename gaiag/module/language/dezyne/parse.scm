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

(define-module (language dezyne parse)
  #:use-module (ice-9 match)
  #:use-module (ice-9 and-let-star)

  #:use-module (system base lalr)
  #:use-module (language tree-il)

  #:use-module (language dezyne location)

  #:export (
            compile-tree-il
            make-dezyne-tokenizer
            make-parser
            ))

(define (make-parser)
  (lalr-parser
   (driver: lr)
   ;;(out-table: "dezyne.out")
   (
    lbrace rbrace lparen rparen rbracket semicolon colon dot comma
    (left: on lbracket)
    inevitable optional
    otherwise
    if reply return
    true false

    (left: in inout out)
    (left: illegal)
    (left: behaviour import interface component system)
    (left: provides requires injected)
    (left: bool enum extern int typedef void)
    (left: Identifier NumericLiteral Data)
    (left: dollar)

    (nonassoc: = <=> ..)
    (left: or)
    (left: and)
    (left: == != < > <= >=)
    (left: !)
    (left: + -)
    (left: * /)
    (left: &)

    (right: else)

    )

   (program
    (model-list *eoi*) : (cons 'root $1))

   (model-list
    () : '()
    (model-list model-spec) : (append $1 (list $2)))

   (model-spec
    (import-list) : $1
    (interface-spec) : $1
    (component-spec) : $1
    (system-spec) : $1)

   (import-list
    () : '(imports)
    (import-list import-spec) : (append $1 (list $2)))

   (interface-spec
    (interface Identifier lbrace type-list event-list optional-behaviour rbrace) :
    (note-location `(,$1 ,$2 ,$4 ,$5 ,$6) @1))

   (component-spec
    (component Identifier lbrace port-list optional-behaviour rbrace) :
    (note-location `(,$1 ,$2 ,$4 ,$5) @1))

   (system-spec
    (system Identifier lbrace port-list system-statement-list rbrace) : `(,$1 ,$2 ,$4 ,$5))

   (system-statement-list
    () : '(compound)
    (system-statement-list system-statement) : (append $1 (list $2)))

   (system-statement
    (bind) : $1
    (instance) : $1)

   (binding
    (*) : `(binding #f *)
    (Identifier) : `(binding #f ,$1)
    (Identifier dot Identifier) : `(binding ,$1 ,$3))

   (bind
    (binding <=> binding semicolon) : `(bind ,$1 ,$3))

   (instance
    (Identifier Identifier semicolon) : `(instance ,$1 ,$2))

   (import-spec
    (import Identifier semicolon) : `(,$1 ,$2)
    (import Identifier dot Identifier semicolon) : `(,$1 ,(symbol-append $2 '. $4)))

   (event-list
    () : '(events)
    (event-list event) : (append $1 (list $2))
    (event-list type-spec) : (append $1 (list $2)))

   (event
    (event-direction type Identifier semicolon) : `(,$1 ,(note-location `(signature ,$2) @2) ,$3)
    (event-direction type Identifier lparen rparen semicolon) : `(,$1 ,(note-location `(signature ,$2) @2) ,$3)
    (event-direction type Identifier lparen parameter-list rparen semicolon) : `(,$1 ,(note-location `(signature ,$2 ,$5) @2) ,$3))

   (parameter-direction
    (in) : 'in
    (out) : 'out
    (inout) : 'inout)

   (event-direction
    (in) : $1
    (out) : $1)

   (port-list
    () : '(ports)
    (port-list port) : (append $1 (list $2)))

   (port
    (port-direction Identifier Identifier semicolon) : `(,$1 ,$2 ,$3 #f)
    (port-direction injected Identifier Identifier semicolon) : `(,$1 ,$3 ,$4 ,$2))

   (port-direction
    (provides) : 'provides
    (requires) : 'requires)

   (type-list
    () : '(types)
    (type-list type-spec) : (append $1 (list $2)))

   (type-spec
    (enum-spec) : $1
    (extern-spec) : $1
    (typedef-spec): $1)

   (type
    (bool) : '(type bool)
    (int) : '(type int)
    (void) : '(type void)
    (Identifier) : (note-location `(type ,$1) @1)
    (Identifier dot Identifier) : (note-location `(type ,$3 ,$1) @1))

   (enum-spec
    (enum Identifier lbrace enum-value-list rbrace semicolon) : `(,$1 ,$2 ,$4))

   (enum-value-list
    (enum-value) : `(,$1)
    (enum-value-list comma enum-value) : (append $1 (list $3)))

   (enum-value
    (Identifier) : $1)

   (typedef-spec
    (typedef int lbracket NumericLiteral .. NumericLiteral rbracket Identifier semicolon) : `(int ,$8 (range ,$4 ,$6)))

   (extern-spec
    (extern Identifier = Data semicolon) : `(,$1 ,$2 ,$4))

   (expression
    (false) : $1
    (true) : $1
    (NumericLiteral) : $1
    (compound-identifier) : $1
    (Data) : (note-location `(data ,$1) @1)

    (lparen expression rparen) : `(group ,$2)

    (! expression) : `(! ,$2)
    (expression and expression) : `(and ,$1 ,$3)
    (expression or expression) : `(or ,$1 ,$3)

    (expression == expression) : `(== ,$1 ,$3)
    (expression != expression) : `(!= ,$1 ,$3)
    (expression < expression) : `(< ,$1 ,$3)
    (expression <= expression) : `(<= ,$1 ,$3)
    (expression > expression) : `(> ,$1 ,$3)
    (expression >= expression) : `(>= ,$1 ,$3)

    (expression + expression) : `(+ ,$1 ,$3)
    (expression - expression) : `(- ,$1 ,$3)

    (function-call) : $1
    (action) : $1)

   (function-call
    (Identifier lparen rparen) : (note-location `(call ,$1) @1)
    (Identifier lparen argument-list rparen) : (note-location `(call ,$1 ,$3) @1))

   (argument-list
    (expression) : `(arguments (expression ,$1))
    (argument-list comma expression) : (append $1 (list `(expression ,$3))))

   (optional-behaviour
    () : '(no-behaviour)
    (behaviour lbrace type-list variable-list function-list function-statement-list rbrace) : `(,$1 #f ,$3 ,$4 ,$5 ,$6)
    (behaviour Identifier lbrace type-list variable-list function-list function-statement-list rbrace) : `(,$1 ,$2 ,$4 ,$5 ,$6 ,$7)
    (system lbrace system-statement-list rbrace) : `(,$1 #f ,$3)
    (system Identifier lbrace system-statement-list rbrace) : `(,$1 ,$2 ,$4))

   (function
    (type Identifier lparen rparen compound-statement) : (note-location `(function ,$2 ,(note-location `(signature ,$1) @1), $5) @1)

    (type Identifier lparen parameter-list rparen compound-statement) : (note-location `(function ,$2 ,(note-location `(signature ,$1 ,$4) @1) ,$6) @1))

   (parameter-list
    (parameter) : `(parameters ,$1)
    (parameter-list comma parameter) : (append $1 (list $3)))

   (parameter
    (type Identifier): (note-location `(parameter ,$2 ,$1) @1)
    (parameter-direction type Identifier): (note-location `(parameter ,$3 ,$2 ,$1) @1))

   (function-list
    () : '(functions)
    (function) : `(functions ,$1)
    (function-list function) : (append $1 (list $2)))

   (statement-list
    () : '(compound)
    (statement-list statement) : (append $1 (list $2)))

   (function-statement-list
    () : '(compound)
    (function-statement-list function-statement) : (append $1 (list $2)))

   (function-statement
    (function) : $1
    (statement) : $1)

   (statement
    (function-call-statement) : $1
    (guarded-statement) : $1
    (compound-statement) : $1
    (on-event-statement) : $1
    (illegal-statement) : $1
    (assignment-statement) : $1
    (action-statement) : $1
    (if-statement) : $1
    (reply-statement) : $1
    (return-statement) : $1
    (variable-statement) : $1)

   (function-call-statement
    (function-call semicolon) : $1)

   (guarded-statement
    (lbracket guard rbracket statement) : (note-location `(guard ,$2 ,$4) @1))

   (guard
    (expression) : `(expression ,$1)
    (otherwise) : `(,$1))

   (compound-statement
    (lbrace statement-list rbrace) : (note-location $2 @1))

   (compound-identifier
    (Identifier) : (note-location `(var ,$1) @1)
    (Identifier dot Identifier) : `(value ,$1 ,$3)
    (Identifier dot Identifier dot Identifier) : `(literal ,$1 ,$3 ,$5))

   (on-event-statement
    (on trigger-spec colon statement) : (note-location `(,$1 ,$2 ,$4) @1))

   (trigger-spec
    (trigger-list) : (note-location (cons 'triggers $1) @1)
    (optional) : (note-location `(triggers ,(note-location `(trigger #f ,$1) @1)) @1)
    (inevitable) : (note-location `(triggers ,(note-location `(trigger #f ,$1) @1)) @1))

   (trigger-list
    (trigger) : `(,$1)
    (trigger-list comma trigger) : (append $1 (list $3)))

   (trigger
    (Identifier) : (note-location `(trigger #f ,$1) @1)
    (Identifier lparen rparen) : (note-location `(trigger #f ,$1) @1)
    (Identifier dot Identifier) : (note-location `(trigger ,$1 ,$3) @1)
    (Identifier dot Identifier lparen rparen) : (note-location `(trigger ,$1 ,$3) @1)
    (Identifier lparen argument-list rparen) : (note-location `(trigger #f ,$1 ,$3) @1)
    (Identifier dot Identifier lparen argument-list rparen) : (note-location `(trigger ,$1 ,$3 ,$5) @1))

   (illegal-statement
    (illegal semicolon) : (note-location `(illegal) @1))

   (assignment-statement
    (Identifier = expression semicolon) : (note-location `(assign ,$1 (expression ,$3)) @1))

   (action
    (Identifier dot Identifier lparen rparen) : (note-location `(action (trigger ,$1 ,$3)) @1)
    (Identifier dot Identifier lparen argument-list rparen) : (note-location `(action (trigger ,$1 ,$3 ,$5)) @1))

   (action-statement
    (Identifier semicolon) : (note-location `(action (trigger #f ,$1)) @1)
    (Identifier dot Identifier semicolon) : (note-location `(action (trigger ,$1 ,$3)) @1)
    (action semicolon) : $1)

   (if-statement
    (if lparen expression rparen statement) : `(if (expression ,$3) ,$5)
    (if lparen expression rparen statement else statement) : `(if (expression ,$3) ,$5 ,$7))

   (reply-statement
    (reply lparen expression rparen semicolon) : `(,$1 (expression ,$3)))

   (return-statement
    (return semicolon) : (note-location '(return) @1)
    (return expression semicolon) : (note-location `(return (expression ,$2)) @1))

   (variable-statement
    (type Identifier semicolon) : `(variable ,$2 ,$1 ,(note-location '(expression) @3))
    (Identifier dot Identifier Identifier semicolon) : `(variable ,$4 (type ,$3 ,$1) ,(note-location '(expression) @5))
    (type Identifier = expression semicolon) : `(variable ,$2 ,$1 ,(note-location `(expression ,$4) @3))
    (Identifier dot Identifier Identifier = expression semicolon) : `(variable ,$4 (type ,$3 ,$1) ,(note-location `(expression ,$6) @3)))

   (variable-list
    () : '(variables)
    (variable-list variable-statement) : (append $1 (list $2)))))

(define (compile-tree-il exp env opts)
  (values (parse-tree-il (comp exp '())) env env))

(define (comp src e)
  (match src
    (() (exit))
    (tree `(const ,tree))))
