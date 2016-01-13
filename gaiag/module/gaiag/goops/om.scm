;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(read-set! keywords 'prefix)

(define-module (gaiag goops om)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 optargs)
  :use-module (ice-9 match)
  :use-module ((oop goops;;the only spot
                    )
               :select
               ((make . goops:make)
                (is-a? . goops:is-a?)
                <accessor>
                <boolean>
                <class>
                <integer>
                <list>
                <null>
                <procedure>
                <string>
                <symbol>
                <top>
                class-name
                class-of
                class-slots
                define-class
                define-generic
                define-method
                make-class
                slot-definition-name
                slot-ref
                slot-set!
                ))
  :re-export (
              <accessor>
              <boolean>
              <class>
              <integer>
              <list>
              <null>
              <procedure>
              <string>
              <symbol>
              <top>
              class-name
              class-of
              class-slots
              define-class
              define-generic
              define-method
              make-class
              slot-definition-name
              slot-ref
              slot-set!
              )
  :export (
           make
           is-a?
           .ast
           .message
           <error>

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
           .external
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
           <name>
           <named>
           <on>
           <otherwise>
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
           <system>
           <trigger>
           <triggers>
           <type>
           <*type*>
           <types>
           <value>
           <var>
           <variable>
           <variables>
           ))

(define-class <ast> ())

(define-class <ast-list> (<ast>)
  (elements :accessor @elements :init-form (list) :init-keyword :elements))

(define .elements cdr)

(define-class <statement> (<ast>))

(define-class <arguments> (<ast-list>))
(define-class <bindings> (<ast-list>))
(define-class <compound> (<ast-list> <statement>))
(define-class <events> (<ast-list>))
(define-class <fields> (<ast-list>))
(define-class <formals> (<ast-list>))
(define-class <functions> (<ast-list>))
(define-class <instances> (<ast-list>))
(define-class <name> (<ast-list>))
(define-class <ports> (<ast-list>))
(define-class <root> (<ast-list>))
(define-class <triggers> (<ast-list>))
(define-class <types> (<ast-list>))
(define-class <variables> (<ast-list>))


(define ast-lists
  (list
    <arguments>
    <ast-list>
    <bindings>
    <compound>
    <events>
    <fields>
    <formals>
    <functions>
    <instances>
    <name>
    <ports>
    <root>
    <triggers>
    <types>
    <variables>
    ))

(define ast-list-names (map class-name ast-lists))

(define (ast-name class)
  (string->symbol (string-drop (string-drop-right (symbol->string (class-name class)) 1) 1)))

(define (symbol->class x) (symbol-append '< x '>))

(define (make class . args)
  (if (member class ast-lists)
      (let-keywords
       args #f ((elements '()))
       (cons (ast-name class) elements))
      (apply goops:make (cons class args))))

(define (is-a? o class)
  (and (if (not (pair? o)) (goops:is-a? o class)
           (and-let* ((type (car o))
                      ((symbol? type))
                      (name (symbol->class type)))
                     (if (or (eq? class <ast>) (eq? class <ast-list>) (eq? class <statement>))
                         (member name ast-list-names)
                         (eq? name (class-name class)))))
       o))

(define-class <named> (<ast>)
  (name :accessor @name :init-form (make <name>) :init-keyword :name))

(define-class <model> (<named>))

(define-class <import> (<named>))

(define-class <interface> (<model>)
  (types :accessor @types :init-form (make <types>) :init-keyword :types)
  (events :accessor .events :init-form (make <events>) :init-keyword :events)
  (behaviour :accessor @behaviour :init-value #f :init-keyword :behaviour))

(define-class <*type*> (<named>))
(define-class <type> (<*type*>))

(define-class <signature> (<ast>)
  (type :accessor @type :init-form (make <type>) :init-keyword :type)
  (formals :accessor .formals :init-form (make <formals>) :init-keyword :formals))

(define-class <event> (<ast>)
  (name :accessor @name :init-value #f :init-keyword :name)
  (signature :accessor @signature :init-form (make <signature>) :init-keyword :signature)
  (direction :accessor @direction :init-value #f :init-keyword :direction))

(define-class <port> (<ast>)
  (name :accessor @name :init-value #f :init-keyword :name)
  (type :accessor @type :init-value (make <name>) :init-keyword :type)
  (direction :accessor @direction :init-value #f :init-keyword :direction)
  (external :accessor .external :init-value #f :init-keyword :external)
  (injected :accessor .injected :init-value #f :init-keyword :injected))

(define-class <trigger> (<ast>)
  (port :accessor @port :init-value #f :init-keyword :port)
  (event :accessor .event :init-value #f :init-keyword :event)
  (arguments :accessor @arguments :init-form (make <arguments>) :init-keyword :arguments))

(define-class <expression> (<ast>)
  (value :accessor @value :init-value *unspecified* :init-keyword :value))

(define-class <otherwise> (<expression>))

(define-class <var> (<ast>)
  (name :accessor @name :init-value #f :init-keyword :name))

(define-class <field> (<ast>)
  (identifier :accessor @identifier :init-value #f :init-keyword :identifier)
  (field :accessor @field :init-value #f :init-keyword :field))

(define-class <literal> (<named>)
  (field :accessor @field :init-value #f :init-keyword :field))

(define-class <formal> (<ast>)
  (name :accessor @name :init-value #f :init-keyword :name)
  (type :accessor @type :init-form (make <type>) :init-keyword :type)
  (direction :accessor @direction :init-value #f :init-keyword :direction))

(define-class <component> (<model>)
  (ports :accessor @ports :init-form (make <ports>) :init-keyword :ports)
  (behaviour :accessor @behaviour :init-value #f :init-keyword :behaviour))

(define-class <system> (<model>)
  (ports :accessor @ports :init-form (make <ports>) :init-keyword :ports)
  (instances :accessor .instances :init-form (make <instances>) :init-keyword :instances)
  (bindings :accessor .bindings :init-form (make <bindings>) :init-keyword :bindings))

(define-class <enum> (<type>)
  (fields :accessor .fields :init-form (list) :init-keyword :fields))

(define-class <extern> (<type>)
  (value :accessor @value :init-value #f :init-keyword :value))

(define-class <data> (<ast>)
  (value :accessor @value :init-value #f :init-keyword :value))

(define-class <int> (<type>)
  (range :accessor .range :init-form (make <range>) :init-keyword :range))

(define-class <range> (<ast>)
  (from :accessor .from :init-value 0 :init-keyword :from)
  (to :accessor .to :init-value 0 :init-keyword :to))

(define-class <behaviour> (<ast>)
  (name :accessor @name :init-value #f :init-keyword :name)
  (types :accessor @types :init-form (make <types>) :init-keyword :types)
  (variables :accessor .variables :init-form (make <variables>) :init-keyword :variables)
  (functions :accessor .functions :init-form (make <functions>) :init-keyword :functions)
  (statement :accessor @statement :init-form (make <compound>) :init-keyword :statement))

(define-class <function> (<ast>)
  (name :accessor @name :init-value #f :init-keyword :name)
  (signature :accessor @signature :init-form (make <signature>) :init-keyword :signature)
  (recursive :accessor .recursive :init-value #f :init-keyword :recursive)
  (statement :accessor @statement :init-value #f :init-keyword :statement))

;;; statements
(define-class <declarative> (<statement>))
(define-class <imperative> (<statement>))

(define-class <action> (<imperative>)
  (trigger :accessor .trigger :init-value #f :init-keyword :trigger))

(define-class <assign> (<imperative>)
  (identifier :accessor @identifier :init-value #f :init-keyword :identifier)
  (expression :accessor @expression :init-form (make <expression>) :init-keyword :expression))

(define-class <call> (<imperative>)
  (identifier :accessor @identifier :init-value #f :init-keyword :identifier)
  (arguments :accessor @arguments :init-form (make <arguments>) :init-keyword :arguments)
  (last? :accessor .last? :init-value #f :init-keyword :last?))


(define-class <guard> (<declarative>)
  (expression :accessor @expression :init-form (make <expression>) :init-keyword :expression)
  (statement :accessor @statement :init-value #f :init-keyword :statement))

(define-class <if> (<imperative>)
  (expression :accessor @expression :init-form (make <expression>) :init-keyword :expression)
  (then :accessor .then :init-value #f :init-keyword :then)
  (else :accessor .else :init-value #f :init-keyword :else))

(define-class <illegal> (<statement>))

(define-class <blocking> (<declarative>)
  (statement :accessor @statement :init-value #f :init-keyword :statement))

(define-class <on> (<declarative>)
  (triggers :accessor .triggers :init-form (make <triggers>) :init-keyword :triggers)
  (statement :accessor @statement :init-value #f :init-keyword :statement))

(define-class <reply> (<imperative>)
  (expression :accessor @expression :init-value #f :init-keyword :expression)
  (port :accessor @port :init-value #f :init-keyword :port))

(define-class <return> (<imperative>)
  (expression :accessor @expression :init-value #f :init-keyword :expression))

(define-class <variable> (<imperative>)
  (name :accessor @name :init-value #f :init-keyword :name)
  (type :accessor @type :init-form (make <type> :name 'bool) :init-keyword :type)
  (expression :accessor @expression :init-form (make <expression>) :init-keyword :expression))

(define-class <bind> (<statement>)
  (left :accessor .left :init-value #f :init-keyword :left)
  (right :accessor .right :init-value #f :init-keyword :right))

(define-class <binding> (<statement>)
  (instance :accessor .instance :init-value #f :init-keyword :instance)
  (port :accessor @port :init-value #f :init-keyword :port))

(define-class <instance> (<statement>)
  (name :accessor @name :init-value #f :init-keyword :name)
  (component :accessor .component :init-value (make <name>) :init-keyword :component))

(define-class <error> (<ast>)
  (ast :accessor .ast :init-value #f :init-keyword :ast)
  (message :accessor .message :init-value "" :init-keyword :message))


;;; matchers are much faster than generics in guile-2.2
;;; disable all duplicate accessors for now
(define (.arguments ast)
  (match ast
    (($ <call> name arguments last?) arguments)
    (($ <trigger> port event arguments) arguments)))

(define (.behaviour o)
  (match o
    (($ <interface> name types events behaviour) behaviour)
    (($ <component> name ports behaviour) behaviour)))

(define (.direction ast)
  (match ast
    (($ <event> name signature direction) direction)
    (($ <formal> name type direction) direction)
    (($ <port> name type direction external injected) direction)))

(define (.expression o)
  (match o
    (($ <assign> expression) expression)
    (($ <guard> expression) expression)
    (($ <if> expression) expression)
    (($ <reply> expression) expression)
    (($ <return> expression) expression)
    (($ <variable> name type expression) expression)))

(define (.field ast)
  (match ast
    (($ <field> identifier field) field)
    (($ <literal> name field) field)))

(define (.identifier ast)
  (match ast
    (($ <assign> identifier expression) identifier)
    (($ <call> identifier arguments last?) identifier)
    (($ <field> identifier field) identifier)))

(define (.name o)
  (match o
    (($ <behaviour> name) name)
    (($ <component> name) name)
    (($ <enum> name) name)
    (($ <event> name) name)
    (($ <extern> name) name)
    (($ <function> name) name)
    (($ <formal> name) name)
    (($ <port> name) name)
    (($ <import> name) name)
    (($ <instance> name) name)
    (($ <literal> name) name)
    (($ <interface> name) name)
    (($ <int> name) name)
    (($ <model> name) name)
    (($ <named> name) name)
    (($ <system> name) name)
    (($ <type> name) name)
    (($ <var> name) name)
    (($ <variable> name) name)))

(define (.port o)
  (match o
    (($ <binding> instance port) port)
    (($ <reply> expression port) port)
    (($ <trigger> port event) port)))

(define (.ports o)
  (match o
    (($ <component> name ports) ports)
    (($ <system> name ports) ports)))

(define (.signature ast)
  (match ast
    (($ <event> name signature direction) signature)
    (($ <function> name signature recursive statement) signature)))

(define (.statement o)
  (match o
    (($ <behaviour> name types variables functions statement) statement)
    (($ <blocking> statement) statement)
    (($ <function> name signature recursive statement) statement)
    (($ <guard> expression statement) statement)
    (($ <on> expression statement) statement)))

(define (.type o)
  (match o
    (($ <formal> name type) type)
    (($ <literal> scope type field) type)
    (($ <port> name type) type)
    (($ <signature> type) type)
    (($ <variable> name type) type)))

(define (.types o)
  (match o
    (($ <interface> name types) types)
    (($ <behaviour> name types) types)))

(define (.value ast)
  (match ast
    (($ <expression> value) value)
    (($ <extern> name value) value)
    (($ <otherwise> value) value)))
