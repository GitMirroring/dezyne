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

;;; Commentary:
;;
;; @subheading Gaiag AST accessors
;;
;;   (read-asd "examples/Alarm.asd")
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
;;      := ((enum     States (Disarmed Armed Triggered Disarming))
;;           ^type    ^name  ^elements
;;           |implicit: class=type
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
;;      := ((function name  ((type void)  (parameters (((type bool) b))) (compound)))
;;           ^class   ^name ^^return-type ^parameters ^parameter         ^statement
;;                          |signature    
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
;;   (call   f      (arguments a b c)
;;    ^class ^name  ^arguments
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
;;       ^class  ^port-name   ^event-name
;;
;;
;;   (ast:types (ast:interface ast))
;;      ==>
;;   SUB-AST
;;      (value  type    field)
;;       ^class ^type   ^field
;;
;;   FIXME (ast:types (ast:interface ast))
;;      ==>
;;   SUB-AST
;;      (literal  Interface    type    field)
;;       ^class   ^scope       ^type   ^field
;;
;;
;;   FIXME (ast:types (ast:interface ast))
;;      ==>
;;   SUB-AST
;;      (type   type    field)
;;       ^class ^type   ^field;;
;;
;;   SUB-AST
;;      (action (trigger console arm))
;;       ^class ^event
;;
;;
;;  (read-asd "examples/AlarmSystem.asd")
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

(define-module (language asd ast)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 receive)

  :use-module (srfi srfi-1)
  :use-module (system foreign)

  :use-module (language asd misc)
  :use-module (language asd parse)
  :use-module (language asd reader)

  :export (
           Class
           action?
           arguments
           arguments?
           assign?
           ast
           behaviour
           behaviour?
           bind?
           binds
           body
           bottom?
           call?
           class
           component
           components
           component?
           compound
           declarative?
           dir-matches?
           direction
           elements
           enum?
           event
           event?
	   event-name
           events
           events?
           expression
           field
           find-events
           function
           functions
           trigger?
           value?
           guard?
           guard-equals?
           in?
           instance
           instance?
           instances
           instances?
           interface
           interfaces
           interface?
           left
	   literal?
           make
           model?
           name
           on?
           out?
           parameter
           parameter?
           parameters
           parameters?
           parent
           port
           port?
	   port-name
           ports
           provides?
           register
           requires?
	   return-type
           right
	   scope
	   signature
	   signature?
           statement
           statement?
           statements-of-type
           system
           system?
           triggers
           type
           type-name-component
           type?
           typed?
           types
           types?
           variable
           variable?
           variables
           variables?

           arguments-element
           events-element
           functions-element
           imports-element
           parameters-element
           ports-element
           types-element
           variables-element
           ))

(define (make . t)
  (apply (@@ (language asd parse) ast:make) t))

(define (element ast name)
  (or (assoc name (body ast)) '()))

(define (arguments-element ast) (element ast 'arguments))
(define (events-element ast) (element ast 'events))
(define (imports-element ast) (element ast 'imports))
(define (functions-element ast) (element ast 'functions))
(define (parameters-element ast) (element ast 'parameters))
(define (ports-element ast) (element ast 'ports))
(define (types-element ast) (element ast 'types))
(define (variables-element ast) (element ast 'variables))

(define (model? ast) (or (interface? ast) (component? ast) (system? ast)))
(define (type-helper? type ast)
  (and (pair? ast)
       (let ((head (car ast)))
         (case type
           ((event) (member head '(in out)))
           ((parameter) (and (=2 (length ast)) (type? (car ast)) (symbol? (cadr ast))))
           ((port) (member head '(provides requires)))
	   ((signature) (or (and (=1 (length ast)) (type? (car ast)))
                            (and (=2 (length ast))
                                 (type? (car ast))
                                 (parameters? (cadr ast)))))
         (else (eq? head type))))))

(define (action? ast) (type-helper? 'action ast))
(define (arguments? ast) (type-helper? 'arguments ast))
(define (assign? ast) (type-helper? 'assign ast))
(define (behaviour? ast) (type-helper? 'behaviour ast))
(define (bind? ast) (type-helper? 'bind ast))
(define (call? ast) (type-helper? 'call ast))
(define (component? ast) (type-helper? 'component ast))
(define (compound? ast) (type-helper? 'compound ast))
(define (enum? ast) (type-helper? 'enum ast))
(define (event? ast) (type-helper? 'event ast))
(define (events? ast) (type-helper? 'events ast))
(define (function? ast) (type-helper? 'function ast))
(define (functions? ast) (type-helper? 'functions ast))
(define (guard? ast) (type-helper? 'guard ast))
(define (instance? ast) (type-helper? 'instance ast))
(define (instances? ast) (type-helper? 'instances ast))
(define (interface? ast) (type-helper? 'interface ast))
(define (imports? ast) (type-helper? 'imports ast))
(define (literal? ast) (type-helper? 'literal ast))
(define (on? ast) (type-helper? 'on ast))
(define (parameter? ast) (type-helper? 'parameter ast))
(define (parameters? ast) (type-helper? 'parameters ast))
(define (port? ast) (type-helper? 'port ast))
(define (ports? ast) (type-helper? 'ports ast))
(define (signature? ast) (type-helper? 'signature ast))
(define (system? ast) (type-helper? 'system ast))
(define (trigger? ast) (type-helper? 'trigger ast))
(define (type? ast) (type-helper? 'type ast))
(define (types? ast) (type-helper? 'types ast))
(define (value? ast) (type-helper? 'value ast))
(define (variable? ast) (type-helper? 'variable ast))
(define (variables? ast) (type-helper? 'variables ast))

(define (statement? ast)
  (member (class ast) '(action assign bind compound guard if instance on reply variable)))

(define (body ast)
  (match ast
    ((or (? behaviour?) (? model?))
     (or (and (>2 (length ast)) (cddr ast)) '()))
    ((or  (? arguments?) (? compound?) (? events?) (? functions?) (? guard?) (? imports?) (? on?) (? parameters?) (? ports?) (? types?) (? variables?))
     (cdr ast))
    ;; be permissive for events, imports ports, types, variable
    ((('in type name) t ...) ast)
    ((('out type name) t ...) ast)
    ((('imports type name expression) t ...) ast)
    ((('requires type name) t ...) ast)
    ((('provides type name) t ...) ast)
    ((('enum type elements) t ...) ast)
    ((('variable type name expression) t ...) ast)
    ('() ast)
    (_ (throw 'match-error  (format #f "~a:body: no match: ~a\n" (current-source-location) ast)))))

(define (interface- ast)
  (if (interface? ast)
      ast
      (if (component? ast)
	  #f
	  (assoc 'interface ast))))

(define (component- ast)
  (if (component? ast)
      ast
      (assoc 'component ast)))

(define (system- ast)
  (if (system? ast)
      ast
      (assoc 'system ast)))

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

(define* (register ast :optional (clear? #f))
  (if clear?
      (set! *ast-alist* '()))
  (for-each (lambda (x) ((model (case (class x)
                                  ((interface) interface-)
                                  ((component) component-)
                                  ((system) system-))) x)) (models ast))
  ast)

(define (arguments ast)
  (match ast
    ((? call?) (body (if (>2 (length ast)) (caddr ast) '())))
    (_ (throw 'match-error (format #f "~a:arguments: no match: ~a\n" (current-source-location) ast)))))


(define (left ast)
  (match ast
    ((? bind?) (cadr ast))
    (_ (throw 'match-error (format #f "~a:left: no match: ~a\n" (current-source-location) ast)))))

(define (right ast)
  (match ast
    ((? bind?) (caddr ast))
    (_ (throw 'match-error (format #f "~a:left: no match: ~a\n" (current-source-location) ast)))))

(define (binds ast)
  (match ast
    ((? compound?) ((statements-of-type 'bind) ast))
    ((? system?) (binds (statement ast)))
    ((? model?) '())
    (_ (throw 'match-error (format #f "~a:binds: no match: ~a\n" (current-source-location) ast)))))

(define (instances ast)
  (match ast
    ((? compound?) ((statements-of-type 'instance) ast))
    ((? system?) (instances (statement ast)))
    ((? model?) '())
    (_ (throw 'match-error (format #f "~a:instances: no match: ~a\n" (current-source-location) ast)))))

(define (event ast)
  (match ast
    ((? action?) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:event: no match: ~a\n" (current-source-location) ast)))))

(define (parameters ast)
  (match ast
    ((? function?) (parameters (signature ast)))
    ((? signature?) (if (>2 (length ast)) (caddr ast) '()))
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

(define (variable ast)
  (match ast
    ((? assign?) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:variable: no match: ~a\n" (current-source-location) ast)))))


(define (return-type ast)
  (match ast
    ((or (? event?) (? function?)) (return-type (signature ast)))
    ((? signature?) (car ast))
    (_ (throw 'match-error  (format #f "~a:return-type: no match: ~a\n" (current-source-location) ast))))  )

(define (port-name ast)
  (match ast
    ((? port?) (name ast))
    ((? trigger?) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:port-name: no match: ~a\n" (current-source-location) ast)))))

(define (event-name ast)
  (match ast
    ((? symbol?) ast)
    ((? trigger?) (caddr ast))
    (_ (throw 'match-error  (format #f "~a:event-name: no match: ~a\n" (current-source-location) ast)))))

(define (events ast)
  (match ast
    ((? interface?) (body (events-element ast)))
    ((? component?) (triggers ast))
    ((? port?) (events (import-ast (type ast))))
    (_ (throw 'match-error  (format #f "~a:events: no match: ~a\n" (current-source-location) ast)))))

(define (triggers ast)
  (match ast
    ((? interface?) (events ast))
    ((? component?) (triggers (statement ast)))
    ((? on?) (cadr ast))
    ((? port?) (events ast))
    ((? compound?) (apply append (map triggers ((statements-of-type 'on) ast))))
    (_ (throw 'match-error  (format #f "~a:triggers: no match: ~a\n" (current-source-location) ast)))))

(define (behaviour ast)
  (match ast
    ((? model?) (element ast 'behaviour))
    ((? port?) (behaviour (import-ast (type ast))))
    (_ (throw 'match-error  (format #f "~a:behaviour: no match: ~a\n" (current-source-location) ast)))))

(define (ports ast)
  (match ast
    ((or (? component?) (? system?)) (body (ports-element ast)))
    ((? interface?) '())
    (_ (throw 'match-error  (format #f "~a:ports: no match: ~a\n" (current-source-location) ast)))))

(define (imports ast) (body (imports-element ast)))

(define (function ast identifier)
  (find (lambda (p) (eq? (name p) identifier))
        (match ast
          ((? functions?) (body ast))
          ((or (? component?) (? interface?)) (functions ast))
          (_ (throw 'match-error  (format #f "~a:function: no match: ~a\n" (current-source-location) ast))))))

(define* (port ast :optional (identifier #f))
  (match identifier
    (#f (match ast
          ((or (? component?) (? system?)) (assoc 'provides (ports ast)))
          (_ (throw 'match-error  (format #f "~a:port: no match: ~a\n" (current-source-location) ast)))))
    ((? symbol?)
     (find (lambda (p) (eq? (name p) identifier))
           (body
            (match ast
              ((? ports?) ast)
              ((or (? component?) (? system?)) (ports-element ast))
              (_ (throw 'match-error  (format #f "~a:port: no match: ~a\n" (current-source-location) ast)))))))
    ((? value?) (let* ((t (type identifier))
                       (f (field identifier))
                       (i (instance ast t)))
                  (if (eq? t f) ;; FIXME
                      (port (import-ast 'Alarm) f) ;; FIXME
                      (port (import-ast (type i)) f))))))

(define (instance- ast identifier)
  (find (lambda (i) (eq? (name i) identifier))
        (match ast
          ((? system?) (instances ast))
          ((h ...) ast)
          (_ (throw 'match-error  (format #f "~a:instance-: no match: ~a\n" (current-source-location) ast))))))

(define (instance ast identifier)
  (match ast
    ((? system?) (if (value? identifier)
                     (instance- ast (type identifier))
                     (or (instance- ast identifier)
                         (and-let* ((provides (port ast identifier))
                                    ((eq? (name provides) identifier)))
                                   identifier))))
    (_ (throw 'match-error  (format #f "~a:instance: no match: ~a\n" (current-source-location) ast)))))

(define (direction ast)
  (match ast
    ((or (? event?) (? port?)) (car ast))
    (_ (throw 'match-error  (format #f "~a:direction: no match: ~a\n" (current-source-location) ast)))))

(define (elements ast)
  (match ast
    ((? enum?) (caddr ast))
    (_ (throw 'match-error  (format #f "~a:elements: no match: ~a\n" (current-source-location) ast)))))

(define (expression ast)
  (match ast
    ((? assign?) (caddr ast))
    ((? guard?) (cadr ast))
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
    ((or (? behaviour?) (? enum?) (? function?) (? model?) (? parameter?)) (or (and (>1 (length ast)) (cadr ast)) ""))
    ((or (? event?) (? instance?) (? port?) (? variable?)) (caddr ast))
    ((? symbol?) ast)
    (_ (throw 'match-error  (format #f "~a:name: no match: ~a\n" (current-source-location) ast)))))

(define (class ast)
  (match ast
    ((? enum?) 'type)
    ((? event?) 'event)
    ((? port?) 'port)
    ((? trigger?) 'trigger)
    ((? value?) 'value)
    ((? variable?) 'variable)
    ('() #f)
    (#f #f)
    (_ (car ast))))

(define (Class ast)
  (symbol-capitalize (class ast)))

(define (statement ast)
  (match ast
    ((? system?) (or (assoc 'compound (body ast)) (make 'compound '())))
    ((? model?) (statement (behaviour ast)))
    ((? behaviour?) (or (assoc 'compound (body ast)) (make 'compound '())))
    ((or (? guard?) (? on?)) (caddr ast))
    ((? function?) (cadddr ast))
    (_ (throw 'match-error  (format #f "~a:statement: no match: ~a\n" (current-source-location) ast)))))

(define (type ast)
  (match ast
    ((? event?) (return-type ast)) ;; FIXME junk relaxed accessor
    ((? parameter?) (car ast))
    ((? literal?) (caddr ast))
    ((or (? instance?) (? port?) (? type?) (? value?) (? variable?)) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:type: no match: ~a\n" (current-source-location) ast)))))

(define (field ast)
  (match ast
    ((? literal?) (cadddr ast))
    ((? value?) (caddr ast))
    (_ (throw 'match-error  (format #f "~a:field: no match: ~a\n" (current-source-location) ast)))))

(define (functions ast)
  (match ast
    ((? behaviour?) (body (functions-element ast)))
    ((? interface?) (append (body (functions-element ast))
                            (functions (behaviour ast))))
    ((? component?) (functions (behaviour ast)))
    ((? port?) (functions (import-ast (type ast))))
               (_ (throw 'match-error  (format #f "~a:functions: no match: ~a\n" (current-source-location) ast)))))

(define (types ast)
  (match ast
    ((or (? interface?) (? behaviour?)) (body (types-element ast)))
    ((? component?) (types (behaviour ast)))
    ((? port?) (types (import-ast (type ast))))
    ((? system?) '())
    ('() ast)
    (_ (throw 'match-error  (format #f "~a:types: no match: ~a\n" (current-source-location) ast)))))

(define (variables ast)
  (match ast
    ((? behaviour?) (body (variables-element ast)))
    ((? interface?) (append (body (variables-element ast))
                            (variables (behaviour ast))))
    ((? component?) (variables (behaviour ast)))
    ((? port?) (variables (import-ast (type ast))))
               (_ (throw 'match-error  (format #f "~a:variables: no match: ~a\n" (current-source-location) ast)))))


;;;;; FIXME

(define (type-name-component type component) (symbol-append (name component) (type type)))

(define (enum-name enum) (cadr enum))

;;; utilities
(define (declarative? statement)
  (or (on? statement) (guard? statement)))

(define (provides? ast) (eq? (direction ast) 'provides))
(define (requires? ast) (eq? (direction ast) 'requires))

(define (guard-equals? lhs rhs) (equal? (expression lhs) (expression rhs)))

(define (typed? ast)
  (match ast
    ((? event?) (not (equal? (return-type ast) '(type void))))
    ((? port?) (null-is-#f (filter typed? (events ast))))
    (_ (throw 'match-error  (format #f "~a:typed?: no match: ~a\n" (current-source-location) ast)))))

(define (dir-matches? port)
  (lambda (event)
    (or (and (eq? (direction port) 'provides)
             (eq? (direction event) 'in))
        (and (eq? (direction port) 'requires)
             (eq? (direction event) 'out)))))

(define (bottom? ast)
  (and-let* ((ports (ports ast))
             ((=1 (length ports))))
            (provides? (car ports))))

;;; walkers

(define ((statement-of-type type) statement)
  (and (pair? statement) (eq? (car statement) type) statement))

(define ((statements-of-type type) statement)
  (match statement
    ((? (statement-of-type type)) (list statement))
    (('compound t ...) (filter identity (apply append (map (statements-of-type type) t)))) ;; FIXME: do we want to go deep?! this is for flat list, no?
    (('guard expr s) (filter identity ((statements-of-type type) s)))
    ((? statement?) '())
    ('() '())
    ((t ...) (filter identity (apply append (map (statements-of-type type) t))))
    (_ (throw 'match-error  (format #f "~a:statements-of-type, type: ~a: no match: ~a\n" (current-source-location) type statement)))))

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

(define* ((find-events :optional (predicate identity)) ast :optional (found '()))
  (let ((find-events-p (lambda* (ast :optional (found '()))
                         ((find-events predicate) ast found))))
    (match ast
      ((? component?)
       (delete-duplicates (sort (find-events-p (statement (behaviour ast))) list<)))
      ((? interface?)
       (let ((declared (events ast)))
         (receive (keep discard)
             (partition predicate declared)
           (let* ((behaviour (find-events-p (statement (behaviour ast))))
                  (behaviour-keep (filter (lambda (x) (negate (member x discard equal?))) behaviour)))
             (map name (delete-duplicates (sort (append keep behaviour-keep) list<) equal?))))))
      (('compound t ...) (append (apply append (map find-events-p t)) found))
      (('on t statement) (map find-events-p t))
      (('trigger port event) ast)
      (('guard expression statement) (find-events-p statement found))
      ((? symbol?) (make 'in '((type void)) ast))
      (('action x) '())
      (_ (throw 'match-error  (format #f "~a:find-events: no match: ~a\n" (current-source-location) ast))))))

;;;; reading/caching
(define *ast-alist* '())
(define (ast-add name ast)
  (set! *ast-alist* (assoc-set! *ast-alist* name ast))
  ast)

;; procedure: ast:import MODEL-NAME
;;
;; Read and parse the ASD source file for MODEL-NAME, return its AST.
(define (read-ast model-name)
  (and-let* ((ast (null-is-#f (read-asd (->string (list 'examples '/ model-name '.asd)))))
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
