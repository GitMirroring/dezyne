;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2020, 2021 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2017, 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017, 2018, 2019, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn ast goops)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (system foreign)
  #:use-module (ice-9 curried-definitions)

  #:use-module ((oop goops)
                #:renamer (lambda (x)
                            (if (member x '(<port> <foreign>))
                                (symbol-append 'goops: x)
                                x)))
  #:use-module (dzn goops util)
  #:export (define-ast

             .id
             .operator
             .variable.name)
  #:re-export (<top>
               <class> <object>
               <applicable> <procedure>
               <boolean> <char> <list> <pair> <null> <string> <symbol>
               <number>
               <unknown>

               as
               class-name
               class-of
               define-class
               define-generic
               define-method
               is?
               is-a?
               make))

(define-syntax define-ast
  (lambda (x)
    (define (getter-name name)
      (string->symbol (string-append "." (symbol->string name))))
    (define (complete-slot slot)
      (define (create-slot name init-keyword init-value)
        (let ((getter (datum->syntax x (getter-name (syntax->datum name))))
              (keyword (datum->syntax x (symbol->keyword (syntax->datum name)))))
          #`(#,name #:getter #,getter #,init-keyword #,init-value #:init-keyword #,keyword)))
      (syntax-case slot ()
        ((name)
         (create-slot #'name #:init-value #f))
        ((name #:init-form form)
         (create-slot #'name #:init-form #'form))
        ((name #:init-value value)
         (create-slot #'name #:init-value #'value))))
    (define (slot->getter-name slot)
      (let ((name (syntax-case slot ()
                    ((name) #'name)
                    ((name #:init-form form) #'name)
                    ((name #:init-value value) #'name))))
        (datum->syntax x (getter-name (syntax->datum name)))))
    (syntax-case x ()
      ((_ name supers slot ...)
       (with-syntax (((slot' ...) (map complete-slot #'(slot ...))))
         #`(begin
             (export name
                     #,@(filter (compose not defined? syntax->datum)
                                (map slot->getter-name #'(slot ...))))
             (define-class name supers slot' ...)))))))

(define-ast <ast> ())

(define-ast <ast-list> (<ast>)
  (elements #:init-form (list)))

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

(define-ast <namespace> (<declaration> <ast-list> <scope>))

(define-ast <root> (<namespace>))

(define-ast <scope.name> (<ast>)
  (ids #:init-form (list)))


(define-ast <block-comment> (<comment>))
(define-ast <line-comment> (<comment>))

(define-ast <statement> (<locationed>))
(define-ast <declarative> (<statement>))
(define-ast <imperative> (<statement>))

(define-ast <arguments> (<ast-list> <locationed>))
(define-ast <bindings> (<ast-list>))
(define-ast <compound> (<scope> <ast-list> <statement>))
(define-ast <blocking-compound> (<compound>)
  (port))

(define-ast <declarative-compound> (<ast-list> <declarative>))
(define-ast <events> (<ast-list>))
(define-ast <fields> (<ast-list>))
(define-ast <formals> (<ast-list> <scope>))
(define-ast <out-bindings> (<formals> <imperative>)
  (port))
(define-ast <functions> (<ast-list>))
(define-ast <instances> (<ast-list>))
(define-ast <ports> (<ast-list>))

(define g-root-id 0)
(define-method (initialize (o <root>) . initargs)
  (let ((root (apply next-method (cons o initargs))))
    (set! g-root-id (.id root))
    root))

(define-ast <triggers> (<ast-list>))
(define-ast <types> (<ast-list>))
(define-ast <variables> (<ast-list>))

(define-ast <import> (<named>))

(define-ast <model> (<scope> <declaration>))

(define-ast <interface> (<model>)
  (types #:init-form (make <types>))
  (events #:init-form (make <events>))
  (behavior))

(define-ast <type> (<declaration>))

(define-ast <enum> (<scope> <type>)
  (fields #:init-form (list)))

(define-ast <extern> (<type>)
  (value))

(define-ast <bool> (<type>))
(define-method (initialize (o <bool>) . initargs)
  (next-method o (append (car initargs) (list #:name (make <scope.name> #:ids '("bool"))))))

(define-ast <void> (<type>))
(define-method (initialize (o <void>) . initargs)
  (next-method o (append (car initargs) (list #:name (make <scope.name> #:ids '("void"))))))

(define-ast <int> (<type>))
(define-method (initialize (o <int>) . initargs)
  (next-method o (append (car initargs) (list #:name (make <scope.name> #:ids '("<int>"))))))

(define-ast <subint> (<int>)
  (range #:init-form (make <range>)))

(define-ast <range> (<ast>)
  (from #:init-value 0)
  (to #:init-value 0))

(define-ast <signature> (<locationed>) ;; instance
  (type.name #:init-form (make <void>))
  (formals #:init-form (make <formals>)))

(define-ast <event> (<declaration>)
  (signature #:init-form (make <signature>))
  (direction))

(define-ast <modeling-event> (<event>))
(define-method (.signature (o <modeling-event>))
  (make <signature>))

(define-method (.direction (o <modeling-event>)) 'in)

(define-ast <inevitable> (<modeling-event>))
(define-method (.name (o <inevitable>)) "inevitable")

(define-ast <optional> (<modeling-event>))
(define-method (.name (o <optional>)) "optional")

(define-ast <instance> (<declaration> <declarative>)
  (type.name #:init-form (make <scope.name>)))

(define-ast <port> (<instance>)
  (direction)                           ; symbol 'provides / 'requires
  (blocking?)
  (external?)
  (formals #:init-form (make <formals>))
  (injected?))

(define-ast <trigger> (<scope> <locationed>)
  (port.name)
  (event.name)
  (formals #:init-form (make <formals>)))

(define-ast <silent-trigger> (<trigger>))

(define-ast <expression> (<locationed>))

(define-ast <binary> (<expression>)
  (left #:init-value *unspecified*)
  (right #:init-value *unspecified*))

(define-ast <unary> (<expression>)
  (expression #:init-value *unspecified*))

(define-ast <literal> (<unary>)
  (value #:init-value (make <void>)))

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

(define-ast <reference> (<named> <unary>))

(define-ast <undefined> (<unary>)
  (name))

(define-ast <shared> (<ast>))

(define-ast <shared-reference> (<shared> <reference>)
  (port.name))

(define-ast <variable> (<declaration> <imperative> <unary>)
  (type.name)
  (expression #:init-form (make <expression>)))

(define-ast <shared-variable> (<shared> <variable>)
  (port.name))

(define-ast <field-test> (<unary> <bool-expr>)
  (name)
  (field))
;; TODO REMOVEME backwards compatibility function variable.name -> name
;; when refactoring naming and lookup
(define-method (.variable.name (o <field-test>))
  (.name o))

(define-ast <shared-field-test> (<shared> <field-test>)
  (port.name))

(define-ast <enum-literal> (<unary> <enum-expr>)
  (type.name)
  (field))

(define-ast <otherwise> (<expression>)
  (value #:init-value *unspecified*))

(define-ast <formal> (<declaration> <unary>)
  (type.name)
  (direction #:init-value 'in))

(define-ast <formal-binding> (<formal>)
  (variable.name))

(define-ast <formal-reference> (<declaration>))

(define-ast <formal-reference-binding> (<formal-reference>)
  (variable.name))

(define-ast <component-model> (<model>)
  (ports #:init-form (make <ports>)))

(define-ast <foreign> (<component-model>))

(define-ast <component> (<component-model>)
  (behavior))

(define-ast <system> (<component-model>)
  (instances #:init-form (make <instances>))
  (bindings #:init-form (make <bindings>)))

(define-ast <shell-system> (<system>))

(define-ast <behavior> (<scope> <declaration>)
  (types #:init-form (make <types>))
  (variables #:init-form (make <variables>))
  (functions #:init-form (make <functions>))
  (statement #:init-form (make <compound>)))

(define-ast <function> (<scope> <declaration>)
  (signature #:init-form (make <signature>))
  (noisy?)
  (recursive?)
  (statement))

(define-ast <action> (<imperative> <unary>)
  (port.name)
  (event.name)
  (arguments #:init-form (make <arguments>)))

(define-ast <defer> (<scope> <imperative>)
  (arguments)
  (statement))

(define-ast <defer-end> (<imperative>))

(define-ast <assign> (<imperative>)
  (variable.name)
  (expression #:init-form (make <expression>)))

(define-ast <call> (<imperative> <unary>)
  (function.name)
  (arguments #:init-form (make <arguments>))
  (last?))

(define-ast <guard> (<declarative>)
  (expression #:init-form (make <expression>))
  (statement))

(define-ast <otherwise-guard> (<guard>))

(define-ast <if> (<imperative> <scope>)
  (expression #:init-form (make <expression>))
  (then)
  (else))

(define-ast <declarative-illegal> (<declarative>))

(define-ast <illegal> (<imperative>)
  (event.name))

(define-ast <blocking> (<declarative>)
  (statement))

(define-ast <on> (<declarative>)
  (triggers #:init-form (make <triggers>))
  (statement))

(define-ast <canonical-on> (<declarative>)
  (blocking)
  (guard)
  (trigger)
  (statement))

(define-ast <reply> (<imperative>)
  (expression #:init-form (make <literal>))
  (port.name))

(define-ast <return> (<imperative>)
  (expression #:init-form (make <literal>)))

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
  (direction)
  (expression))

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


;;;
;;; Helpers.
;;;
(define-method (.id (o <object>))
  (pointer-address (scm->pointer o)))
