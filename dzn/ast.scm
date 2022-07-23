;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2018, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017, 2018, 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
;;; Copyright © 2019, 2020, 2022 Paul Hoogendijk <paul@dezyne.org>
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

(define-module (dzn ast)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (ice-9 q)

  #:use-module (dzn ast accessor)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast equal)
  #:use-module (dzn ast lookup)
  #:use-module (dzn ast util)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)

  #:export (ast:argument->formal
            ast:base-name
            ast:blocking?
            ast:component-model*
            ast:declarative?
            ast:default-value
            ast:defer-variable*
            ast:direction
            ast:dotted-name
            ast:expression->type
            ast:external?
            ast:filter-model
            ast:formal->index
            ast:full-scope
            ast:get-model
            ast:graph-cyclic?
            ast:imperative?
            ast:imported?
            ast:in-event*
            ast:in-triggers
            ast:in?
            ast:injected-port*
            ast:injected?
            ast:inout?
            ast:instance?
            ast:interface*
            ast:literal-false?
            ast:literal-true?
            ast:location
            ast:location->string
            ast:member?
            ast:modeling?
            ast:normalize
            ast:optional?
            ast:other-direction
            ast:other-end-point
            ast:other-end-point-injected
            ast:out-event*
            ast:out-triggers
            ast:out-triggers-in-events
            ast:out-triggers-out-events
            ast:out-triggers-valued-in-events
            ast:out-triggers-void-in-events
            ast:out?
            ast:provides-in-triggers
            ast:provides-in-valued-triggers
            ast:provides-in-void-triggers
            ast:provides-out-triggers
            ast:provides-port
            ast:provides-port*
            ast:provides?
            ast:recursive?
            ast:requires-in-triggers
            ast:requires-in-void-triggers
            ast:requires-no-injected-port*
            ast:requires-out-triggers
            ast:requires-port*
            ast:requires?
            ast:rescope
            ast:return-type
            ast:return-types
            ast:return-types-provides
            ast:return-values
            ast:source-file
            ast:system*
            ast:topological-model-sort
            ast:type
            ast:typed?
            ast:value
            ast:valued-in-triggers
            ast:values
            ast:void-in-triggers
            ast:wildcard?)
  #:re-export (.direction
               .event
               .event.direction
               .function
               .type
               .instance
               .port.name
               .variable
               .variable.name

               ast:eq?
               ast:equal?
               ast:full-name
               ast:name
               ast:parent
               ast:path
               ast:pure-funcq

               ast:argument*
               ast:binding*
               ast:data*
               ast:event*
               ast:field*
               ast:formal*
               ast:function*
               ast:import*
               ast:instance*
               ast:member*
               ast:model*
               ast:namespace*
               ast:port*
               ast:statement*
               ast:top*
               ast:trigger*
               ast:type*
               ast:variable*

               as
               ast-name
               clone
               drop-<>
               is?
               tree-collect
               tree-collect-filter
               tree-filter
               tree-map))

;;;
;;; Predicates.
;;;
(define-method (ast:literal-true? (e <ast>))
  (and (is-a? e <literal>)
       (equal? (.value e) "true")))

(define-method (ast:literal-false? (e <ast>))
  (and (is-a? e <literal>)
       (equal? (.value e) "false")))

(define-method (ast:declarative? (o <declarative>))
  #t)

(define-method (ast:declarative? o)
  #f)

(define-method (ast:declarative? (o <compound>))
  (let ((statements (ast:statement* o)))
    (or (and (null? statements) (is-a? (.parent o) <behavior>))
        (and (pair? statements) ((compose ast:declarative? car) statements)))))

(define-method (ast:imperative? (o <imperative>))
  #t)

(define-method (ast:imperative? o)
  #f)

(define-method (ast:imperative? (o <compound>))
  (let ((statements (ast:statement* o)))
    (or (and (null? statements) (not (is-a? (.parent o) <behavior>)))
        (and (pair? statements) ((compose ast:imperative? car) statements)))))

(define-method (ast:imported? (o <ast>))
  (not (equal? (ast:source-file o) (ast:source-file (ast:parent o <root>)))))

(define-method (ast:in? (o <event>))
  (eq? 'in (.direction o)))

(define-method (ast:in? (o <formal>))
  (eq? 'in (.direction o)))

(define-method (ast:in? (o <argument>))
  (eq? 'in (.direction o)))

(define-method (ast:in? (o <trigger>))
  (and=> (.event o) ast:in?))

(define-method (ast:in? (o <action>))
  (and=> (.event o) ast:in?))

(define-method (ast:in? (o <variable>))
  #t)

(define-method (ast:out? (o <event>))
  (eq? 'out (.direction o)))

(define-method (ast:out? (o <formal>))
  (eq? 'out (.direction o)))

(define-method (ast:out? (o <argument>))
  (eq? 'out (.direction o)))

(define-method (ast:out? (o <trigger>))
  (and=> (.event o) ast:out?))

(define-method (ast:out? (o <action>))
  (and=> (.event o) ast:out?))

(define-method (ast:out? (o <variable>))
  #f)

(define-method (ast:inout? (o <event>))
  (eq? 'inout (.direction o)))

(define-method (ast:inout? (o <formal>))
  (eq? 'inout (.direction o)))

(define-method (ast:inout? (o <argument>))
  (eq? 'inout (.direction o)))

(define-method (ast:inout? (o <variable>))
  #f)

(define-method (ast:modeling? (o <event>))
  #f)

(define-method (ast:modeling? (o <modeling-event>))
  #t)

(define-method (ast:modeling? (o <trigger>))
  ((compose ast:modeling? .event) o))

(define-method (ast:optional? (o <optional>))
  #t)

(define-method (ast:optional? (o <event>))
  #f)

(define-method (ast:optional? (o <trigger>))
  (ast:optional? (.event o)))

(define-method (ast:optional? (o <interface>))
 (pair? (ast:optional* o)))

(define-method (ast:blocking? (o <port>))
  (and (.blocking? o) o))

(define-method (ast:blocking? (o <action>))
  (and=> (.port o) ast:blocking?))

(define-method (ast:external? (o <port>))
  (and (.external? o) o))

(define-method (ast:injected? (o <port>))
  (and (.injected? o) o))

(define-method (ast:member? (o <variable>))
  (is-a? (.parent (.parent o)) <behavior>))

(define-method (ast:member? (o <top>))
  #f)

(define-method (ast:provides? (o <port>))
  (and (eq? (.direction o) 'provides) o))

(define-method (ast:provides? (o <trigger>))
  (and (.port.name o) ((compose ast:provides? .port) o)))

(define-method (ast:provides? (o <action>))
  (and (.port.name o) ((compose ast:provides? .port) o)))

(define-method (ast:requires? (o <port>))
  (and (eq? (.direction o) 'requires) o))

(define-method (ast:requires? (o <trigger>))
  (and (.port.name o) ((compose ast:requires? .port) o)))

(define-method (ast:requires? (o <action>))
  (and (.port.name o) ((compose ast:requires? .port) o)))

(define-method (ast:wildcard? (o <string>))
  (equal? o "*"))

(define-method (ast:wildcard? (o <boolean>))
  #f)

(define-method (ast:typed? (o <event>))
  (let ((type ((compose .type .signature) o)))
    (not (as type <void>))))

(define-method (ast:typed? (o <action>))
  (ast:typed? (.event o)))

(define-method (ast:typed? (o <signature>))
  (not (as (.type o) <void>)))

(define-method (ast:typed? (o <trigger>))
  ((compose ast:typed? .event) o))

(define-method (ast:typed? (o <type>))
  #t)

(define-method (ast:typed? (o <void>))
  #f)

(define-method (ast:typed? (o <modeling-event>))
  #f)

(define-method (ast:typed? (o <expression>))
  (match o
    (($ <literal>) (not (equal? "void" (.value o))))
    (_ #t)))

(define-method (ast:instance? (o <component-model>))
  (let* ((root (ast:parent o <root>))
         (models (ast:model* root))
         (systems (filter (is? <system>) models)))
    (find (lambda (s)
            (find (lambda (i) (ast:eq? (.type i) o)) (ast:instance* s)))
          systems)))


;;;
;;; Resolving accessors.
;;;
(define-method (ast:event* (o <port>)) ((compose ast:event* .type) o))

(define-method (ast:function* (o <function>))
  (let* ((calls (tree-collect (is? <call>) o))
         (functions (filter-map .function calls)))
    (delete-duplicates
     functions
     (lambda (a b) (equal? (.name a) (.name b))))))


;;;
;;; Algorithmic accessors.
;;;
(define-method (ast:dotted-name (o <ast>))
  (string-join (ast:full-name o) "."))

(define-method (ast:full-scope (o <ast>))
  (drop-right (ast:full-name o) 1))

(define-method (ast:full-scope (o <root>))
  '())

(define-method (ast:full-scope (o <field-test>))
  ((compose ast:full-scope .type .variable) o))

(define-method (ast:provides-port o)
  (let ((ports (ast:provides-port* o)))
    (and (pair? ports) (car ports))))

(define-method (ast:other-direction (o <event>))
  (assoc-ref `((in . out)
               (out . in))
             (.direction o)))

(define-method (ast:other-direction (o <trigger>))
  ((compose ast:other-direction .event) o))

(define-method (ast:injected-port* (o <component-model>))
  (filter ast:injected? (ast:port* o)))

(define-method (ast:injected-port* (o <trigger>))
  (ast:injected-port* (ast:parent o <component-model>)))

(define-method (ast:provides-port* (o <component-model>))
  (filter ast:provides? (ast:port* o)))

(define-method (ast:provides-port* (o <port>))
  (ast:provides-port* (ast:parent o <component-model>)))

(define-method (ast:requires-port* (o <component-model>))
  (filter ast:requires? (ast:port* o)))

(define-method (ast:requires-port* (o <port>))
  (ast:requires-port* (ast:parent o <component-model>)))

(define-method (ast:requires-no-injected-port* (o <component-model>))
  (filter (conjoin (negate ast:injected?) ast:requires?) (ast:port* o)))

(define-method (ast:direction (o <port>))
  (if (ast:provides? o) 'in
      'out))

(define-method (ast:direction (o <trigger>))
  (.direction (.event o)))

(define-method (trigger-in-component (t <trigger>) (c <component>))
  (let ((parent (or (and=> (.behavior c) .statement) c)))
    (clone t #:parent parent)))

(define-method (trigger-in-component (t <trigger>) (c <component-model>))
  (clone t #:parent c))

(define-method (ast:in-event* o)
  (filter ast:in? (ast:event* o)))

(define-method (ast:out-event* o)
  (filter ast:out? (ast:event* o)))

(define-method (ast:provides-in-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
                          (filter ast:in? (ast:event* (.type port)))))
                   (filter ast:provides? (ast:port* o)))))

(define-method (ast:provides-in-void-triggers (o <component-model>))
  (filter (compose (is? <void>) .type .signature .event)
          (ast:provides-in-triggers o)))

(define-method (ast:provides-in-valued-triggers (o <component-model>))
  (filter (compose (negate (is? <void>)) .type .signature .event)
          (ast:provides-in-triggers o)))

(define-method (ast:requires-out-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
                          (filter ast:out? (ast:event* (.type port)))))
                   (filter ast:requires? (ast:port* o)))))

(define-method (ast:in-triggers (o <component-model>))
  (append (ast:provides-in-triggers o)
          (ast:requires-out-triggers o)))

(define-method (ast:in-triggers (o <interface>))
  (map (lambda (event) (make <trigger> #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
       (filter ast:in? (ast:event* o))))

(define-method (ast:provides-out-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
                          (filter ast:out? (ast:event* (.type port)))))
                   (filter ast:provides? (ast:port* o)))))

(define-method (ast:requires-in-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
                          (filter ast:in? (ast:event* (.type port)))))
                   (filter ast:requires? (ast:port* o) ))))

(define-method (ast:requires-in-void-triggers (o <component-model>))
  (filter (compose (is? <void>) ast:type) (ast:requires-in-triggers o)))

(define-method (ast:out-triggers (o <component-model>))
  (append (ast:provides-out-triggers o) (ast:requires-in-triggers o)))

(define-method (ast:void-in-triggers (o <component-model>))
  (filter
   (lambda (t) (is-a? ((compose .type .signature .event) t) <void>))
   (ast:in-triggers o)))

(define-method (ast:valued-in-triggers (o <component-model>))
  (filter
   (lambda (t) (not (is-a? ((compose .type .signature .event) t) <void>)))
   (ast:in-triggers o)))

(define-method (trigger-in-event? (o <trigger>))
  ((compose ast:in? .event) o))

(define-method (ast:out-triggers-in-events (o <component-model>))
  (filter (compose ast:in? .event) (ast:out-triggers o)))

(define-method (ast:out-triggers-out-events (o <component-model>))
  (filter (compose ast:out? .event) (ast:out-triggers o)))

(define-method (ast:out-triggers-void-in-events (o <component-model>))
  (filter
   (compose (is? <void>) .type .signature .event)
   (ast:out-triggers-in-events o)))

(define-method (ast:out-triggers-valued-in-events (o <component-model>))
  (filter
   (compose not (is? <void>) .type .signature .event)
   (ast:out-triggers-in-events o)))

(define-method (ast:optional* (o <ast>))
   (match o
     (($ <interface>) ((compose ast:optional* .behavior) o))
     (($ <component>) '())
     (($ <behavior>) (append-map ast:optional* (ast:statement* o)))
     (($ <guard>) ((compose ast:optional* .statement) o))
     (($ <on>) (filter (cut equal? "optional" <>) (map .event.name (ast:trigger* o))))
     ((? (disjoin (is? <declarative-compound>) (is? <compound>))) (append-map ast:optional* (ast:statement* o)))))

(define-method (ast:type (o <action>))
  ((compose ast:type .event) o))
(define-method (ast:type (o <call>))
  ((compose ast:type .function) o))
(define-method (ast:type (o <bool>)) o)
(define-method (ast:type (o <enum>)) o)
(define-method (ast:type (o <enum-literal>))
  (or (ast:parent o <enum>)
      (.type o)))
(define-method (ast:type (o <enum-field>))
  (.type o))
(define-method (ast:type (o <event>))
  ((compose ast:type .signature) o))
(define-method (ast:type (o <function>))
  ((compose ast:type .signature) o))
(define-method (ast:type (o <formal>))
  (.type o))
(define-method (ast:type (o <int>)) o)
(define-method (ast:literal-value->type o)
  (match o
    ((or "false" "true") (make <bool>))
    ((? number?) (make <int>))
    (_ (make <void>))))
(define-method (ast:type (o <literal>))
(ast:literal-value->type (.value o)))
(define-method (ast:type (o <port>))
  (.type o))
(define-method (ast:type (o <instance>))
  (.type o))
(define-method (ast:type (o <signature>))
  (.type o))
(define-method (ast:type (o <subint>)) o)
(define-method (ast:type (o <trigger>))
  ((compose ast:type .event) o))
(define-method (ast:type (o <on>))
  (map ast:type ((compose .elements .triggers) o)))
(define-method (ast:type (o <assign>))
  (ast:type (.variable o)))
(define-method (ast:type (o <variable>))
  (.type o))
(define-method (ast:type (o <var>))
  (and=> (.variable o) .type))
(define-method (ast:type (o <void>)) o)

(define-method (ast:type (o <bool-expr>))
  (make <bool>))
(define-method (ast:type (o <data-expr>))
  (make <extern>))
(define-method (ast:type (o <int-expr>))
  (make <int>))
(define-method (ast:type (o <group>))
  ((compose ast:type .expression) o))

(define-method (ast:type (o <reply>))
  (ast:type (.expression o)))

(define-method (ast:type (o <return>))
  (ast:type (.expression o)))

(define-method (ast:type o) #f)

(define-method (ast:type (o <extern>))
  o)

(define-method (ast:type (o <model>))
  o)

(define-method (ast:argument->formal (o <expression>))
  (let* ((call (ast:parent o <call>))
         (arguments (ast:argument* call))
         (index (list-index (cut ast:eq? o <>) arguments))
         (formals ((compose ast:formal* .function) call)))
    (list-ref formals index)))

(define-method (ast:formal->index (o <formal>))
  (let* ((formals (.elements (ast:parent o <formals>)))
         (index (list-index (cut ast:eq? o <>) formals)))
    index))

(define-method (ast:defer-variable* (o <defer>))
  (if (not (.arguments o)) (ast:member* (ast:parent o <model>))
      (map .variable (ast:argument* o))))

(define-method (ast:expression->type (o <expression>))
  (let ((p (.parent o)))
    (define (as-p o class)
      (or (as o class) (as p class)))
    (cond ((as-p o <action>) => (compose .type .signature .event))
          ((as-p o <assign>) => (compose .type .variable))
          ((as-p o <arguments>) ((compose .type ast:argument->formal) o))
          ((as-p o <var>) => (compose .type .variable))
          ((as-p o <variable>) => .type)
          ((as-p o <return>)
           => (compose .type .signature (cute ast:parent <> <function>)))
          ((is-a? o <bool-expr>) (make <bool>))
          ((is-a? o <int-expr>) (make <int>))
          ((ast:parent <expression>) => ast:expression->type)
          ((is-a? o <literal>) (ast:literal-value->type (.value o)))
          (else (make <void>)))))

(define-method (ast:return-types (interface <interface>))
  "Return all event types used in INTERFACE."
  (delete-duplicates (append-map ast:return-types (ast:event* interface)) ast:eq?))

(define-method (ast:return-types (component <component-model>))
  "Return all event types used in COMPONENT."
  (delete-duplicates (append-map ast:return-types (filter-map ast:type (ast:port* component))) ast:eq?))

(define-method (ast:return-types (o <event>))
  (list (ast:type o)))

(define-method (ast:return-types (o <type>))
  (list o))

(define-method (ast:return-types-provides (component <component-model>))
  "Return all event types used in COMPONENT."
  (let* ((ports (ast:provides-port* component))
         (interfaces (filter-map ast:type ports))
         (types (append-map ast:return-types interfaces)))
   (delete-duplicates types ast:eq?)))

(define-method (ast:values (o <type>) void)
  (cond
   ((as o <void>)
    void)
   ((as o <enum>)
    (let ((type (make <scope.name> #:ids (ast:full-name o))))
     (map (cute make <enum-literal> #:type.name type #:field <>)
          (ast:field* o))))
   ((as o <bool>)
    (map (cute make <literal> #:value <>) '("false" "true")))
   ((as o <subint>)
    (map (cute make <literal> #:value <>)
         (iota (1+ (- (.to (.range o)) (.from (.range o))))
               (.from (.range o)))))))

(define-method (ast:values (o <type>))
  (ast:values o '()))

(define-method (ast:default-value (o <type>))
  (match (ast:values o)
    ((default rest ...) default)))

(define-method (ast:default-value (o <ast>))
  (ast:default-value (ast:type o)))

(define-method (ast:return-values (o <event>) void)
  (let ((type ((compose .type .signature) o)))
    (ast:values type void)))

(define-method (ast:return-values (o <event>))
  (ast:return-values o '()))

(define-method (ast:return-values (o <port>))
  (append-map (cute ast:return-values <> '("return")) (ast:in-event* o)))

(define-method (ast:return-values (o <action>))
  (ast:return-values (.event o)))

(define-method (ast:return-values (o <trigger>))
  (ast:return-values (.event o)))

(define-method (ast:location (o <locationed>))
  (.location o))

(define-method (ast:location (o <root>))
  (.location o))

(define-method (ast:location (o <ast-list>))
  (or (.location o)
      (let ((elements (.elements o)))
        (if (null? elements) (ast:location (.parent o))
            (ast:location (car elements))))))

(define-method (ast:location o) #f)

(define (ast:location->string o)
  (let ((location (ast:location o)))
    (and location
         (format #f "~a:~a:~a"
                 (.file-name location)
                 (.line location)
                 (.column location)))))

(define-method (ast:base-name (o <ast>))
  (basename (ast:source-file o) ".dzn"))

(define-method (ast:source-file (o <ast>))
  (or (and=> (ast:location o) .file-name) (ast:source-file (.parent o))))

(define-method (ast:value (o <literal>))
  (.value o))
(define-method (ast:value (o <enum-literal>))
  (string-join (append (.ids (.type.name o)) (list (.field o)))))

(define-method (ast:interface* (o <component-model>))
  (let ((ports (ast:port* o)))
    (delete-duplicates (map .type ports) ast:eq?)))

(define-method (ast:model* (o <interface>))
  (list o))

(define-method (ast:model* (o <component-model>))
  (append (ast:interface* o) (list o)))

(define-method (ast:model* (o <system>))
  (let* ((components (ast:component-model* o))
         (components (delete-duplicates components ast:eq?))
         (interfaces (append-map ast:interface* components))
         (interfaces (delete-duplicates interfaces ast:eq?)))
    (ast:topological-model-sort (append interfaces components))))

(define-method (ast:instance-model* (o <system>))
  (filter-map .type (ast:instance* o)))

(define-method (ast:component-model* (o <component-model>))
  (list o))

(define-method (ast:component-model* (o <system>))
  (let ((components (ast:instance-model* o)))
    (cons o (append-map ast:component-model* components))))

(define-method (ast:system* (o <system>))
  (filter (is? <system>) (ast:instance-model* o)))

(define-method (ast:system* (o <root>))
  (filter (is? <system>) (ast:model* o)))


;;;
;;; Filtering, partitioning.
;;;

(define-method (ast:filter-model (root <root>) (model <model>))
  (let ((models (ast:model* model)))
    (tree-filter (disjoin (negate (is? <component-model>))
                          (cute member <> models ast:eq?))
                 root)))


;;;
;;; Utility.
;;;
(define* (ast:get-model root #:optional model-name)
  (let ((models (ast:model* root)))
    (cond
     (model-name
      (let ((model (find (lambda (o) (equal? (ast:dotted-name o) model-name)) models)))
        (unless model
          (throw 'error (format #f "No such model: ~s" model-name)))
        model))
     (else
      (let ((models (filter (negate ast:imported?) models)))
        (or (let ((systems (filter (is? <system>) models)))
              (find (negate ast:instance?) systems))
            (find (is? <component>) models)
            (find (is? <interface>) models)))))))

(define-method (ast:normalize (o <binding>))
  "Bring binding O in canonical form, i.e., ordering from a system's top
to bottom."
  (let* ((left (.left o))
         (right (.right o))
         (left-instance (.instance left))
         (right-instance (.instance right))
         (left-provides? (and=> (.port left) ast:provides?))
         (right-provides? (and=> (.port right) ast:provides?))
         (canonical?
          (or (and (not left-instance) right-instance left-provides?)
              (and left-instance right-instance (not left-provides?))
              (and left-instance (not right-instance) (not left-provides?)))))
    (if canonical? o
        (clone o #:left right #:right left))))

(define-method (ast:other-end-point (o <port>))
  (let loop ((bindings (ast:binding* (ast:parent o <system>))))
    (and (pair? bindings)
         (let* ((binding (car bindings))
                (left (.left binding))
                (right (.right binding))
                (port (.name o)))
           (cond ((and (not (.instance.name left))
                       (equal? (.port.name left) port))
                  right)
                 ((and (not (.instance.name right))
                       (equal? (.port.name right) port))
                  left)
                 (else (loop (cdr bindings))))))))

(define-method (ast:other-end-point (i <instance>) (o <port>))
  (let ((system (ast:parent i <system>)))
    (let loop ((bindings (ast:binding* system)))
      (and (pair? bindings)
           (let* ((binding (car bindings))
                  (left (.left binding))
                  (right (.right binding))
                  (port (.name o)))
             (cond ((and (equal? (.instance.name left) (.name i))
                         (equal? (.port.name left) port))
                    right)
                   ((and (equal? (.instance.name right) (.name i))
                         (equal? (.port.name right) port))
                    left)
                   (else (loop (cdr bindings)))))))))

(define-method (ast:other-end-point-injected (system <system>) (o <port>))
  ;; pre: (and (.injected? o) (not "o is directly bound"))
  (let loop ((bindings (ast:binding* system)))
    (and (pair? bindings)
         (let* ((binding (car bindings))
                (left (.left binding))
                (right (.right binding))
                (port (.name o)))
           (cond ((and (not (.instance.name left))
                       (equal? (.port.name left) "*")
                       (ast:eq? (.type (.port right)) (.type o)))
                  right)
                 ((and (not (.instance.name right))
                       (equal? (.port.name right) "*")
                       (ast:eq? (.type (.port left)) (.type o)))
                  left)
                 ;; todo: try j.*
                 (else (loop (cdr bindings))))))))

(define-method (rescope-name (o <ast>) (parent <model>))
  (let* ((name (ast:full-name o))
         (parent-name (ast:full-name parent))
         (scoped (let loop ((list1 name) (list2 parent-name))
                   (if (and (pair? list1) (pair? list2) (equal? (car list1) (car list2)))
                       (loop (cdr list1) (cdr list2))
                       list1))))
    (make <scope.name> #:ids scoped)))

(define-method (ast:rescope (o <ast>) (parent <model>))
  (match o
    ((and ($ <reply>) (= .expression expression))
     (clone o #:expression (ast:rescope expression parent)))
    ((and ($ <enum-literal>) (= .type.name type.name))
     (clone o #:type.name (rescope-name (.type o) parent)))
    ((and ($ <formals>) (= .elements elements))
     (clone o #:elements (map (cut ast:rescope <> parent) elements)))
    (($ <formal>)
     (clone o #:type.name (rescope-name (.type o) parent)))
    (_ o)))

(define-method (ast:rescope (o <boolean>) x)
  o)

(define-method (topological-sort (dag <list>) key)
"Sort DAG topologically using function KEY, where DAG looks like

@lisp
((a child-a-0 child a-1 ...)
 (b child-b-0 child-b-1 ...))
@end lisp
"
  (if (null? dag) '()
      (let* ((adj-table (make-hash-table))
             (sorted '()))

        (define (visit node children)
          (if (eq? 'visited (hashq-ref adj-table (key node))) (error "double visit")
              (begin
                (hashq-set! adj-table (key node) 'visited)
                ;; Visit unvisited nodes which node connects to
                (for-each (lambda (child)
                            (let ((val (hashq-ref adj-table (key child))))
                              (if (not (eq? val 'visited))
                                  (visit child (or val '())))))
                          children)
                ;; Since all nodes downstream node are visited
                ;; by now, we can safely put node on the output list
                (set! sorted (cons node sorted)))))

        ;; Visit nodes
        (for-each (lambda (def) (hashq-set! adj-table (key (car def)) (cdr def))) dag)
        (visit (caar dag) (cdar dag))
        (for-each (lambda (def)
                    (let ((val (hashq-ref adj-table (key (car def)))))
                      (if (not (eq? val 'visited))
                          (visit (car def) (cdr def)))))
                  (cdr dag))
        (reverse sorted))))

(define-method (ast:topological-model-sort (models <list>))
  "Return MODELS, sorted topologically."

  (let* ((systems rest (partition (is? <system>) models))
         (rest (stable-sort rest
                            (lambda (a b)
                              (or (and (is-a? a <extern>)
                                       (or (is-a? b <interface>)
                                           (is-a? b <component>)
                                           (is-a? b <foreign>)))
                                  (and (is-a? a <interface>)
                                       (or (is-a? b <component>)
                                           (is-a? b <foreign>)))))))
         (system-dag (map (lambda (o)
                            (cons o (filter (is? <system>)
                                            (map .type (ast:instance* o)))))
                          systems))
         (systems (topological-sort system-dag ast:name))
         (systems (filter (cute member <> models ast:eq?) systems)))
    (append rest systems)))

;; This implements Tarjan's strongly connected components algorithm,
;; see https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
(define ast:graph-scc
  (let ((index-table (make-hash-table))     ;values: #f or 0..#num-nodes
        (lowlink-table (make-hash-table))   ;values: 0..#num-nodes
        (on-stack?-table (make-hash-table)) ;values: #f, #t
        (scc-table (make-hash-table))       ;values: list of nodes
        (index 0)
        (stack (make-q)))
    (lambda (succ* v)              ;(succ* x) -> list of successors of x
      (define (push! v)
        (hashq-set! on-stack?-table v #t)
        (q-push! stack v))
      (define (pop!)
        (let ((top (q-pop! stack)))
          (hashq-set! on-stack?-table top #f)
          top))
      (let ((v-key (.node v)))
        (when (not (hashq-ref index-table v-key #f))
          (hashq-set! index-table v-key index)
          (hashq-set! lowlink-table v-key index)
          (set! index (1+ index))
          (push! v-key)
          (for-each
           (lambda (w)
             (let ((w-key (.node w)))
               (cond ((not (hashq-ref index-table w-key #f))
                      (ast:graph-scc succ* w)
                      (hashq-set! lowlink-table v-key
                                  (min (hashq-ref lowlink-table v-key)
                                       (hashq-ref lowlink-table w-key))))
                     ((hashq-ref on-stack?-table w-key)
                      (hashq-set! lowlink-table v-key
                                  (min (hashq-ref lowlink-table v-key)
                                       (hashq-ref index-table w-key)))))))
           (succ* v))
          (when (eq? (hashq-ref index-table v-key)
                     (hashq-ref lowlink-table v-key))
            (let ((scc (let loop ((w-key (pop!)))
                         (if (eq? w-key v-key) (list v-key)
                             (cons w-key (loop (pop!)))))))
              (for-each (cut hashq-set! scc-table <> scc) scc))))
        (hashq-ref scc-table v-key)))))

(define (ast:graph-cyclic? succ* o)
  (let ((scc (ast:graph-scc succ* o)))
    (or (not (null? (cdr scc)))
        (find (lambda (s) (eq? (.node o) (.node s))) (succ* o)))))

(define-method (ast:recursive? (o <function>))
  (ast:graph-cyclic? ast:function* o))
