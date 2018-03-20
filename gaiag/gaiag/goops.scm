;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014, 2015, 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2018 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag goops)
  #:use-module (system foreign)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (gaiag misc)
  #:use-module (gaiag location)
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
           .functions
           .id
           .injected
           .incomplete
           .instance
           .instances
           .last?
           .left
           .name
           .operator
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
           ;;.trigger
           .triggers
           .type
           .types
	   .type.name
           .value
           .variables
           <argument>
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
           <direction>
           <enum>
           <enum-field>
           <enum-literal>
           <event>
           <events>
           <extern>
           <field-test>
           <fields>
           <file-name>
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
           <local>
           <model-scope>
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
           <out-formal>
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
           <skip>
           <statement>
           <system>
           <the-end>
           <the-end-blocking>
           <trigger>
           <triggers>
           <type>
           <types>
           <literal>
           <var>
           <variable>
           <variables>
           <void>
           <voidreply>
           <unspecified>

           <expression>
           <bool-expr>
           <data-expr>
           <enum-expr>
           <int-expr>
           <void-expr>
           <literal>
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

           clone
           tree-map
           parent

           <action-node>
           <arguments-node>
           <assign-node>
           <ast-node>
           <ast-node-list>
           <behaviour-node>
           <bind-node>
           <binding-node>
           <bindings-node>
           <blocking-node>
           <blocking-compound-node>
           <bool-node>
           <call-node>
           <component-node>
           <component-model-node>
           <compound-node>
           <data-node>
           <declarative-node>
           <declarative-compound-node>
           <enum-node>
           <event-node>
           <events-node>
           <extern-node>
           <field-test-node>
           <fields-node>
           <foreign-node>
           <function-node>
           <functions-node>
           <guard-node>
           <if-node>
           <illegal-node>
           <imperative-node>
           <import-node>
           <inevitable-node>
           <instance-node>
           <instances-node>
           <int-node>
           <interface-node>
           <enum-literal-node>
           <model-node>
           <modeling-event-node>
           <named-node>
           <on-node>
           <optional-node>
           <otherwise-node>
           <otherwise-guard-node>
           <out-bindings-node>
           <formal-node>
           <formal-binding-node>
           <formals-node>
           <port-node>
           <ports-node>
           <range-node>
           <reply-node>
           <return-node>
           <root-node>
           <scoped-node>
           <scope.name-node>
           <shell-system-node>
           <signature-node>
           <statement-node>
           <system-node>
           <trigger-node>
           <triggers-node>
           <type-node>
           <types-node>
           <literal-node>
           <var-node>
           <variable-node>
           <variables-node>
           <void-node>

           <expression-node>
           <bool-expr-node>
           <data-expr-node>
           <enum-expr-node>
           <int-expr-node>
           <void-expr-node>
           <literal-node>
           <binary-node>
           <unary-node>

           <and-node>
           <equal-node>
           <greater-equal-node>
           <greater-node>
           <group-node>
           <less-equal-node>
           <less-node>
           <minus-node>
           <not-equal-node>
           <not-node>
           <or-node>
           <plus-node>

           .node
           .parent
;;           .node-elements


	   .trigger))

(define (stderr format-string . o)
  (apply format (append (list (current-error-port) format-string) o)))

;; (define (.name o)
;;   (match o
;;     ((or 'bool 'void) o)
;;     (_ (cadr o))))

(define-method (.name (o <pair>))
  (cadr o))

;; (define-method (.name (o <boolean>))
;;   "BARF: (.name <bool>")

(define-class <ast-node> ())

(define-class <ast-node-list> (<ast-node>)
;;  (elements #:getter .node-elements #:init-form (list) #:init-keyword #:elements)
  (elements #:getter .elements #:init-form (list) #:init-keyword #:elements)
  )

(define-class <statement-node> (<ast-node>))
(define-class <declarative-node> (<statement-node>))
(define-class <imperative-node> (<statement-node>))

(define-class <arguments-node> (<ast-node-list>))
(define-class <bindings-node> (<ast-node-list>))
(define-class <out-bindings-node> (<ast-node-list> <imperative-node>)
  (port #:getter .port #:init-value #f #:init-keyword #:port))
(define-method (.port.name (o <out-bindings-node>)) (and=> (.port o) .name))

(define-class <compound-node> (<ast-node-list> <statement-node>))
(define-class <blocking-compound-node> (<compound-node>)
  (port #:getter .port #:init-value #f #:init-keyword #:port))
(define-method (.port.name (o <blocking-compound-node>)) (and=> (.port o) .name))

(define-class <declarative-compound-node> (<ast-node-list> <declarative-node>))
(define-class <events-node> (<ast-node-list>))
(define-class <fields-node> (<ast-node-list>))
(define-class <formals-node> (<ast-node-list>))
(define-class <functions-node> (<ast-node-list>))
(define-class <instances-node> (<ast-node-list>))
(define-class <ports-node> (<ast-node-list>))

(define-class <root-node> (<ast-node-list>))
(define g-root-id 0)
(define-method (initialize (o <root-node>) . initargs)
  (let ((root (apply next-method (cons o initargs))))
    (set! g-root-id (.id root))
    ;(stderr "initialize root; id ~a\n" (.id root))
    root))

(define-class <triggers-node> (<ast-node-list>))
(define-class <types-node> (<ast-node-list>))
(define-class <variables-node> (<ast-node-list>))

(define-class <named-node> (<ast-node>)
  (name #:getter .name #:init-form #f #:init-keyword #:name))

(define-class <scope.name-node> (<ast-node>)
  (scope #:getter .scope #:init-form (list) #:init-keyword #:scope)
  (name #:getter .name #:init-form #f #:init-keyword #:name))

(define-class <scoped-node> (<ast-node>)
  (name #:getter .name #:init-form (make <scope.name-node>) #:init-keyword #:name))

(define-class <import-node> (<named-node>))

(define-class <model-node> (<scope.name-node>))

(define-class <interface-node> (<model-node>)
  (types #:getter .types #:init-form (make <types-node>) #:init-keyword #:types)
  (events #:getter .events #:init-form (make <events-node>) #:init-keyword #:events)
  (behaviour #:getter .behaviour #:init-value #f #:init-keyword #:behaviour))

(define-class <type-node> (<scoped-node>))

(define-class <enum-node> (<type-node>)
  (fields #:getter .fields #:init-form (list) #:init-keyword #:fields))

(define-method (.name.name (o <enum-node>))
  (symbol->string ((compose .name .name) o)))

(define-class <extern-node> (<type-node>)
  (value #:getter .value #:init-value #f #:init-keyword #:value))

(define-method (.name.name (o <extern-node>))
  (symbol->string ((compose .name .name) o)))

(define-class <bool-node> (<type-node>))
(define-method (initialize (o <bool-node>) . initargs)
  (next-method o (list #:name (make <scope.name-node> #:name 'bool))))

(define-class <void-node> (<type-node>))
(define-method (initialize (o <void-node>) . initargs)
  (next-method o (list #:name (make <scope.name-node> #:name 'void))))

(define-class <int-node> (<type-node>)
  (range #:getter .range #:init-form (make <range-node>) #:init-keyword #:range))

(define-method (.name.name (o <int-node>))
  ((compose symbol->string .name .name) o))

(define-class <range-node> (<ast-node>)
  (from #:getter .from #:init-value 0 #:init-keyword #:from)
  (to #:getter .to #:init-value 0 #:init-keyword #:to))

(define-class <signature-node> (<ast-node>)
  (type #:getter .type #:init-form (make <void-node>) #:init-keyword #:type)
  (formals #:getter .formals #:init-form (make <formals-node>) #:init-keyword #:formals))




(define void-signature (make <signature-node>))

(define-class <event-node> (<named-node>)
  (signature #:getter .signature #:init-form (make <signature-node>) #:init-keyword #:signature)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction))

(define-class <modeling-event-node> (<event-node>))
(define-method (.signature (o <modeling-event-node>) void-signature))


(define-method (.direction (o <modeling-event-node>)) 'in)

(define-class <inevitable-node> (<modeling-event-node>))
(define-method (.name (o <inevitable-node>)) 'inevitable)

(define-class <optional-node> (<modeling-event-node>))
(define-method (.name (o <optional-node>)) 'optional)

(define ast:inevitable (make <inevitable-node>))
(define ast:optional (make <optional-node>))

(define-class <port-node> (<named-node>)
  (type.name #:getter .type.name #:init-form (make <scope.name-node>) #:init-keyword #:type.name)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction)
  (external #:getter .external #:init-value #f #:init-keyword #:external)
  (injected #:getter .injected #:init-value #f #:init-keyword #:injected))

(define-class <trigger-node> (<ast-node>)
  (port.name #:getter .port.name #:init-value #f #:init-keyword #:port.name)
  (event #:getter .event #:init-value #f #:init-keyword #:event)
  (formals #:getter .formals #:init-form (make <formals-node>) #:init-keyword #:formals))
(define-method (.event.name (o <trigger-node>)) (and=> (.event o) .name))
(define-method (.event.direction (o <trigger-node>)) (and=> (.event o) .direction))


(define-class <expression-node> (<ast-node>))

(define-class <literal-node> (<expression-node>)
  (value #:getter .value #:init-value *unspecified* #:init-keyword #:value))

(define-class <binary-node> (<expression-node>)
  (left #:getter .left #:init-value *unspecified* #:init-keyword #:left)
  (right #:getter .right #:init-value *unspecified* #:init-keyword #:right))

(define-class <unary-node> (<expression-node>)
  (expression #:getter .expression #:init-expression *unspecified* #:init-keyword #:expression))

(define-class <group-node> (<unary-node>))

(define-class <bool-expr-node> (<expression-node>))
(define-class <enum-expr-node> (<expression-node>))
(define-class <int-expr-node> (<expression-node>))
(define-class <data-expr-node> (<expression-node>))
(define-class <void-expr-node> (<expression-node>))

(define-class <not-node> (<unary-node> <bool-expr-node>))
(define-class <and-node> (<binary-node> <bool-expr-node>))
(define-class <equal-node> (<binary-node> <bool-expr-node>))
(define-class <greater-equal-node> (<binary-node> <bool-expr-node>))
(define-class <greater-node> (<binary-node> <bool-expr-node>))
(define-class <less-equal-node> (<binary-node> <bool-expr-node>))
(define-class <less-node> (<binary-node> <bool-expr-node>))
(define-class <minus-node> (<binary-node> <int-expr-node>))
(define-class <not-equal-node> (<binary-node> <bool-expr-node>))
(define-class <or-node> (<binary-node> <bool-expr-node>))
(define-class <plus-node> (<binary-node> <int-expr-node>))

(define-method (.operator (o <binary-node>))
  (assoc-ref
   '((<and-node> . "&&")
     (<equal-node> . "==")
     (<greater-equal-node> . ">=")
     (<greater-node> . ">")
     (<less-equal-node> . "<=")
     (<less-node> . "<")
     (<minus-node> . "-")
     (<not-equal-node> . "!=")
     (<or-node> . "||")
     (<plus-node> . "+")) (class-name (class-of o))))

(define-class <data-node> (<data-expr-node>)
  (value #:getter .value #:init-value #f #:init-keyword #:value))

(define-class <var-node> (<expression-node>)
  (variable.name #:getter .variable.name #:init-value #f #:init-keyword #:variable.name))

(define-class <variable-node> (<named-node> <imperative-node> <expression-node>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (expression #:getter .expression #:init-form (make <expression-node>) #:init-keyword #:expression))

(define-class <field-test-node> (<bool-expr-node>)
  (variable.name #:getter .variable.name #:init-value #f #:init-keyword #:variable.name)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

(define-class <enum-literal-node> (<enum-expr-node>)
  (type #:getter .type #:init-value #f #:init-keyword #:type)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

(define-class <otherwise-node> (<expression-node>) ;; FIXME: make <guard-otherwise/guard-else-node> instead
  (value #:getter .value #:init-value *unspecified* #:init-keyword #:value))

(define-class <formal-node> (<named-node> <expression-node>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction))

(define-class <formal-binding-node> (<formal-node>)
  (variable.name #:getter .variable.name #:init-form #f #:init-keyword #:variable.name))

(define-class <component-model-node> (<model-node>)
  (ports #:getter .ports #:init-form (make <ports-node>) #:init-keyword #:ports))

(define-class <foreign-node> (<component-model-node>))

(define-class <component-node> (<component-model-node>)
  (behaviour #:getter .behaviour #:init-value #f #:init-keyword #:behaviour))

(define-class <system-node> (<component-model-node>)
  (instances #:getter .instances #:init-form (make <instances-node>) #:init-keyword #:instances)
  (bindings #:getter .bindings #:init-form (make <bindings-node>) #:init-keyword #:bindings))

(define-class <shell-system-node> (<system-node>))

(define-class <behaviour-node> (<named-node>)
  (types #:getter .types #:init-form (make <types-node>) #:init-keyword #:types)
  (ports #:getter .ports #:init-form (make <ports-node>) #:init-keyword #:ports)
  (variables #:getter .variables #:init-form (make <variables-node>) #:init-keyword #:variables)
  (functions #:getter .functions #:init-form (make <functions-node>) #:init-keyword #:functions)
  (statement #:getter .statement #:init-form (make <compound-node>) #:init-keyword #:statement))

(define-class <function-node> (<named-node>)
  (signature #:getter .signature #:init-form (make <signature-node>) #:init-keyword #:signature)
  (recursive #:getter .recursive #:init-value #f #:init-keyword #:recursive)
  (statement #:getter .statement #:init-value #f #:init-keyword #:statement))

(define-class <action-node> (<imperative-node> <expression-node>)
  (port.name #:getter .port.name #:init-value #f #:init-keyword #:port.name)
  (event #:getter .event #:init-value #f #:init-keyword #:event)
  (arguments #:getter .arguments #:init-form (make <arguments-node>) #:init-keyword #:arguments))
(define-method (.event.name (o <action-node>)) (and=> (.event o) .name))
(define-method (.event.direction (o <action-node>)) (and=> (.event o) .direction))

(define-class <assign-node> (<imperative-node>)
  (variable.name #:getter .variable.name #:init-value #f #:init-keyword #:variable.name)
  (expression #:getter .expression #:init-form (make <expression-node>) #:init-keyword #:expression))

(define-class <call-node> (<imperative-node> <expression-node>)
  (function.name #:getter .function.name #:init-value #f #:init-keyword #:function.name)
  (arguments #:getter .arguments #:init-form (make <arguments-node>) #:init-keyword #:arguments)
  (last? #:getter .last? #:init-value #f #:init-keyword #:last?))

(define-class <guard-node> (<declarative-node>)
  (expression #:getter .expression #:init-form (make <expression-node>) #:init-keyword #:expression)
  (statement #:getter .statement #:init-value #f #:init-keyword #:statement))

(define-class <otherwise-guard-node> (<guard-node>))

(define-class <if-node> (<imperative-node>)
  (expression #:getter .expression #:init-form (make <expression-node>) #:init-keyword #:expression)
  (then #:getter .then #:init-value #f #:init-keyword #:then)
  (else #:getter .else #:init-value #f #:init-keyword #:else))

(define-class <illegal-node> (<imperative-node>)
  (event #:getter .event #:init-value #f #:init-keyword #:event)
  (incomplete #:getter .incomplete #:init-value #f #:init-keyword #:incomplete))

(define-class <blocking-node> (<declarative-node>)
  (statement #:getter .statement #:init-value #f #:init-keyword #:statement))

(define-class <on-node> (<declarative-node>)
  (triggers #:getter .triggers #:init-form (make <triggers-node>) #:init-keyword #:triggers)
  (statement #:getter .statement #:init-value #f #:init-keyword #:statement))

(define-class <reply-node> (<imperative-node>)
  (expression #:getter .expression #:init-value #f #:init-keyword #:expression)
  (port.name #:getter .port.name #:init-value #f #:init-keyword #:port.name))

(define-class <return-node> (<imperative-node>)
  (expression #:getter .expression #:init-value #f #:init-keyword #:expression))

(define-class <bind-node> (<declarative-node>)
  (left #:getter .left #:init-value #f #:init-keyword #:left)
  (right #:getter .right #:init-value #f #:init-keyword #:right))

(define-class <binding-node> (<ast-node>)
  (instance #:getter .instance #:init-value #f #:init-keyword #:instance)
  (port.name #:getter .port.name #:init-value #f #:init-keyword #:port.name))

(define-method (.instance.name (o <binding-node>)) (and=> (.instance o) .name))

(define-class <instance-node> (<named-node> <declarative-node>)
  (type.name #:getter .type.name #:init-form (make <scope.name-node>) #:init-keyword #:type.name))

(define-class <error-node> (<ast-node>)
  (ast #:getter .ast #:init-value #f #:init-keyword #:ast)
  (message #:getter .message #:init-value "" #:init-keyword #:message))

(define-class <skip-node> (<imperative-node>))

(define-class <the-end-node> (<statement-node>)
  (trigger #:getter .trigger #:init-value #f #:init-keyword #:trigger))
(define-class <the-end-blocking-node> (<statement-node>))
(define-class <voidreply-node> (<statement-node>))

(define-class <argument-node> (<named-node> <expression-node>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction))

(define-class <enum-field-node> (<ast-node>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

(define-class <file-name-node> (<ast-node>)
  (name #:getter .name #:init-form #f #:init-keyword #:name))

(define-class <local-node> (<variable-node>))
(define-class <model-scope-node> (<ast-node>))
(define-class <out-formal-node> (<variable-node>))
(define-class <direction-node> (<named-node>))
(define-class <unspecified-node> (<ast-node>))

(define-method (make-wrapper e o) e)

(define-class <ast> ()
  (node #:getter .node #:init-value #f #:init-keyword #:node)
  (parent #:getter .parent #:init-value #f #:init-keyword #:parent))

(define-method (.id (o <object>))
  (pointer-address (scm->pointer o)))

(define-method (.id (o <ast>))  (.id (.node o)))

(define-class <ast-list> (<ast>))

(define-method (.elements (o <ast-list>))
  (map (lambda (e) (make-wrapper e o)) ((compose .elements .node) o)))

(define-method (make-wrapper (n <ast-node-list>) p) (make <ast-list> #:parent p #:node n))


;;(define-class <root> (<ast-list>))
;;(define-method (make-wrapper (n <root-node>) p) (make <root> #:parent p #:node n))


(define-syntax wrap-method
  (syntax-rules ()
    ((_ method class)
     (define-method (method (o class)) (make-wrapper ((compose method .node) o) o)))))

(use-modules (oop goops describe))

(define-syntax wrap
  (syntax-rules ()
    ((_ class-node class supers)
     (let* ((methods (map method-generic-function (class-direct-methods class-node)))
            (super-methods (map method-generic-function (append-map class-direct-methods (class-direct-supers class-node))))
            (super-names (map generic-function-name super-methods))
            (methods (filter (lambda (m) (not (member (generic-function-name m) super-names))) methods))
            ;;(foo (stderr "methods: ~s\n" methods))
            )
       (define-class class supers)
       (for-each (lambda (m) (wrap-method m class)) methods)
       (define-method (node-class- (o class)) class-node)
       (define-method (make-wrapper (n class-node) p) (make class #:parent p #:node n))))))

(export wrap)
(define-method (node-class (class <class>))
  (node-class- (make class #:node #f #:parent #f)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;(wrap <ast-node-list> <ast-list> (<ast>))
(wrap <statement-node> <statement> (<ast>))
(wrap <declarative-node> <declarative> (<statement>))
(wrap <imperative-node> <imperative> (<statement>))
(wrap <arguments-node> <arguments> (<ast-list>))
(wrap <bindings-node> <bindings> (<ast-list>))
(wrap <out-bindings-node> <out-bindings> (<ast-list> <imperative>))
(wrap <compound-node> <compound> (<ast-list> <statement>))
(wrap <blocking-compound-node> <blocking-compound> (<compound>))
(wrap <declarative-compound-node> <declarative-compound> (<ast-list> <declarative>))
(wrap <events-node> <events> (<ast-list>))
(wrap <fields-node> <fields> (<ast-list>))
(wrap <formals-node> <formals> (<ast-list>))
(wrap <functions-node> <functions> (<ast-list>))
(wrap <instances-node> <instances> (<ast-list>))
(wrap <ports-node> <ports> (<ast-list>))
(wrap <root-node> <root> (<ast-list>))
(wrap <triggers-node> <triggers> (<ast-list>))
(wrap <types-node> <types> (<ast-list>))
(wrap <variables-node> <variables> (<ast-list>))
(wrap <named-node> <named> (<ast>))
(wrap <scope.name-node> <scope.name> (<ast>))
(wrap <scoped-node> <scoped> (<ast>))
(wrap <import-node> <import> (<named>))
(wrap <model-node> <model> (<scope.name>))
(wrap <interface-node> <interface> (<model>))
(wrap <type-node> <type> (<scoped>))
(wrap <enum-node> <enum> (<type>))
(wrap <extern-node> <extern> (<type>))
(wrap <bool-node> <bool> (<type>))
(wrap <void-node> <void> (<type>))
(wrap <int-node> <int> (<type>))
(wrap <range-node> <range> (<ast>))
(wrap <signature-node> <signature> (<ast>))
(wrap <event-node> <event> (<named>))
(wrap <modeling-event-node> <modeling-event> (<event>))
(wrap <inevitable-node> <inevitable> (<modeling-event>))
(wrap <optional-node> <optional> (<modeling-event>))
(wrap <port-node> <port> (<named>))
(wrap <trigger-node> <trigger> (<ast>))
(wrap <expression-node> <expression> (<ast>))
(wrap <literal-node> <literal> (<expression>))
(wrap <binary-node> <binary> (<expression>))
(wrap <unary-node> <unary> (<expression>))
(wrap <group-node> <group> (<unary>))
(wrap <bool-expr-node> <bool-expr> (<expression>))
(wrap <enum-expr-node> <enum-expr> (<expression>))
(wrap <int-expr-node> <int-expr> (<expression>))
(wrap <data-expr-node> <data-expr> (<expression>))
(wrap <void-expr-node> <void-expr> (<expression>))
(wrap <not-node> <not> (<unary> <bool-expr>))
(wrap <and-node> <and> (<binary> <bool-expr>))
(wrap <equal-node> <equal> (<binary> <bool-expr>))
(wrap <greater-equal-node> <greater-equal> (<binary> <bool-expr>))
(wrap <greater-node> <greater> (<binary> <bool-expr>))
(wrap <less-equal-node> <less-equal> (<binary> <bool-expr>))
(wrap <less-node> <less> (<binary> <bool-expr>))
(wrap <minus-node> <minus> (<binary> <int-expr>))
(wrap <not-equal-node> <not-equal> (<binary> <bool-expr>))
(wrap <or-node> <or> (<binary> <bool-expr>))
(wrap <plus-node> <plus> (<binary> <int-expr>))
(wrap <data-node> <data> (<data-expr>))
(wrap <var-node> <var> (<expression>))
(wrap <variable-node> <variable> (<named> <imperative> <expression>))
(wrap <field-test-node> <field-test> (<bool-expr>))
(wrap <enum-literal-node> <enum-literal> (<enum-expr>))
(wrap <otherwise-node> <otherwise> (<expression>))
(wrap <formal-node> <formal> (<named> <expression>))
(wrap <formal-binding-node> <formal-binding> (<formal>))
(wrap <component-model-node> <component-model> (<model>))
(wrap <foreign-node> <foreign> (<component-model>))
(wrap <component-node> <component> (<component-model>))
(wrap <system-node> <system> (<component-model>))
(wrap <shell-system-node> <shell-system> (<system>))
(wrap <behaviour-node> <behaviour> (<named>))
(wrap <function-node> <function> (<named>))
(wrap <action-node> <action> (<imperative> <expression>))
(wrap <assign-node> <assign> (<imperative>))
(wrap <call-node> <call> (<imperative> <expression>))
(wrap <guard-node> <guard> (<declarative>))
(wrap <otherwise-guard-node> <otherwise-guard> (<guard>))
(wrap <if-node> <if> (<imperative>))
(wrap <illegal-node> <illegal> (<imperative>))
(wrap <blocking-node> <blocking> (<declarative>))
(wrap <on-node> <on> (<declarative>))
(wrap <reply-node> <reply> (<imperative>))
(wrap <return-node> <return> (<imperative>))
(wrap <bind-node> <bind> (<declarative>))
(wrap <binding-node> <binding> (<ast>))
(wrap <instance-node> <instance> (<named> <declarative>))
(wrap <error-node> <error> (<ast>))
(wrap <skip-node> <skip> (<imperative>))
(wrap <the-end-node> <the-end> (<statement>))
(wrap <the-end-blocking-node> <the-end-blocking> (<statement>))
(wrap <voidreply-node> <voidreply> (<statement>))
(wrap <argument-node> <argument> (<named> <expression>))
(wrap <enum-field-node> <enum-field> (<ast>))
(wrap <file-name-node> <file-name> (<ast>))
(wrap <local-node> <local> (<variable>))
(wrap <model-scope-node> <model-scope> (<ast>))
(wrap <out-formal-node> <out-formal> (<variable>))
(wrap <direction-node> <direction> (<named>))
(wrap <unspecified-node> <unspecified> (<ast>))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; TODO: make construct function line clone, explicitely looking for pairs
(define-method (node o) o)
(define-method (node (o <ast-node>)) o)
(define-method (node (o <pair>)) (map node o))
(define-method (node (o <ast>)) (.node o))

(define-method (get-parent o) #f)
(define-method (get-parent (o <ast>)) (.parent o))

(define (construct class . setters)
  (let* ((class-node (node-class class))
         (node (apply make (cons class-node (map node setters))))
         (parent (find get-parent setters)))
    (if (equal? class class-node) node (make class #:node node #:parent parent))))

(define-method (make-instance (class <class>) . initargs)
  (if (and (member <ast> (class-precedence-list class))
           (not (memq #:node initargs))
           (not (memq #:parent initargs))) (apply construct (cons class initargs))
           ;; FIXME: copy of body in (oop goops)
           (let ((instance (allocate-instance class initargs)))
             (initialize instance initargs)
             instance)))

(define-method (tree-map f o) o)

(define-method (tree-map f (o <ast>))
  (define (setters f names getters)
    (zip (map symbol->keyword names)
         (map (lambda (g) ((compose f g) o)) getters)))
  (let* ((class (class-of (.node o)))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (getters (map slot-definition-getter slots))
         (changed (setters f names getters))
         (original (setters identity names getters))
         )
    (if (equal? original changed) o
        (apply clone (cons o (apply append changed)))
        )))

(define-method (tree-map f (o <ast-list>)) (clone o #:elements (map f (.elements o))))

(define-method (clone-base o . setters)
  (let* ((class (class-of o))
         (setters (if (memq #:parent setters) setters
                      (map node setters)))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (make-pair (lambda (name) (list (symbol->keyword name) (slot-ref o name))))
         (paired-members (map make-pair names))
         (paired-setters (fold (lambda (elem previous) (if (or (null? previous) (pair? (car previous)))
                                                           (cons elem previous)
                                                           (cons (list (car previous) elem) (cdr previous))))
                               '() setters))
         (wrong (lset-difference equal? (map car paired-setters) (map car paired-members)))
         (changed (lset-difference equal? paired-setters paired-members))
         (unchanged (lset-difference (lambda (a b) (eq? (car a) (car b))) paired-members changed)))
    (if (pair? wrong) (error (format #f "WRONG SETTERS FOUND in ~a: ~a; names = ~a\n" o wrong names)))
    (if (null? changed) o
        (apply make (cons class (apply append (append unchanged changed)))))))


(define-method (clone-base-node (o <ast-node>) . setters)
  (retain-source-properties o (apply clone-base (cons o setters))))

(define-method (clone-base-ast (o <ast>) . setters)
  (retain-source-properties o (apply clone-base (cons o setters))))


(define-method (clone (o <ast-node>) . setters)
  (apply clone-base-node (cons o setters)))

(define-method (clone (o <ast>) . setters)
  (if (or (memq #:node setters) (memq #:parent setters))
      (apply clone-base-ast (cons o setters))
      (clone-base-ast o #:node (apply clone-base-node (cons (.node o) setters)))))

(define-method (parent class o) #f)
(define-method (parent class (o <ast>))
  (if (is-a? o class) o (parent class (.parent o))))
