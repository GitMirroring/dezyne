;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

;;; Commentary:
;;
;; @subheading Gaiag AST accessors
;;
;;   (read-dzn "examples/Alarm.dzn")
;;     ==>
;;    AST
;;       (
;;          (interface Console (types) (events) (behaviour))
;;           ^class    ^name   ^types  ^events  ^behaviour
;;
;;          (component Alarm   (ports) (behaviour))
;;           ^class    ^name   ^ports  ^behaviour
;;
;;          (system    AlarmSystem  (ports) (compound)) *see below
;;          ^class    ^name        ^ports  ^statement
;;         )
;;
;;
;;   (ast:types (ast:interface AST))
;;      ==>
;;   SUB-AST
;;      := ((enum     States (Disarmed Armed Triggered Disarming)))
;;           ^type    ^name  ^fields
;;           |implicit: class=type
;;
;;   (ast:types (ast:interface (read-dzn "examples/Typedef.dzn")))
;;      ==>
;;      := (enum ....)
;;         (int     Typedef (range   0     3)
;;          ^type   ^name    ^range  ^from ^to
;;          |implicit: class=type
;;
;;
;;   (ast:events (ast:interface AST))
;;      ==>
;;   SUB-AST
;;      := ((in           ((type void))  arm)  virtual base class: (event (type void) arm)
;;           ^direction   ^signature     ^name
;;           |implicit: class=event
;;
;;  note:  (ast:return-type '((type void))) --> '(type void)
;;
;;   (ast:behaviour (ast:interface AST))
;;      ==>
;;   SUB-AST
;;      := (behaviour b      (types) (variables) (function) (compound))
;;          ^class    ^name  ^types  ^variables  ^functions  ^statement
;;
;;
;;   (ast:ports (ast:interface AST))
;;      ==>
;;   SUB-AST
;;      := ((provides     Console console))
;;           ^direction   ^type   ^name
;;           |implicit: class=port
;;
;;  note:  (ast:interface port-name) --> '(interface Console ..))
;;  TODO:  (ast:interface port) --> '(interface Console ..))
;;
;;
;;   (ast:variables (ast:behaviour (ast:interface AST)))
;;      ==>
;;   SUB-AST
;;      := ((variable States state  (value States Disarmed))
;;           ^class   ^type  ^name  ^expression
;;
;;   (ast:functions (ast:behaviour (ast:interface AST)))
;;      ==>
;;   SUB-AST
;;      := ((function name  ((type void)  (parameters (parameter ((type bool) b)))         (compound)))
;;           ^class   ^name ^type         ^parameters ^parameter              ^identifier   ^statement
;;                           |signature
;;
;;
;;   (ast:parameters function)
;;      ==>
;;   SUB-AST
;;     :=  ( ((type bool) a)))
;;           ^^type ^name ^name
;;           |parameter
;;
;;
;;   (call   f            (arguments a b c)
;;    ^class ^identifier  ^a..-list  ^arguments
;;
;;
;;
;;   (ast:arguments call)
;;      ==>
;;   SUB-AST
;;     :=  ( ((type bool) a)))
;;           ^^type ^name ^name
;;           |parameter
;;
;;
;;   (ast:triggers (ast:component AST))
;;      ==>
;;   SUB-AST
;;      (trigger  console      arm)
;;       ^class  ^port-name   ^event-name  ;; FIXME: port / event?
;;
;;   SUB-AST
;;      (value  type    field)
;;       ^class ^type   ^field
;;
;;   SUB-AST
;;      (literal  Interface    type    field)
;;       ^class   ^scope       ^type   ^field
;;
;;   SUB-AST
;;      (action (trigger console arm))
;;       ^class ^trigger
;;
;;  (read-dzn "examples/AlarmSystem.dzn")
;;     ==>
;;    AST
;;       (
;;          (system    AlarmSystem  (ports) (compound)) *see below
;;          ^class    ^name        ^ports  ^statement
;;         )
;;
;;
;;   (ast:instances (ast:system AST))
;;      ==>
;;   SUB-AST
;;      := ((instance     Alarm   alarm))
;;           ^class       ^type   ^name
;;
;;
;;   (ast:binds (ast:system AST))
;;      ==>
;;   SUB-AST
;;    := ((bind   console (value alarm console)))
;;         ^class  ^left  ^right
;;
;;
;;; Code:

(read-set! keywords 'prefix)

(define-module (g ast)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)

  :use-module (srfi srfi-1)
  :use-module (system foreign)

  :use-module (g misc)
  :use-module (language dezyne parse)  
  :use-module (g reader)

  :export (
	   event-name
	   literal?
	   port-name
	   return-type
	   scope
	   signature
	   signature?
           Class
           action?
           collect
           ast?
           argument-list
           argument-list?
           arguments
           arguments?
           assign?
           ast
           behaviour
           behaviour?
           bind?
           binding-list
           binding-list?
           plug?
           bindings
           binds
           body
           bool?
           booleans
           bottom?
           call?
           class
           component
           component?
           components
           compound?
           declarative?
           def
           dir-matches?
           direction
           ;;xelse
           elements
           enum?
           enums
           event
           event-list
           event-list?
           event?
           events
           events?
           expression
           expression?
           extern?
           field
           field?
           fields
           find-events
           find-triggers
           from
           function
           function-list
           function-list?
           function?
           functions
           globals
           guard-equal?
           guard?
           identifier
           if?
           illegal?
           import?
           in?
           instance
           instance-list
           instance-list?
           instance?
           instances
           instances?
           int?
           integers
           interface
           interface-types           
           interface?
           interfaces
           is?
           is-a?
           left
           make
           member-names
           member-values
           model?
           name
           named           
           on?
           out?
           parameter
           parameter-list
           parameter-list?
           parameter?
           parameters
           parameters?
           parent
           port
           port-list
           port-list?
           port?
           ports
           provides?
           range
           range?
           recursive
           register
           reply?
           requires?
           return?
           right
           root?
           statement
           statement-list?
           statement?
           statements-of-type
           system
           system?
           then
           to
           trigger
           trigger-list
           trigger-list?
           trigger?
           triggers
           triggers?
           type
           type-list
           type-list?
           type-name-component
           type?
           typed?
           types
           types?
           user-type?
           value
           value?
           var?
           variable
           variable-list
           variable-list?
           variable?
           variables
           variables?
           ))

(define (make type ast)
  ((@@ (language dezyne parse) ast:make) type ast))

(define (ast? ast)
  (or
   (root? ast)
   (model? ast)
   (statement? ast)))

;;(define (statement? ast) ((@@ (language dezyne parse) ast:statement?) ast))

(define (statement? o)
  (and (pair? o)
       (member (car o)
               '(action assign bind call compound guard if illegal instance on reply variable return))))

(define (element ast name)
  (or (and (>2 (length ast)) (assoc name (body ast))) '()))

(define (argument-list ast) (element ast 'arguments))
(define (binding-list ast) (element ast 'bindings))
(define (event-list ast) (element ast 'events))
(define (function-list ast) (element ast 'functions))
(define (instance-list ast) (element ast 'instances))
(define (parameter-list ast) (or (assoc 'parameters (body ast)) '()))
(define (port-list ast) (element ast 'ports))
(define (trigger-list ast) (element ast 'triggers))
(define (type-list ast) (element ast 'types))
(define (variable-list ast) (element ast 'variables))

(define (model? ast) (or (interface? ast) (component? ast) (system? ast)))
(define (user-type? ast) (or (enum? ast) (extern? ast) (int? ast)))

(define (is-a? ast type)
  ((is? type) ast))

(define ((is? type) ast)
  (and (pair? ast)
       (let ((head (car ast)))
         (case type
           ((event) (member head '(in out)))
           ((port) (member head '(provides requires)))
           ((trigger) (or (member head '(inevitable optional))
                          (eq? head type)))
           ((type) (or (eq? head 'type)
                       (enum? ast) (extern? ast) (int? ast)))
           (else (eq? head type))))
       ast))

;; FIXME
(define (type-helper? type ast)
  ((is? type) ast))
(define (action? ast) (type-helper? 'action ast))
(define (argument-list? ast) (type-helper? 'arguments ast))
(define (arguments? ast) (type-helper? 'arguments ast))
(define (assign? ast) (type-helper? 'assign ast))
(define (behaviour? ast) (type-helper? 'behaviour ast))
(define (bind? ast) (type-helper? 'bind ast))
(define (plug? ast) (type-helper? 'plug ast))
(define (bindings? ast) (type-helper? 'bindings ast))
(define (binding-list? ast) (type-helper? 'bindings ast))
(define (bool? ast) (type-helper? 'bool ast))
(define (call? ast) (type-helper? 'call ast))
(define (component? ast) (type-helper? 'component ast))
(define (compound? ast) (type-helper? 'compound ast))
(define (enum? ast) (type-helper? 'enum ast))
(define (event-list? ast) (type-helper? 'events ast))
(define (event? ast) (type-helper? 'event ast))
(define (events? ast) (type-helper? 'events ast))
(define (expression? ast) (type-helper? 'expression ast))
(define (extern? ast) (type-helper? 'extern ast))
(define (field? ast) (type-helper? 'field ast))
(define (function-list? ast) (type-helper? 'functions ast))
(define (function? ast) (type-helper? 'function ast))
(define (functions? ast) (type-helper? 'functions ast))
(define (guard? ast) (type-helper? 'guard ast))
(define (illegal? ast) (type-helper? 'illegal ast))
(define (if? ast) (type-helper? 'if ast))
(define (import? ast) (type-helper? 'import ast))
(define (instance? ast) (type-helper? 'instance ast))
(define (instance-list? ast) (type-helper? 'instances ast))
(define (instances? ast) (type-helper? 'instances ast))
(define (int? ast) (type-helper? 'int ast))
(define (interface? ast) (type-helper? 'interface ast))
(define (literal? ast) (type-helper? 'literal ast))
(define (on? ast) (type-helper? 'on ast))
(define (parameter-list? ast) (type-helper? 'parameters ast))
(define (parameter? ast) (type-helper? 'parameter ast))
(define (parameters? ast) (type-helper? 'parameters ast))
(define (port-list? ast) (type-helper? 'ports ast))
(define (port? ast) (type-helper? 'port ast))
(define (ports? ast) (type-helper? 'ports ast))
(define (range? ast) (type-helper? 'range ast))
(define (reply? ast) (type-helper? 'reply ast))
(define (return? ast) (type-helper? 'return ast))
(define (root? ast) (type-helper? 'root ast))
(define (signature? ast) (type-helper? 'signature ast))
(define statement-list? compound?)
(define (system? ast) (type-helper? 'system ast))
(define (trigger? ast) (type-helper? 'trigger ast))
(define (trigger-list? ast) (type-helper? 'triggers ast))
(define (triggers? ast) (type-helper? 'triggers ast))
(define (type-list? ast) (type-helper? 'types ast))
(define (type? ast) (type-helper? 'type ast))
(define (types? ast) (type-helper? 'types ast))
(define (value? ast) (type-helper? 'value ast))
(define (var? ast) (type-helper? 'var ast))
(define (variable-list? ast) (type-helper? 'variables ast))
(define (variable? ast) (type-helper? 'variable ast))
(define (variables? ast) (type-helper? 'variables ast))

(define (body ast)
  (match ast
    ((or (? behaviour?) (? call?) (? model?))
     (or (and (>2 (length ast)) (cddr ast)) '()))
    ((or  (? arguments?) (? bindings?) (? compound?) (? events?) (? functions?) (? guard?) (? instances?) (? on?) (? parameters?) (? ports?) (? root?) (? signature?) (? triggers?) (? types?) (? variables?))
     (cdr ast))
    ;; be permissive for events, imports ports, types, variable
    ((('in type name) t ...) ast)
    ((('out type name) t ...) ast)
    ((('requires type name) t ...) ast)
    ((('provides type name) t ...) ast)
    ((('enum type elements) t ...) ast)
    ((('variable type name expression) t ...) ast)
    ('() ast)
    (_ (throw 'match-error  (format #f "~a:body: no match: ~a\n" (current-source-location) ast)))))

(define (elements ast)
  (cdr ast))

(define (interface- ast)
  (match ast
    ((? component?) #f)
    ((? interface?) ast)
    ((? root?) (interface- (body ast)))
    ((h t ...) (assoc 'interface ast))))

(define (component- ast)
  (match ast
    ((? component?) ast)
    ((? root?) (component- (body ast)))
    ((h t ...) (assoc 'component ast))))

(define (system- ast)
  (match ast
    ((? system?) ast)
    ((? root?) (system- (body ast)))
    ((h t ...) (assoc 'system ast))))

(define ((model model-) ast)
  (and-let* ((model-ast (model- ast))
             (name (name model-ast)))
            (if (not (assoc-ref *ast-alist* name))
                (ast-add name model-ast))
            model-ast))

(define (component ast) ((model component-) ast))
(define (interface ast) ((model interface-) ast))
(define (system ast) ((model system-) ast))

(define (interfaces ast)
  (filter (lambda (x) (interface? x)) ast))

(define (models ast)
  (filter (lambda (x) (model? x)) ast))

(define (register-type t)
  (and-let* ((name (name t)))
            (if (not (assoc-ref *ast-alist* name))
                (ast-add name t))
            t))

(define (globals)
  (filter type? (map cdr *ast-alist*)))

(define* (register ast :optional (clear? #f))
  (if clear?
      (set! *ast-alist* '()))
  (for-each (lambda (x) ((model (case (class x)
                                  ((interface) interface-)
                                  ((component) component-)
                                  ((system) system-))) x)) (models ast))
  (for-each register-type (filter type? ast))
  ast)

(define (recursive ast)
  (match ast
    ((? function?) (cadddr ast))
    (_ (throw 'match-error (format #f "~a:recursive: no match: ~a\n" (current-source-location) ast)))))

(define (arguments ast)
  (match ast
    ((? call?) (body (if (>2 (length ast)) (caddr ast) '())))
    (_ (throw 'match-error (format #f "~a:arguments: no match: ~a\n" (current-source-location) ast)))))

(define (value ast)
  (match ast
    ((? expression?) (cadr ast))
    (('otherwise) 'otherwise)
    (('otherwise value) value)    
    (_ (throw 'match-error (format #f "~a:value: no match: ~a\n" (current-source-location) ast)))))

(define (left ast)
  (match ast
    ((? bind?) (cadr ast))
    (_ (throw 'match-error (format #f "~a:left: no match: ~a\n" (current-source-location) ast)))))

(define (right ast)
  (match ast
    ((? bind?) (caddr ast))
    (_ (throw 'match-error (format #f "~a:right: no match: ~a\n" (current-source-location) ast)))))

(define (binds ast)
  (match ast
    ((? compound?) ((statements-of-type 'bind) ast))
    ((? system?) (binds (statement ast)))
    ((? model?) '())
    (_ (throw 'match-error (format #f "~a:binds: no match: ~a\n" (current-source-location) ast)))))

(define (instances ast)
  (match ast
    ((? compound?) ((statements-of-type 'instance) ast))
    ((? system?) (body (instance-list ast)))
    ((? model?) '())
    (_ (throw 'match-error (format #f "~a:instances: no match: ~a\n" (current-source-location) ast)))))

(define (bindings ast)
  (match ast
    ((? system?) (body (binding-list ast)))
    (_ (throw 'match-error (format #f "~a:bindings: no match: ~a\n" (current-source-location) ast)))))

(define (event-name ast)
  (match ast
    ((? action?) (cadr ast))
    ((? symbol?) ast)
    ((or ('inevitable) ('optional)) (car ast))
    ((? trigger?) (caddr ast))
    (_ (throw 'match-error  (format #f "~a:event-name: no match: ~a\n" (current-source-location) ast)))))

(define (trigger ast)
  (match ast
    ((? action?) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:trigger: no match: ~a\n" (current-source-location) ast)))))

(define* (event ast :optional (identifier #f))
  (match identifier
    (#f (match ast
          ((? action?)
           (stderr "deprecated: event; use event-name\n")
           (event-name ast))
          (_ (throw 'match-error  (format #f "~a:event: no match: ~a\n" (current-source-location) ast)))))
    ((? symbol?)
     (find (lambda (e) (eq? (name e) identifier))
           (body
            (match ast
              ((? events?) ast)
              ((? interface?) (event-list ast))
              (_ (throw 'match-error  (format #f "~a:event: no match: ~a\n" (current-source-location) ast)))))))))

(define (parameters ast)
  (match ast
    ((? function?) (parameters (signature ast)))
    ((? signature?) (body (if (>2 (length ast)) (caddr ast) '())))
    (_ (throw 'match-error  (format #f "~a:parameters: no match: ~a\n" (current-source-location) ast)))))

(define (scope ast)
  (match ast
    ((? literal?) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:scope: no match: ~a\n" (current-source-location) ast)))))

(define (signature ast)
  (match ast
    ((? event?) (cadr ast))
    ((? function?) (caddr ast))
    (_ (throw 'match-error  (format #f "~a:signature: no match: ~a\n" (current-source-location) ast)))))

(define* (variable ast #:optional (identifier #f))
  (if identifier
      (match ast
        ((? component?) (variable (variables ast) identifier))
        ((? interface?) (variable (variables ast) identifier))
        ((? variable?) (if (eq? (name ast) identifier) ast #f))
        ((h ...) (and=> (null-is-#f (filter identity (map (lambda (x) (variable x identifier)) ast))) car))
        (_ (throw 'match-error  (format #f "~a:variable: no match: ~a\n" (current-source-location) ast))))
      (match ast
        ((? assign?) (cadr ast))
        (_ (throw 'match-error  (format #f "~a:variable: no match: ~a\n" (current-source-location) ast))))))

(define (identifier ast)
  (match ast
    ((? assign?) (cadr ast))
    ((? call?) (cadr ast))
    ((? field?) (cadr ast))
    ((? parameter?) (cadr ast))
    ((? var?) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:identifier: no match: ~a\n" (current-source-location) ast)))))

(define (return-type ast)
  (match ast
    ((or (? event?) (? function?)) (return-type (signature ast)))
    ((? signature?) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:return-type: no match: ~a\n" (current-source-location) ast)))))

(define (events ast)
  (match ast
    ((? interface?) (body (event-list ast)))
    ((? component?) (triggers ast))
    ((? port?) (events (import-ast (type ast))))
    (_ (throw 'match-error  (format #f "~a:events: no match: ~a\n" (current-source-location) ast)))))

(define (triggers ast)
  (match ast
    ((? interface?) (stderr "deprecated: use events\n") (events ast))
    ((? component?) (triggers (statement ast)))
    ((? on?) (triggers (cadr ast)))
    ((? trigger-list?) (body ast))
    ((? port?) (stderr "deprecated: use events\n") (events ast))
    ((? compound?) (apply append (map triggers ((statements-of-type 'on) ast))))
    (_ (throw 'match-error  (format #f "~a:triggers: no match: ~a\n" (current-source-location) ast)))))

(define (behaviour ast)
  (match ast
    ((? model?) (element ast 'behaviour))
    ((? port?) (behaviour (import-ast (type ast))))
    (_ (throw 'match-error  (format #f "~a:behaviour: no match: ~a\n" (current-source-location) ast)))))

(define (ports ast)
  (match ast
    ((or (? component?) (? system?)) (body (port-list ast)))
    ((? interface?) '())
    (_ (throw 'match-error  (format #f "~a:ports: no match: ~a\n" (current-source-location) ast)))))

(define (imports ast) (filter import? ast))

(define (function ast identifier)
  (find (lambda (p) (eq? (name p) identifier))
        (match ast
          ((? functions?) (body ast))
          ((or (? component?) (? interface?)) (functions ast))
          (_ (throw 'match-error  (format #f "~a:function: no match: ~a\n" (current-source-location) ast))))))

(define (port-name ast)
  (match ast
    ((? action?) (cadr ast))
    ((? port?) (name ast))
    ((or ('inevitable) ('optional)) #f)
    ((? trigger?) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:port-name: no match: ~a\n" (current-source-location) ast)))))

(define* (port ast :optional (identifier #f))
  (match identifier
    (#f (match ast
          ((or (? component?) (? system?)) (assoc 'provides (ports ast)))
          ((? action?) (stderr "deprecated: event; use port-name\n")
           (port-name ast))
          ((? plug?) (caddr ast))
          (_ (throw 'match-error  (format #f "~a:port: no match: ~a\n" (current-source-location) ast)))))
    ((? symbol?)
     (find (lambda (p) (eq? (name p) identifier))
           (body
            (match ast
              ((? ports?) ast)
              ((or (? component?) (? system?)) (port-list ast))
              (_ (throw 'match-error  (format #f "~a:port: no match: ~a\n" (current-source-location) ast)))))))
    ((? value?) (let* ((t (type identifier))
                       (f (field identifier))
                       (i (instance ast t)))
                  (if (eq? t f) ;; FIXME
                      (port (import-ast 'Alarm) f) ;; FIXME
                      (port (import-ast (type i)) f))))
    (_ (throw 'match-error  (format #f "~a:port: no match: ~a\n" (current-source-location) ast)))))

(define (instance- ast identifier)
  (find (lambda (i) (eq? (name i) identifier))
        (match ast
          ((? system?) (instances ast))
          ((h ...) ast)
          (_ (throw 'match-error  (format #f "~a:instance-: no match: ~a\n" (current-source-location) ast))))))

(define* (instance ast :optional (identifier #f))
  (match identifier
    (#f (match ast
          ((? plug?) (cadr ast))
          (_ (throw 'match-error  (format #f "~a:instance: no match: ~a\n" (current-source-location) ast)))))
    ((? symbol?)
     (match ast
       ((? system?) (if (value? identifier)
                        (instance- ast (type identifier))
                       (or (instance- ast identifier)
                           (and-let* ((provides (port ast identifier))
                                      ((eq? (name provides) identifier)))
                                     identifier))))
       (_ (throw 'match-error  (format #f "~a:instance: no match: ~a\n" (current-source-location) ast)))))
    (_ (throw 'match-error  (format #f "~a:instance: no match: ~a\n" (current-source-location) ast)))))

(define (direction ast)
  (match ast
    ((or (? event?) (? port?)) (car ast))
    (_ (throw 'match-error  (format #f "~a:direction: no match: ~a\n" (current-source-location) ast)))))

(define (from ast)
  (match ast
    ((? int?) (from (range ast)))
    ((? range?) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:from: no match: ~a\n" (current-source-location) ast)))))

(define (to ast)
  (match ast
    ((? int?) (to (range ast)))
    ((? range?) (caddr ast))
    (_ (throw 'match-error  (format #f "~a:to: no match: ~a\n" (current-source-location) ast)))))

(define (range ast)
  (match ast
    ((? int?) (caddr ast))
    (_ (throw 'match-error  (format #f "~a:direction: no match: ~a\n" (current-source-location) ast)))))

(define (fields ast)
  (match ast
    (('enum name fields) fields)
    (('enum scope name fields) fields)    
    (_ (throw 'match-error  (format #f "~a:fields: no match: ~a\n" (current-source-location) ast)))))

(define (expression ast)
  (match ast
    ((? assign?) (caddr ast))
    ((? guard?) (cadr ast))
    ((? if?) (cadr ast))
    ((? reply?) (cadr ast))
    ((? return?) (if (>1 (length ast)) (cadr ast) '()))
    ((? variable?) (cadddr ast))
    (_ (throw 'match-error  (format #f "~a:expression: no match: ~a\n" (current-source-location) ast)))))

(define (in? ast)
  (match ast
    ((? event?) (eq? (direction ast) 'in))
    (_ (throw 'match-error  (format #f "~a:in?: no match: ~a\n" (current-source-location) ast)))))

(define (out? ast)
  (match ast ((? event?) (eq? (direction ast) 'out))
    (_ (throw 'match-error  (format #f "~a:out?: no match: ~a\n" (current-source-location) ast)))))

(define (name ast)
  (match ast
    (('enum scope name fields) name)
    (('int scope name range) name)
    (('extern scope name value) name)
    ((or (? behaviour?) (? enum?) (? extern?) (? function?) (? int?) (? model?) (? parameter?) (? type?) (? variable?)) (or (and (>1 (length ast)) (cadr ast)) ""))
    ((or (? event?) (? instance?) (? port?)) (caddr ast))
    ((? symbol?) ast)
    (_ (throw 'match-error  (format #f "~a:name: no match: ~a\n" (current-source-location) ast)))))

(define (class ast)
  (match ast
    ((? enum?) 'type)
    ((? event?) 'event)
    ((? int?) 'type)
    ((? port?) 'port)
    ('() #f)
    (#f #f)
    (_ (car ast))))

(define (Class ast)
  (symbol-capitalize (class ast)))

(define (then ast)
  (caddr ast))

(define (else ast)
  (if (> (length ast) 3) (cadddr ast) #f))

(define (statement ast)
  (match ast
    ((? system?) (or (assoc 'compound (body ast)) (make 'compound '())))
    ((? model?) (or (null-is-#f (statement (behaviour ast))) (make 'compound '())))
    ((? behaviour?) (or (assoc 'compound (body ast)) (make 'compound '())))
    ((or (? guard?) (? on?)) (caddr ast))
    ((? function?) (fifth ast))
    (_ (throw 'match-error  (format #f "~a:statement: no match: ~a\n" (current-source-location) ast)))))

(define (type ast)
  (match ast
    ((? event?)
     (stderr "deprecated: return-type event; use type signature\n")
     (return-type ast))
    ((or (? interface?) (? component?) (? system?)) (car ast))
    ((or (? enum?) (? int?)) (car ast))
    ((? function?) (type (signature ast)))
    ((? signature?) (cadr ast))
    ((or (? literal?) (? variable?)) (caddr ast))
    ((or (? parameter?) (? signature?)) (caddr ast))
    ((or (? instance?) (? port?) (? type?) (? value?)) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:type: no match: ~a\n" (current-source-location) ast)))))

(define ((def model) ast)
  (match ast
    ((? variable?)
     (let ((t ((compose name type) ast)))
       (cond ((eq? t 'bool) 'bool)
             ((eq? t 'void) 'void)
             (else (find (lambda (x) (eq? (name x) t)) (types model))))))
    (_ (throw 'match-error  (format #f "~a:type: no match: ~a\n" (current-source-location) ast)))))

(define (field ast)
  (match ast
    ((? field?) (caddr ast))
    ((? literal?) (cadddr ast))
    ((? value?) (caddr ast))
    (_ (throw 'match-error  (format #f "~a:field: no match: ~a\n" (current-source-location) ast)))))

(define (functions ast)
  (match ast
    ((? behaviour?) (body (function-list ast)))
    ((? interface?) (append (body (function-list ast))
                            (functions (behaviour ast))))
    ((? component?) (functions (behaviour ast)))
    ((? port?) (functions (import-ast (type ast))))
               (_ (throw 'match-error  (format #f "~a:functions: no match: ~a\n" (current-source-location) ast)))))

(define (interface-types port)
  (let ((scope (type port)))
   (map (lambda (o)
          (match o
            (('enum name fields) (list 'enum scope name fields))
            (('extern name value) (list 'extern scope name fields))
            (('int name range) (list 'int scope name range))))
        ((compose public-types ast type) port))))

(define (public-types ast)
  (match ast
    ((? interface?) (body (type-list ast)))
    (_ (throw 'match-error  (format #f "~a:public-types: no match: ~a\n" (current-source-location) ast)))))

(define (types ast)
  (match ast
    ((? behaviour?) (body (type-list ast)))
    ((? component?) (append (types (behaviour ast))
                            (apply append (map interface-types (ports ast)))
                            (filter user-type? *ast-alist*)))
    ((? interface?) (append (types (behaviour ast))
                            (body (type-list ast))
                            (filter user-type? *ast-alist*)))
    ((? port?) (types (import-ast (type ast))))
    ((? system?) '())
    ('() ast)
    (_ (throw 'match-error  (format #f "~a:types: no match: ~a\n" (current-source-location) ast)))))

(define (booleans ast)
  (filter bool? (types ast)))

(define (enums ast)
  (filter enum? (types ast)))

(define (integers ast)
  (filter int? (types ast)))

(define (variables ast)
  (match ast
    ((? behaviour?) (body (variable-list ast)))
    ((? interface?) (append (body (variable-list ast))
                            (variables (behaviour ast))))
    ((? component?) (variables (behaviour ast)))
    ((? port?) (variables (import-ast (type ast))))
    ('() '())
    (#f '())
    (_ (throw 'match-error  (format #f "~a:variables: no match: ~a\n" (current-source-location) ast)))))


;;;;; FIXME

(define (type-name-component type component) (symbol-append (name component) (type type)))

(define (enum-name enum) (cadr enum))

;;; utilities
(define (declarative? statement)
  (or (on? statement) (guard? statement)))

(define (provides? ast) (eq? (direction ast) 'provides))
(define (requires? ast) (eq? (direction ast) 'requires))

(define (guard-equal? lhs rhs) (equal? (expression lhs) (expression rhs)))

(define (typed? ast)
  (match ast
    ((? event?) (not (equal? (type (signature ast)) '(type void))))
    ((? port?) (null-is-#f (filter typed? (events ast))))
    (_ (throw 'match-error  (format #f "~a:typed?: no match: ~a\n" (current-source-location) ast)))))

(define (dir-matches? port)
  (lambda (event)
    (or (and (eq? (direction port) 'provides)
             (eq? (direction event) 'in))
        (and (eq? (direction port) 'requires)
             (eq? (direction event) 'out)))))

(define (f-is-null x)
  (or x '()))

(define (member-names model)
  (f-is-null (and=> (behaviour model) (lambda (b) (map name (variables b))))))

(define ((member-values value) model)
  (map (lambda (x) (value (expression x))) (variables (behaviour model))))

(define (bottom? ast)
  (and-let* ((ports (ports ast))
             ((=1 (length ports))))
            (provides? (car ports))))

(define ((named n) ast)
  (and (or (interface? ast) (component? ast) (system? ast))
       (eq? (name ast) n)))

;;; walkers

(define ((statement-of-type type) statement)
  (eq? (class statement) type))

;; FIXME: use filter??!
(define ((statements-of-type type) statement)
  (match statement
    ((? (statement-of-type type)) (list statement))
    (('compound t ...) (filter identity (apply append (map (statements-of-type type) t)))) ;; FIXME: do we want to go deep?! this is for flat list, no?
    (('guard expr s) (filter identity ((statements-of-type type) s)))
    ((? statement?) '())
    ('() '())
    ((t ...) (filter identity (apply append (map (statements-of-type type) t))))
    (_ (throw 'match-error  (format #f "~a:statements-of-type, type: ~a: no match: ~a\n" (current-source-location) type statement)))))

(define ((collect predicate) o)
  (match o
    (('compound t ...)
     (filter identity (apply append (map (collect predicate) t))))
    (('guard e s) (filter identity ((collect predicate) s)))
    (('on t s) (filter identity ((collect predicate) s)))
    ((? (compose null-is-#f predicate)) (list o))
    ;; TODO: component, interface, behaviour?
    (_ '())))

(define (parent ast lst)
  (if (object? lst)
    (id-parent ast (object-id lst))
    #f))

(define (id-parent ast id)
  (let loop ((ast ast) (stack '()))
    (if (null? ast)
        (if (null? stack)
            #f
            (loop (car stack) (cdr stack)))
        (let ((children (map object-id ast)))
          (if (member id children)
              ast
              (if (pair? (car ast))
                  (loop (car ast) (cons (cdr ast) stack))
                  (loop (cdr ast) stack)))))))

(define (trigger< lhs rhs)
  (if (and (symbol? lhs) (symbol? rhs) (symbol< lhs rhs))
      (if (and (pair? lhs) (pair? rhs)) (list< lhs rhs)
          (symbol? lhs))))

(define* (find-triggers ast :optional (found '()))
  "Search for optional and inevitable."
  (match ast
    ((or (? interface?) (? component?))
     (delete-duplicates (sort (find-triggers (statement (behaviour ast))) trigger<)))
    (('compound t ...) (append (apply append (map find-triggers t)) found))
    (('on t statement) (find-triggers t))
    (('trigger port event) ast)
    (('triggers triggers ...) triggers)
    (('guard expression statement) (find-triggers statement found))
    (('inevitable) ast)
    (('optional) ast)
    (('action x) '())
    (('illegal) '())
    (_ (throw 'match-error  (format #f "~a:find-triggers: no match: ~a\n" (current-source-location) ast)))))

(define (find-events ast)
  (match ast
    ((? interface?) (events ast))
    ((? component?) (apply append (map find-events (ports ast))))
    ((? port?) (find-events (import-ast (type port))))
    (_ (throw 'match-error  (format #f "~a:find-events: no match: ~a\n" (current-source-location) ast)))))

;;;; reading/caching
(define *ast-alist* '())
(define (ast-add name ast)
  (set! *ast-alist* (assoc-set! *ast-alist* name ast))
  ast)

;; procedure: ast:import MODEL-NAME
;;
;; Read and parse the ASD source file for MODEL-NAME, return its AST.
(define (read-ast model-name)
  (and-let* ((ast (null-is-#f (read-dzn (list model-name '.dzn))))
             (models (null-is-#f (models ast))))
            (find (lambda (model) (eq? (name model) model-name)) models)))

(define* (import-ast name #:optional (transform identity))
  "
procedure: ast:import MODEL-NAME

Read and parse the ASD source file for MODEL-NAME, return its AST.

"
  (or (assoc-ref *ast-alist* name)
      (and-let* ((ast (transform (read-ast name))))
                (ast-add name ast))))

;; procedure: ast:ast MODEL-NAME
;;
;; Read and parse the ASD source file for MODEL-NAME, return its AST.
(define ast import-ast)
