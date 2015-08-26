;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 optargs)
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

(define (make-parser)
  (lalr-parser
   (driver: lr)
   (out-table: "dezyne.out")
   (
    #{{}# #{}}# #{)}# #{]}# #{\;}# : #{,}#
    blocking on namespace #{[}#
    inevitable optional
    otherwise
    if reply return
    true false

    in inout out
    illegal
    behaviour import interface component system
    provides requires external injected
    bool enum extern subint void
    NumericLiteral Data
    $

    Identifier
    (left: #{.}# #{(}#)
    (nonassoc: = <=> ..)
    (left: #{||}#)
    (left: &&)
    (left: <- == != < > <= >=)
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
    (models model) : (append $1 (list $2))
    (models namespace name #{{}# models #{}}#) : (append $1 (map (add-scope $3) $5)))

   (name
    (#{.}# Identifier) : (note-location `(name * ,$2) @1)
    (name-pair) : $1
    (name #{.}# Identifier) : (append $1 `(,$3)))

   (name-pair
    (Identifier) : (note-location `(name ,$1) @1)
    (Identifier #{.}# Identifier) : (note-location `(name ,$1 ,$3) @1))

   (model
    (import-spec) : $1
    (type) : $1
    (interface-spec) : $1
    (component-spec) : $1)

   (import-spec
    (import Identifier #{\;}#) : `(,$1 ,$2)
    (import Identifier #{.}# Identifier #{\;}#) : `(,$1 ,(symbol-append $2 '. $4)))

   (type
    (enum-spec) : $1
    (extern-spec) : $1
    (subint-spec): $1)

   (interface-spec
    (interface name #{{}# events/types #{}}#)
    : (receive (e t)
          (partition event? $4)
        (note-location `(,$1 ,$2 ,(cons 'types (map (add-scope $2) t)) ,(cons 'events (map (add-scope $2) e))) @1))
    (interface name #{{}# events/types behaviour-spec #{}}#)
    : (receive (e t)
          (partition event? $4)
        (note-location `(,$1 ,$2 ,(cons 'types (map (add-scope $2) t)) ,(cons 'events (map (add-scope $2) e)) ,((add-scope $2) $5)) @1)))

   (component-spec
    (component name #{{}# ports #{}}#)
    : (note-location `(,$1 ,$2 ,$4) @1)
    (component name #{{}# ports behaviour-spec #{}}#)
    : (note-location `(,$1 ,$2 ,$4 ,$5) @1)
    (component name #{{}# ports system #{{}# instances/binds #{}}# #{}}#)
    : (receive (instances binds)
          (partition (lambda (x) (eq? (car x) 'instance)) $7)
        (note-location `(system ,$2 ,$4 ,(cons 'instances instances) ,(cons 'bindings binds)) @1)))

   (instances/binds
    () : '()
    (instances/binds instance/bind) : (append $1 (list $2)))

   (instance
    (name Identifier #{\;}#) : `(instance ,$2 ,$1))

   (instance/bind
    (instance) : $1
    (bind) : $1)

   (bind
    (binding <=> binding #{\;}#) : `(bind ,$1 ,$3))

   (binding
    (*) : `(binding #f *)
    (Identifier) : `(binding #f ,$1)
    (Identifier #{.}# Identifier) : `(binding ,$1 ,$3))

   (events/types
    () : '()
    (events/types event/type) : (append $1 (list $2)))

   (event/type
    (event) : $1
    (type) : $1)

   (event
    (event-direction variable-type Identifier #{\;}#) : `(event ,$3 ,(note-location `(signature ,$2) @2) ,$1)
    (event-direction variable-type Identifier #{(}# #{)}# #{\;}#) : `(event , $3 ,(note-location `(signature ,$2) @2) ,$1)
    (event-direction variable-type Identifier #{(}# formals #{)}# #{\;}#) : `(event ,$3 ,(note-location `(signature ,$2 ,$5) @2) ,$1))

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
    (port-direction name Identifier #{\;}#) : `(port ,$3 ,$2 ,$1 #f #f)
    (port-direction external name Identifier #{\;}#) : `(port ,$4 ,$3 ,$1 ,$2 #f)
    (port-direction injected name Identifier #{\;}#) : `(port ,$4 ,$3 ,$1 #f ,$2)
    (port-direction external injected name Identifier #{\;}#) : `(port ,$5 ,$4 ,$1 ,$2 ,$3)
    (port-direction injected external name Identifier #{\;}#) : `(port ,$5 ,$4 ,$1 ,$3 ,$2))

   (port-direction
    (provides) : 'provides
    (requires) : 'requires)

   (optional-types
    () : '(types)
    (optional-types type) : (append $1 (list $2)))

   (variable-type
    (bool) : '(type bool)
    (void) : '(type void)
    (name) : (note-location `(type ,$1) @1))

   (enum-spec
    (enum Identifier #{{}# enum-fields #{}}# #{\;}#) : (note-location `(enum (name ,$2) ,$4) @1))

   (enum-fields
    (Identifier) : `(fields ,$1)
    (enum-fields #{,}# Identifier) : (append $1 (list $3)))

   (subint-spec
    (subint Identifier #{{}# integer .. integer #{}}# #{\;}#) : (note-location `(int (name ,$2) (range ,$4 ,$6)) @1))

   (integer
    (NumericLiteral): $1
    (- NumericLiteral): (- $2))

   (extern-spec
    (extern Identifier Data #{\;}#) : (note-location `(extern (name ,$2) ,$3) @1))

   (expression
    (expr): `(expression ,$1))

   (expr
    (false) : $1
    (true) : $1
    (integer) : $1
    (name) : $1
    (Data) : (note-location `(data ,$1) @1)

    (#{(}# expr #{)}#) : `(group ,$2)

    (! expr) : `(! ,$2)
    (expr && expr) : `(and ,$1 ,$3)
    (expr #{||}# expr) : `(or ,$1 ,$3)

    (expr <- expr) : `(<- ,$1 ,$3)
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
    (Identifier #{(}# #{)}#) : (note-location `(call ,$1 (arguments) #f) @1)
    (Identifier #{(}# arguments #{)}#) : (note-location `(call ,$1 ,$3 #f) @1))

   (arguments
    (expression) : `(arguments ,$1)
    (arguments #{,}# expression) : (append $1 (list $3)))

   (behaviour-spec
    (behaviour optional-identifier #{{}# optional-types #{}}#)
    : `(,$1 ,$2 ,$4)
    (behaviour optional-identifier #{{}# optional-types functions/statements/variables #{}}#)
    : (receive (f r)
          (partition (lambda (x) (eq? (car x) 'function)) $5)
        (receive (s v)
            (partition (lambda (x) (not (eq? (car x) 'variable))) r)
          `(,$1 ,$2 ,$4 ,(cons 'variables v) ,(cons 'functions f) ,(note-location (cons 'compound s) @1)))))

   (optional-identifier
    () : #f
    (Identifier): $1)

   (function
    (variable-type Identifier #{(}# #{)}# compound-statement) : (note-location `(function ,$2 ,(note-location `(signature ,$1) @1), #f ,$5) @1)
    (variable-type Identifier #{(}# formals #{)}# compound-statement) : (note-location `(function ,$2 ,(note-location `(signature ,$1 ,$4) @1) #f ,$6) @1))

   (formals
    (formal) : `(formals ,$1)
    (formals #{,}# formal) : (append $1 (list $3)))

   (formal
    (variable-type Identifier): (note-location `(formal ,$2 ,$1) @1)
    (formal-direction variable-type Identifier): (note-location `(formal ,$3 ,$2 ,$1) @1))

   (statements
    () : (list 'compound)
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
    (blocking-statement) : $1
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

   (blocking-statement
    (blocking statement) : (note-location `(blocking ,$2) @1))

   (function-call-statement
    (function-call #{\;}#) : $1)

   (guarded-statement
    (#{[}# guard #{]}# statement) : (note-location `(guard ,$2 ,$4) @1))

   (guard
    (expression) : $1
    (otherwise) : `(,$1))

   (compound-statement
    (#{{}# statements #{}}#) : (note-location $2 @1))

   (on-event-statement
    (on trigger-spec : statement) : (note-location `(,$1 ,$2 ,$4) @1))

   (trigger-spec
    (triggers) : (note-location (cons 'triggers $1) @1)
    (optional) : (note-location `(triggers ,(note-location `(trigger #f ,$1 (arguments)) @1)) @1)
    (inevitable) : (note-location `(triggers ,(note-location `(trigger #f ,$1 (arguments)) @1)) @1))

   (triggers
    (trigger) : `(,$1)
    (triggers #{,}# trigger) : (append $1 (list $3)))

   (trigger
    (Identifier) : (note-location `(trigger #f ,$1 (arguments)) @1)
    (Identifier #{(}# #{)}#) : (note-location `(trigger #f ,$1 (arguments)) @1)
    (Identifier #{.}# Identifier) : (note-location `(trigger ,$1 ,$3 (arguments)) @1)
    (Identifier #{.}# Identifier #{(}# #{)}#) : (note-location `(trigger ,$1 ,$3 (arguments)) @1)
    (Identifier #{(}# arguments #{)}#) : (note-location `(trigger #f ,$1 ,$3) @1)
    (Identifier #{.}# Identifier #{(}# arguments #{)}#) : (note-location `(trigger ,$1 ,$3 ,$5) @1))

   (illegal-statement
    (illegal #{\;}#) : (note-location `(illegal) @1))

   (assignment-statement
    (Identifier = expression #{\;}#) : (note-location `(assign ,$1 ,$3) @1)
    (Identifier #{.}# Identifier = expression #{\;}#) : (note-location `(assign (name ,$1 ,$3) ,$5) @1))

   (action
    (name-pair #{(}# #{)}#) : (rsp $1 `(action ,(make-trigger $1)))
    (name-pair #{(}# arguments #{)}#) : (rsp $1 `(action ,(make-trigger $1 $3))))

   (action-statement
    (name-pair #{\;}#) : (rsp $1 `(action ,(make-trigger $1)))
    (action #{\;}#) : $1)

   (if-statement
    (if #{(}# expression #{)}# statement) : (note-location `(if ,$3 ,$5) @1)
    (if #{(}# expression #{)}# statement else statement) : (note-location `(if ,$3 ,$5 ,$7) @1))

   (reply-statement
    (reply #{(}# #{)}# #{\;}#) : (note-location `(,$1 (expression)) @1)
    (reply #{(}# expression #{)}# #{\;}#) : (note-location `(,$1 ,$3) @1)
    (Identifier #{.}# reply #{(}# #{)}# #{\;}#) : (note-location `(,$3 (expression) ,$1) @1)
    (Identifier #{.}# reply #{(}# expression #{)}# #{\;}#) : (note-location `(,$3 ,$5 ,$1) @1))

   (return-statement
    (return #{\;}#) : (note-location '(return) @1)
    (return expression #{\;}#) : (note-location `(return ,$2) @1))

   (variable
    (variable-type Identifier #{\;}#) : `(variable ,$2 ,$1 (expression))
    (variable-type Identifier = expression #{\;}#) : `(variable ,$2 ,$1 ,(note-location $4 @2)))

   (variables
    (variable) : `(variables ,$1)
    (variables variable) : (append $1 (list $2)))))

(define (event? x) (eq? (car x) 'event))

(define (stderr string . rest)
  (apply format (cons* (current-error-port) string rest)))

(define* (make-trigger o #:optional (arguments '(arguments)))
  (match o
    ((? symbol?) `(trigger #f o ,arguments))
    (('name event) `(trigger #f ,event ,arguments))
    (('name port event) `(trigger ,port ,event ,arguments))))

(define ((add-scope scope) o)
  (rsp o ((add-scope- scope) o)))

(define ((add-scope- scope) o)
  ;;(stderr "ADD-SCOPE[~a]: ~a\n" scope o)
  (if (or (and (pair? scope) (eq? (car scope) '*))) o
      (match o
        (('name '* scope ...) o)
        (('name name) o)
        (('name name ...) (append scope name))
        (('guard expression statement)
         `(guard ,expression ,((add-scope scope) statement)))
        (((and (or 'enum 'extern 'int) (get! type)) ('name name ...) spec)
         (list (type) (append scope name) spec))
        ((h t ...) (map (add-scope scope) o))
        (_ o))))

(define (compile-tree-il exp env opts)
  (values (parse-tree-il (comp exp '())) env env))

(define (comp src e)
  (match src
    (() (exit))
    (tree `(const ,tree))))
