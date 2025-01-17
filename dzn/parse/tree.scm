;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2020, 2021, 2022, 2023, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
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
  #:use-module (ice-9 poe)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (dzn misc)

  #:export (%file-name->parse-tree
            %resolve-file

            complete?
            context?
            has-location?
            incomplete?
            is-a?
            is?
            tree?

            assert-type
            parent
            context:parent
            slot

            .behavior
            .behavior-compound
            .behavior-statements
            .direction
            .else
            .end
            .event-name
            .expression
            .field
            .fields
            .file-name
            .from
            .function-name
            .global
            .instance-name
            .instances-and-bindings
            .left
            .location
            .name
            .namespace-root
            .parent
            .port-name
            .port-qualifiers
            .ports
            .pos
            .range
            .right
            .scope
            .statement
            .system
            .then
            .to
            .tree
            .triggers
            .type-name
            .value
            .var

            tree->context

            tree:bool
            tree:extern
            tree:int
            tree:void

            tree:component?
            tree:declaration?
            tree:foreign?
            tree:in?
            tree:location?
            tree:model?
            tree:name-equal?
            tree:out?
            tree:port-qualifier?
            tree:provides?
            tree:requires?
            tree:scope?
            tree:statement?
            tree:system?
            tree:type-equal?
            tree:type?

            tree:add-file-name
            tree:collect
            tree:filter
            tree:debug-context
            tree:direction
            tree:dotted-name
            tree:file-name
            tree:location
            tree:name
            tree:normalize
            tree:offset
            tree:scope+name

            tree:argument*
            tree:component*
            tree:declaration*
            tree:enum*
            tree:event*
            tree:field*
            tree:formal*
            tree:function*
            tree:id*
            tree:import*
            tree:instance*
            tree:int*
            tree:interface*
            tree:list-model*
            tree:model*
            tree:namespace*
            tree:port*
            tree:port-qualifier*
            tree:statement*
            tree:top*
            tree:trigger*
            tree:type*
            tree:variable*

            context:bool
            context:extern
            context:int
            context:void

            context:collect
            context:dotted-name
            context:stripped-dotted-name

            context:component*
            context:event*
            context:formal*
            context:function*
            context:interface*
            context:model*
            context:port*
            context:top*
            context:trigger*
            context:type*
            context:variable*))

;;;
;;; Utilities.
;;;

(define (tree:type-name o)
  (match o
    (((? symbol? type) slot ...) type)))

(define (context:type-name o)
  (tree:type-name (.tree o)))

(define (tree:debug-context context)
  (and context
       (let ((tree (.tree context)))
         (if (is-a? tree 'root) (.file-name tree)
             (tree:dotted-name tree)))))

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
  (and (match predicate
         ((? symbol?)
          (and (pair? o)
               (eq? predicate (car o))))
         ((? procedure? predicate)
          (predicate o)))
       o))

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

(define (.behavior o)
  (match o
    ((or (? (is? 'component))
         (? (is? 'interface)))
     (slot o 'behavior))))

(define (.behavior-compound o)
  (match o
    ((? (is? 'behavior))
     (slot o 'behavior-compound))))

(define (.behavior-statements o)
  (match o
    ((? (is? 'behavior-compound))
     (slot o 'behavior-statements))))

(define (.direction o)
  (match o
    (('direction (? string? direction) rest ...) direction)
    ((? (is? 'event)) (slot o 'direction))
    ((? (is? 'formal)) (slot o 'direction))
    ((? (is? 'port)) (slot o 'direction))))

(define (.else o)
  (match o
    ((? (is? 'if-statement))
     (let* ((slots (slots o tree?))
            (statements (filter tree:statement? slots)))
       (match statements
         ((then else) else)
         (_ #f))))))

(define (.end o)
  (match o
    (('location pos end) end)
    (('location pos end file-name) end)))

(define (.expression o)
  (assert-type o 'assign 'enum-literal 'guard 'return 'reply 'variable)
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

(define (.from o)
  (assert-type o 'range)
  (slot o 'from))

(define (.global o)
  (match o
    ((? (is? 'compound-name))
     (slot o 'global))
    (_ #f)))

(define (.location o)
  (assert-type o tree?)
  (slot o 'location))

(define (.name o)
  (match o
    (('name (? string? name) rest ...)
     name)
    ((or (? (is? tree:model?))
         (? (is? 'enum))
         (? (is? 'extern))
         (? (is? 'int))
         (? (is? 'namespace))
         (? (is? 'type-name))
         (? (is? 'component))
         (? (is? 'interface)))
     (slot o 'compound-name))
    ((or (? (is? 'bool))
         (? (is? 'call))
         (? (is? 'compound-name))
         (? (is? 'formal))
         (? (is? 'function))
         (? (is? 'event-name))
         (? (is? 'port))
         (? (is? 'instance))
         (? (is? 'interface))
         (? (is? 'trigger-formal))
         (? (is? 'var))
         (? (is? 'variable))
         (? (is? 'void)))
     (slot o 'name))
    ((? (is? 'event))
     (.name (slot o 'event-name)))
    (_
     #f)))

(define (tree:name o)
  (or (is-a? o 'name)
      (is-a? o 'compound-name)
      (.name o)))

(define (.namespace-root o)
  (match o
    ((? (is? 'namespace))
     (slot o 'namespace-root))))

(define (.event-name o)
  (match o
    (((or 'action 'interface-action 'illegal-trigger 'trigger)
      (? (is? 'name) port) (? (is? 'name) event) rest ...) event)
    (((or 'action 'interface-action 'illegal-trigger 'trigger)
      (? (is? 'name) event) rest ...) event)
    (('trigger (and (or "inevitable" "optional") event) rest ...) event)))

(define (.port-name o)
  (match o
    (((or 'action 'interface-action 'illegal-trigger 'trigger)
      (? (is? 'name) port) (? (is? 'name) event) rest ...) port)
    (((or 'action 'interface-action 'illegal-trigger 'trigger)
      (? (is? 'name) event) rest ...) #f)
    (((or 'action 'interface-action 'illegal-trigger 'trigger)
      rest ...) #f)
    ((? (is? 'end-point)) (.port-name (slot o 'compound-name)))
    ((? (is? 'reply))
     (slot o 'name))
    (('compound-name (? (is? 'scope) instance) (? (is? 'name) port) rest ...) port)
    (('compound-name (? (is? 'name) port) rest ...) port)))

(define (.instance-name o)
  (match o
    ((? (is? 'end-point)) (.instance-name (slot o 'compound-name)))
    (('compound-name (? (is? 'scope) instance) (? (is? 'name) port) rest ...) instance)
    (('compound-name (? (is? 'name) port) rest ...) #f)))

(define (.instances-and-bindings o)
  (match o
    ((? (is? 'system)) (slot o 'instances-and-bindings))))

(define (.left o)
  (match o
    ((? (is? 'binding)) (slot o 'end-point))))

(define (.right o)
  (match o
    ((? (is? 'binding)) (match (slots o 'end-point)
                          (((? (is? 'end-point)) (and (? (is? 'end-point)) right)) right)
                          (_ #f)))))

(define (.function-name o)
  (match o
    ((? (is? 'call)) (.name o))))

(define (.port-qualifiers o)
  (match o
    ((? (is? 'port)) (slot o 'port-qualifiers))))

(define (.ports o)
  (match o
    ((? (is? 'component)) (slot o 'ports))))

(define (.pos o)
  (match o
    (('location pos end) pos)
    (('location pos end file-name) pos)))

(define (.range o)
  (assert-type o 'int)
  (slot o 'range))

(define (.statement o)
  (assert-type o 'blocking 'guard 'on)
  (slot o tree:statement?))

(define (.then o)
  (match o
    ((? (is? 'if-statement))
     (let* ((slots (slots o tree?))
            (statements (filter tree:statement? slots)))
       (match statements
         ((then else ...) then)
         (_ #f))))))

(define (.to o)
  (assert-type o 'range)
  (slot o 'to))

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
  (assert-type o 'compound-name 'enum-literal 'event 'formal 'function 'instance 'port 'variable)
  (match o
    ((? (is? 'port))    ;; Hmm: .compound-name??
     (slot o 'compound-name))
    ((? (is? 'instance))
     (slot o 'compound-name))
    ((or (? (is? 'event))
         (? (is? 'formal))
         (? (is? 'function))
         (? (is? 'variable)))
     (.name (slot o 'type-name)))
    ((? (is? 'enum-literal))
     (let* ((type     (slot o 'scope))
            (names    (filter (is? 'name) type))
            (scope
             name     (tree:scope+name names))
            (location (.location type)))
       (if (not (context? scope)) `(compound-name ,name ,location)
           `(compound-name (scope ,@scope ,location) ,name ,location))))
    ((? (is? 'compound-name))
     (.name o))))

(define (.types-and-events o)
  (match o
    ((? (is? 'interface)) (slot o 'types-and-events))))

(define (.value o)
  (assert-type o 'expression 'literal)
  (match o
    (('expression (? (is? 'location))) #f)
    (('expression expression (? (is? 'location))) expression)
    (('expression expression x ...) expression)
    (('expression) #f)
    (('literal (? (is? 'location))) #f)
    (('literal literal (? (is? 'location))) literal)))

(define (.var o)
  (assert-type o 'assign 'field-test)
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
    defer
    if-statement
    illegal
    reply
    skip-statement
    variable))

(define tree:model
  '(component
    interface))

(define tree:type
  '(bool
    enum
    extern
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
     argument
     behavior
     behavior-compound
     behavior-statements
     binding
     blocking-q
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
     external
     field-test
     fields
     file-name
     formal
     formals
     from
     function
     from
     global
     group
     illegal-trigger
     illegal-triggers
     injected
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
     or
     otherwise
     port
     port-qualifiers
     ports
     provides
     range
     requires
     return
     root
     scope
     system
     to
     trigger
     trigger-formals
     trigger-formal
     triggers
     type-name
     types-and-events
     unknown-identifier
     var
     void)))

(define (tree? o)
  (match o
    (((? symbol? (? (cute memq <> tree:record)) type) slot ...)
     o)
    (((? symbol?) slot ...)
     (format (current-error-port)
             "programming-warning: tree?: missing-type: ~s\n" o))
    (_
     #f)))

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
      (is-a? o 'behavior)
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
      (is-a? o 'extern)
      (is-a? o 'int)
      (is-a? o 'trigger)
      (is-a? o 'behavior-statements)
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

(define (tree:component? o)
  (and (is-a? o 'component)
       (.behavior o)
       o))

(define (tree:foreign? o)
  (and (is-a? o 'component)
       (not (tree:component? o))
       (not (tree:system? o))
       o))

(define (tree:system? o)
  (and (is-a? o 'component)
       (.system o)
       o))

(define (tree:type? o)
  (match o
    ((? (is? 'bool)) o)
    ((? (is? 'enum)) o)
    ((? (is? 'extern)) o)
    ((? (is? 'int)) o)
    ((? (is? 'void)) o)
    ((or "true" "false") tree:bool)
    ((and (? string?) (? string->number)) tree:int)
    ((? (is? 'enum-literal)) '(enum))
    ((? (is? 'literal)) (tree:type? (.value o)))
    (_ #f)))

(define (tree:type-equal? a b)
  (tree:name-equal? (.type-name a)  (.type-name b)))

(define (tree:location? o)
  ((is? 'location) o))

(define (has-location? o)
  (and (pair? o) (slot o 'location)))

(define (tree:name-equal? a b)
  (and a b
       (assert-type a string? 'name 'compound-name 'scope)
       (assert-type b string? 'name 'compound-name 'scope)
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

(define (tree:port-qualifier? o)
  (or (and (is-a? o 'blocking-q)
           'blocking)
      (is-a? o 'external)
      (is-a? o 'injected)))

(define (tree:provides? o)
  (match o
    ((? (is? 'port)) (slot o 'provides))))

(define (tree:requires? o)
  (match o
    ((? (is? 'port)) (slot o 'requires))))


;;;
;;; Context.
;;;
;;; A context is a list of tree elements:
;;;
;;; (tree parent grand-parent ... root)
;;;

(define (.tree context)
  (and (context? context) (car context)))

(define* (tree->context tree #:optional (context '()))
  (cons tree context))

(define (.parent context)
  (and (context? context) (cdr context)))

(define (complete? o)
  ((disjoin string?
            (conjoin pair?
                     (compose symbol? first)
                     (compose (is? 'location) last)
                     (compose (cute every complete? <>)
                              (cute drop-right <> 1)
                              cdr))) o))

(define incomplete? (negate complete?))

(define (context? context)
  (and (pair? context) (tree? (car context)) context))

(define (context:parent context type)
  (let loop ((context (.parent context)))
    (and (context? context)
         (let ((tree (.tree context)))
           (if (is-a? tree type) context
               (and tree
                    (loop (.parent context))))))))

(define (parent context type)
  (and=> (context:parent context type)
         .tree))


;;;
;;; Parse tree accessors.
;;;

(define (tree:list-model* tree)
  (if (not (tree? tree)) '()
      (context:collect tree tree:model?)))

(define (tree:collect o predicate)
  (if (not (tree? o)) '()
      (if (predicate o) (cons o (append-map (cute tree:collect <> predicate) o))
          (append-map (cute tree:collect <> predicate) o))))

(define (tree:filter o predicate)
  (if (predicate o) (cons o (append-map (cute tree:filter <> predicate) o))
      '()))

(define (tree:direction o)
  (match o
    ((? (is? 'event)) (tree:direction (.direction o)))
    ((? (is? 'direction)) (string->symbol (.direction o)))
    ((? (is? 'provides)) 'provides)
    ((? (is? 'requires)) 'requires)
    ((? pair?) (tree:direction (find tree:direction o)))
    (_ #f)))

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
     (values scope name))
    ((? string?) (values '() o))))

(define (tree:full-name o)
  (tree:id* o))

(define (tree:dotted-name o)
  "Return name of O as a string, scopes separated by dots."
  (match o
    ((? (is? 'name)) (.name o))
    ((? (is? 'compound-name)) (string-join (filter-map tree:dotted-name `(,@(.scope o) ,(.name o))) "."))
    ((? (is? 'event-name)) (tree:dotted-name (.name o)))
    ((? (is? 'instance)) (tree:dotted-name (.name o)))
    ((? (is? 'port)) (tree:dotted-name (.name o)))
    ((? (is? 'type-name)) #f)
    ((? pair?) (tree:dotted-name (find tree:dotted-name o)))
    (_ #f)))

(define (tree:offset o)
  (and=> (.location o) .pos))

(define (tree:file-name o)
  (and=> (.location o) .file-name))

(define (tree:declaration* o)
  (match o
    ((or (? (is? 'root))
         (? (is? 'behavior-statements))
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
    ((? (is? 'behavior))
     (tree:declaration* (.behavior-compound o)))
    ((? (is? 'behavior-compound))
     (tree:declaration* (.behavior-statements o)))
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
    ((? (is? 'name))
     (list (.name o)))
    (('scope (? (is? 'name) name) ... (? (is? 'location) location))
     (append-map tree:id* name))
    ((? (is? 'compound-name))
     (append (tree:id* (.scope o)) (tree:id* (.name o))))
    (((? string? id) ...)
     o)
    ((? string?)
     (list o))))

(define (tree:instance* o)
  (match o
    ((? (is? 'instances-and-bindings)) (slots o 'instance))
    ((? (is? 'system)) (tree:instance* (.instances-and-bindings o)))
    (_ '())))

(define (tree:import* o)
  (match o
    ((? (is? 'root)) (slots o 'import))
    (_ '())))

(define (tree:port* o)
  (match o
    ((? (is? 'port)) (list o))
    ((? pair?) (append-map tree:port* o))
    (_ '())))

(define (tree:port-qualifier* o)
  (match o
    ((? (is? 'port)) (tree:port-qualifier* (.port-qualifiers o)))
    ((? (is? 'port-qualifiers))  (slots o tree:port-qualifier?))
    ((or (? (is? 'external) (? (is? 'injected)))) (list o))
    (_ '())))

(define* tree:top*
  (pure-funcq
   (lambda* (o #:key (imports '()) (seen '()))
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
        '())))))

(define (tree:namespace* o)
  (filter (is? 'namespace) (tree:top* o)))

(define (tree:component* o)
  (filter (is? 'component) (tree:top* o)))

(define (tree:interface* o)
  (filter (is? 'interface) (tree:top* o)))

(define (tree:model* o)
  (filter (is? tree:model?) (tree:top* o)))

(define (tree:type* o)
  (match o
    ((? (is? 'behavior)) (append-map tree:type* (slots o tree?)))
    ((? (is? 'interface)) (append-map tree:type* (slots o 'types-and-events)))
    ((or (? (is? 'enum)) (? (is? 'extern)) (? (is? 'int))) `(,o))
    ((? (is? 'root))
     (append (append-map tree:type* (filter (is? 'interface) (tree:top* o)))
             (filter (disjoin (is? 'enum) (is? 'int) (is? 'extern)) (tree:top* o))))
    ((? pair?) (append-map tree:type* o))
    (_ '())))

(define (tree:enum* o)
  (filter (is? 'enum) (tree:type* o)))

(define (tree:int* o)
  (filter (is? 'int) (tree:type* o)))

(define (tree:argument* o)
  (match o
    ((? (is? 'action)) (tree:argument* (slot o 'arguments)))
    ((? (is? 'call)) (tree:argument* (slot o 'arguments)))
    ((? (is? 'arguments)) (slots o 'argument))
    (_ '())))

(define (tree:event* o)
  (match o
    ((? (is? 'interface)) (append-map tree:event* (cdr o)))
    ((? (is? 'event)) `(,o))
    ((? pair?) (append-map tree:event* o))
    (_ '())))

(define (tree:function* o)
  (assert-type o 'behavior-statements 'behavior-compound 'behavior)
  (match o
    ((? (is? 'behavior)) (tree:function* (.behavior-compound o)))
    ((? (is? 'behavior-compound)) (tree:function* (.behavior-statements o)))
    ((? (is? 'behavior-statements)) (slots o (is? 'function)))))

(define (tree:statement* o)
  (assert-type o 'behavior 'behavior-compound 'behavior-statements 'blocking 'compound 'guard 'function 'if 'on)
  (match o
    ((? (is? 'behavior)) (tree:statement* (.behavior-compound o)))
    ((? (is? 'behavior-compound)) (tree:statement* (.behavior-statements o)))
    (_ (slots o tree:statement?))))

(define (tree:variable* o)
  (assert-type o 'behavior-statements 'compound 'function)
  (match o
    ((? (is? 'function))
     '())
    (_
     (slots o 'variable))))

(define (tree:formal* o)
  (match o
    ((? (is? 'event)) (tree:formal* (slot o 'formals)))
    ((? (is? 'formals)) (slots o 'formal))
    ((? (is? 'function)) (tree:formal* (slot o 'formals)))
    ((? (is? 'trigger)) (tree:formal* ( slot o 'trigger-formals)))
    ((? (is? 'trigger-formals)) (slots o 'trigger-formal))
    (_ '())))

(define (tree:trigger* o)
  (match o
    ((? (is? 'triggers)) (slots o 'trigger))
    ((? (is? 'on)) (tree:trigger* (.triggers o)))
    (_ '())))


;;;
;;; Constants.
;;;

(define context:bool '((bool (name "bool"))))
(define context:extern '((extern (name "extern"))))
(define context:int '((int (name "int"))))
(define context:void '((void (name "void"))))

(define tree:bool (.tree context:bool))
(define tree:extern (.tree context:extern))
(define tree:int (.tree context:int))
(define tree:void (.tree context:void))


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

(define (tree:scoped-name->compound-name o)
  (match o
    (('scoped-name name location)
     `(compound-name (name ,name ,location) ,location))
    (((and type (or 'root 'namespace 'namespace-root)) slots ...)
     (let ((slots (map tree:scoped-name->compound-name slots)))
       `(,type ,@slots)))
    (((and type (or 'types-and-events 'behavior
                    'behavior-compound 'behavior-statements)) slots ...)
     (let ((slots (map tree:scoped-name->compound-name slots)))
       `(,type ,@slots)))
    ((and (type slots ...) (or (? tree:model?) (? tree:type?)))
     (let ((slots (map tree:scoped-name->compound-name slots)))
       `(,type ,@slots)))
    (_ o)))

(define (tree:normalize o)
  (tree:scoped-name->compound-name o))


;;;
;;; Context accessors.
;;;

(define* (context:collect tree predicate #:optional (context '()))
  (if (not (tree? tree)) '()
      (let* ((context (tree->context tree context))
             (rest (append-map (cute context:collect <> predicate context) tree)))
        (if (not (predicate tree)) rest
            (cons context rest)))))

(define (context:full-name context)
  (filter (negate string-null?)
          (append-map tree:id*
                      (filter-map .name (filter tree:scope? (reverse context))))))

(define (context:dotted-name context)
  (string-join (context:full-name context) "."))

(define (context:stripped-dotted-name o context)
  (define (strip-prefix prefix str)
    (let loop ((prefix prefix))
      (let ((prefix-string (string-join prefix "." 'suffix)))
        (cond ((null? prefix)
               str)
              ((string-prefix? prefix-string str)
               (substring str (string-length prefix-string)))
              (else
               (loop (drop-right prefix 1)))))))
  (let ((name (context:dotted-name o))
        (namespace (or (context:parent context tree:model?)
                       (context:parent context (is? 'namespace)))))
    (if (not namespace) name
        (let ((prefix (context:full-name namespace)))
          (strip-prefix prefix name)))))

(define* context:root-top*
  (pure-funcq
   (lambda* (o #:key (imports '()) (seen '()))
     (let ((context (list o)))
       (match o
         ((? (is? 'root))
          (let* ((file-name ((%resolve-file) (.file-name o) #:imports imports))
                 (imports (cons (dirname file-name) imports))
                 (seen (cons file-name seen)))
            (map (lambda (x) (if (context? x) x (tree->context x context)))
                 (append-map (cut context:top* <> #:imports imports #:seen seen)
                             (map (cute tree->context <> context) (slots o tree?))))))
         (_
          '()))))))

(define* (context:top* o #:key (imports '()) (seen '()))
  (match (.tree o)
    ((? (is? 'root))
     (context:root-top* (.tree o)))
    ((? (is? 'import))
     (let ((file-name ((%resolve-file) (.file-name (.tree o)) #:imports imports)))
       (if (member file-name seen) '()
           (and=> ((%file-name->parse-tree) file-name)
                  (compose context:top* tree->context)))))
    ((? (is? 'interface))
     (cons o
           (map (cute cons <> o)
                (and=> (slot (.tree o) 'types-and-events) (cute slots <> tree?)))))
    ((? (is? 'namespace))
     (append-map (cut context:top* <> #:imports imports #:seen seen)
                 (map (cute tree->context <> o)
                      (slots (.namespace-root (.tree o)) tree?))))
    ((? tree?)
     (list o))
    (_
     '())))

(define (context:type* o)
  (define (helper o)
    (match (.tree o)
      ((or (? (is? 'behavior))
           (? (is? 'behavior-compound))
           (? (is? 'behavior-statements))
           (? (is? 'types-and-events)))
       (append-map helper
                   (map (cute cons <> o)
                        (slots (.tree o) tree?))))
      ((? (is? 'root))
       (filter (compose tree:type? .tree) (context:top* o)))
      ((? tree:type?)
       (list o))
      (_
       '())))

  (let loop ((o o))
    (if (not (context? o)) '()
        (append (helper o) (loop (.parent o))))))

(define (tree*->context* accessor)
  (lambda (context)
    (map (cute tree->context <> context) (accessor (.tree context)))))

(define context:event*    (tree*->context* tree:event*))
(define context:formal*   (tree*->context* tree:formal*))
(define context:function* (tree*->context* tree:function*))
(define context:port*     (tree*->context* tree:port*))
(define context:trigger*  (tree*->context* tree:trigger*))
(define context:variable* (tree*->context* tree:variable*))

(define (tree:top*->context* predicate)
  (lambda (context)
    (filter (compose predicate .tree) (context:top* context))))

(define context:interface* (tree:top*->context* (is? 'interface)))
(define context:component* (tree:top*->context* (is? 'component)))
(define context:model*     (tree:top*->context* tree:model))
