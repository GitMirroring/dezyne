;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Dezyne Language parse tree library.
;;;
;;; Code:

(define-module (dzn parse tree)
  #:use-module (ice-9 match)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (dzn misc)

  #:export (%file-name->parse-tree
            %resolve-file
            assert-type

            complete?
            incomplete?
            is-a?
            is?
            has-location?
            parent
            parent-context
            tree?
            slot

            .behaviour
            .behaviour-compound
            .end
            .event-name
            .expression
            .field
            .fields
            .file-name
            .function-name
            .instance-name
            .location
            .name
            .namespace-root
            .parent
            .port-name
            .ports
            .pos
            .scope
            .statement
            .system
            .tree
            .triggers
            .type-name
            .value
            .var

            tree:context?
            tree:declaration?
            tree:in?
            tree:location?
            tree:model?
            tree:name-equal?
            tree:out?
            tree:provides?
            tree:requires?
            tree:scope?
            tree:type?

            tree:collect
            tree:dotted-name
            tree:file-name
            tree:location
            tree:name
            tree:offset
            tree:scope+name

            tree:declaration*
            tree:field*
            tree:function*
            tree:enum*
            tree:event*
            tree:formal*
            tree:id*
            tree:import*
            tree:int*
            tree:interface*
            tree:port*
            tree:trigger*
            tree:type*
            tree:statement*
            tree:variable*

            tree:add-file-name))

;;;
;;; Utilities.
;;;

(define %file-name->parse-tree (make-parameter (const '())))
(define %resolve-file
  (make-parameter
   (lambda* (file-name #:key (imports '())) file-name)))

(define (assert-type o . any-of-types)
  (unless (any (cute <> o) (map is? any-of-types))
    (throw 'assert-type (format #f "~a is not one of type: ~a\n" o any-of-types))))

(define (is-a? o predicate)
  "Return if O (a tree'ish pair) meets PREDICATE (a tree-type symbol or
procedure)."
  (and (pair? o)
       (match predicate
         ((? symbol?)
          (eq? predicate (car o)))
         ((? procedure? predicate)
          (predicate o)))))

(define (is? predicate)
  "Return a predicate that tests for PREDICATE."
  (lambda (o) (is-a? o predicate)))

(define (slot o symbol)
  "Access slot SYMBOL in O."
  (find (is? symbol) (cdr o)))

(define (slots o symbol)
  "Return list of all SYMBOL slots in O."
  (filter (is? symbol) (cdr o)))


;;;
;;; Parse record accessors.
;;;

(define (.behaviour o)
  (match o
    ((or (? (is? 'component))
         (? (is? 'interface)))
     (slot o 'behaviour))))

(define (.behaviour-compound o)
  (match o
    ((? (is? 'behaviour))
     (slot o 'behaviour-compound))))

(define (.end o)
  (match o
    (('location pos end) end)
    (('location pos end file-name) end)))

(define (.expression o)
  (assert-type o 'enum-literal 'assign 'variable)
  (slot o 'expression))

(define (.field o)
  (assert-type o 'enum-literal 'field-test)
  (slot o 'name))

(define (.fields o)
  (assert-type o 'enum)
  (slot o 'fields))

(define (.file-name o)
  (match o
    ((? (is? 'root))
     (and=> (slot o 'file-name) .file-name))
    (((or 'file-name 'import) (? string? file-name) rest ...)
     file-name)
    (('location start end file-name)
     file-name)))

(define (.formals o)
  (match o
    ((or (? (is? 'function))
         (? (is? 'trigger)) (slot o 'formals))
     (slot o 'formals))))

(define (.location o)
  (assert-type o tree?)
  (slot o 'location))

(define (.name o) ;; XXX FIXME: access NAME field (a string, a 'name, or 'compound-name)
  (match o
    (('name (? string? name) (? (is? 'location)))
     name)
    ((or (? (is? 'enum))
         (? (is? 'int))
         (? (is? 'namespace))
         (? (is? 'type-name)))
     (slot o 'compound-name))
    ((or (? (is? 'call))
         (? (is? 'compound-name))
         (? (is? 'event-name))
         (? (is? 'port))
         (? (is? 'interface))
         (? (is? 'var))
         (? (is? 'variable)))
     (slot o 'name))
    ((? (is? 'event))
     (.name (slot o 'event-name)))))

(define (.namespace-root o)
  (match o
    ((? (is? 'namespace))
     (slot o 'namespace-root))))

(define (.event-name o)
  (match o
    (((or 'action 'interface-action 'illegal-trigger 'trigger)
      (? (is? 'name) port) (? (is? 'name) event) rest ...) event)
    (((or 'action 'interface-action 'illegal-trigger 'trigger)
      (? (is? 'name) event) rest ...) event)))

(define (.port-name o)
  (match o
    (((or 'action 'interface-action 'illegal-trigger 'trigger)
      (? (is? 'name) port) (? (is? 'name) event) rest ...) port)
    (((or 'action 'interface-action 'illegal-trigger 'trigger)
      (? (is? 'name) event) rest ...) #f)
    ((? (is? 'end-point)) (.port-name (slot o 'compound-name)))
    (('compound-name (? (is? 'scope) instance) (? (is? 'name) port) rest ...) port)
    (('compound-name (? (is? 'name) port) rest ...) port)))

(define (.instance-name o)
  (match o
    ((? (is? 'end-point)) (.instance-name (slot o 'compound-name)))
    (('compound-name (? (is? 'scope) instance) (? (is? 'name) port) rest ...) instance)
    (('compound-name (? (is? 'name) port) rest ...) #f)))

(define (.function-name o)
  (match o
    ((? (is? 'call)) (.name o))))

(define (.ports o)
  (match o
    ((? (is? 'component)) (slot o 'ports))))

(define (.pos o)
  (match o
    (('location pos end) pos)
    (('location pos end file-name) pos)))

(define (.statement o)
  (assert-type o 'blocking 'guard 'on)
  (slot o tree:statement?))

(define (.triggers o)
  (assert-type o 'on)
  (slot o 'triggers))

(define (.scope o) ;; accessor with default: '()
  (match o
    ((? (is? 'compound-name))
     (or (slot o 'scope) '()))))

(define (.system o)
  (match o
    ((? (is? 'component)) (slot o 'system))))

(define (.trigger-formals o)
  (match o
    ((? (is? 'trigger)) (slot o 'trigger-formals))))

(define (.type-name o)
  (assert-type o 'enum-literal 'event 'function 'port 'variable)
  (match o
    ((? (is? 'port))   ;; Hmm: .compound-name??
     (slot o 'compound-name))
    ((or (? (is? 'event))
         (? (is? 'function))
         (? (is? 'variable)))
     (.name (slot o 'type-name)))
    ((? (is? 'enum-literal))
     (let* ((type     (slot o 'scope))
            (names    (filter (is? 'name) type))
            (scope
             name     (tree:scope+name names))
            (location (.location type)))
       (if (null? scope) `(compound-name ,name ,location)
           `(compound-name (scope ,@scope ,location) ,name ,location))))))

(define (.types-and-events o)
  (match o
    ((? (is? 'interface)) (slot o 'types-and-events))))

(define (.value o)
  (assert-type o 'expression)
  (match o
    (('expression (? (is? 'location))) #f)
    (('expression expression (? (is? 'location))) expression)))

(define (.var o)
  (assert-type o 'field-test)
  (slot o 'var))


;;;
;;; Parse tree predicates.
;;;

(define tree:declarative
  '(blocking
    guard
    on))

(define tree:imperative
  '(action
    assign
    call
    if-statement
    illegal
    reply
    variable))

(define tree:model
  '(component
    interface))

(define tree:type
  '(bool
    enum
    interface
    int
    void))

(define tree:record
  (append
   tree:declarative
   tree:imperative
   tree:model
   tree:type
   '(arguments
     behaviour
     behaviour-compound
     binding
     comment
     compound
     compound-name
     direction
     dollars
     end-point
     enum-literal
     enum-name
     event
     event-name
     events
     expression
     extern
     field-test
     fields
     file-name
     formal
     formals
     function
     global
     group
     illegal-trigger
     illegal-triggers
     import
     instance
     instances-and-bindings
     interface
     interface-action
     literal
     location
     name
     namespace
     namespace-root
     not
     offset
     otherwise
     port
     port-qualifiers
     ports
     provides
     requires
     root
     scope
     system
     trigger
     trigger-formals
     triggers
     type-name
     types-and-events
     var
     void)))

(define (tree? o)
  (match o
    (((? symbol? (? (cute memq <> tree:record)) type) slot ...)
     o)
    (((? symbol?) slot ...)
     (warn "XXX tree? noisy fallback:" o))
    (_ #f)))

(define (tree:declaration? o)
  (or (is-a? o 'namespace)
      (is-a? o 'interface)
      (is-a? o 'component)
      (is-a? o 'enum)
      (is-a? o 'extern)
      (is-a? o 'bool)
      (is-a? o 'void)
      (is-a? o 'int)
      (is-a? o 'event)
      (is-a? o 'instance)
      (is-a? o 'port)
      (is-a? o 'variable)
      (is-a? o 'formal)
      (is-a? o 'behaviour)
      (is-a? o 'function)
      (is-a? o 'variable)))

(define (tree:scope? o)
  (or (is-a? o 'root)
      (is-a? o 'namespace)
      (is-a? o 'interface)
      (is-a? o 'component)
      (is-a? o 'system)
      (is-a? o 'compound)
      (is-a? o 'enum)
      (is-a? o 'trigger)
      (is-a? o 'behaviour)
      (is-a? o 'behaviour-compound)
      (is-a? o 'function)
      (is-a? o 'instances-and-bindings)))

(define (tree:declarative? o)
  (match o
    (('compound (? tree:location?))
     #f)
    (('compound first rest ...)
     (tree:declarative? first))
    (((? symbol? type) slot ...)
     (or (memq type tree:declarative)))
    (_ #f)))

(define (tree:imperative? o)
  (match o
    (('compound (? tree:location?))
     #t)
    (('compound first rest ...)
     (tree:imperative? first))
    (((? symbol? type) slot ...)
     (or (memq type tree:imperative)))
    (_ #f)))

(define (tree:statement? o)
  (or (tree:declarative? o)
      (tree:imperative? o)))

(define (tree:model? o)
  (match o
    (((? symbol? type) slot ...)
     (memq type tree:model))
    (_ #f)))

(define (tree:type? o)
  (match o
    (((? symbol? type) slot ...)
     (memq type tree:type))
    (_ #f)))

(define (tree:location? o)
  ((is? 'location) o))

(define (has-location? o)
  (and (pair? o) (slot o 'location)))

(define (tree:name-equal? a b)
  (and a b
       (assert-type a 'name 'compound-name 'scope)
       (assert-type b 'name 'compound-name 'scope)
       (equal? (last (tree:id* a))
               (last (tree:id* b)))))

(define (tree:in? o)
  (match o
    ((? (is? 'direction)) (equal? (.direction o) "in"))
    ((? (is? 'event)) (tree:in? (.direction o)))))

(define (tree:out? o)
  (match o
    ((? (is? 'direction)) (equal? (.direction o) "out"))
    ((? (is? 'event)) (tree:out? (.direction o)))))

(define (tree:provides? o)
  (match o
    ((? (is? 'port)) (slot o 'provides))))

(define (tree:requires? o)
  (match o
    ((? (is? 'port)) (slot o 'requires))))


;;;
;;; Context.
;;;
;;; A context is a list of tree?'is elements:
;;;
;;; (tree?
;;;   (parent tree? ... tree?)
;;;   (grand-parent ... (parent-tree? ... tree?))
;;;   ..
;;;   ('root ....))
;;;

(define (.tree context)
  (and (tree:context? context) (car context)))

(define (.parent context)
  (and (tree:context? context) (cdr context)))

(define (complete? o)
  ((disjoin string?
            (conjoin pair?
                     (compose symbol? first)
                     (compose (is? 'location) last)
                     (compose (cute every complete? <>)
                              (cute drop-right <> 1)
                              cdr))) o))

(define incomplete? (negate complete?))

(define (tree:context? context)
  (and (pair? context) (tree? (car context)) context))

(define (parent-context context type)
  (let loop ((context (.parent context)))
    (and (tree:context? context)
         (let ((tree (.tree context)))
           (if (is-a? tree type) context
               (and tree
                    (loop (.parent context))))))))

(define (parent context type)
  (and=> (parent-context context type)
         .tree))


;;;
;;; Parse tree accessors.
;;;

(define (tree:collect o predicate)
  (if (predicate o) (cons o (append-map (cute tree:collect <> predicate) o))
      '()))

(define (tree:name o)
  (match o
    ((or (? (is? 'name))
         (? (is? 'compound-name)))
     o)
    ((? (is? 'event)) (tree:name (slot o 'event-name)))
    (_   (or (slot o 'name)
             (slot o 'compound-name)))))

(define (tree:scope+name o)
  (match o
    (((? (is? 'name) scope) ... (? (is? 'name) name))
     (values scope name))
    ((? (is? 'scope))
     (tree:scope+name (slots o 'name)))
    ((? (is? 'compound-name))
     (let ((scope (.scope o))
           (name (.name o)))
       (values (filter (is? 'name) scope) name)))
    ((? (is? 'name) name)
     (values '() name))
    (((? string? scope) ... (? string? name))
     (values scope name))))

(define (tree:full-name o) ;;; XXX TODO: namespaces
  (tree:id* o))

(define (tree:dotted-name o) ;; XXX This is not full-name, we need context/parent for that.
  "Return name of O as a string, scopes separated by dots."
  (match o
    ((? (is? 'name)) (.name o))

    ((? (is? 'compound-name)) (string-join (filter-map tree:dotted-name (cdr o)) "."))
    ((? (is? 'event-name)) (tree:dotted-name (.name o)))
    ((? (is? 'port)) (tree:dotted-name (.name o)))
    ((? (is? 'type-name)) #f)
    ((? pair?) (tree:dotted-name (find tree:dotted-name o)))
    (_ #f)))

(define (tree:offset o)
  (and=> (.location o) .pos))

(define (tree:file-name o)
  (and=> (.location o) .file-name))

(define (tree:instance* o)
  (match o
    ((? (is? 'component)) (or (and=> (.system o) tree:instance*) '()))
    ((? (is? 'system)) (slots o 'instance))))

(define (tree:declaration* o)
  (match o
    ((or (? (is? 'root))
         (? (is? 'behaviour-compound))
         (? (is? 'compound))
         (? (is? 'ports))
         (? (is? 'types-and-events)))
     (slots o tree:declaration?))
    ((? (is? 'namespace))
     (slots (.namespace-root o) tree:declaration?))
    ((? (is? 'interface))
     (tree:declaration* (.types-and-events o)))
    ((? (is? 'component))
     (append (tree:declaration* (.ports o))
             (append-map tree:declaration* (tree:instance* o))))
    ((? (is? 'behaviour))
     (tree:declaration* (.behaviour-compound o)))
    ((? (is? 'field))
     (slots o 'name))
    ((? (is? 'enum))
     (tree:declaration* (.fields o)))
    ((? (is? 'trigger-formals))
     (slots o 'trigger-formal))
    ((? (is? 'instances-and-bindings))
     (slots o 'instance))
    ((? (is? 'trigger))
     (tree:declaration* (.trigger-formals o)))
    ((? (is? 'formals))
     (slots o 'formal))
    ((? (is? 'function))
     (tree:declaration* (.formals o)))
    ((? (is? 'variable))
     (list o))
    (_
     '())))

(define (tree:field* o)
  (match o
    ((? (is? 'enum) )(tree:field* (slot o 'fields)))
    ((? (is? 'fields)) (slots o 'name))
    (((? (is? 'name) field) ...) field)
    (_ '())))

(define (tree:id* o)
  (match o
    (('name (? string? name) (? (is? 'location) location))
     (list name))
    (('scope (? (is? 'name) name) ... (? (is? 'location) location))
     (append-map tree:id* name))
    ((? (is? 'compound-name))
     (append (tree:id* (.scope o)) (tree:id* (.name o))))
    (((? string? id) ...)
     o)))

(define (tree:import* o)
  (match o
    ((? (is? 'root)) (slots o 'import))
    (_ '())))

(define (tree:port* o)
  (match o
    ((? (is? 'port)) (list o))
    ((? pair?) (append-map tree:port* o))
    (_ '())))

(define* (tree:top* o #:key (imports '()) (seen '()))
  (match o
    ((? (is? 'root))
     (let* ((file-name ((%resolve-file) (.file-name o) #:imports imports))
            (imports (cons (dirname file-name) imports))
            (seen (cons file-name seen)))
       (append-map (cut tree:top* <> #:imports imports #:seen seen)
                   (slots o tree?))))
    ((? (is? 'import))
     (let ((file-name ((%resolve-file) (.file-name o) #:imports imports)))
       (if (member file-name seen) '()
           (and=> ((%file-name->parse-tree) file-name) tree:top*))))
    ((? (is? 'namespace))
     (append-map (cut tree:top* <> #:imports imports #:seen seen)
                 (slots (.namespace-root o) tree?)))
    ((? tree?)
     (list o))
    (()
     '())))

(define (tree:namespace* o)
  (filter (is? 'namespace) (tree:top* o)))

(define (tree:component* o)
  (filter (is? 'component) (tree:top* o)))

(define (tree:interface* o)
  (filter (is? 'interface) (tree:top* o)))

(define (tree:type* o)
  (match o
    ((? (is? 'interface)) (append-map tree:type* (cdr o)))
    ((or (? (is? 'enum)) (? (is? 'int))) `(,o))
    ((? (is? 'root)) (filter (disjoin (is? 'enum) (is? 'int)) (tree:top* o)))
    ((? pair?) (append-map tree:type* o))
    (_ '())))

(define (tree:enum* o)
  (filter (is? 'enum) (tree:type* o)))

(define (tree:int* o)
  (filter (is? 'int) (tree:type* o)))

(define (tree:event* o)
  (match o
    ((? (is? 'interface)) (append-map tree:event* (cdr o)))
    ((? (is? 'event)) `(,o))
    ((? pair?) (append-map tree:event* o))
    (_ '())))

(define (tree:function* o)
  (assert-type o 'behaviour-compound 'behaviour)
  (match o
    ((? (is? 'behaviour)) (tree:function* (.behaviour-compound o)))
    ((? (is? 'behaviour-compound)) (slots o (is? 'function)))))

(define (tree:statement* o)
  (assert-type o 'behaviour 'behaviour-compound 'blocking 'compound 'guard 'function 'if 'on)
  (match o
    ((? (is? 'behaviour)) (tree:statement* (.behaviour-compound o)))
    (_ (slots o tree:statement?))))

(define (tree:variable* o)
  (assert-type o 'behaviour-compound 'compound)
  (slots o 'variable))

(define (tree:formal* o)
  (match o
    ((? (is? 'event)) (tree:formal* (slot o 'formals)))
    ((? (is? 'formals)) (slots o 'formal))
    ((? (is? 'function)) (tree:formal* (slot o 'formals)))
    (_ '())))

(define (tree:trigger* o)
  (match o
    ((? (is? 'triggers)) (slots o 'trigger))
    ((? (is? 'on)) (tree:trigger* (.triggers o)))
    (_ '())))


;;;
;;; Parse tree transformations.
;;;

(define (tree:add-file-name o file-name)
  (match o
    (('location start end)
     `(location ,start ,end ,file-name))
    (((? symbol? type) slots ...)
     (let ((slots (map (cute tree:add-file-name <> file-name) slots)))
       `(,type ,@slots)))
    (_ o)))
