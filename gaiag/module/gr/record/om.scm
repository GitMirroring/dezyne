;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gr record om)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

  :use-module (srfi srfi-9)
  :use-module (srfi srfi-9 gnu)

  :use-module (gaiag misc)
  :export (
           ast-name
           om:children
           ast-accessors
           om:clone
           .ast
           .message
           <error>

           is-a?
           is?

           .arguments
           .behaviour
           .bindings
           .component
           .direction
           .elements
           .else
           .event
           .events
           .expression
           .field
           .fields
           .from
           .functions
           .identifier
           .injected
           .instance
           .instances
           .last?
           .left
           .name
           .parameters
           .port
           .ports
           .range
           .recursive
           .right
           .scope
           .signature
           .statement
           .then
           .to
           .trigger
           .triggers
           .type
           .types
           .value
           .variables
           <action>
           <arguments>
           <assign>
           <ast>
           <ast-list>
           <behaviour>
           <bind>
           <binding>
           <bindings>
           <call>
           <component>
           <compound>
           <data>
           <declarative>
           <enum>
           <event>
           <events>
           <expression>
           <extern>
           <field>
           <fields>
           <function>
           <functions>
           <guard>
           <if>
           <illegal>
           <imperative>
           <import>
           <instance>
           <instances>
           <int>
           <interface>
           <literal>
           <model>
           <named>
           <on>
           <otherwise>
           <om:parameter>
           <parameters>
           <om:port>
           <ports>
           <range>
           <reply>
           <return>
           <root>
           <signature>
           <statement>
           <system>
           <trigger>
           <triggers>
           <type>
           <types>
           <value>
           <var>
           <variable>
           <variables>
           <*type*>


           make
           make-<action>
           make-<assign>
           make-<arguments>
           make-<behaviour>
           make-<bind>
           make-<binding>
           make-<bindings>
           make-<call>
           make-<component>
           make-<data>           
           make-<enum>
           make-<error>
           make-<event>
           make-<events>
           make-<extern>
           make-<expression>
           make-<field>
           make-<fields>
           make-<function>
           make-<guard>
           make-<instance>
           make-<if>
           make-<instances>
           make-<int>
           make-<interface>
           make-<named>
           make-<system>
           make-<bindings>
           make-<compound>
           make-<functions>
           make-<illegal>
           make-<import>
           make-<instances>
           make-<instances>
           make-<instance>
           make-<literal>
           make-<on>
           make-<otherwise>
           make-<om:parameter>
           make-<parameters>
           make-<om:port>
           make-<ports>
           make-<range>
           make-<reply>
           make-<return>
           make-<root>
           make-<scoped>
           make-<signature>
           make-<type>
           make-<types>
           make-<trigger>
           make-<triggers>
           make-<var>
           make-<variable>
           make-<value>           
           make-<variables>

           make-action
           make-assign
           make-arguments
           make-behaviour
           make-bind
           make-binding
           make-bindings
           make-call
           make-component
           make-enum
           make-error
           make-event
           make-events
           make-extern
           make-expression
           make-field
           make-fields
           make-function
           make-guard
           make-instance
           make-if
           make-instances
           make-int
           make-interface
           make-named
           make-system
           make-bindings
           make-compound
           make-functions
           make-import
           make-instances
           make-instance
           make-literal
           make-on
           make-otherwise
           make-om:parameter
           make-parameters
           make-om:port
           make-ports
           make-range
           make-root
           make-scoped
           make-signature
           make-type
           make-types
           make-trigger
           make-triggers
           make-value
           make-var
           make-variable
           make-variables


           ))

(cond-expand-provide (current-module) '(record-om))

(define (debug . args) #t)

;;lists
(define-record-type <compound> (make-compound elements)
  compound?
  (elements compound.elements))

(define-record-type <arguments> (make-arguments elements)
  arguments?
  (elements arguments.elements))

(define-record-type <bindings> (make-bindings elements)
  bindings?
  (elements bindings.elements))

(define-record-type <events> (make-events elements)
  events?
  (elements events.elements))

(define-record-type <fields> (make-fields elements)
  fields?
  (elements fields.elements))

(define-record-type <functions> (make-functions elements)
  functions?
  (elements functions.elements))

(define-record-type <instances> (make-instances elements)
  instances?
  (elements instances.elements))

(define-record-type <parameters> (make-parameters elements)
  parameters?
  (elements parameters.elements))

(define-record-type <ports> (make-ports elements)
  ports?
  (elements ports.elements))

(define-record-type <root> (make-root elements)
  root?
  (elements root.elements))

(define-record-type <triggers> (make-triggers elements)
  triggers?
  (elements triggers.elements))

(define-record-type <types> (make-types elements)
  types?
  (elements types.elements))

(define-record-type <variables> (make-variables elements)
  variables?
  (elements variables.elements))



(define-record-type <import> (make-import name)
  import?
  (name import.name))

(define-record-type <interface> (make-interface name types events behaviour)
  interface?
  (name interface.name) (types interface.types) (events interface.events) (behaviour interface.behaviour))

(define-record-type <type> (make-type name scope)
  type?
  (name type.name) (scope type.scope))

(define-record-type <signature> (make-signature type parameters)
  signature?
  (type signature.type) (parameters signature.parameters))

(define-record-type <event> (make-event name signature direction)
  event?
  (name event.name) (signature event.signature) (direction event.direction))

(define-record-type <om:port> (make-om:port name type direction injected)
  om:port?
  (name port.name) (type port.type) (direction port.direction) (injected port.injected))

(define-record-type <trigger> (make-trigger port event arguments)
  trigger?
  (port trigger.port) (event trigger.event) (arguments trigger.arguments))

(define-record-type <expression> (make-expression value)
  expression?
  (value expression.value))

(define-record-type <otherwise> (make-otherwise value)
  otherwise?
  (value otherwise.value))

(define-record-type <var> (make-var name)
  var?
  (name var.name))

(define-record-type <field> (make-field identifier field)
  field?
  (identifier field.identifier) (field field.field))

(define-record-type <value> (make-value type field)
  value?
  (type value.type) (field value.field))

(define-record-type <literal> (make-literal scope type field)
  literal?
  (scope literal.scope) (type literal.type) (field literal.field))

(define-record-type <om:parameter> (make-om:parameter name type direction)
  om:parameter?
  (name parameter.name) (type parameter.type) (direction parameter.direction))

(define-record-type <component> (make-component name ports behaviour)
  component?
  (name component.name) (ports component.ports) (behaviour component.behaviour))

(define-record-type <system> (make-system name ports instances bindings)
  system?
  (name system.name) (ports system.ports) (instances system.instances) (bindings system.bindings))

(define-record-type <enum> (make-enum name scope fields)
  enum?
  (name enum.name) (scope enum.scope) (fields enum.fields))

(define-record-type <extern> (make-extern name scope value)
  extern?
  (name extern.name) (scope extern.scope) (value extern.value))

(define-record-type <data> (make-data value)
  data?
  (value data.value))

(define-record-type <int> (make-int name scope range)
  int?
  (name int.name) (scope int.scope) (range int.range))

(define-record-type <range> (make-range from to)
  range?
  (from range.from) (to range.to))

(define-record-type <behaviour> (make-behaviour name types variables functions statement)
  behaviour?
  (name behaviour.name) (types behaviour.types) (variables behaviour.variables) (functions behaviour.functions) (statement behaviour.statement))

(define-record-type <function> (make-function name signature recursive statement)
  function?
  (name function.name) (signature function.signature) (recursive function.recursive) (statement function.statement))

;;; statements

(define-record-type <action> (make-action trigger)
  action?
  (trigger action.trigger))

(define-record-type <assign> (make-assign identifier expression)
  assign?
  (identifier assign.identifier) (expression assign.expression))

(define-record-type <call> (make-call identifier arguments last?)
  call?
  (identifier call.identifier) (arguments call.arguments) (last? call.last?))

(define-record-type <guard> (make-guard expression statement)
  guard?
  (expression guard.expression) (statement guard.statement))

(define-record-type <if> (make-if expression then else)
  if?
  (expression if.expression) (then if.then) (else if.else))

(define-record-type <illegal> (make-illegal)
  illegal?)

(define-record-type <on> (make-on triggers statement)
  on?
  (triggers on.triggers) (statement on.statement))

(define-record-type <reply> (make-reply expression)
  reply?
  (expression reply.expression))

(define-record-type <return> (make-return expression)
  return?
  (expression return.expression))

(define-record-type <variable> (make-variable name type expression)
  variable?
  (name variable.name) (type variable.type) (expression variable.expression))

(define-record-type <bind> (make-bind left right)
  bind?
  (left bind.left) (right bind.right))

(define-record-type <binding> (make-binding instance port)
  binding?
  (instance binding.instance) (port binding.port))

(define-record-type <instance> (make-instance name component)
  instance?
  (name instance.name) (component instance.component))

(define-record-type <error> (make-error ast message)
  error?
  (ast error.ast) (message error.message))



(define-record-type <ast> (make-ast) record-ast?)
(define-record-type <ast-list> (make-ast-list) record-ast-list?)
(define-record-type <model> (make-model) record-model?)
(define-record-type <*type*> (make-*type*) record-*type*?)
(define-record-type <named> (make-named) record-named?)
(define-record-type <statement> (make-statement) record-statement?)

;;;; CLONING
;;lists
(define (ast-accessors o)
  (match o
    (($ <compound>) (list compound.elements))
    (($ <arguments>) (list arguments.elements))
    (($ <bindings>) (list bindings.elements))
    (($ <events>) (list events.elements))
    (($ <fields>) (list fields.elements))
    (($ <functions>) (list functions.elements))
    (($ <instances>) (list instances.elements))
    (($ <parameters>) (list parameters.elements))
    (($ <ports>) (list ports.elements))
    (($ <root>) (list root.elements))
    (($ <triggers>) (list triggers.elements))
    (($ <types>) (list types.elements))
    (($ <variables>) (list variables.elements))

    (($ <import>) (list import.name))
    (($ <interface>) (list interface.name interface.types interface.events interface.behaviour))
    (($ <type>) (list type.name type.scope))
    (($ <signature>) (list signature.type signature.parameters))
    (($ <event>) (list event.name event.signature event.direction))
    (($ <om:parameter>) (list parameter.name parameter.type parameter.direction))
    (($ <om:port>) (list port.name port.type port.direction port.injected))
    (($ <trigger>) (list trigger.port trigger.event trigger.arguments))
    (($ <expression>) (list expression.value))
    (($ <otherwise>) (list otherwise.value))
    (($ <var>) (list var.name))
    (($ <field>) (list field.identifier field.field))
    (($ <value>) (list value.type value.field))
    (($ <literal>) (list literal.scope literal.type literal.field))
    (($ <component>) (list component.name component.ports component.behaviour))
    (($ <system>) (list system.name system.ports system.instances system.bindings))
    (($ <enum>) (list enum.name enum.scope enum.fields))
    (($ <extern>) (list extern.name extern.scope extern.value))
    (($ <data>) (list data.value))
    (($ <int>) (list int.name int.scope int.range))
    (($ <range>) (list range.from range.to))
    (($ <behaviour>) (list behaviour.name behaviour.types behaviour.variables behaviour.functions behaviour.statement))
    (($ <function>) (list function.name function.signature function.recursive function.statement))

;;; statements
    (($ <action>) (list action.trigger))
    (($ <assign>) (list assign.identifier assign.expression))
    (($ <call>) (list call.identifier call.arguments call.last?))
    (($ <guard>) (list guard.expression guard.statement))
    (($ <if>) (list if.expression if.then if.else))
    (($ <illegal>) (list))
    (($ <on>) (list on.triggers on.statement))
    (($ <reply>) (list reply.expression))
    (($ <return>) (list return.expression))
    (($ <variable>) (list variable.name variable.type variable.expression))
    (($ <bind>) (list bind.left bind.right))
    (($ <binding>) (list binding.instance binding.port))
    (($ <instance>) (list instance.name instance.component))
    (($ <error>) (list error.ast error.message))))

(define (ast-record-type o)
  (match o
    (($ <compound>) <compound>)
    (($ <arguments>) <arguments>)
    (($ <bindings>) <bindings>)
    (($ <events>) <events>)
    (($ <fields>) <fields>)
    (($ <functions>) <functions>)
    (($ <instances>) <instances>)
    (($ <parameters>) <parameters>)
    (($ <ports>) <ports>)
    (($ <root>) <root>)
    (($ <triggers>) <triggers>)
    (($ <types>) <types>)
    (($ <variables>) <variables>)

    (($ <import>) <import>)
    (($ <interface>) <interface>)
    (($ <type>) <type>)
    (($ <signature>) <signature>)
    (($ <event>) <event>)
    (($ <om:port>) <om:port>)
    (($ <trigger>) <trigger>)
    (($ <expression>) <expression>)
    (($ <otherwise>) <otherwise>)
    (($ <var>) <var>)
    (($ <field>) <field>)
    (($ <value>) <value>)
    (($ <literal>) <literal>)
    (($ <om:parameter>) <om:parameter>)
    (($ <component>) <component>)
    (($ <system>) <system>)
    (($ <enum>) <enum>)
    (($ <extern>) <extern>)
    (($ <data>) <data>)
    (($ <int>) <int>)
    (($ <range>) <range>)
    (($ <behaviour>) <behaviour>)
    (($ <function>) <function>)

;;; statements
    (($ <action>) <action>)
    (($ <assign>) <assign>)
    (($ <call>) <call>)
    (($ <guard>) <guard>)
    (($ <if>) <if>)
    (($ <illegal>) <illegal>)
    (($ <on>) <on>)
    (($ <reply>) <reply>)
    (($ <return>) <return>)
    (($ <variable>) <variable>)
    (($ <bind>) <bind>)
    (($ <binding>) <binding>)
    (($ <instance>) <instance>)
    (($ <error>) <error>)))

(define (ast-constructor o)
  (match o
    (($ <compound>) make-compound)
    (($ <arguments>) make-arguments)
    (($ <bindings>) make-bindings)
    (($ <events>) make-events)
    (($ <fields>) make-fields)
    (($ <functions>) make-functions)
    (($ <instances>) make-instances)
    (($ <parameters>) make-parameters)
    (($ <ports>) make-ports)
    (($ <root>) make-root)
    (($ <triggers>) make-triggers)
    (($ <types>) make-types)
    (($ <variables>) make-variables)

    (($ <import>) make-import)
    (($ <interface>) make-interface)
    (($ <type>) make-type)
    (($ <signature>) make-signature)
    (($ <event>) make-event)
    (($ <om:port>) make-om:port)
    (($ <trigger>) make-trigger)
    (($ <expression>) make-expression)
    (($ <otherwise>) make-otherwise)
    (($ <var>) make-var)
    (($ <field>) make-field)
    (($ <value>) make-value)
    (($ <literal>) make-literal)
    (($ <om:parameter>) make-om:parameter)
    (($ <component>) make-component)
    (($ <system>) make-system)
    (($ <enum>) make-enum)
    (($ <extern>) make-extern)
    (($ <data>) make-data)
    (($ <int>) make-int)
    (($ <range>) make-range)
    (($ <behaviour>) make-behaviour)
    (($ <function>) make-function)

;;; statements
    (($ <action>) make-action)
    (($ <assign>) make-assign)
    (($ <call>) make-call)
    (($ <guard>) make-guard)
    (($ <if>) make-if)
    (($ <illegal>) make-illegal)
    (($ <on>) make-on)
    (($ <reply>) make-reply)
    (($ <return>) make-return)
    (($ <variable>) make-variable)
    (($ <bind>) make-bind)
    (($ <binding>) make-binding)
    (($ <instance>) make-instance)
    (($ <error>) make-error)))

(define ast-leafs
  '(
    ast
    model
    named
    type

    action
    assign
    behaviour
    bind
    binding
    call
    component
    enum
    event
    error
    expression
    extern
    field
    function
    guard
    if
    illegal
    import
    instance
    int
    interface
    literal
    on
    otherwise
    parameter
    port
    range
    reply
    return
    signature
    system
    trigger
    var
    variable
    ))

(define ast-lists
  '(
    arguments
    bindings
    compound
    events
    fields
    functions
    instances
    parameters
    ports
    root
    triggers
    types
    variables
    ))

(define ast-statements
  '(
    action
    assign
    behaviour
    bind
    call
    compound
    enum
    extern
    guard
    if
    illegal
    instance
    int
    on
    otherwise
    reply
    return
    variable
    ))

;;(define ast-nodes (delete-duplicates (append ast-leafs ast-statements ast-lists)))
(define ast-nodes (append ast-leafs ast-lists))

(define (symbol->class x) (symbol-append '< x '>))

(define (ast-class x) (and (ast? x) ((compose symbol->class ast-name) x)))

(define (ast-name ast)
  (match ast
    ;;leafs
    ;; ((? ast?) 'ast)
    ;; ((? ast-list?) 'ast-list)    
    ;; ((? type?) 'type)
    ;; ((? model?) 'model)
    ;; ((? named?) 'named)

    ((? assign?) 'assign)
    ((? action?) 'action)
    ((? behaviour?) 'behaviour)
    ((? bind?) 'bind)
    ((? binding?) 'binding)
    ((? call?) 'call)
    ((? component?) 'component)
    ((? enum?) 'enum)
    ((? event?) 'event)
    ((? error?) 'error)
    ((? expression?) 'expression)
    ((? extern?) 'extern)
    ((? field?) 'field)
    ((? function?) 'function)
    ((? guard?) 'guard)
    ((? if?) 'if)
    ((? illegal?) 'illegal)
    ((? import?) 'import)
    ((? instance?) 'instance)
    ((? int?) 'int)
    ((? interface?) 'interface)
    ((? literal?) 'literal)
    ((? on?) 'on)
    ((? otherwise?) 'otherwise)
    ((? om:parameter?) 'parameter)    
    ((? om:port?) 'port)
    ((? range?) 'range)
    ((? reply?) 'reply)
    ((? return?) 'return)
    ((? signature?) 'signature)
    ((? system?) 'system)
    ((? trigger?) 'trigger)
    ((? type?) 'type)    
    ((? value?) 'value)
    ((? var?) 'var)    
    ((? variable?) 'variable)

    ;;lists
    ((? arguments?) 'arguments)
    ((? bindings?) 'bindings)
    ((? compound?) 'compound)
    ((? events?) 'events)
    ((? fields?) 'fields)
    ((? functions?) 'functions)
    ((? instances?) 'instances)
    ((? parameters?) 'parameters)
    ((? ports?) 'ports)
    ((? root?) 'root)
    ((? triggers?) 'triggers)
    ((? types?) 'types)
    ((? variables?) 'variables)
    (*unspecified* #f)
;;    (_ (stderr "no match: x\n" (ast-name ast)))

    ))

(define (ast? ast)
  (and (record? ast) (member (ast-name ast) (append ast-leafs ast-lists)) ast))

(define (ast-list? ast)
  (and (record? ast) (member (ast-name ast) ast-lists) ast))

(define (model? ast)
  (or (interface? ast) (component? ast) (system? ast)))

(define (statement? ast)
  (and (record? ast) (member (ast-name ast) ast-statements) ast))

(define (*type*? ast)
  (or (enum? ast) (extern? ast) (int? ast) (type? ast)))

(define (is-a? ast type)
  ((is? type) ast))

;; this is kinda ugly: we simulate inheritance
;; interface, component, system are models
;; otherwise is an expression

(define ((is? type) o)
  (define ((t? t p) x) (and (eq? x t) (p o)))
  (match type

    ((? (t? <ast-list> ast-list?)) o)
    ((? (t? <ast> ast?)) o)
    ((? (t? <model> model?)) o)
    ;;     (($ <named>) o)
    ((? (t? <*type*> *type*?)) o)
    
    ;;leafs
    ((? (t? <assign> assign?)) o)
    ((? (t? <action> action?)) o)
    ((? (t? <behaviour> behaviour?)) o)
    ((? (t? <bind> bind?)) o)
    ((? (t? <binding> binding?)) o)
    ((? (t? <call> call?)) o)
    ((? (t? <component> component?)) o)
    ((? (t? <enum> enum?)) o)
    ((? (t? <event> event?)) o)
    ((? (t? <error> error?)) o)
    ((? (t? <expression> expression?)) o)
    ((? (t? <extern> extern?)) o)
    ((? (t? <field> field?)) o)
    ((? (t? <function> function?)) o)
    ((? (t? <guard> guard?)) o)
    ((? (t? <if> if?)) o)
    ((? (t? <illegal> illegal?)) o)
    ((? (t? <import> import?)) o)
    ((? (t? <instance> instance?)) o)
    ((? (t? <int> int?)) o)
    ((? (t? <interface> interface?)) o)
    ((? (t? <literal> literal?)) o)
    ((? (t? <on> on?)) o)
    ((? (t? <otherwise> otherwise?)) o)
    ((? (t? <om:parameter> om:parameter?)) o)
    ((? (t? <om:port> om:port?)) o)
    ((? (t? <range> range?)) o)
    ((? (t? <reply> reply?)) o)
    ((? (t? <return> return?)) o)
    ((? (t? <signature> signature?)) o)
    ((? (t? <system> system?)) o)
    ((? (t? <trigger> trigger?)) o)
    ((? (t? <type> type?)) o)
    ((? (t? <var> var?)) o)
    ((? (t? <variable> variable?)) o)

    ;;lists
    ((? (t? <arguments> arguments?)) o)
    ((? (t? <bindings> bindings?)) o)
    ((? (t? <compound> compound?)) o)
    ((? (t? <events> events?)) o)
    ((? (t? <fields> fields?)) o)
    ((? (t? <functions> functions?)) o)
    ((? (t? <instances> instances?)) o)
    ((? (t? <parameters> parameters?)) o)
    ((? (t? <ports> ports?)) o)
    ((? (t? <root> root?)) o)
    ((? (t? <triggers> triggers?)) o)
    ((? (t? <types> types?)) o)
    ((? (t? <variables> variables?)) o)
    (_ #f)))



(define (.behaviour o)
  (match o
    (($ <interface> name types events behaviour) behaviour)
    (($ <component> name ports behaviour) behaviour)))

(define (.direction o)
  (match o
    (($ <event> name signature direction) direction)
    (($ <om:port> name type direction) direction)
    (($ <om:parameter> name type direction) direction)))

(define (.elements o)
  (match o
    (($ <arguments> elements) elements)
    (($ <bindings> elements) elements)
    (($ <compound> elements) elements)
    (($ <events> elements) elements)
    (($ <fields> elements) elements)
    (($ <functions> elements) elements)
    (($ <instances> elements) elements)
    (($ <parameters> elements) elements)
    (($ <ports> elements) elements)
    (($ <root> elements) elements)
    (($ <triggers> elements) elements)
    (($ <types> elements) elements)
    (($ <variables> elements) elements)))

(define (.expression o)
  (match o
    (($ <assign> identifier expression) expression)
    (($ <guard> expression) expression)
    (($ <if> expression) expression)
    (($ <reply> expression) expression)
    (($ <return> expression) expression)
    (($ <variable> name type expression) expression)))

(define (.then o)
  (match o
    (($ <if> expression then else) then)))

(define (.else o)
  (match o
    (($ <if> expression then else) else)))

(define (.left o)
  (match o
    (($ <bind> left right) left)))

(define (.right o)
  (match o
    (($ <bind> left right) right)))

(define (.instance o)
  (match o
    (($ <binding> instance port) instance)))

(define (.from o)
  (match o
    (($ <range> from to) from)))

(define (.to o)
  (match o
    (($ <range> from to) to)))

(define (.message o)
  (match o
    (($ <error> ast message) message)
    (($ <root> models) #f)
    ))

(define (.ast o)
  (match o
    (($ <error> ast message) ast)
    (($ <root> models) #f)
    ))

(define (.range o)
  (match o
    (($ <int> name scope range) range)))

(define (.fields o)
  (match o
    (($ <enum> name scope fields) fields)))

(define (.arguments o)
  (match o
    (($ <call> identifier arguments) arguments)
    (($ <trigger> port event arguments) arguments)))

(define (.last? o)
  (match o
    (($ <call> identifier arguments last?) last?)))

(define (.bindings o)
  (match o
    (($ <system> name ports instances bindings) bindings)))

(define (.events o)
  (match o
    (($ <interface> name types events) events)))

(define (.event o)
  (match o
    (($ <trigger> port event) event)))

(define (.instances o)
  (match o
    (($ <system> name ports instances bindings) instances)))

(define (.parameters o)
  (match o
    (($ <signature> type parameters) parameters)))

(define (.trigger o)
  (match o
    (($ <action> trigger) trigger)))

(define (.triggers o)
  (match o
    (($ <on> triggers) triggers)))

(define (.variables o)
  (match o
    (($ <behaviour> name types variables functions statement) variables)))

(define (.functions o)
  (match o
    (($ <behaviour> name types variables functions statement) functions)))

(define (.injected o)
  (match o
    (($ <om:port> name type direction injected) injected)))

(define (.field o)
  (match o
    (($ <field> identifier field) field)
    (($ <literal> scope type field) field)
    (($ <value> type field) field)))

(define (.identifier o)
  (match o
    (($ <assign> identifier) identifier)
    (($ <call> identifier) identifier)
    (($ <field> identifier field) identifier)))

(define (.name o)
  (match o
    (($ <behaviour> name) name)
    (($ <component> name) name)
    (($ <enum> name) name)
    (($ <event> name) name)
    (($ <extern> name) name)
    (($ <function> name) name)
    (($ <om:parameter> name) name)
    (($ <om:port> name) name)
    (($ <import> name) name)
    (($ <instance> name) name)
    (($ <interface> name) name)
    (($ <int> name) name)
;;    (($ <model> name) name)
;;    (($ <named> name) name)
    (($ <system> name) name)
    (($ <type> name) name)
    (($ <var> name) name)
    (($ <variable> name) name)))

(define (.component o)
  (match o
    (($ <instance> name component) component)))

(define (.port o)
  (match o
    (($ <binding> instance port) port)
    (($ <trigger> port event arguments) port)))

(define (.ports o)
  (match o
    (($ <component> name ports) ports)
    (($ <system> name ports) ports)))

(define (.scope o)
  (match o
    (($ <enum> name scope) scope)
    (($ <extern> name scope) scope)
    (($ <int> name scope) scope)
    (($ <type> name scope) scope)
    (($ <literal> scope type field) scope)))

(define (.signature o)
  (match o
    (($ <event> name signature direction) signature)
    (($ <function> name signature recursive statement) signature)))

(define (.statement o)
  (match o
    (($ <behaviour> name types variables functions statement) statement)
    (($ <function> name signature recursive statement) statement)
    (($ <guard> expression statement) statement)
    (($ <on> expression statement) statement)))

(define (.type o)
  (match o
    (($ <signature> type) type)
    (($ <om:port> name type) type)
    (($ <literal> scope type field) type)
    (($ <om:parameter> name type) type)
    (($ <value> type) type)
    (($ <variable> name type) type)))

(define (.types o)
  (match o
    (($ <interface> name types) types)
    (($ <behaviour> name types) types)))

(define (.value o)
  (match o
    (($ <data> value) value)
    (($ <expression> value) value)
    (($ <extern> name scope value) value)
    (($ <otherwise> value) value)))

(define (.recursive ast)
  (match ast
    (($ <function> name signature recursive statement) recursive)))

(define-syntax make
  (lambda (s)
    (syntax-case s ()
      ((_ type args ...)
       (with-syntax
           ((m (datum->syntax #'type (symbol-append 'make- (syntax->datum #'type))))) #'(m args ...))))))


;; Goops interface
(define (make-<import> . args)
  (let-keywords
   args #f
   ((name #f))
   (make-import name)))

(define (make-<interface> . args)
  (let-keywords
   args #f
   ((name #f)
    ;;(types (make o<types>))
    (types (make-types '()))
    (events (make <events>))
    (behaviour (make <behaviour>)))
   (make-interface name types events behaviour)))

(define (make-<component> . args)
  (let-keywords
   args #f
   ((name #f)
    (ports (make <ports>))
    (behaviour (make <behaviour>)))
   (make-component name ports behaviour)))

(define (make-<system> . args)
  (let-keywords
   args #f
   ((name #f)
    (ports (make <ports>))
    (instances (make <instances>))
    (bindings (make <bindings>)))
   (make-system name ports instances bindings)))

(define (make-<event> . args)
  (let-keywords
   args #f
   ((name #f)
    (signature (make <signature>))
    (direction #f))
   (make-event name signature direction)))

(define (make-<trigger> . args)
  (let-keywords
   args #f
   ((port #f)
    (event #f)
    (arguments (make <arguments>)))
   (make-trigger port event arguments)))

(define (make-<om:port> . args)
  (let-keywords
   args #f
   ((name #f)
    (type #f)
    (direction #f)
    (injected #f))
   (make-om:port name type direction injected)))

(define (make-<behaviour> . args)
  (let-keywords
   args #f
   ((name #f)
    (types (make <types>))
    (variables (make <variables>))
    (functions (make <functions>))
    (statement (make <compound>)))
   (make-behaviour name types variables functions statement)))

(define (make-<enum> . args)
  (let-keywords
   args #f
   ((name #f)
    (scope #f)
    (fields (make <fields>)))
   (make-enum name scope fields)))

(define (make-<extern> . args)
  (let-keywords
   args #f
   ((name #f)
    (scope #f)
    (value #f))
   (make-extern name scope value)))

(define (make-<expression> . args)
  (let-keywords
   args #f
   ((value #f))
   (make-expression value)))

(define (make-<function> . args)
  (let-keywords
   args #f
   ((name #f)
    (recursive #f)
    (signature (make <signature>))
    (statement (make <compound>)))
   (make-function name signature recursive statement)))

(define (make-<int> . args)
  (let-keywords
   args #f
   ((name #f)
    (scope #f)
    (range (make <range>)))
   (make-int name scope range)))

(define (make-<om:parameter> . args)
  (let-keywords
   args #f
   ((name #f)
    (type (make <type> :name 'void))
    (direction #f))
   (make-om:parameter name type direction)))

(define (make-<range> . args)
  (let-keywords
   args #f
   ((from 0)
    (to 0))
   (make-range from to)))

(define (make-<signature> . args)
  (let-keywords
   args #f
   ((type (make <type> :name 'void))
    (parameters (make <parameters>)))
   (make-signature type parameters)))

(define (make-<action> . args)
  (let-keywords
   args #f
   ((trigger #f))
   (make-action trigger)))

(define (make-<assign> . args)
  (let-keywords
   args #f
   ((identifier #f)
    (expression (make <expression>)))
   (make-assign identifier expression)))

(define (make-<call> . args)
  (let-keywords
   args #f
   ((identifier #f)
    (arguments (make <arguments>))
    (last? #f))
   (make-call identifier arguments last?)))

(define (make-<data> . args)
  (let-keywords
   args #f
   ((value #f))
   (make-data value)))

(define (make-<guard> . args)
  (let-keywords
   args #f
   ((expression (make <expression>))
    (statement #f))
   (make-guard expression statement)))

(define (make-<if> . args)
  (let-keywords
   args #f
   ((expression (make <expression>))
    (then #f)
    (else #f))
   (make-if expression then else)))

(define (make-<illegal> . args)
  (make-illegal))

(define (make-<on> . args)
  (let-keywords
   args #f
   ((triggers (make <triggers>))
    (statement #f))
   (make-on triggers statement)))

(define (make-<reply> . args)
  (let-keywords
   args #f
   ((expression #f))
   (make-reply expression)))

(define (make-<return> . args)
  (let-keywords
   args #f
   ((expression #f))
   (make-return expression)))

(define (make-<bind> . args)
  (let-keywords
   args #f
   ((left #f)
    (right #f))
   (make-bind left right)))

(define (make-<binding> . args)
  (let-keywords
   args #f
   ((instance #f)
    (port #f))
   (make-binding instance port)))

(define (make-<instance> . args)
  (let-keywords
   args #f
   ((name #f)
    (component #f))
   (make-instance name component)))

(define (make-<value> . args)
  (let-keywords
   args #f
   ((type #f)
    (field #f))
   (make-value type field)))

(define (make-<variable> . args)
  (let-keywords
   args #f
   ((name #f)
    (type #f)
    (expression (make <expression>)))
   (make-variable name type expression)))

(define (make-<var> . args)
  (let-keywords
   args #f
   ((name #f))
   (make-var name)))

(define (make-<otherwise> . args)
  (let-keywords
   args #f
   ((value 'otherwise))
   (make-otherwise value)))

(define (make-<field> . args)
  (let-keywords
   args #f
   ((identifier #f)
    (field #f))
   (make-field identifier field)))

(define (make-<literal> . args)
  (let-keywords
   args #f
   ((scope #f)
    (type #f)
    (field #f))
   (make-literal scope type field)))

(define (make-<type> . args)
  (let-keywords
   args #f
   ((name #f)
    (scope #f))
   (make-type name scope)))

(define (make-<error> . args)
  (let-keywords
   args #f
   ((ast #f)
    (message ""))
   (make-error ast message)))



;; FIXME
(define (make-<arguments> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-arguments elements)))

(define (make-<bindings> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-bindings elements)))

(define (make-<compound> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-compound elements)))

(define (make-<events> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-events elements)))

(define (make-<fields> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-fields elements)))

(define (make-<functions> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-functions elements)))

(define (make-<instances> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-instances elements)))

(define (make-<parameters> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-parameters elements)))

(define (make-<ports> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-ports elements)))

(define (make-<root> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-root elements)))

(define (make-<triggers> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-triggers elements)))

(define (make-<types> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-types elements)))

(define (make-<variables> . args)
  (let-keywords
   args #f
   ((elements '()))
   (make-variables elements)))


(define (om:children ast)
  (;;apply
   append
   (map
    (lambda (x) (x ast))
    (match ast
      ;;leafs
      ((? action?) (list .trigger))
      ((? assign?) (list .identifier .expression))
      ((? behaviour?) (list .name .types .variables .functions .statement))
      ((? bind?) (list .left .right))
      ((? binding?) (list .instance .port))
      ((? call?) (list .identifier .arguments .last?))
      ((? component?) (list .name .ports .behaviour))
      ((? data?) (list .value))
      ((? enum?) (list .name .scope .fields))
      ((? error?) (list .ast .message))
      ((? event?) (list .name .signature .direction))      
      ((? expression?) (list .value))
      ((? extern?) (list .name .scope .value))
      ((? field?) (list .identifier .field))
      ((? function?) (list .name .signature .recursive .statement))
      ((? om:parameter?) (list .name .type .direction))
      ((? om:port?) (list .name .type .direction .injected))
      ((? guard?) (list .expression .statement))
      ((? if?) (list .expression .then .else))
      ((? illegal?) (list))
      ((? import?) (list .name))
      ((? instance?) (list .name .component))
      ((? int?) (list .name .scope .range))
      ((? interface?) (list .name .types .events .behaviour))
      ((? literal?) (list .scope .type .field))
      ((? on?) (list .triggers .statement))
      ((? otherwise?) (list .value))
      ((? range?) (list .from .to))
      ((? reply?) (list .expression))
      ((? return?) (list .expression))
      ((? signature?) (list .type .parameters))
      ((? system?) (list .name .ports .instances .bindings))
      ((? trigger?) (list .port .event .arguments))
      ((? type?) (list .name .scope))
      ((? value?) (list .type .field))
      ((? var?) (list .name))
      ((? variable?) (list .name .type .expression))

      ;; lists
      ((? arguments?) (list .elements))
      ((? bindings?) (list .elements))
      ((? compound?) (list .elements))
      ((? events?) (list .elements))
      ((? fields?) (list .elements))
      ((? functions?) (list .elements))
      ((? instances?) (list .elements))
      ((? parameters?) (list .elements))
      ((? ports?) (list .elements))
      ((? root?) (list .elements))
      ((? triggers?) (list .elements))
      ((? types?) (list .elements))
      ((? variables?) (list .elements))

      (_ (list (lambda (x) #f)))
      ))))


(if #t (for-each
  (lambda (x)
    (set-record-type-printer!
     x
     (lambda (record port)
       (write-char #\( port)
       (display (ast-name record) port)
       (map (lambda (x) (when (not (null? x)) (display #\space port) (display x port))) (om:children record))
       (write-char #\) port)))
    )
  (list
   ;;leafs
   <action>
   <assign>
   <behaviour>
   <bind>
   <binding>
   <call>
   <component>
   <data>
   <enum>
   <error>
   <event>
   <expression>
   <extern>
   <field>
   <function>
   <om:parameter>
   <om:port>
   <guard>
   <if>
   <illegal>
   <import>
   <instance>
   <int>
   <interface>
   <literal>
   <on>
   <otherwise>
   <range>
   <reply>
   <return>
   <signature>
   <system>
   <trigger>
   <type>
   <value>
   <var>
   <variable>

   ;; lists
   <arguments>
   <bindings>
   <compound>
   <events>
   <fields>
   <functions>
   <instances>
   <parameters>
   <ports>
   <root>
   <triggers>
   <types>
   <variables>

   )))


(define (copy-of-om->list om)
  (with-input-from-string
      (with-output-to-string (lambda ()
                               (write om)
                               ;;(write-ast om)
                               ))
    read))


(define* (om:clone o :optional (f #f))
  (if f
      (apply (ast-constructor o) (map f (om:children o)))
      o))

(define (foo)
  (pretty-print
   (copy-of-om->list
    (make <root>
      :elements (list
                 (make <interface> :name 'I
                       :events (make <events> :elements '(foo bar baz)))
                 (make <component> :name 'C)
                 (make <system> :name 'S))))))
