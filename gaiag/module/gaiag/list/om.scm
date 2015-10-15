;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(read-set! keywords 'prefix)

(define-module (gaiag list om)

  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

  :export (
           symbol->class

           .arguments
           .ast
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
           .message
           .name
           .formals
           .port
           .ports
           .range
           .recursive
           .right
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
           <blocking>
           <call>
           <component>
           <data>
           <error>
           <enum>
           <event>
           <events>
           <expression>
           <extern>
           <field>
           <fields>
           <function>
           <guard>
           <if>
           <illegal>
           <import>
           <instance>
           <instances>
           <int>
           <integer>
           <interface>
           <list>
           <literal>
           <name>
           <named>
           <null>
           <system>
           <bindings>
           <compound>
           <functions>
           <instances>
           <model>
           <on>
           <otherwise>
           <formal>
           <formal>
           <formals>
           <port>
           <ports>
           <range>
           <reply>
           <return>
           <root>
           <signature>
           <statement>
           <trigger>
           <triggers>
           <type>
           <*type*>
           <types>
           <var>
           <value>
           <variable>
           <variables>

           make
           make-<action>
           make-<assign>
           make-<arguments>
           make-<behaviour>
           make-<bind>
           make-<binding>
           make-<bindings>
           make-<blocking>
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
           make-<illegal>
           make-<instances>
           make-<int>
           make-<interface>
           make-<name>
           make-<system>
           make-<bindings>
           make-<compound>
           make-<functions>
           make-<import>
           make-<instances>
           make-<instance>
           make-<literal>
           make-<list>
           make-<on>
           make-<otherwise>
           make-<formal>
           make-<formals>
           make-<port>
           make-<ports>
           make-<range>
           make-<reply>
           make-<return>
           make-<root>
           make-<signature>
           make-<type>
           make-<types>
           make-<trigger>
           make-<triggers>
           make-<var>
           make-<value>
           make-<variable>
           make-<variables>

           is?
           is-a?
           ))

(define <ast-list> 'ast-list)
(define <list> 'list)
(define <integer> 'integer)
(define <null> '())
(define ast-leafs
  '(
    assign
    action
    ast
    behaviour
    bind
    binding
    blocking
    call
    component
    data
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
    model
    on
    otherwise
    formal
    port
    om:formal
    om:port
    range
    reply
    return
    signature
    system
    trigger
    type
    value
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
    formals
    functions
    instances
    name
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
    blocking
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
(define (is-a? ast type)
  ((is? type) ast))

;; this is kinda ugly: we simulate inheritance
;; interface, component, system are models
;; otherwise is an expression
(define ((is? type) ast)
  (define (test x) (and (pair? ast) (eq? (car ast) type) ast))
  (match type

    ;; ('ast (ast? ast))
    ;; ('ast-list (ast-list? ast))
    ;; ('model (model? ast))
    ;; ('statement (statement? ast))
    ;; ('*type* (*type*? ast))

    ('ast (and (pair? ast) (member (car ast) (append ast-leafs ast-lists)) ast))
    ('ast-list (and (pair? ast) (member (car ast) ast-lists) ast))
    ('expression (or (and (pair? ast) (member (car ast) '(expression otherwise)) ast)))
    ('named (or (is-a? ast <model>) (is-a? ast <import>) (is-a? ast <literal>) (is-a? ast <*type*>)))
    ('model (or (is-a? ast <component>) (is-a? ast <interface>) (is-a? ast <system>)))
    ('statement (and (pair? ast) (member (car ast) ast-statements) ast))
    ('*type* (or (is-a? ast <enum>) (is-a? ast <extern>) (is-a? ast <int>) (is-a? ast <type>)))

    ('expression (or (test type) (test 'otherwise)))
    (_ (test type))))

(define (symbol->class x) (symbol-append '< x '>))
(let ((module (current-module)))
  (for-each (lambda (x) (module-define! module (symbol->class x) x))
            (append ast-leafs ast-lists))
  ;; (for-each (lambda (x) (module-define! module (symbol-append x '?) (is? x)))
  ;;           (append ast-leafs ast-lists))
  (for-each
   (lambda (x)
     (module-define!
      module
      (symbol-append 'make- (symbol->class x))
      (lambda (. args) (apply make-<list> (append (list :type x) args)))))
   ast-lists))

;;(define <formal> <formal>)
;;(define <port> <port>)

(define ast-types (map symbol->class ast-nodes))

(define-syntax make
  (lambda (s)
    (syntax-case s ()
      ((_ 'formal args ...)
       (with-syntax
           ((m (datum->syntax #'formal #'make-<formal>))) #'(m args ...)))
      ((_ type args ...)
       (with-syntax
           ((m (datum->syntax #'type (symbol-append 'make- (syntax->datum #'type))))) #'(m args ...))))))

(define <model> 'model)
(define <named> 'named)
(define <statement> 'statement)
(define <*type*> '*type*)

;; (define (model? ast)
;;   (or (interface? ast) (component? ast) (system? ast)))
;; (define (statement? ast)
;;   (and (pair? ast) (member (car ast) ast-statements) ast))
;; (define (*type*? ast)
;;   (or (enum? ast) (extern? ast) (int? ast) (type? ast)))
;; (define (ast? ast)
;;   (and (pair? ast) (member (car ast) (append ast-leafs ast-lists)) ast))
;; (define (ast-list? ast)
;;   (and (pair? ast) (member (car ast) ast-lists) ast))

(define (make-<list> . args)
  (let-keywords
   args #f
   ((type <list>)
    (elements '()))
   (cons type elements)))

(define (make-<import> . args)
  (let-keywords
   args #f
   ((name (make <name>)))
   (cons <import> (list name))))

(define (make-<interface> . args)
  (let-keywords
   args #f
   ((name (make <name>))
    (types (make <types>))
    (events (make <events>))
    (behaviour (make <behaviour>)))
   (cons <interface> (list name types events behaviour))))

(define (make-<component> . args)
  (let-keywords
   args #f
   ((name (make <name>))
    (ports (make <ports>))
    (behaviour #f))
   (cons <component> (list name ports behaviour))))

(define (make-<system> . args)
  (let-keywords
   args #f
   ((name (make <name>))
    (ports (make <ports>))
    (instances (make <instances>))
    (bindings (make <bindings>)))
   (cons <system> (list name ports instances bindings))))

(define (make-<event> . args)
  (let-keywords
   args #f
   ((name (make <name>))
    (signature (make <signature>))
    (direction #f))
   (cons <event> (list name signature direction))))

(define (make-<trigger> . args)
  (let-keywords
   args #f
   ((port #f)
    (event #f)
    (arguments (make <arguments>)))
   (cons <trigger> (list port event arguments))))

(define (make-<port> . args)
  (let-keywords
   args #f
   ((name (make <name>))
    (type #f)
    (direction #f)
    (injected #f))
   (cons <port> (list name type direction injected))))

(define (make-<behaviour> . args)
  (let-keywords
   args #f
   ((name #f)
    (types (make <types>))
    (variables (make <variables>))
    (functions (make <functions>))
    (statement (make <compound>)))
   (cons <behaviour> (list name types variables functions statement))))

(define (make-<data> . args)
  (let-keywords
   args #f
   ((value #f))
   (cons <data> (list value))))

(define (make-<enum> . args)
  (let-keywords
   args #f
   ((name (make <name>))
    (fields (make <fields>)))
   (cons <enum> (list name fields))))

(define (make-<extern> . args)
  (let-keywords
   args #f
   ((name (make <name>))
    (value #f))
   (cons <extern> (list name value))))

(define (make-<int> . args)
  (let-keywords
   args #f
   ((name (make <name>))
    (range (make <range>)))
   (cons <int> (list name range))))

(define (make-<expression> . args)
  (let-keywords
   args #f
   ((value *unspecified*))
   (cons <expression> (list value))))

(define (make-<function> . args)
  (let-keywords
   args #f
   ((name #f)
    (recursive #f)
    (signature (make <signature>))
    (statement (make <compound>)))
   (cons <function> (list name signature recursive statement))))

(define (make-<formal> . args)
  (let-keywords
   args #f
   ((name #f)
    (type '(type void))
    (direction #f))
   (cons <formal> (list name type direction))))

(define (make-<range> . args)
  (let-keywords
   args #f
   ((from 0)
    (to 0))
   (cons <range> (list from to))))

(define (make-<signature> . args)
  (let-keywords
   args #f
   ((type '(type void))
    (formals (make <formals>)))
   (cons <signature> (list type formals))))

(define (make-<action> . args)
  (let-keywords
   args #f
   ((trigger #f))
   (cons <action> (list trigger))))

(define (make-<assign> . args)
  (let-keywords
   args #f
   ((identifier #f)
    (expression (make <expression>)))
   (cons <assign> (list identifier expression))))

(define (make-<call> . args)
  (let-keywords
   args #f
   ((identifier #f)
    (arguments (make <arguments>))
    (last? #f))
   (cons <call> (list identifier arguments last?))))

(define (make-<guard> . args)
  (let-keywords
   args #f
   ((expression (make <expression>))
    (statement #f))
   (cons <guard> (list expression statement))))

(define (make-<if> . args)
  (let-keywords
   args #f
   ((expression (make <expression>))
    (then #f)
    (else #f))
   (cons <if> (list expression then else))))

(define (make-<illegal> . args)
  (list <illegal>))

(define (make-<blocking> . args)
  (let-keywords
   args #f
   ((statement #f))
   (cons <blocking> (list statement))))

(define (make-<on> . args)
  (let-keywords
   args #f
   ((triggers (make <triggers>))
    (statement #f))
   (cons <on> (list triggers statement))))

(define (make-<reply> . args)
  (let-keywords
   args #f
   ((expression #f)
    (port #f))
   (cons <reply> (list expression port))))

(define (make-<return> . args)
  (let-keywords
   args #f
   ((expression #f))
   (cons <return> (list expression))))

(define (make-<bind> . args)
  (let-keywords
   args #f
   ((left #f)
    (right #f))
   (cons <bind> (list left right))))

(define (make-<binding> . args)
  (let-keywords
   args #f
   ((instance #f)
    (port #f))
   (cons <binding> (list instance port))))

(define (make-<instance> . args)
  (let-keywords
   args #f
   ((name #f)
    (component #f))
   (cons <instance> (list name component))))

(define (make-<variable> . args)
  (let-keywords
   args #f
   ((name #f)
    (type #f)
    (expression (make <expression>)))
   (cons <variable> (list name type expression))))

(define (make-<var> . args)
  (let-keywords
   args #f
   ((name (make <name>)))
   (cons <var> (list name))))

(define (make-<value> . args)
  (let-keywords
   args #f
   ((type #f)
    (field #f))
   (cons <value> (list type field))))

(define (make-<otherwise> . args)
  (let-keywords
   args #f
   ((value 'otherwise))
   (cons <otherwise> (list value))))

(define (make-<field> . args)
  (let-keywords
   args #f
   ((identifier #f)
    (field #f))
   (cons <field> (list identifier field))))

(define (make-<literal> . args)
  (let-keywords
   args #f
   ((name (make <name>))
    (field #f))
   (cons <literal> (list name field))))

(define (make-<type> . args)
  (let-keywords
   args #f
   ((name (make <name>)))
   (cons <type> (list name))))

(define (make-<error> . args)
  (let-keywords
   args #f
   ((ast #f)
    (message ""))
   (cons <error> (list ast message))))

(define (.arguments ast)
  (match ast
    (('call name) '(arguments))
    (('call name arguments) arguments)
    (('call name arguments last?) arguments)
    (('trigger port event) '(arguments))
    (('trigger port event arguments) arguments)))

(define (.last? ast)
  (match ast
    (('call name) #f)
    (('call name arguments) #f)
    (('call name arguments last?) last?)))

(define (.instances ast)
  (match ast
    (('system name ports instances bindings) instances)))

(define (.bindings ast)
  (match ast
    (('system name ports instances bindings) bindings)))

(define (.ports ast)
  (match ast
    (('component name ports) ports)
    (('component name ports behaviour) ports)
    (('system name ports instances bindings) ports)))

(define (.event ast)
  (match ast
    (('trigger port event) event)
    (('trigger port event arguments) event)))

(define (.port ast)
  (match ast
    (('binding instance port) port)
    (('trigger port event) port)
    (('trigger port event arguments) port)
    (('reply expression port) port)))

(define (.instance ast)
  (match ast
    (('binding instance port) instance)))

(define (unspecified? x) (eq? x *unspecified*))

(define (.formals ast)
  (match ast
    (('signature type) '(formals))
    ;;(('signature type (? unspecified?)) '(formals))  ;; Hmm?
    (('signature type formals) formals)))

(define (.events ast)
  (match ast
    (('interface name types events behaviour) events)))

(define (.triggers ast)
  (match ast
    (('on triggers statement) triggers)))

(define (.name ast)
  (match ast
    ;;(('name scope ... name) name)
    ((or 'bool 'void) ast)
    (_ (cadr ast))))

(define (.elements ast)
  (if (pair? ast)
      (cdr ast)
      '()))

(define (.recursive ast)
  (match ast
    (('function name signature recursive statement) recursive)))

(define (.value ast)
  (match ast
    (('expression value) value)
    (('extern name value) value)
    (('otherwise) 'otherwise)
    (('otherwise value) value)))

(define (.left ast)
  (match ast
    (('bind left right) left)))

(define (.right ast)
  (match ast
    (('bind left right) right)))

(define (.behaviour ast)
  (match ast
    (('component name ports) #f)
    ;;(('component name ports (? unspecified?)) #f)
    (('component name ports behaviour) behaviour)
    ;;(('interface name types events (? unspecified?)) #f)
    (('interface name types events) #f)
    (('interface name types events behaviour) behaviour)))

(define (.trigger ast)
  (match ast
    (('action trigger) trigger)))

(define (.signature ast)
  (match ast
    (('event name signature direction) signature)
    (('function name signature recursive statement) signature)))

(define (.identifier ast)
  (match ast
    (('assign identifier expression) identifier)
    (('call identifier) identifier)
    (('call identifier arguments) identifier)
    (('call identifier arguments last?) identifier)
    (('field identifier field) identifier)))

(define (.from ast)
  (match ast
    (('range from to) from)))

(define (.to ast)
  (match ast
    (('range from to) to)))

(define (.range ast)
  (match ast
    (('int name range) range)))

(define (.fields ast)
  (match ast
    (('enum name fields) fields)))

(define (.expression ast)
  (match ast
    (('assign identifier expression) expression)
    (('guard expression statement) expression)
    (('if expression then) expression)
    (('if expression then else) expression)
    (('reply) #f)
    (('reply expression) expression)
    (('return) #f)
    (('return expression) expression)
    ((variable name type expression) expression)))

(define (.then ast)
  (match ast
    (('if expression then) then)
    (('if expression then else) then)))

(define (.else ast)
  (match ast
    (('if expression then) #f)
    (('if expression then else) else)))

(define (.statement ast)
  (match ast
    (('blocking statement) statement)
    (('guard expression statement) statement)
    (('on triggers statement) statement)
    (('behaviour name types variables functions statement) statement)
    (('function name signature recursive statement) statement)))

(define (.functions ast)
  (match ast
    (#f '())
    (('behaviour name types variables functions statement) functions)))

(define (.variables ast)
  (match ast
    (#f '())
    (('behaviour name types variables functions statement) variables)))

(define (.types ast)
  (match ast
    (#f '())
    (('behaviour name types variables functions statement) types)
    (('interface name types events behaviour) types)
    (('root models ...) (filter (is? <*type*>) models))))

(define (.direction ast)
  (match ast
    (('event name signature direction) direction)
    (('formal name type) #f)
    (('formal name type direction) direction)
    (('port name type direction) direction)
    (('port name type direction injected) direction)))

(define (.injected ast)
  (match ast
    (('port name type direction) #f)
    (('port name type direction injected) injected)))

(define (.type ast)
  (match ast
    (('literal scope type field) type)
    (('port name type direction) type)
    (('port name type direction injected) type)
    (('formal name type) #f)
    (('formal name direction type) direction)
    (('signature type) type)
    (('signature type formals) type)
    (('value type field) type)
    (('variable name type expression) type)))

(define (.injected ast)
  (match ast
    (('port name type direction) #f)
    (('port name type direction injected) injected)))

(define (.component ast)
  (match ast
    (('instance name component) component)))

(define (.field ast)
  (match ast
    (('field identifier field) field)
    (('literal name field) field)))

(define (.message ast)
  (match ast
    (('error ast message) message)))

(define (.ast o)
  (match o
    (('error ast message) ast)
    (('info trail ast state q reply return state-alist trace error) ast))) ;; FIXME

(define (foo)
  (pretty-print
   (make <root>
     :elements (list
                (make <interface>)
                (make <component>)
                (make <system>)))))
