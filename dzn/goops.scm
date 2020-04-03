;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2020, 2021 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2017, 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017, 2018, 2019, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn goops)
  #:use-module (system foreign)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (dzn misc)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:export (define-ast
            <ast>
            <ast-node>
            .node
            .parent

            .event.name
            .id
            .instance.name
            .operator
            .port.name

            ast:inevitable
            ast:optional

            as
            ast-name
            ast:unwrap
            clone
            clone-base
            drop-<>
            has-slot?
            is?
            parent
            parent-not
            symbol->class
            tree-collect
            tree-collect-filter
            tree-filter
            tree-map))

;; FIXME: generate-me
(export
           .arguments
           .ast
           .behavior
           .bindings
           .blocking?
           .column
           .comment
           .direction
           .elements
           .else
           .end-column
           .end-line
           .event.name
           .events
           .expression
           .external?
           .field
           .fields
           .file-name
           .formals
           .from
           .function.name
           .functions
           .ids
           .injected?
           .instances
           .last?
           .left
           .length
           .line
           .location
           .message
           .name
           .noisy?
           .offset
           .port
           .ports
           .range
           .recursive?
           .right
           .root
           .scope
           .signature
           .statement
           .string
           .then
           .to
           .trigger
           .triggers
           .type.name
           .types
           .value
           .variable.name
           .variables
           .working-directory

           <action-or-call>
           <action>
           <and>
           <argument>
           <arguments>
           <assign>
           <ast-list>
           <ast-node-list>
           <behavior>
           <binary>
           <binding>
           <bindings>
           <block-comment>
           <blocking-compound>
           <blocking>
           <bool-expr>
           <bool>
           <call>
           <comment>
           <component-model>
           <component>
           <compound>
           <data-expr>
           <data>
           <declarative-compound>
           <declarative-illegal>
           <declarative>
           <direction>
           <end-point>
           <enum-expr>
           <enum-field>
           <enum-literal>
           <enum>
           <equal>
           <error>
           <event>
           <events>
           <expression>
           <extern>
           <field-test>
           <fields>
           <file-name>
           <foreign>
           <formal-binding>
           <formal>
           <formals>
           <function>
           <functions>
           <greater-equal>
           <greater>
           <group>
           <guard>
           <if>
           <illegal>
           <imperative>
           <import>
           <inevitable>
           <info>
           <instance>
           <instances>
           <int-expr>
           <int>
           <interface>
           <less-equal>
           <less>
           <line-comment>
           <literal>
           <local>
           <location>
           <location-end>
           <message>
           <minus>
           <model-scope>
           <model>
           <modeling-event>
           <named>
           <namespace>
           <not-equal>
           <not>
           <on>
           <optional>
           <or>
           <otherwise-guard>
           <otherwise>
           <out-bindings>
           <out-formal>
           <plus>
           <port>
           <ports>
           <range>
           <reply>
           <return>
           <root>
           <scope.name>
           <selection>
           <shell-system>
           <signature>
           <silent-trigger>
           <skip>
           <stack>
           <statement>
           <system>
           <tag>
           <the-end-blocking>
           <the-end>
           <trigger>
           <triggers>
           <type>
           <types>
           <unary>
           <undefined>
           <unspecified>
           <var>
           <variable>
           <variables>
           <void>
           <voidreply>
           <warning>)

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

(define-class <ast-node> ()
  (comment #:getter .comment #:init-value #f #:init-keyword #:comment))

(define-method (.comment (o <ast>))
  (.comment (.node o)))

(define-ast <ast-list> (<ast>)
  (elements #:init-form (list)))

(define-method (.elements (o <ast-list>))
  (map (lambda (e) (make-wrapper e o)) ((compose .elements .node) o)))

(define-method (make-wrapper (o <top>) p) o)
(define-method (make-wrapper (o <ast-node>) p) o)
(define-method (make-wrapper (o <ast-list-node>) p) (make <ast-list> #:parent p #:node o))

(define-ast <location> (<ast>)
  (file-name)
  (line)
  (column)
  (end-line)
  (end-column)
  (offset)
  (length))

(define-ast <locationed> (<ast>)
  (comment)
  (location))                           ; <location>

(define-ast <comment> (<locationed>)
  (string))

(define-ast <named> (<locationed>)
  (name))                               ; symbol or <scope.name>

(define-ast <declaration> (<named>))
(define-ast <scope> (<ast>))

(define-ast <namespace> (<scope> <ast-list> <declaration>))

(define-ast <root> (<namespace>)
  (working-directory))

(define-ast <scope.name> (<ast>)
  (ids #:init-form (list)))


(define-ast <block-comment> (<comment>))
(define-ast <line-comment> (<comment>))

(define-ast <statement> (<locationed>))
(define-ast <declarative> (<statement>))
(define-ast <imperative> (<statement>))

(define-ast <arguments> (<ast-list> <locationed>))
(define-ast <bindings> (<ast-list>))
(define-ast <out-bindings> (<ast-list> <imperative>)
  (port))
(define-method (.port.name (o <out-bindings>)) (and=> (.port o) .name))

(define-ast <compound> (<scope> <ast-list> <statement>))
(define-ast <blocking-compound> (<compound>)
  (port))
(define-method (.port.name (o <blocking-compound>)) (and=> (.port o) .name))

(define-ast <declarative-compound> (<ast-list> <declarative>))
(define-ast <events> (<ast-list>))
(define-ast <fields> (<ast-list>))
(define-ast <formals> (<ast-list> <scope>))
(define-ast <functions> (<ast-list>))
(define-ast <instances> (<ast-list>))
(define-ast <ports> (<ast-list>))

(define g-root-id 0)
(define-method (initialize (o <root-node>) . initargs)
  (let ((root (apply next-method (cons o initargs))))
    (set! g-root-id (.id root))
    root))

(define-ast <triggers> (<ast-list>))
(define-ast <types> (<ast-list>))
(define-ast <variables> (<ast-list>))

(define-ast <import> (<named>))

(define-ast <model> (<scope> <declaration>))

(define-ast <interface> (<model>)
  (types #:init-form (make <types-node>))
  (events #:init-form (make <events-node>))
  (behavior))

(define-ast <type> (<declaration>))

(define-ast <enum> (<scope> <type>)
  (fields #:init-form (list)))

(define-ast <extern> (<type>)
  (value))

(define-ast <bool> (<type>))
(define-method (initialize (o <bool-node>) . initargs)
  (next-method o (append (car initargs) (list #:name (make <scope.name-node> #:ids '("bool"))))))

(define-ast <void> (<type>))
(define-method (initialize (o <void-node>) . initargs)
  (next-method o (append (car initargs) (list #:name (make <scope.name-node> #:ids '("void"))))))

(define-ast <int> (<type>)
  (range #:init-form (make <range-node>)))

(define-ast <range> (<ast>)
  (from #:init-value 0)
  (to #:init-value 0))

(define-ast <signature> (<locationed>)
  (type.name #:init-form (make <scope.name-node> #:ids '("void")))
  (formals #:init-form (make <formals-node>)))

(define void-signature-node (make <signature-node>))

(define-ast <event> (<declaration>)
  (signature #:init-form (make <signature-node>))
  (direction))

(define-ast <modeling-event> (<event>))
(define-method (.signature (o <modeling-event>))
  (make <signature> #:node void-signature-node #:parent o))

(define-method (.direction (o <modeling-event>)) 'in)

(define-ast <inevitable> (<modeling-event>))
(define-method (.name (o <inevitable>)) "inevitable")

(define-ast <optional> (<modeling-event>))
(define-method (.name (o <optional>)) "optional")

(define (ast:inevitable) (make <inevitable>))
(define (ast:optional) (make <optional>))

(define-ast <instance> (<declaration> <declarative>)
  (type.name #:init-form (make <scope.name-node>)))

(define-ast <port> (<instance>)
  (direction)                           ; symbol 'provides / 'requires
  (blocking?)
  (external?)
  (formals #:init-form (make <formals-node>))
  (injected?))

(define-ast <trigger> (<scope> <locationed>)
  (port.name)
  (event.name)
  (formals #:init-form (make <formals-node>)))

(define-ast <silent-trigger> (<trigger>))

(define-ast <expression> (<locationed>))

(define-ast <binary> (<expression>)
  (left #:init-value *unspecified*)
  (right #:init-value *unspecified*))

(define-ast <unary> (<expression>)
  (expression #:init-value *unspecified*))

(define-ast <literal> (<unary>)
  (value #:init-value "void"))

(define-ast <group> (<unary>))

(define-ast <bool-expr> (<expression>))
(define-ast <enum-expr> (<expression>))
(define-ast <int-expr> (<expression>))
(define-ast <data-expr> (<expression>))

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

(define-ast <var> (<named> <unary>))

(define-ast <undefined> (<unary>)
  (name))

(define-ast <variable> (<declaration> <imperative> <unary>)
  (type.name)
  (expression #:init-form (make <expression-node>)))

(define-ast <field-test> (<unary> <bool-expr>)
  (variable.name)
  (field))

(define-ast <enum-literal> (<unary> <enum-expr>)
  (type.name)
  (field))

(define-ast <otherwise> (<expression>) ;; FIXME: make <guard-otherwise/guard-else-node> instead
  (value #:init-value *unspecified*))

(define-ast <formal> (<declaration> <unary>)
  (type.name)
  (direction #:init-value 'in))

(define-ast <formal-binding> (<formal>)
  (variable.name))

(define-ast <component-model> (<model>)
  (ports #:init-form (make <ports-node>)))

(define-ast <foreign> (<component-model>))

(define-ast <component> (<component-model>)
  (behavior))

(define-ast <system> (<component-model>)
  (instances #:init-form (make <instances-node>))
  (bindings #:init-form (make <bindings-node>)))

(define-ast <shell-system> (<system>))

(define-ast <behavior> (<scope> <declaration>)
  (types #:init-form (make <types-node>))
  (ports #:init-form (make <ports-node>))
  (variables #:init-form (make <variables-node>))
  (functions #:init-form (make <functions-node>))
  (statement #:init-form (make <compound-node>)))

(define-ast <function> (<scope> <declaration>)
  (signature #:init-form (make <signature-node>))
  (noisy?)
  (recursive?)
  (statement))

(define-ast <action> (<imperative> <unary>)
  (port.name)
  (event.name)
  (arguments #:init-form (make <arguments-node>)))

(define-ast <defer> (<scope> <imperative>)
  (arguments)
  (statement))

(define-ast <defer-end> (<imperative>))

(define-ast <action-or-call> (<named> <imperative> <unary>)
  (arguments #:init-form (make <arguments-node>)))

(define-ast <assign> (<imperative>)
  (variable.name)
  (expression #:init-form (make <expression-node>)))

(define-ast <call> (<imperative> <unary>)
  (function.name)
  (arguments #:init-form (make <arguments-node>))
  (last?))

(define-ast <guard> (<declarative>)
  (expression #:init-form (make <expression-node>))
  (statement))

(define-ast <otherwise-guard> (<guard>))

(define-ast <if> (<imperative> <scope>)
  (expression #:init-form (make <expression-node>))
  (then)
  (else))

(define-ast <declarative-illegal> (<declarative>))

(define-ast <illegal> (<imperative>)
  (event.name))

(define-ast <blocking> (<declarative>)
  (statement))

(define-ast <on> (<declarative>)
  (triggers #:init-form (make <triggers-node>))
  (statement))

(define-ast <reply> (<imperative>)
  (expression #:init-form (make <literal-node>))
  (port.name))

(define-ast <return> (<imperative>)
  (expression #:init-form (make <literal-node>)))

(define-ast <stack> (<ast>))
(define-ast <return-value> (<ast>))

(define-ast <binding> (<declarative>)
  (left)
  (right))

(define-ast <end-point> (<locationed>)
  (instance.name)
  (port.name))

(define-ast <status> (<ast>)
  (ast))

(define-ast <message> (<status>)
  (message #:init-value ""))

(define-ast <error> (<message>))

(define-ast <info> (<message>))

(define-ast <warning> (<message>))

(define-ast <skip> (<imperative>))

(define-ast <tag> (<imperative>))

(define-ast <the-end> (<statement>)
  (trigger))
(define-ast <the-end-blocking> (<statement>))
(define-ast <voidreply> (<statement>))

(define-ast <argument> (<named> <unary>)
  (type.name)
  (direction))

(define-ast <enum-field> (<ast>)
  (type.name)
  (field)
  (value))

(define-ast <file-name> (<ast>)
  (name))

(define-ast <local> (<variable>))
(define-ast <model-scope> (<ast>)
  (scope))
(define-ast <out-formal> (<variable>))
(define-ast <direction> (<named>))
(define-ast <unspecified> (<ast>))

(define-method (.variable.name (o <action>))
  (let ((parent (.parent o)))
    (match parent
      (($ <assign>) (.variable.name parent))
      (($ <variable>) (.name parent)))))

(define-method (.variable.name (o <var>))
  (.name o))

(define-method (.id (o <object>))
  (pointer-address (scm->pointer o)))

(define-method (.id (o <ast>))  (.id (.node o)))

(define-method (node-class (class <class>))
  (node-class- (make class #:node #f #:parent #f)))

(define-method (ast:unwrap o) o)
(define-method (ast:unwrap (o <ast-node>)) o)
(define-method (ast:unwrap (o <pair>)) (map ast:unwrap o))
(define-method (ast:unwrap (o <ast>)) (.node o))

(define-method (get-parent o) #f)
(define-method (get-parent (o <ast>)) (.parent o))

(define (construct class . setters)
  (let* ((class-node (node-class class))
         (node (apply make (cons class-node (map ast:unwrap setters))))
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

(define-method (slot-names (o <class>))
  (map slot-definition-name (class-slots o)))
(define-method (slot-names (o <object>))
  ((compose slot-names class-of) o))
(define-method (slot-names (o <ast>))
  ((compose slot-names .node) o))
(define-method (has-slot? (o <object>) name)
  (memq name (slot-names o)))

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
(define-method (tree-map f (o <namespace>)) (clone o #:elements (map f (.elements o)) #:name (f (.name o))))
(define-method (tree-map f (o <root>)) (clone o #:elements (map f (.elements o))))

(define-method (tree-filter f (o <ast>)) (and (f o) o))
(define-method (tree-filter f (o <ast-list>)) (clone o #:elements (map (cut tree-filter f <>) (filter f (.elements o)))))

(define-method (tree-collect-filter filter-predicate predicate o)
  (if (and (filter-predicate o) (predicate o)) (list o) '()))

(define-method (tree-collect-filter filter-predicate predicate (o <ast>))
  (if (not (filter-predicate o)) '()
      (let* ((class (class-of (.node o)))
             (slots (class-slots class))
             (getters (map slot-definition-getter slots))
             (children (append-map (lambda (g) (tree-collect-filter filter-predicate predicate (g o))) getters)))
        (if (predicate o) (cons o children) children))))

(define-method (tree-collect-filter filter-predicate predicate (o <ast-list>))
  (if (not (filter-predicate o)) '()
      (let ((children (append-map (cut tree-collect-filter filter-predicate predicate <>) (.elements o))))
        (if (predicate o) (cons o children) children))))

(define-method (tree-collect predicate o)
  (tree-collect-filter identity predicate o))

(define-method (clone-base o . setters)
  (let* ((class (class-of o))
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

(define-method (clone-base-unwrap o . setters)
  (let ((setters (if (memq #:parent setters) setters
                     (map ast:unwrap setters))))
    (apply clone-base (cons o setters))))

(define-method (clone-base-node (o <ast-node>) . setters)
  (apply clone-base-unwrap (cons o setters)))

(define-method (clone-base-ast (o <ast>) . setters)
  (apply clone-base-unwrap (cons o setters)))

(define-method (clone (o <ast-node>) . setters)
  (apply clone-base-node (cons o setters)))

(define-method (clone (o <ast>) . setters)
  (if (or (memq #:node setters) (memq #:parent setters))
      (apply clone-base-ast (cons o setters))
      (clone-base-ast o #:node (apply clone-base-node (cons (.node o) setters)))))

(define-method (parent o (class <class>)) #f)
(define-method (parent (o <ast>) (class <class>))
  (if (is-a? o class) o
      (parent (.parent o) class)))

(define-method (parent-not o (class <class>)) #f)
(define-method (parent-not (o <ast>) (class <class>))
  (let ((parent (.parent o)))
    (if (not (is-a? parent class)) parent
        (parent-not parent class))))

(define (drop-<> o)
  (string-drop (string-drop-right (symbol->string o) 1) 1))

(define-method (ast-name (o <top>))
  (drop-<> (class-name (class-of o))))

(define-method (ast-name (o <class>))
  (drop-<> (class-name o)))

(define (symbol->class x) (symbol-append '< x '>))

(define (as o c)
  (and (is-a? o c) o))

(define ((is? class) o)
  (and (is-a? o class) o))
