;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (language asd parse)
  #:use-module (system base lalr)
  #:use-module (language tree-il)
  #:use-module (system foreign)

  #:use-module (ice-9 match)

  #:export (ast->
            compile-tree-il
            make-asd-tokenizer
            make-parser
            object?
            object-id
            source-location
            source-location->source-properties))

(define (debug m x) (display (format #f "~a: ~a\n" m x) (current-error-port)))

(define (ast:make . t)
  (let ((ast t);; (ast (if (pair? t) t (car t)))
        )
    (match ast
      (('imports i ...) ast)
      (('import type) ast)
      (('component name ('ports p ...) ('behaviour n ...) ...) ast)
      (('interface name ('types t ...) ('events e ...) ('behaviour n ...) ...) ast)
      (('behaviour) ast)
      (('behaviour name ('types t ...) ('variables v ...) ('compound s ...)) ast)
      (('compound lst) (cons 'compound lst))
      (('compound s ...) ast)
      (('types t ...) ast)
      (('events e ...) ast)
      (('in type name) ast)
      (('out type name) ast)
      (('ports p ...) ast)
      (('provides type name) ast)
      (('value type field) ast)
      (('variables v ...) ast)
      (('variable type name value ...) ast)
      (('requires type name) ast)
      (('trigger port event) ast)
      (('guard expression statement) ast)
      (('on (trigger t ...) statement) ast)
      (('action 'illegal) ast)
      (('action ('field type name)) ast)
      (('assign name expression) ast)
;;      ((? (lambda (ast) (and (symbol? (car ast)) (pair? (cdr ast)) (= (length ast) 2)))) (apply ast:make (cons (car ast) (cdr ast))))
      ((x) (apply ast:make x))
      (_ (throw 'match-error  (format #f "~a:ast:make: no match: ~a\n" (current-source-location) ast))))))

(define (make ast loc)
  (note-location (ast:make ast) loc))

(define (object? lst) #t)

(define (object-id lst)
  (and=> lst (compose pointer-address scm->pointer)))

(if (not (defined? 'supports-source-properties?))
    (module-define! (current-module) 'supports-source-properties? pair?))

(define (note-location ast loc)
  (when (supports-source-properties? ast)
      (set-source-property! ast 'loc loc))
  ast)

(define (source-location lst)
  (source-property lst 'loc))

(define (source-location->source-properties loc)
  `((filename . ,(source-location-input loc))
    (line . ,(+ 1 (source-location-line loc)))
    (column . ,(+ 1 (source-location-column loc)))))

(define *eof-object*
  (call-with-input-string "" read-char))

(define (make-parser)
  (lalr-parser
   (driver: lr)
   ;; (out-table: "asd.out")
   (
    lbrace rbrace lparen rparen lbracket rbracket semicolon colon dot comma
    =
    Identifier
    in out interface component system
    behaviour namespace on
    illegal inevitable optional
    provides requires otherwise import
    if else reply return
    (left: or and ! * / + -)
    (left: bool enum void int)
    (nonassoc: == != <=>)
    )

   (program
    (model-list *eoi*) : $1)

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
    (interface Identifier lbrace type-list event-list optional-behaviour rbrace) : `(,$1 ,$2 ,$4 ,$5 ,$6))

   (component-spec
    (component Identifier lbrace port-list optional-behaviour rbrace) : `(,$1 ,$2 ,$4 ,$5))

   (system-spec
    (system Identifier lbrace port-list system-statement-list rbrace) : `(,$1 ,$2 ,$4 ,$5))

   (system-statement-list
    () : '(compound)
    (system-statement-list system-statement) : (append $1 (list $2)))

   (system-statement
    (bind) : $1
    (instance) : $1)

   (bind
    (compound-identifier <=> compound-identifier semicolon) : `(bind ,$1 ,$3))

   (instance
    (compound-identifier Identifier semicolon) : `(instance ,$1 ,$2))

   (import-spec
    (import Identifier semicolon) : `(,$1 ,$2))

   (event-list
    () : '(events)
    (event-list event) : (append $1 (list $2)))

   (event
    (event-direction type Identifier semicolon) : `(,$1 (,$2) ,$3))

   (event-direction
    (in) : 'in
    (out) : 'out)

   (port-list
    () : '(ports)
    (port-list port) : (append $1 (list $2)))

   (port
    (port-direction Identifier Identifier semicolon) : `(,$1 ,$2 ,$3))

   (port-direction
    (provides) : 'provides
    (requires) : 'requires)

   (type-list
    () : '(types)
    (type-list type-spec) : (append $1 (list $2)))

   (type-spec
    (enum-spec) : $1)

   (type
    (bool) : '(type bool)
    (int) : '(type int)
    (enum-identifier) : `(type ,$1)
    (void) : '(type void))

   (compound-type
    (type) : $1
    (Identifier dot type) : `(type ,$1 ,$3))

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
    (expression and expression) : `(and ,$1 ,$3)
    (expression or expression) : `(or ,$1 ,$3)
    (expression == expression) : `(== ,$1 ,$3)
    (expression != expression) : `(!= ,$1 ,$3)
    (compound-identifier) : $1)

   (type-identifier
    (Identifier) : $1)

   (optional-behaviour
    () : '(behaviour)
    (behaviour lbrace type-list variable-list function-list statement-list rbrace) : `(,$1 #f ,$3 ,$4 ,$5 ,$6)
    (behaviour Identifier lbrace type-list variable-list function-list statement-list rbrace) : `(,$1 ,$2 ,$4 ,$5 ,$6 ,$7))

   (function
    (type Identifier lparen rparen compound-statement) : `(function ,$2 (,$1) ,$5)
    (type Identifier lparen parameter-list rparen compound-statement) : `(function ,$2 (,$1 ,$4) ,$6))

   (parameter-list
    (parameter) : `(parameters ,$1)
    (parameter-list comma parameter) : (append $1 (list $3)))

   (parameter
    (type Identifier): `(,$1 ,$2))

   (function-list
    () : '(functions)
    (function) : `(functions ,$1) ;; FIXME?
    (function-list function) : (append $1 (list $2)))

   (statement-list
    () : '(compound)
    (statement-list statement) : (append $1 (list $2)))

   (statement
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

   (guarded-statement
    (lbracket guard rbracket statement) : (make `(guard ,$2 ,$4) @1))

   (guard
    (expression) : $1
    (otherwise) : $1)

   (compound-statement
    (lbrace statement-list rbrace) : $2)

   (compound-identifier
    (Identifier) : $1
    (Identifier dot Identifier) : `(value ,$1 ,$3)
    (Identifier dot Identifier dot Identifier) : `(literal ,$1 ,$3 ,$5))

   (on-event-statement
    (on trigger-spec colon statement) : (make `(,$1 ,$2 ,$4) @1))

   (trigger-spec
    (trigger-list) : $1
    (optional) : `(,$1)
    (inevitable) : `(,$1))

   (trigger-list
    (trigger) : `(,$1)
    (trigger-list comma trigger) : (append $1 (list $3)))

   (trigger
    (compound-trigger) : $1)

   (compound-trigger
    (Identifier) : $1

    (Identifier dot Identifier) : `(trigger ,$1 ,$3))

   (illegal-statement
    (illegal semicolon) : $1)

   (assignment-statement
    (Identifier = expression semicolon) : `(assign ,$1 ,$3))

   (action-statement
    (trigger semicolon) : `(action ,$1))

   (if-statement
    (if lparen expression rparen statement) : `(if ,$3 ,$5)
    (if lparen expression rparen statement else statement) : `(if ,$3 ,$5 ,$7))

   (reply-statement
    (reply lparen expression rparen semicolon) : `(,$1 ,$3))

   (return-statement
    (return semicolon) : `(return)
    (return expression semicolon) : `(return ,$2))

   (variable-statement
    (compound-type Identifier = expression semicolon) : `(variable ,$1 ,$2 ,$4))

   (variable-list
    () : '(variables)
    (variable-list variable) : (append $1 (list $2)))

   (variable
    (type Identifier = expression semicolon) : `(variable ,$1 ,$2 ,$4))))

(define (compile-tree-il exp env opts)
  (values (parse-tree-il (comp exp '())) env env))

(define (comp src e)
  (match src
    (() (exit))
    (tree `(const ,tree))))

(define ast-> (@ (language asd pretty) ast->))
