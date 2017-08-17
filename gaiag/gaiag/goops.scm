;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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
  #:use-module (system foreign)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (srfi srfi-1)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:export (
           .ast
           .message
           <error>

           .port.name
           .event.name
           .event.direction
           .variable.name
           .name.name
           .type.name
           .function.name
           .instance.name
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
           .formals
           .from
           .function@
           .functions
           .id
           .injected
           .instance
           .instances
           .last?
           .left
           .name
           .operator
           .port
           .port@
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
           .type@
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
           <blocking-compound>
           <bool>
           <call>
           <component>
           <component-model>
           <compound>
           <data>
           <declarative>
           <declarative-compound>
           <enum>
           <event>
           <events>
           <extern>
           <field>
           <fields>
           <foreign>
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
           <otherwise-guard>
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
           <shell-system>
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

           <expression>
           <bool-expr>
           <data-expr>
           <enum-expr>
           <int-expr>
           <void-expr>
           <value>
           <binary>
           <unary>

           <and>
           <equal>
           <greater-equal>
           <greater>
           <group>
           <less-equal>
           <less>
           <minus>
           <not-equal>
           <not>
           <or>
           <plus>
           ))

(define (stderr format-string . o)
  (apply format (append (list (current-error-port) format-string) o)))

(define (.name o)
  (match o
    ((or 'bool 'void) o)
    (_ (cadr o))))

(define-class <ast> ())

(define-method (.id (o <ast>))
  (pointer-address (scm->pointer o)))

(define-class <ast-list> (<ast>)
  (elements #:getter .elements #:init-form (list) #:init-keyword #:elements))

(define-class <statement> (<ast>))
(define-class <declarative> (<statement>))
(define-class <imperative> (<statement>))

(define-class <arguments> (<ast-list>))
(define-class <bindings> (<ast-list>))
(define-class <out-bindings> (<ast-list> <imperative>)
  (port #:getter .port #:init-value #f #:init-keyword #:port))
(define-method (.port.name (o <out-bindings>)) (and=> (.port o) .name))

(define-class <compound> (<ast-list> <statement>))
(define-class <blocking-compound> (<compound>)
  (port #:getter .port #:init-value #f #:init-keyword #:port))
(define-method (.port.name (o <blocking-compound>)) (and=> (.port o) .name))

(define-class <declarative-compound> (<ast-list> <declarative>))
(define-class <events> (<ast-list>))
(define-class <fields> (<ast-list>))
(define-class <formals> (<ast-list>))
(define-class <functions> (<ast-list>))
(define-class <instances> (<ast-list>))
(define-class <ports> (<ast-list>))

(define-class <root> (<ast-list>))
(define g-root-id 0)
(define-method (initialize (o <root>) . initargs)
  (let ((root (apply next-method (cons o initargs))))
    (set! g-root-id (.id root))
    ;(stderr "initialize root; id ~a\n" (.id root))
    root))

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

(define-class <enum> (<type>)
  (fields #:getter .fields #:init-form (list) #:init-keyword #:fields))

(define-method (.name.name (o <enum>))
  (symbol->string ((compose .name .name) o)))

(define-class <extern> (<type>)
  (value #:getter .value #:init-value #f #:init-keyword #:value))

(define-class <bool> (<type>))
(define-method (initialize (o <bool>) . initargs)
  (next-method o (list #:name (make <scope.name> #:name 'bool))))

(define-class <void> (<type>))
(define-method (initialize (o <void>) . initargs)
  (next-method o (list #:name (make <scope.name> #:name 'void))))

(define-class <int> (<type>)
  (range #:getter .range #:init-form (make <range>) #:init-keyword #:range))

(define-class <range> (<ast>)
  (from #:getter .from #:init-value 0 #:init-keyword #:from)
  (to #:getter .to #:init-value 0 #:init-keyword #:to))

(define-class <signature> (<ast>)
  (type #:getter .type #:init-form (make <void>) #:init-keyword #:type)
  (formals #:getter .formals #:init-form (make <formals>) #:init-keyword #:formals))




(define void-signature (make <signature>))

(define-class <event> (<named>)
  (signature #:getter .signature #:init-form (make <signature>) #:init-keyword #:signature)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction))

(define-class <modeling-event> (<event>))
(define-method (.signature (o <modeling-event>) void-signature))


(define-method (.direction (o <modeling-event>)) 'in)

(define-class <inevitable> (<modeling-event>))
(define-method (.name (o <inevitable>)) 'inevitable)

(define-class <optional> (<modeling-event>))
(define-method (.name (o <optional>)) 'optional)

(define ast:inevitable (make <inevitable>))
(define ast:optional (make <optional>))

(define-class <port> (<named>)
  (type #:getter .type@ #:init-form (make <scope.name>) #:init-keyword #:type)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction)
  (external #:getter .external #:init-value #f #:init-keyword #:external)
  (injected #:getter .injected #:init-value #f #:init-keyword #:injected))

(define-class <trigger> (<ast>)
  (port #:getter .port@ #:init-value #f #:init-keyword #:port)
  (event #:getter .event #:init-value #f #:init-keyword #:event)
  (formals #:getter .formals #:init-form (make <formals>) #:init-keyword #:formals))
(define-method (.port.name (o <trigger>)) (.port@ o))
(define-method (.event.name (o <trigger>)) (and=> (.event o) .name))
(define-method (.event.direction (o <trigger>)) (and=> (.event o) .direction))


(define-class <expression> (<ast>))

(define-class <value> (<expression>)
  (value #:getter .value #:init-value *unspecified* #:init-keyword #:value))

(define-class <binary> (<expression>)
  (left #:getter .left #:init-value *unspecified* #:init-keyword #:left)
  (right #:getter .right #:init-value *unspecified* #:init-keyword #:right))

(define-class <unary> (<expression>)
  (expression #:getter .expression #:init-expression *unspecified* #:init-keyword #:expression))

(define-class <group> (<unary>))

(define-class <bool-expr> (<expression>))
(define-class <enum-expr> (<expression>))
(define-class <int-expr> (<expression>))
(define-class <data-expr> (<expression>))
(define-class <void-expr> (<expression>))

(define-class <not> (<unary> <bool-expr>))
(define-class <and> (<binary> <bool-expr>))
(define-class <equal> (<binary> <bool-expr>))
(define-class <greater-equal> (<binary> <bool-expr>))
(define-class <greater> (<binary> <bool-expr>))
(define-class <less-equal> (<binary> <bool-expr>))
(define-class <less> (<binary> <bool-expr>))
(define-class <minus> (<binary> <int-expr>))
(define-class <not-equal> (<binary> <bool-expr>))
(define-class <or> (<binary> <bool-expr>))
(define-class <plus> (<binary> <int-expr>))

(define-method (.operator (o <binary>))
  (assoc-ref
   '((<and> . "&&")
     (<equal> . "==")
     (<greater-equal> . ">=")
     (<greater> . ">")
     (<less-equal> . "<=")
     (<less> . "<")
     (<minus> . "-")
     (<not-equal> . "!=")
     (<or> . "||")
     (<plus> . "+")) (class-name (class-of o))))

(define-class <data> (<data-expr>)
  (value #:getter .value #:init-value #f #:init-keyword #:value))

(define-class <var> (<expression>)
  (variable #:getter .variable #:init-value #f #:init-keyword #:variable))

(define-method (.variable.name (o <var>)) (and=> (.variable o) .name))

(define-class <variable> (<named> <imperative> <expression>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (expression #:getter .expression #:init-form (make <expression>) #:init-keyword #:expression))

(define-class <field> (<bool-expr>)
  (variable #:getter .variable #:init-value #f #:init-keyword #:variable)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

(define-method (.variable.name (o <field>)) (and=> (.variable o) .name))

(define-class <literal> (<enum-expr>)
  (type #:getter .type #:init-value #f #:init-keyword #:type)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

(define-class <otherwise> (<expression>) ;; FIXME: make <guard-otherwise/guard-else> instead
  (value #:getter .value #:init-value *unspecified* #:init-keyword #:value))

(define-class <formal> (<named> <expression>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction))

(define-class <formal-binding> (<formal>)
  (variable #:getter .variable #:init-form #f #:init-keyword #:variable))

(define-method (.variable.name (o <formal-binding>)) (and=> (.variable o) .name))

(define-class <component-model> (<model>)
  (ports #:getter .ports #:init-form (make <ports>) #:init-keyword #:ports))

(define-class <foreign> (<component-model>))

(define-class <component> (<component-model>)
  (behaviour #:getter .behaviour #:init-value #f #:init-keyword #:behaviour))

(define-class <system> (<component-model>)
  (instances #:getter .instances #:init-form (make <instances>) #:init-keyword #:instances)
  (bindings #:getter .bindings #:init-form (make <bindings>) #:init-keyword #:bindings))

(define-class <shell-system> (<system>))

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

(define-class <action> (<imperative> <expression>)
  (port #:getter .port@ #:init-value #f #:init-keyword #:port)
  (event #:getter .event #:init-value #f #:init-keyword #:event)
  (arguments #:getter .arguments #:init-form (make <arguments>) #:init-keyword #:arguments))
(define-method (.port.name (o <action>)) (.port@ o))
(define-method (.event.name (o <action>)) (and=> (.event o) .name))
(define-method (.event.direction (o <action>)) (and=> (.event o) .direction))

(define-class <assign> (<imperative>)
  (variable #:getter .variable #:init-value #f #:init-keyword #:variable)
  (expression #:getter .expression #:init-form (make <expression>) #:init-keyword #:expression))

(define-method (.variable.name (o <assign>)) (and=> (.variable o) .name))

(define-class <call> (<imperative> <expression>)
  (function #:getter .function@ #:init-value #f #:init-keyword #:function)
  (arguments #:getter .arguments #:init-form (make <arguments>) #:init-keyword #:arguments)
  (last? #:getter .last? #:init-value #f #:init-keyword #:last?))
(define-method (.function.name (o <call>)) (.function@ o))

(define-class <guard> (<declarative>)
  (expression #:getter .expression #:init-form (make <expression>) #:init-keyword #:expression)
  (statement #:getter .statement #:init-value #f #:init-keyword #:statement))

(define-class <otherwise-guard> (<guard>))

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

(define-method (.port.name (o <reply>)) (and=> (.port o) .name))

(define-class <return> (<imperative>)
  (expression #:getter .expression #:init-value #f #:init-keyword #:expression))

(define-class <bind> (<declarative>)
  (left #:getter .left #:init-value #f #:init-keyword #:left)
  (right #:getter .right #:init-value #f #:init-keyword #:right))

(define-class <binding> (<ast>)
  (instance #:getter .instance #:init-value #f #:init-keyword #:instance)
  (port #:getter .port@ #:init-value #f #:init-keyword #:port))

(define-method (.instance.name (o <binding>)) (and=> (.instance o) .name))
(define-method (.port.name (o <binding>)) (.port@ o))

(define-class <instance> (<named> <declarative>)
  (type #:getter .type@ #:init-form (make <scope.name>) #:init-keyword #:type))

(define-method (.type.name (o <instance>)) (.type@ o))
(define-method (.type.name (o <port>)) (.type@ o))

(define-class <error> (<ast>)
  (ast #:getter .ast #:init-value #f #:init-keyword #:ast)
  (message #:getter .message #:init-value "" #:init-keyword #:message))
