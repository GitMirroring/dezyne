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
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (gaiag misc)
  #:use-module (gaiag location)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:export (
            define-ast
            <ast>
            <ast-node>
            .node
            .parent

            .event.direction
            .event.name
            .id
            .instance.name
            .name.name
            .operator
            .port.name
            .type

            ast:inevitable
            ast:optional
            void-signature

            clone
            tree-map
            parent))

;; FIXME: generate-me
(export
           .arguments
           .ast
           .behaviour
           .bindings
           .direction
           .elements
           .else
           .event
           .event.direction
           .event.name
           .events
           .expression
           .external
           .field
           .fields
           .formals
           .from
           .function.name
           .functions
           .incomplete
           .injected
           .instance
           .instances
           .last?
           .left
           .message
           .name
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
           .type.name
           .types
           .value
           .variable.name
           .variables
           <action-node>
           <action>
           <and-node>
           <and>
           <argument>
           <arguments-node>
           <arguments>
           <assign-node>
           <assign>
           <ast-list>
           <ast-node-list>
           <behaviour-node>
           <behaviour>
           <binary-node>
           <binary>
           <bind-node>
           <bind>
           <binding-node>
           <binding>
           <bindings-node>
           <bindings>
           <blocking-compound-node>
           <blocking-compound>
           <blocking-node>
           <blocking>
           <bool-expr-node>
           <bool-expr>
           <bool-node>
           <bool>
           <call-node>
           <call>
           <component-model-node>
           <component-model>
           <component-node>
           <component>
           <compound-node>
           <compound>
           <data-expr-node>
           <data-expr>
           <data-node>
           <data>
           <declarative-compound-node>
           <declarative-compound>
           <declarative-node>
           <declarative>
           <direction>
           <enum-expr-node>
           <enum-expr>
           <enum-field>
           <enum-literal-node>
           <enum-literal>
           <enum-node>
           <enum>
           <equal-node>
           <equal>
           <error>
           <event-node>
           <event>
           <events-node>
           <events>
           <expression-node>
           <expression>
           <extern-node>
           <extern>
           <field-test-node>
           <field-test>
           <fields-node>
           <fields>
           <file-name>
           <foreign-node>
           <foreign>
           <formal-binding-node>
           <formal-binding>
           <formal-node>
           <formal>
           <formals-node>
           <formals>
           <function-node>
           <function>
           <functions-node>
           <functions>
           <greater-equal-node>
           <greater-equal>
           <greater-node>
           <greater>
           <group-node>
           <group>
           <guard-node>
           <guard>
           <if-node>
           <if>
           <illegal-node>
           <illegal>
           <imperative-node>
           <imperative>
           <import-node>
           <import>
           <inevitable-node>
           <inevitable>
           <instance-node>
           <instance>
           <instances-node>
           <instances>
           <int-expr-node>
           <int-expr>
           <int-node>
           <int>
           <interface-node>
           <interface>
           <less-equal-node>
           <less-equal>
           <less-node>
           <less>
           <literal-node>
           <literal-node>
           <literal>
           <literal>
           <local>
           <minus-node>
           <minus>
           <model-node>
           <model-scope>
           <model>
           <modeling-event-node>
           <modeling-event>
           <named-node>
           <named>
           <not-equal-node>
           <not-equal>
           <not-node>
           <not>
           <on-node>
           <on>
           <optional-node>
           <optional>
           <or-node>
           <or>
           <otherwise-guard-node>
           <otherwise-guard>
           <otherwise-node>
           <otherwise>
           <out-bindings-node>
           <out-bindings>
           <out-formal>
           <plus-node>
           <plus>
           <port-node>
           <port>
           <ports-node>
           <ports>
           <range-node>
           <range>
           <reply-node>
           <reply>
           <return-node>
           <return>
           <root-node>
           <root>
           <scope.name-node>
           <scope.name>
           <scoped-node>
           <scoped>
           <shell-system-node>
           <shell-system>
           <signature-node>
           <signature>
           <skip>
           <statement-node>
           <statement>
           <system-node>
           <system>
           <the-end-blocking>
           <the-end>
           <trigger-node>
           <trigger>
           <triggers-node>
           <triggers>
           <type-node>
           <type>
           <types-node>
           <types>
           <unary-node>
           <unary>
           <unspecified>
           <var-node>
           <var>
           <variable-node>
           <variable>
           <variables-node>
           <variables>
           <void-expr-node>
           <void-expr>
           <void-node>
           <void>
           <voidreply>
           )

;; (define-method (.name (o <pair>))
;;   (cadr o))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-syntax define-ast
  (lambda (x)
    (define (make-node name)
      (string->symbol (string-append (string-drop-right (symbol->string name) 1) "-node>")))
    (define (make-getter name)
      (string->symbol (string-append "." (symbol->string name))))
    (define (complete-slot slot)
      (define (create-slot name init-keyword init-value)
        (let ((getter (datum->syntax x (make-getter (syntax->datum name))))
              (keyword (datum->syntax x (symbol->keyword (syntax->datum name)))))
          #`(#,name #:getter #,getter #,init-keyword #,init-value #:init-keyword #,keyword)))
      (syntax-case slot ()
        ((name)
         (create-slot #'name #:init-value #f))
        ((name #:init-form form)
         (create-slot #'name #:init-form #'form))
        ((name #:init-value value)
         (create-slot #'name #:init-value #'value))))
    (define ((define-wrapper-getter class) slot)
      (syntax-case slot ()
        ((name foo ...)
         (with-syntax ((getter (datum->syntax x (make-getter (syntax->datum #'name)))))
           (with-syntax ((export? (not (defined? 'getter))))
             #`(begin
                 ;; #,(if #'export?
                 ;;       (export getter))
                 (define-method (getter (o #,class))
                   (make-wrapper ((compose getter .node) o) o))))))))
    (syntax-case x ()
      ((_ name supers slot ...)
       (with-syntax (((slot' ...) (map complete-slot #'(slot ...)))
                     ((wrapper-method ...) (map (define-wrapper-getter #'name) #'(slot ...)))
                     (node-supers (datum->syntax x (map make-node (syntax->datum #'supers))))
                     (node (datum->syntax x (make-node (syntax->datum #'name)))))
         #`(begin
             (export name node)
             (define-class node node-supers slot' ...)
             (define-class name supers)
             (define-method (node-class- (o name)) node)
             (define-method (make-wrapper (n node) p) (make name #:parent p #:node n))
             #,@#'(wrapper-method ...)))))))

(define-class <ast> ()
  (node #:getter .node #:init-value #f #:init-keyword #:node)
  (parent #:getter .parent #:init-value #f #:init-keyword #:parent))

(define-class <ast-node> ())
(define-ast <ast-list> (<ast>)
  (elements #:init-form (list)))

(define-method (.elements (o <ast-list>))
  (map (lambda (e) (make-wrapper e o)) ((compose .elements .node) o)))

(define-method (make-wrapper (o <top>) p) o)
(define-method (make-wrapper (o <ast-node>) p) o)
(define-method (make-wrapper (o <ast-list-node>) p) (make <ast-list> #:parent p #:node o))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(define-ast <statement> (<ast>))
(define-ast <declarative> (<statement>))
(define-ast <imperative> (<statement>))

(define-ast <arguments> (<ast-list>))
(define-ast <bindings> (<ast-list>))
(define-ast <out-bindings> (<ast-list> <imperative>)
  (port))
(define-method (.port.name (o <out-bindings>)) (and=> (.port o) .name))

(define-ast <compound> (<ast-list> <statement>))
(define-ast <blocking-compound> (<compound>)
  (port))
(define-method (.port.name (o <blocking-compound>)) (and=> (.port o) .name))

(define-ast <declarative-compound> (<ast-list> <declarative>))
(define-ast <events> (<ast-list>))
(define-ast <fields> (<ast-list>))
(define-ast <formals> (<ast-list>))
(define-ast <functions> (<ast-list>))
(define-ast <instances> (<ast-list>))
(define-ast <ports> (<ast-list>))

(define-ast <root> (<ast-list>))
(define g-root-id 0)
(define-method (initialize (o <root-node>) . initargs)
  (let ((root (apply next-method (cons o initargs))))
    (set! g-root-id (.id root))
    root))

(define-ast <triggers> (<ast-list>))
(define-ast <types> (<ast-list>))
(define-ast <variables> (<ast-list>))

(define-ast <named> (<ast>)
  (name))

(define-ast <scope.name> (<ast>)
  (scope #:init-form (list))
  (name))

(define-ast <scoped> (<ast>)
  (name #:init-form (make <scope.name-node>)))

(define-ast <import> (<named>))

(define-ast <model> (<scope.name>))

(define-ast <interface> (<model>)
  (types #:init-form (make <types-node>))
  (events #:init-form (make <events-node>))
  (behaviour))

(define-ast <type> (<scoped>))

(define-ast <enum> (<type>)
  (fields #:init-form (list)))

(define-method (.name.name (o <enum>))
  (symbol->string ((compose .name .name) o)))

(define-ast <extern> (<type>)
  (value))

(define-method (.name.name (o <extern>))
  (symbol->string ((compose .name .name) o)))

(define-ast <bool> (<type>))
(define-method (initialize (o <bool-node>) . initargs)
  (next-method o (list #:name (make <scope.name-node> #:name 'bool))))

(define-ast <void> (<type>))
(define-method (initialize (o <void-node>) . initargs)
  (next-method o (list #:name (make <scope.name-node> #:name 'void))))

(define-ast <int> (<type>)
  (range #:init-form (make <range-node>)))

(define-method (.name.name (o <int>))
  ((compose symbol->string .name .name) o))

(define-ast <range> (<ast>)
  (from #:init-value 0)
  (to #:init-value 0))

(define-ast <signature> (<ast>)
  (type.name #:init-form (make <void-node>))
  (formals #:init-form (make <formals-node>)))

(define void-signature (make <signature-node>))

(define-ast <event> (<named>)
  (signature #:init-form (make <signature-node>))
  (direction))

(define-ast <modeling-event> (<event>))
(define-method (.signature (o <modeling-event>) void-signature))

(define-method (.direction (o <modeling-event>)) 'in)

(define-ast <inevitable> (<modeling-event>))
(define-method (.name (o <inevitable>)) 'inevitable)

(define-ast <optional> (<modeling-event>))
(define-method (.name (o <optional>)) 'optional)

(define ast:inevitable (make <inevitable-node>))
(define ast:optional (make <optional-node>))

(define-ast <port> (<named>)
  (type.name #:init-form (make <scope.name-node>))
  (direction)
  (external)
  (injected))

(define-ast <trigger> (<ast>)
  (port.name)
  (event)
  (formals #:init-form (make <formals-node>)))
(define-method (.event.name (o <trigger>)) (and=> (.event o) .name))
(define-method (.event.direction (o <trigger>)) (and=> (.event o) .direction))

(define-ast <expression> (<ast>))

(define-ast <literal> (<expression>)
  (value #:init-value *unspecified*))

(define-ast <binary> (<expression>)
  (left #:init-value *unspecified*)
  (right #:init-value *unspecified*))

(define-ast <unary> (<expression>)
  (expression #:init-value *unspecified*))

(define-ast <group> (<unary>))

(define-ast <bool-expr> (<expression>))
(define-ast <enum-expr> (<expression>))
(define-ast <int-expr> (<expression>))
(define-ast <data-expr> (<expression>))
(define-ast <void-expr> (<expression>))

(define-ast <not> (<unary> <bool-expr>))
(define-ast <and> (<binary> <bool-expr>))
(define-ast <equal> (<binary> <bool-expr>))
(define-ast <greater-equal> (<binary> <bool-expr>))
(define-ast <greater> (<binary> <bool-expr>))
(define-ast <less-equal> (<binary> <bool-expr>))
(define-ast <less> (<binary> <bool-expr>))
(define-ast <minus> (<binary> <int-expr>))
(define-ast <not-equal> (<binary> <bool-expr>))
(define-ast <or> (<binary> <bool-expr>))
(define-ast <plus> (<binary> <int-expr>))

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

(define-ast <data> (<data-expr>)
  (value))

(define-ast <var> (<expression>)
  (variable.name))

(define-ast <variable> (<named> <imperative> <expression>)
  (type.name)
  (expression #:init-form (make <expression-node>)))

(define-ast <field-test> (<bool-expr>)
  (variable.name)
  (field))

(define-ast <enum-literal> (<enum-expr>)
  (type.name)
  (field))

(define-ast <otherwise> (<expression>) ;; FIXME: make <guard-otherwise/guard-else-node> instead
  (value #:init-value *unspecified*))

(define-ast <formal> (<named> <expression>)
  (type.name)
  (direction))

(define-ast <formal-binding> (<formal>)
  (variable.name))

(define-ast <component-model> (<model>)
  (ports #:init-form (make <ports-node>)))

(define-ast <foreign> (<component-model>))

(define-ast <component> (<component-model>)
  (behaviour))

(define-ast <system> (<component-model>)
  (instances #:init-form (make <instances-node>))
  (bindings #:init-form (make <bindings-node>)))

(define-ast <shell-system> (<system>))

(define-ast <behaviour> (<named>)
  (types #:init-form (make <types-node>))
  (ports #:init-form (make <ports-node>))
  (variables #:init-form (make <variables-node>))
  (functions #:init-form (make <functions-node>))
  (statement #:init-form (make <compound-node>)))

(define-ast <function> (<named>)
  (signature #:init-form (make <signature-node>))
  (recursive)
  (statement))

(define-ast <action> (<imperative> <expression>)
  (port.name)
  (event)
  (arguments #:init-form (make <arguments-node>)))
(define-method (.event.name (o <action>)) (and=> (.event o) .name))
(define-method (.event.direction (o <action>)) (and=> (.event o) .direction))

(define-ast <assign> (<imperative>)
  (variable.name)
  (expression #:init-form (make <expression-node>)))

(define-ast <call> (<imperative> <expression>)
  (function.name)
  (arguments #:init-form (make <arguments-node>))
  (last?))

(define-ast <guard> (<declarative>)
  (expression #:init-form (make <expression-node>))
  (statement))

(define-ast <otherwise-guard> (<guard>))

(define-ast <if> (<imperative>)
  (expression #:init-form (make <expression-node>))
  (then)
  (else))

(define-ast <illegal> (<imperative>)
  (event)
  (incomplete))

(define-ast <blocking> (<declarative>)
  (statement))

(define-ast <on> (<declarative>)
  (triggers #:init-form (make <triggers-node>))
  (statement))

(define-ast <reply> (<imperative>)
  (expression)
  (port.name))

(define-ast <return> (<imperative>)
  (expression))

(define-ast <bind> (<declarative>)
  (left)
  (right))

(define-ast <binding> (<ast>)
  (instance)
  (port.name))

(define-method (.instance.name (o <binding>)) (and=> (.instance o) .name))

(define-ast <instance> (<named> <declarative>)
  (type.name #:init-form (make <scope.name-node>)))

(define-ast <error> (<ast>)
  (ast)
  (message #:init-value ""))

(define-ast <skip> (<imperative>))

(define-ast <the-end> (<statement>)
  (trigger))
(define-ast <the-end-blocking> (<statement>))
(define-ast <voidreply> (<statement>))

(define-ast <argument> (<named> <expression>)
  (type)
  (direction))

(define-ast <enum-field> (<ast>)
  (type)
  (field))

(define-ast <file-name> (<ast>)
  (name))

(define-ast <local> (<variable>))
(define-ast <model-scope> (<ast>))
(define-ast <out-formal> (<variable>))
(define-ast <direction> (<named>))
(define-ast <unspecified> (<ast>))

(define-method (.id (o <object>))
  (pointer-address (scm->pointer o)))

(define-method (.id (o <ast>))  (.id (.node o)))

(define-method (node-class (class <class>))
  (node-class- (make class #:node #f #:parent #f)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
