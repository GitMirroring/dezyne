;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
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
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 match)
  #:use-module (ice-9 receive)
  #:use-module (srfi srfi-1)


  #:use-module (system base lalr)
  #:use-module (language tree-il)

  #:use-module (language dezyne location)

  #:export (
            compile-tree-il
            make-dezyne-tokenizer
            make-parser
            ))

(define (event? x) (eq? (car x) 'event))

(define (make-parser)
  (lalr-parser
   (driver: lr)
   ;;(out-table: "dezyne.out")
   (
    lbrace rbrace lparen rparen rbracket semicolon colon dot comma
    on lbracket
    inevitable optional
    otherwise
    if reply return
    true false

    in inout out
    illegal
    behaviour import interface component system
    provides requires injected
    bool enum extern subint void
    NumericLiteral Data    
    dollar

    (left: Identifier)
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
    (models *eoi*) : (cons 'root $1))

   (models
    () : '()
    (models model) : (append $1 (list $2)))

   (model
    (import-spec) : $1
    (type) : (retain-source-properties $1 (append (take $1 2) '(*global*) (drop $1 3)))
    (interface-spec) : $1
    (component-spec) : $1)

   (import-spec
    (import Identifier semicolon) : `(,$1 ,$2)
    (import Identifier dot Identifier semicolon) : `(,$1 ,(symbol-append $2 '. $4)))

   (interface-spec
    (interface Identifier lbrace events/types rbrace)
    : (receive (e t)
          (partition event? $4)
        (note-location `(,$1 ,$2 ,(cons 'types t) ,(cons 'events e)) @1))
    (interface Identifier lbrace events/types behaviour-spec rbrace)
    : (receive (e t)
          (partition event? $4)
        (note-location `(,$1 ,$2 ,(cons 'types t) ,(cons 'events e) ,$5) @1)))

   (component-spec
    (component Identifier lbrace ports rbrace)
    : (note-location `(,$1 ,$2 ,$4) @1)
    (component Identifier lbrace ports behaviour-spec rbrace)
    : (note-location `(,$1 ,$2 ,$4 ,$5) @1)
    (component Identifier lbrace ports system lbrace instances/binds rbrace rbrace)
    : (receive (instances binds)
          (partition (lambda (x) (eq? (car x) 'instance)) $7)
        (note-location `(system ,$2 ,$4 ,(cons 'instances instances) ,(cons 'bindings binds)) @1)))

   (instances/binds
    () : '()
    (instances/binds instance/bind) : (append $1 (list $2)))

   (instance
    (Identifier Identifier semicolon) : `(instance ,$2 ,$1))

   (instance/bind
    (instance) : $1
    (bind) : $1)

   (binding
    (*) : `(binding #f *)
    (Identifier) : `(binding #f ,$1)
    (Identifier dot Identifier) : `(binding ,$1 ,$3))

   (bind
    (binding <=> binding semicolon) : `(bind ,$1 ,$3))

   (events/types
    () : '()
    (events/types event/type) : (append $1 (list $2)))

   (event/type
    (event) : $1
    (type) : $1)

   (event
    (event-direction variable-type Identifier semicolon) : `(event ,$3 ,(note-location `(signature ,$2) @2) ,$1)
    (event-direction variable-type Identifier lparen rparen semicolon) : `(event , $3 ,(note-location `(signature ,$2) @2) ,$1)
    (event-direction variable-type Identifier lparen formals rparen semicolon) : `(event ,$3 ,(note-location `(signature ,$2 ,$5) @2) ,$1))

   (formal-direction
    (in) : 'in
    (out) : 'out
    (inout) : 'inout)

   (event-direction
    (in) : $1
    (out) : $1)

   (ports
    () : '(ports)
    (ports port) : (append $1 (list $2)))

   (port
    (port-direction Identifier Identifier semicolon) : `(port ,$3 ,$2 ,$1 #f)
    (port-direction injected Identifier Identifier semicolon) : `(port ,$4 ,$3 ,$1 ,$2))

   (port-direction
    (provides) : 'provides
    (requires) : 'requires)

   (optional-types
    () : '(types)
    (optional-types type) : (append $1 (list $2)))

   (type
    (enum-spec) : $1
    (extern-spec) : $1
    (subint-spec): $1)

   (variable-type
    (bool) : '(type bool)
    (void) : '(type void)
    (Identifier) : (note-location `(type ,$1) @1)
    (Identifier dot Identifier) : (note-location `(type ,$3 ,$1) @1))

   (enum-spec
    (enum Identifier lbrace enum-fields rbrace semicolon) : (note-location `(enum ,$2 #f ,$4) @1))

   (enum-fields
    (Identifier) : `(fields ,$1)
    (enum-fields comma Identifier) : (append $1 (list $3)))

   (subint-spec
    (subint Identifier lbrace integer .. integer rbrace semicolon) : (note-location `(int ,$2 #f (range ,$4 ,$6)) @1))

   (integer
    (NumericLiteral): $1
    (- NumericLiteral): (- $2))

   (extern-spec
    (extern Identifier Data semicolon) : (note-location `(extern ,$2 #f ,$3) @1))

   (expression
    (expr): `(expression ,$1))

   (expr
    (false) : $1
    (true) : $1
    (integer) : $1
    (compound-identifier) : $1
    (Data) : (note-location `(data ,$1) @1)

    (lparen expr rparen) : `(group ,$2)

    (! expr) : `(! ,$2)
    (expr and expr) : `(and ,$1 ,$3)
    (expr or expr) : `(or ,$1 ,$3)

    (expr == expr) : `(== ,$1 ,$3)
    (expr != expr) : `(!= ,$1 ,$3)
    (expr < expr) : `(< ,$1 ,$3)
    (expr <= expr) : `(<= ,$1 ,$3)
    (expr > expr) : `(> ,$1 ,$3)
    (expr >= expr) : `(>= ,$1 ,$3)

    (expr + expr) : `(+ ,$1 ,$3)
    (expr - expr) : `(- ,$1 ,$3)

    (expr * expr) : `(* ,$1 ,$3)
    (expr / expr) : `(/ ,$1 ,$3)

    (function-call) : $1
    (action) : $1)


   (function-call
    (Identifier lparen rparen) : (note-location `(call ,$1) @1)
    (Identifier lparen arguments rparen) : (note-location `(call ,$1 ,$3) @1))

   (arguments
    (expression) : `(arguments ,$1)
    (arguments comma expression) : (append $1 (list $3)))

   (behaviour-spec
    (behaviour optional-identifier lbrace optional-types rbrace)
    : `(,$1 ,$2 ,$4)
    (behaviour optional-identifier lbrace optional-types functions/statements/variables rbrace)
    : (receive (f r)
          (partition (lambda (x) (eq? (car x) 'function)) $5)
        (receive (s v)
            (partition (lambda (x) (not (eq? (car x) 'variable))) r)
          `(,$1 ,$2 ,$4 ,(cons 'variables v) ,(cons 'functions f) ,(note-location (cons 'compound s) @1)))))

   (optional-identifier
    () : #f
    (Identifier): $1)

   (function
    (variable-type Identifier lparen rparen compound-statement) : (note-location `(function ,$2 ,(note-location `(signature ,$1) @1), #f ,$5) @1)
    (variable-type Identifier lparen formals rparen compound-statement) : (note-location `(function ,$2 ,(note-location `(signature ,$1 ,$4) @1) #f ,$6) @1))

   (formals
    (formal) : `(formals ,$1)
    (formals comma formal) : (append $1 (list $3)))

   (formal
    (variable-type Identifier): (note-location `(formal ,$2 ,$1) @1)
    (formal-direction variable-type Identifier): (note-location `(formal ,$3 ,$2 ,$1) @1))

   (statements
    () : '(compound)
    (statements statement/variable) : (append $1 (list $2)))

   (statement/variable
    (statement) : $1
    (variable) : $1)

   (functions/statements/variables
    () : '()
    (functions/statements/variables function/statement/variable) : (append $1 (list $2)))

   (function/statement/variable
    (function) : $1
    (statement) : $1
    (variable) : $1)

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
    (return-statement) : $1)

   (function-call-statement
    (function-call semicolon) : $1)

   (guarded-statement
    (lbracket guard rbracket statement) : (note-location `(guard ,$2 ,$4) @1))

   (guard
    (expression) : $1
    (otherwise) : `(,$1))

   (compound-statement
    (lbrace statements rbrace) : (note-location $2 @1))

   (compound-identifier
    (Identifier) : (note-location `(var ,$1) @1)
    (Identifier dot Identifier) : `(value ,$1 ,$3)
    (Identifier dot Identifier dot Identifier) : `(literal ,$1 ,$3 ,$5))

   (on-event-statement
    (on trigger-spec colon statement) : (note-location `(,$1 ,$2 ,$4) @1))

   (trigger-spec
    (triggers) : (note-location (cons 'triggers $1) @1)
    (optional) : (note-location `(triggers ,(note-location `(trigger #f ,$1) @1)) @1)
    (inevitable) : (note-location `(triggers ,(note-location `(trigger #f ,$1) @1)) @1))

   (triggers
    (trigger) : `(,$1)
    (triggers comma trigger) : (append $1 (list $3)))

   (trigger
    (Identifier) : (note-location `(trigger #f ,$1) @1)
    (Identifier lparen rparen) : (note-location `(trigger #f ,$1) @1)
    (Identifier dot Identifier) : (note-location `(trigger ,$1 ,$3) @1)
    (Identifier dot Identifier lparen rparen) : (note-location `(trigger ,$1 ,$3) @1)
    (Identifier lparen arguments rparen) : (note-location `(trigger #f ,$1 ,$3) @1)
    (Identifier dot Identifier lparen arguments rparen) : (note-location `(trigger ,$1 ,$3 ,$5) @1))

   (illegal-statement
    (illegal semicolon) : (note-location `(illegal) @1))

   (assignment-statement
    (Identifier = expression semicolon) : (note-location `(assign ,$1 ,$3) @1))

   (action
    (Identifier dot Identifier lparen rparen) : (note-location `(action (trigger ,$1 ,$3)) @1)
    (Identifier dot Identifier lparen arguments rparen) : (note-location `(action (trigger ,$1 ,$3 ,$5)) @1))

   (action-statement
    (Identifier semicolon) : (note-location `(action (trigger #f ,$1)) @1)
    (Identifier dot Identifier semicolon) : (note-location `(action (trigger ,$1 ,$3)) @1)
    (action semicolon) : $1)

   (if-statement
    (if lparen expression rparen statement) : `(if ,$3 ,$5)
    (if lparen expression rparen statement else statement) : `(if ,$3 ,$5 ,$7))

   (reply-statement
    (reply lparen expression rparen semicolon) : (note-location `(,$1 ,$3) @1))

   (return-statement
    (return semicolon) : (note-location '(return) @1)
    (return expression semicolon) : (note-location `(return ,$2) @1))

   (variable
    (variable-type Identifier semicolon) : `(variable ,$2 ,$1 ,(note-location '(expression) @3))
    (Identifier dot Identifier Identifier semicolon) : `(variable ,$4 (type ,$3 ,$1) ,(note-location '(expression) @5))
    (variable-type Identifier = expression semicolon) : `(variable ,$2 ,$1 ,(note-location $4 @3))
    (Identifier dot Identifier Identifier = expression semicolon) : `(variable ,$4 (type ,$3 ,$1) ,(note-location $6 @3)))

   (variables
    (variable) : `(variables ,$1)
    (variables variable) : (append $1 (list $2)))))

(define (compile-tree-il exp env opts)
  (values (parse-tree-il (comp exp '())) env env))

(define (comp src e)
  (match src
    (() (exit))
    (tree `(const ,tree))))
