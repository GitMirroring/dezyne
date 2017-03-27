;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;;
;;; This file is part of Gaiag.
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag goops)
  #:use-module (ice-9 match)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:export (
           .ast
           .message
           <error>

           .port.name
           .event.name
           .variable.name
           ast:inevitable
           ast:optional

           .arguments
           .behaviour
           .bindings
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
           .variable
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
           <bool>
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
           <inevitable>
           <instance>
           <instances>
           <int>
           <interface>
           <literal>
           <model>
           <modeling-event>
           <named>
           <on>
           <optional>
           <otherwise>
           <out-bindings>
           <formal>
           <formal-binding>
           <formals>
           <port>
           <ports>
           <range>
           <reply>
           <return>
           <root>
           <scoped>
           <scope.name>
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
           <void>
           ))

(define (.name o)
  (match o
    ((or 'bool 'void) o)
    (_ (cadr o))))

(define-class <ast> ())

(define-class <ast-list> (<ast>)
  (elements #:getter .elements #:init-form (list) #:init-keyword #:elements))

(define-class <statement> (<ast>))
(define-class <declarative> (<statement>))
(define-class <imperative> (<statement>))

(define-class <arguments> (<ast-list>))
(define-class <bindings> (<ast-list>))
(define-class <out-bindings> (<ast-list> <imperative>))
(define-class <compound> (<ast-list> <statement>))
(define-class <events> (<ast-list>))
(define-class <fields> (<ast-list>))
(define-class <formals> (<ast-list>))
(define-class <functions> (<ast-list>))
(define-class <instances> (<ast-list>))
(define-class <ports> (<ast-list>))
(define-class <root> (<ast-list>))
(define-class <triggers> (<ast-list>))
(define-class <types> (<ast-list>))
(define-class <variables> (<ast-list>))

(define-class <named> (<ast>)
  (name #:getter .name #:init-form #f #:init-keyword #:name))

(define-class <scope.name> (<ast>)
  (scope #:getter .scope #:init-form (list) #:init-keyword #:scope)
  (name #:getter .name #:init-form #f #:init-keyword #:name))

(define-class <scoped> (<ast>)
  (name #:getter .name #:init-form (make <scope.name>) #:init-keyword #:name))

(define-class <model> (<scoped>))

(define-class <import> (<named>))

(define-class <interface> (<model>)
  (types #:getter .types #:init-form (make <types>) #:init-keyword #:types)
  (events #:getter .events #:init-form (make <events>) #:init-keyword #:events)
  (behaviour #:getter .behaviour #:init-value #f #:init-keyword #:behaviour))

(define-class <type> (<scoped>))

(define-class <bool> (<type>))
;;(define-method (.name (o <bool>) 'bool))

(define-class <void> (<type>))
;;(define-method (.name (o <void>) 'void))


(define-class <signature> (<ast>)
  (type #:getter .type #:init-form (make <void>) #:init-keyword #:type)
  (formals #:getter .formals #:init-form (make <formals>) #:init-keyword #:formals))

(define-class <event> (<named>)
  (signature #:getter .signature #:init-form (make <signature>) #:init-keyword #:signature)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction))

(define-class <modeling-event> (<event>))
(define-method (.direction (o <modeling-event>)) 'in)
(define void-signature (make <signature>))
(define-method (.signature (o <modeling-event>) void-signature))

(define-class <inevitable> (<modeling-event>))
(define-method (.name (o <inevitable>)) 'inevitable)

(define-class <optional> (<modeling-event>))
(define-method (.name (o <optional>)) 'optional)

(define ast:inevitable (make <inevitable>))
(define ast:optional (make <optional>))

(define-class <port> (<named>)
  (type #:getter .type #:init-form (make <scope.name>) #:init-keyword #:type)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction)
  (external #:getter .external #:init-value #f #:init-keyword #:external)
  (injected #:getter .injected #:init-value #f #:init-keyword #:injected))

(define-class <trigger> (<ast>)
  (port #:getter .port #:init-value #f #:init-keyword #:port)
  (event #:getter .event #:init-value #f #:init-keyword #:event)
  (formals #:getter .formals #:init-form (make <formals>) #:init-keyword #:formals))

(define-method (.port.name (o <trigger>)) (and=> (.port o) .name))
(define-method (.event.name (o <trigger>)) (and=> (.event o) .name))

(define-class <expression> (<ast>)
  (value #:getter .value #:init-value *unspecified* #:init-keyword #:value))

(define-class <otherwise> (<expression>))

(define-class <var> (<ast>)
  (name #:getter .name #:init-value #f #:init-keyword #:name))

(define-class <field> (<ast>)
  (identifier #:getter .identifier #:init-value #f #:init-keyword #:identifier)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

(define-class <literal> (<scoped>)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

(define-class <formal> (<named>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction))

(define-class <formal-binding> (<formal>)
  (variable #:getter .variable #:init-form #f #:init-keyword #:variable))

(define-method (.variable.name (o <formal-binding>)) (and=> (.variable o) .name))

(define-class <component> (<model>)
  (ports #:getter .ports #:init-form (make <ports>) #:init-keyword #:ports)
  (behaviour #:getter .behaviour #:init-value #f #:init-keyword #:behaviour))

(define-class <system> (<model>)
  (ports #:getter .ports #:init-form (make <ports>) #:init-keyword #:ports)
  (instances #:getter .instances #:init-form (make <instances>) #:init-keyword #:instances)
  (bindings #:getter .bindings #:init-form (make <bindings>) #:init-keyword #:bindings))

(define-class <data> (<ast>)
  (value #:getter .value #:init-value #f #:init-keyword #:value))

(define-class <enum> (<type>)
  (fields #:getter .fields #:init-form (list) #:init-keyword #:fields))

(define-class <extern> (<type>)
  (value #:getter .value #:init-value #f #:init-keyword #:value))

(define-class <int> (<type>)
  (range #:getter .range #:init-form (make <range>) #:init-keyword #:range))

(define-class <range> (<ast>)
  (from #:getter .from #:init-value 0 #:init-keyword #:from)
  (to #:getter .to #:init-value 0 #:init-keyword #:to))

(define-class <behaviour> (<named>)
  (types #:getter .types #:init-form (make <types>) #:init-keyword #:types)
  (ports #:getter .ports #:init-form (make <ports>) #:init-keyword #:ports)
  (variables #:getter .variables #:init-form (make <variables>) #:init-keyword #:variables)
  (functions #:getter .functions #:init-form (make <functions>) #:init-keyword #:functions)
  (statement #:getter .statement #:init-form (make <compound>) #:init-keyword #:statement))

(define-class <function> (<named>)
  (signature #:getter .signature #:init-form (make <signature>) #:init-keyword #:signature)
  (recursive #:getter .recursive #:init-value #f #:init-keyword #:recursive)
  (statement #:getter .statement #:init-value #f #:init-keyword #:statement))

(define-class <action> (<imperative>)
  (port #:getter .port #:init-value #f #:init-keyword #:port)
  (event #:getter .event #:init-value #f #:init-keyword #:event)
  (arguments #:getter .arguments #:init-form (make <arguments>) #:init-keyword #:arguments))

(define-method (.port.name (o <action>)) (and=> (.port o) .name))
(define-method (.event.name (o <action>)) (and=> (.event o) .name))

(define-class <assign> (<imperative>)
  (identifier #:getter .identifier #:init-value #f #:init-keyword #:identifier)
  (expression #:getter .expression #:init-form (make <expression>) #:init-keyword #:expression))

(define-class <call> (<imperative>)
  (identifier #:getter .identifier #:init-value #f #:init-keyword #:identifier)
  (arguments #:getter .arguments #:init-form (make <arguments>) #:init-keyword #:arguments)
  (last? #:getter .last? #:init-value #f #:init-keyword #:last?))


(define-class <guard> (<declarative>)
  (expression #:getter .expression #:init-form (make <expression>) #:init-keyword #:expression)
  (statement #:getter .statement #:init-value #f #:init-keyword #:statement))

(define-class <if> (<imperative>)
  (expression #:getter .expression #:init-form (make <expression>) #:init-keyword #:expression)
  (then #:getter .then #:init-value #f #:init-keyword #:then)
  (else #:getter .else #:init-value #f #:init-keyword #:else))

(define-class <illegal> (<imperative>))

(define-class <blocking> (<declarative>)
  (statement #:getter .statement #:init-value #f #:init-keyword #:statement))

(define-class <on> (<declarative>)
  (triggers #:getter .triggers #:init-form (make <triggers>) #:init-keyword #:triggers)
  (statement #:getter .statement #:init-value #f #:init-keyword #:statement))

(define-class <reply> (<imperative>)
  (expression #:getter .expression #:init-value #f #:init-keyword #:expression)
  (port #:getter .port #:init-value #f #:init-keyword #:port))

(define-class <return> (<imperative>)
  (expression #:getter .expression #:init-value #f #:init-keyword #:expression))

(define-class <variable> (<named> <imperative>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (expression #:getter .expression #:init-form (make <expression>) #:init-keyword #:expression))

(define-class <bind> (<statement>)
  (left #:getter .left #:init-value #f #:init-keyword #:left)
  (right #:getter .right #:init-value #f #:init-keyword #:right))

(define-class <binding> (<statement>)
  (instance #:getter .instance #:init-value #f #:init-keyword #:instance)
  (port #:getter .port #:init-value #f #:init-keyword #:port))

(define-class <instance> (<named> <statement>)
  (type #:getter .type #:init-form (make <scope.name>) #:init-keyword #:type))

(define-class <error> (<ast>)
  (ast #:getter .ast #:init-value #f #:init-keyword #:ast)
  (message #:getter .message #:init-value "" #:init-keyword #:message))
