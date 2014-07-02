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
;;   AST:= (
;;          (interface Console (types) (events) (behaviour))
;;           ^class    ^name   ^types  ^events  ^behaviour
;;
;;          (component Alarm   (ports) (behaviour))
;;           ^class    ^name   ^ports  ^behaviour
;;         )
;;
;;   SUB-AST (ast:types (ast:interface AST))
;;      := ((enum     States (Disarmed Armed Triggered Disarming))
;;           ^type    ^name  ^elements
;;           |implicit: class=type
;;
;;   SUB-AST (ast:events (ast:interface AST))  base class event: (event type name) 
;;      := ((in           void    arm)
;;           ^direction   ^type   ^name
;;           |implicit: class=event
;;
;;   ideas: void --> RETURN-TYPE  (later: rsn? SIGNATURE)
;;
;;   SUB-AST (ast:behaviour (ast:interface AST))
;;      := (behaviour b      (types) (variables) (compound))
;;          ^class    ^name  ^types  ^variables  ^statement  
;;          
;;   SUB-AST (ast:ports (ast:interface AST))
;;      := ((provides     Console console))
;;           ^direction   ^type   ^name
;;           |implicit: class=port
;;
;;    (ast:interface port) --> '(interface Console ..))
;;
;;   SUB-AST (ast:variables (ast:behaviour (ast:interface AST)))
;;      := ((variable States state        (field States Disarmed))
;;           ^class   ^type  ^name  ^expression
;;
;;   SUB-AST (ast:events (ast:component AST))
;;      (event  console arm)
;;       ^class ^port   ^event
;;
;;   SUB-AST (ast:types (ast:interface ast))
;;      (value type field)
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
           ast
           behaviour
           behaviour?
           body
           bottom?
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
           event?
	   event-name
           events
           events?
           expression
           find-events
           field?
           guard?
           guard-equals?
           in?
           interface
           interfaces
           interface?
           make
           model?
           name
           out?
           parent
           port
           port?
	   port-name
           ports
           provides?
           register
           requires?
           statement
           statements-of-type
           type
           type-name-component
           typed?
           types
           types?
           variable
           variable?
           variables
           variables?

           events-element
           imports-element
           ports-element
           types-element
           variables-element
           ))

(define (make . t)
  (apply (@@ (language asd parse) ast:make) t))

(define (element ast name)
  (or (assoc name (body ast)) '()))

(define (events-element ast) (element ast 'events))
(define (imports-element ast) (element ast 'imports))
(define (ports-element ast) (element ast 'ports))
(define (types-element ast) (element ast 'types))
(define (variables-element ast) (element ast 'variables))

(define (model? ast) (or (interface? ast) (component? ast)))
(define (type? type ast)
  (and (pair? ast)
       (let ((head (car ast)))
         (case type
           ((event) (member head '(in out)))
           ((port) (member head '(provides requires)))
         (else (eq? head type))))))

(define (behaviour? ast) (type? 'behaviour ast))
(define (component? ast) (type? 'component ast))
(define (compound? ast) (type? 'compound ast))
(define (enum? ast) (type? 'enum ast))
(define (event? ast) (type? 'event ast))
(define (events? ast) (type? 'events ast))
(define (field? ast) (type? 'field ast))
(define (guard? ast) (type? 'guard ast))
(define (interface? ast) (type? 'interface ast))
(define (imports? ast) (type? 'imports ast))
(define (on? ast) (type? 'on ast))
(define (port? ast) (type? 'port ast))
(define (ports? ast) (type? 'ports ast))
(define (types? ast) (type? 'types ast))
(define (variable? ast) (type? 'variable ast))
(define (variables? ast) (type? 'variables ast))

(define (body ast)
  (match ast
    ((or (? behaviour?) (? model?))
     (or (and (>2 (length ast)) (cddr ast)) '()))
    ((or (? events?) (? guard?) (? imports?) (? ports?) (? compound?) (? on?) (? types?) (? variables?))
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

(define (interface ast)
  (and-let* ((interface-ast (interface- ast))
             (name (name interface-ast)))
            (if (not (assoc-ref *ast-alist* name))
                (ast-add name interface-ast))
            interface-ast))

(define (interfaces ast)
  (filter (lambda (model) (interface? model)) ast))

(define* (register ast :optional (clear? #f))
  (if clear?
      (set! *ast-alist* '(())))
  (for-each interface (interfaces ast))
  ast)

(define (port-name ast)
  (match ast
    ((? field?) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:port-name: no match: ~a\n" (current-source-location) ast)))))

(define (event-name ast)
  (match ast
    ((? symbol?) ast)
    ((? field?) (caddr ast))
    (_ (throw 'match-error  (format #f "~a:event-name: no match: ~a\n" (current-source-location) ast)))))

(define (events ast)
  (match ast
    ((? interface?) (body (events-element ast)))
    ((? component?) (events (statement ast)))
    ((? on?) (cadr ast))
    ((? port?) (events (import-ast (type ast))))
    ((? compound?) (apply append (map events ((statements-of-type 'on) ast))))
    (_ (throw 'match-error  (format #f "~a:events: no match: ~a\n" (current-source-location) ast)))))

(define (behaviour ast)
  (match ast
    ((? model?) (element ast 'behaviour))
    ((? port?) (behaviour (import-ast (type ast))))
    (_ (throw 'match-error  (format #f "~a:behaviour: no match: ~a\n" (current-source-location) ast)))))

(define (component ast) 
  (if (component? ast)
      ast
      (assoc 'component ast)))

(define (ports ast)
  (match ast
    ((? component?) (body (ports-element ast)))
    (_ (throw 'match-error  (format #f "~a:ports: no match: ~a\n" (current-source-location) ast)))))

(define (imports ast) (body (imports-element ast)))

(define* (port ast :optional (identifier #f))
  (if identifier
      (find (lambda (p) (eq? (name p) identifier))
            (body
             (match ast
               ((? ports?) ast)
               ((? component?) (ports-element ast))
               (_ (throw 'match-error  (format #f "~a:port: no match: ~a\n" (current-source-location) ast))))))
      (match ast
        ((? component?) (assoc 'provides (ports ast))))))

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
    ((or (? behaviour?) (? enum?) (? model?)) (or (and (>1 (length ast)) (cadr ast)) ""))
    ((or (? event?) (? field?) (? port?) (? variable?)) (caddr ast))
    (_ (throw 'match-error  (format #f "~a:name: no match: ~a\n" (current-source-location) ast)))))

(define (class ast)
  (match ast 
    ((? enum?) 'type)
    ((? event?) 'event)
    ((? field?) 'field)
    ((? port?) 'port)
    ((? variable?) 'variable)
    (_ (car ast))))

(define (statement ast)
  (match ast
    ((? model?) (statement (behaviour ast)))
    ((? behaviour?) (or (assoc 'compound (body ast)) (make 'compound '())))
    ((? guard?) (caddr ast))
    ((? on?) (caddr ast))
    (_ (throw 'match-error  (format #f "~a:statement: no match: ~a\n" (current-source-location) ast)))))

(define (type ast)
  (match ast 
    ((or (? event?) (? field?) (? port?) (? variable?)) (cadr ast))
    (_ (throw 'match-error  (format #f "~a:type: no match: ~a\n" (current-source-location) ast)))))

(define (types ast)
  (match ast
    ((or (? interface?) (? behaviour?)) (body (types-element ast)))
    ((? component?) (types (behaviour ast)))
    ((? port?) (types (import-ast (type ast))))
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
    ((? event?) (not (eq? (type ast) 'void)))
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
  (and (eq? (car statement) type) statement))

(define ((statements-of-type type) statement)
  (match statement
    ((? (statement-of-type type)) (list statement))
    (('compound t ...) (filter identity (apply append (map (statements-of-type type) t))))
    (('guard expr s) (filter identity ((statements-of-type type) s)))
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
      (('field type name) ast)
      (('guard expression statement) (find-events-p statement found))
      ((? symbol?) (make 'in 'void ast))
      (_ (throw 'match-error  (format #f "~a:find-events: no match: ~a\n" (current-source-location) ast))))))

;;;; reading/caching
(define *ast-alist* '(()))
(define (ast-add name ast)
  (set! *ast-alist* (assoc-set! *ast-alist* name ast))
  ast)

;; procedure: ast:import MODEL-NAME
;;
;; Read and parse the ASD source file for MODEL-NAME, return its AST.
(define (read-ast name)
  (read-asd (->string (list 'examples '/ name '.asd))))

(define* (import-ast name #:optional (transform identity))
  "
procedure: ast:import MODEL-NAME

Read and parse the ASD source file for MODEL-NAME, return its AST.

"
  (or (assoc-ref *ast-alist* name)
      (and-let* ((ast (transform (read-ast name))))
                (ast-add name (car ast)))))

;; procedure: ast:ast MODEL-NAME
;;
;; Read and parse the ASD source file for MODEL-NAME, return its AST.
(define ast import-ast)
