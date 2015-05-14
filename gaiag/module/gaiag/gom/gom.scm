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

(read-set! keywords 'prefix)

(define-module (gaiag gom gom)
  :use-module (oop goops)
  :export (
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
           <gom:parameter>
           <parameters>
           <gom:port>
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
           ))

(define-class <ast> ())

(define-class <named> (<ast>)
  (name :accessor .name :init-value #f :init-keyword :name))

(define-class <ast-list> (<ast>)
  (elements :accessor .elements :init-form (list) :init-keyword :elements))

(define-class <arguments> (<ast-list>))
(define-class <bindings> (<ast-list>))
(define-class <events> (<ast-list>))
(define-class <fields> (<ast-list>))
(define-class <functions> (<ast-list>))
(define-class <instances> (<ast-list>))
(define-class <parameters> (<ast-list>))
(define-class <ports> (<ast-list>))
(define-class <root> (<ast-list>))
(define-class <triggers> (<ast-list>))
(define-class <types> (<ast-list>))
(define-class <variables> (<ast-list>))

(define-class <model> (<named>))

(define-class <import> (<named>))

(define-class <interface> (<model>)
  (types :accessor .types :init-form (make <types>) :init-keyword :types)
  (events :accessor .events :init-form (make <events>) :init-keyword :events)
  (behaviour :accessor .behaviour :init-value #f :init-keyword :behaviour))

(define-class <type> (<named>)
  (scope :accessor .scope :init-value #f :init-keyword :scope))

(define-class <signature> (<ast>)
  (type :accessor .type :init-value (make <type>) :init-keyword :type)
  (parameters :accessor .parameters :init-form (make <parameters>) :init-keyword :parameters))

(define-class <event> (<named>)
  (signature :accessor .signature :init-form (make <signature>) :init-keyword :signature)
  (direction :accessor .direction :init-value #f :init-keyword :direction))

(define-class <gom:port> (<named>)
  (type :accessor .type :init-value #f :init-keyword :type)
  (direction :accessor .direction :init-value #f :init-keyword :direction)  
  (injected :accessor .injected :init-value #f :init-keyword :injected))

(define-class <trigger> (<ast>)
  (port :accessor .port :init-value #f :init-keyword :port)
  (event :accessor .event :init-value #f :init-keyword :event)
  (arguments :accessor .arguments :init-form (make <arguments>) :init-keyword :arguments))

(define-class <expression> (<ast>)
  (value :accessor .value :init-value *unspecified* :init-keyword :value))

(define-class <otherwise> (<expression>))

(define-class <var> (<named>)
  (name :accessor .name :init-value #f :init-keyword :name))

(define-class <field> (<ast>)
  (identifier :accessor .identifier :init-value #f :init-keyword :identifier)
  (field :accessor .field :init-value #f :init-keyword :field))

(define-class <value> (<ast>)
  (type :accessor .type :init-value #f :init-keyword :type)
  (field :accessor .field :init-value #f :init-keyword :field))

(define-class <literal> (<ast>)
  (scope :accessor .scope :init-value #f :init-keyword :scope)
  (type :accessor .type :init-value #f :init-keyword :type)
  (field :accessor .field :init-value #f :init-keyword :field))

(define-class <value> (<ast>)
  (type :accessor .type :init-value #f :init-keyword :type)
  (field :accessor .field :init-value #f :init-keyword :field))

(define-class <gom:parameter> (<named>)
  (type :accessor .type :init-value (make <type>) :init-keyword :type)
  (direction :accessor .direction :init-value #f :init-keyword :direction))

(define-class <component> (<model>)
  (ports :accessor .ports :init-form (make <ports>) :init-keyword :ports)
  (behaviour :accessor .behaviour :init-value #f :init-keyword :behaviour))

(define-class <system> (<model>)
  (ports :accessor .ports :init-form (make <ports>) :init-keyword :ports)
  (instances :accessor .instances :init-form (make <instances>) :init-keyword :instances)
  (bindings :accessor .bindings :init-form (make <bindings>) :init-keyword :bindings))

(define-class <enum> (<type>)
  (fields :accessor .fields :init-form (list) :init-keyword :fields))

(define-class <extern> (<type>)
  (value :accessor .value :init-value #f :init-keyword :value))

(define-class <data> (<ast>)
  (value :accessor .value :init-value #f :init-keyword :value))

(define-class <int> (<type>)
  (range :accessor .range :init-form (make <range>) :init-keyword :range))

(define-class <range> (<ast>)
  (from :accessor .from :init-value 0 :init-keyword :from)
  (to :accessor .to :init-value 0 :init-keyword :to))

(define-class <behaviour> (<named>)
  (types :accessor .types :init-form (make <types>) :init-keyword :types)
  (variables :accessor .variables :init-form (make <variables>) :init-keyword :variables)
  (functions :accessor .functions :init-form (make <functions>) :init-keyword :functions)
  (statement :accessor .statement :init-form (make <compound>) :init-keyword :statement))

(define-class <function> (<named>)
  (signature :accessor .signature :init-form (make <signature>) :init-keyword :signature)
  (recursive :accessor .recursive :init-value #f :init-keyword :recursive)
  (statement :accessor .statement :init-value #f :init-keyword :statement))

;;; statements
(define-class <statement> (<ast>))
(define-class <declarative> (<statement>))
(define-class <imperative> (<statement>))

(define-class <action> (<imperative>)
  (trigger :accessor .trigger :init-value #f :init-keyword :trigger))

(define-class <assign> (<imperative>)
  (identifier :accessor .identifier :init-value #f :init-keyword :identifier)
  (expression :accessor .expression :init-form (make <expression>) :init-keyword :expression))

(define-class <call> (<imperative>)
  (identifier :accessor .identifier :init-value #f :init-keyword :identifier)
  (arguments :accessor .arguments :init-form (make <arguments>) :init-keyword :arguments)
  (last? :accessor .last? :init-value #f :init-keyword :last?))

(define-class <compound> (<ast-list> <statement>))

(define-class <guard> (<declarative>)
  (expression :accessor .expression :init-form (make <expression>) :init-keyword :expression)
  (statement :accessor .statement :init-value #f :init-keyword :statement))

(define-class <if> (<imperative>)
  (expression :accessor .expression :init-form (make <expression>) :init-keyword :expression)
  (then :accessor .then :init-value #f :init-keyword :then)
  (else :accessor .else :init-value #f :init-keyword :else))

(define-class <illegal> (<statement>))

(define-class <on> (<declarative>)
  (triggers :accessor .triggers :init-form (make <triggers>) :init-keyword :triggers)
  (statement :accessor .statement :init-value #f :init-keyword :statement))

(define-class <reply> (<imperative>)
  (expression :accessor .expression :init-value #f :init-keyword :expression))

(define-class <return> (<imperative>)
  (expression :accessor .expression :init-value #f :init-keyword :expression))

(define-class <variable> (<named> <imperative>)
  (type :accessor .type :init-value 'bool :init-keyword :type)
  (expression :accessor .expression :init-form (make <expression>) :init-keyword :expression))

(define-class <bind> (<statement>)
  (left :accessor .left :init-value #f :init-keyword :left)
  (right :accessor .right :init-value #f :init-keyword :right))

(define-class <binding> (<statement>)
  (instance :accessor .instance :init-value #f :init-keyword :instance)
  (port :accessor .port :init-value #f :init-keyword :port))

(define-class <instance> (<named> <statement>)
  (component :accessor .component :init-value #f :init-keyword :component))

(define-class <error> (<ast>)
  (ast :accessor .ast :init-value #f :init-keyword :ast)
  (message :accessor .message :init-value "" :init-keyword :message))
