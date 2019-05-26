;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
;; Copyright © 2017, 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2017, 2018 Johri van Eerd <johri.van.eerd@verum.com>
;; Copyright © 2014, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (gaiag ast)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag parse)

  #:export (
           ast:formal->index
           ast:argument->formal
           ast:async-out-triggers
           ast:async?
           ast:async-port*
           ast:clr-events
           ast:declarative?
           ast:direction
           ast:dzn-scope?
           ast:eq?
           ast:equal?
           ast:expression->type
           ast:filter-model
           ast:full-name
           ast:get-model
           ast:id-path
           ast:in-event*
           ast:in-triggers
           ast:in?
           ast:injected-port*
           ast:inout?
           ast:instance?
           ast:imperative?
           ast:imported?
           ast:literal-false?
           ast:literal-true?
           ast:location
           ast:name
           ast:optional?
           ast:other-direction
           ast:other-end-point
           ast:other-end-point-injected
           ast:out?
           ast:out-event*
           ast:out-triggers
           ast:out-triggers-in-events
           ast:out-triggers-out-events
           ast:provides-port
           ast:provides-port*
           ast:provided-in-triggers
           ast:provided-out-triggers
           ast:rescope
           ast:req-events
           ast:requires-port*
           ast:required+async
           ast:required-in-triggers
           ast:required-out-triggers
           ast:rescope
           ast:scope
           ast:source-file
           ast:return-type
           ast:return-types
           ast:return-values
           ast:valued-in-triggers
           ast:void-in-triggers
           ast:out-triggers-valued-in-events
           ast:out-triggers-void-in-events
           ast:modeling?
           ast:typed?
           ast:used-model*
           ast:path
           ast:provides?
           ast:requires?
           ast:wildcard?
           ast:external?
           ast:injected?
           ast:type
           ast:value

           ast:acceptance*
           ast:argument*
           ast:binding*
           ast:event*
           ast:field*
           ast:formal*
           ast:function*
           ast:instance*
           ast:lookup
           ast:lookup-var
           ast:member*
           ast:model*
           ast:namespace*
           ast:name-equal?
           ast:port*
           ast:statement*
           ast:top*
           ast:trigger*
           ast:type*
           ast:variable*
	   ast:void?
           topological-sort

           .event
           .event.direction
           .function
           .type
           .variable
           .instance
           )
  #:re-export (
               .direction
               ))

(define (deprecated . where)
  (stderr "DEPRECATED:~a\n" where))

;;; ast: accessors

(define-method (ast:acceptance* (o <acceptances>)) (.elements o))
(define-method (ast:argument* (o <arguments>)) (.elements o))
(define-method (ast:binding* (o <bindings>)) (.elements o))
(define-method (ast:statement* (o <compound>)) (.elements o))
(define-method (ast:statement* (o <declarative-compound>)) (.elements o))
(define-method (ast:event* (o <events>)) (.elements o))
(define-method (ast:field* (o <fields>)) (.elements o))
(define-method (ast:formal* (o <formals>)) (.elements o))
(define-method (ast:function* (o <functions>)) (.elements o))
(define-method (ast:instance* (o <instances>)) (.elements o))
(define-method (ast:port* (o <ports>)) (.elements o))
(define-method (ast:top* (o <root>)) (receive (imports rest) (partition (is? <import>) (.elements o)) (append rest (append-map ast:top* imports))))
(define-method (ast:top* (o <namespace>)) (.elements o))
(define-method (ast:top* (o <import>)) (ast:top* (.root o)))
(define-method (ast:member* (o <behaviour>)) (ast:variable* o))
(define-method (ast:member* (o <model>)) ((compose ast:member* .behaviour) o))
(define-method (ast:namespace* (o <namespace>)) (filter (is? <namespace>) (ast:top* o)))
(define-method (ast:trigger* (o <triggers>)) (.elements o))
(define-method (ast:type* (o <types>)) (.elements o))
(define-method (ast:variable* (o <variables>)) (.elements o))

;; namespace-recursive getters
(define-method (ast:namespace-recursive* (o <root>)) (filter (is? <namespace>) (append (ast:top* o) (append-map ast:namespace-recursive* (ast:namespace* o)))))
(define-method (ast:namespace-recursive* (o <namespace>)) (filter (is? <namespace>) (append (ast:top* o) (append-map ast:namespace-recursive* (ast:namespace* o)))))
(define-method (ast:model* (o <root>)) (filter (is? <model>) (append (ast:top* o) (append-map ast:model* (ast:namespace* o)))))
(define-method (ast:model* (o <namespace>)) (filter (is? <model>) (append (ast:top* o) (append-map ast:model* (ast:namespace* o)))))
(define-method (ast:type* (o <root>)) (filter (is? <type>) (append (ast:top* o) (append-map ast:type* (ast:namespace* o)))))
(define-method (ast:type* (o <namespace>)) (filter (is? <type>) (append (ast:top* o) (append-map ast:type* (ast:namespace* o)))))

(define-method (ast:namespace* (o <scope>)) '())

(define-method (ast:acceptance* (o <compliance-error>)) ((compose ast:acceptance* .port-acceptance) o))
(define-method (ast:argument* (o <action>)) ((compose ast:argument* .arguments) o))
(define-method (ast:argument* (o <call>)) ((compose ast:argument* .arguments) o))
(define-method (ast:binding* (o <system>)) ((compose ast:binding* .bindings) o))
(define-method (ast:event* (o <interface>)) ((compose ast:event* .events) o))
(define-method (ast:event* (o <port>)) ((compose ast:event* .type) o))
(define-method (ast:function* (o <component>)) ((compose ast:function* .behaviour) o))
(define-method (ast:field* (o <enum>)) ((compose ast:field* .fields) o))
(define-method (ast:formal* (o <event>)) ((compose ast:formal* .signature) o))
(define-method (ast:formal* (o <function>)) ((compose ast:formal* .signature) o))
(define-method (ast:formal* (o <signature>)) ((compose ast:formal* .formals) o))
(define-method (ast:formal* (o <trigger>)) ((compose ast:formal* .formals) o))
(define-method (ast:formal* (o <out-bindings>)) (.elements o))
(define-method (ast:function* (o <behaviour>)) ((compose ast:function* .functions) o))
(define-method (ast:instance* (o <system>)) ((compose ast:instance* .instances) o))
(define-method (ast:port* (o <component-model>)) ((compose ast:port* .ports) o))
(define-method (ast:port* (o <behaviour>)) ((compose ast:port* .ports) o))
(define-method (ast:statement* (o <behaviour>)) ((compose ast:statement* .statement) o))
(define-method (ast:variable* (o <behaviour>)) ((compose ast:variable* .variables) o))
(define-method (ast:variable* (o <model>)) ((compose ast:variable* .behaviour) o))
(define-method (ast:trigger* (o <on>)) ((compose ast:trigger* .triggers) o))
(define-method (ast:type* (o <interface>)) ((compose ast:type* .types) o))
(define-method (ast:type* (o <behaviour>)) ((compose ast:type* .types) o))
(define-method (ast:variable* (o <behaviour>)) ((compose ast:variable* .variables) o))
(define-method (ast:variable* (o <model>)) ((compose ast:variable* .behaviour) o))
(define-method (ast:variable* (o <compound>)) (filter (is? <variable>) (.elements o)))

(define-method (ast:async? (o <trigger>)) (parent (.port o) <behaviour>))
(define-method (ast:async-port* (o <component-model>)) ((compose ast:port* .behaviour) o))
(define-method (ast:provides-port o)
  (let ((ports (ast:provides-port* o)))
    (and (pair? ports) (car ports))))

(define-method (ast:dzn-scope? (o <model>))
  (let ((scope ((compose .scope .name) o)))
    (and (pair? scope) (member (car scope) '(dzn dzn')))))

(define-method (ast:provides? (o <port>))
  (and (eq? (.direction o) 'provides) o))

(define-method (ast:provides? (o <trigger>))
  (and (.port.name o) ((compose ast:provides? .port) o)))

(define-method (ast:requires? (o <port>))
  (and (eq? (.direction o) 'requires) o))

(define-method (ast:requires? (o <trigger>))
  (and (.port.name o) ((compose ast:requires? .port) o)))

(define-method (ast:empty-namespace? (o <symbol>))
  (eq? o '/))

(define-method (ast:wildcard? (o <symbol>))
  (eq? o '*))

(define-method (ast:wildcard? (o <boolean>))
  #f)

(define-method (ast:external? (o <port>))
  (and (.external o) o))

(define-method (ast:injected? (o <port>))
  (and (.injected o) o))

(define-method (ast:other-direction (o <event>))
  (assoc-ref `((in . out)
               (out . in))
             (.direction o)))

(define-method (ast:other-direction (o <trigger>))
  ((compose ast:other-direction .event) o))

(define-method (ast:injected-port* (o <component-model>))
  (filter ast:injected? (ast:port* o)))

(define-method (ast:provides-port* (o <port>))
  (ast:provides-port* (parent o <component-model>)))

(define-method (ast:provides-port* (o <component-model>))
  (filter ast:provides? (ast:port* o)))

(define-method (ast:requires-port* (o <component-model>))
  (filter ast:requires? (ast:port* o)))

(define-method (ast:required+async (o <component-model>))
  (append (ast:requires-port* o) (ast:async-port* o)))

(define-method (ast:direction (o <trigger>))
  (.direction (.event o)))

(define-method (trigger-in-component (t <trigger>) (c <component>))
  (let ((parent (or (and=> (.behaviour c) .statement) c)))
    (clone t #:parent parent)))

(define-method (trigger-in-component (t <trigger>) (c <component-model>))
  (clone t #:parent c))

(define-method (ast:in-event* o)
  (filter ast:in? (ast:event* o)))

(define-method (ast:out-event* o)
  (filter ast:out? (ast:event* o)))

(define-method (ast:provided-in-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
                          (filter ast:in? (ast:event* (.type port)))))
                   (filter ast:provides? (ast:port* o)))))

(define-method (ast:req-events (o <component>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
                          (filter (conjoin ast:in? (compose (cut eq? 'req <>) .name)) (ast:event* (.type port)))))
                   (if (.behaviour o) (ast:port* (.behaviour o))
                       '()))))

(define-method (ast:clr-events (o <component>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
                          (filter (conjoin ast:in? (compose (cut eq? 'clr <>) .name)) (ast:event* (.type port)))))
                   (if (.behaviour o) (ast:port* (.behaviour o))
                       '()))))

(define-method (ast:required-out-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
                          (filter ast:out? (ast:event* (.type port)))))
                   (filter ast:requires? (ast:port* o)))))

(define-method (ast:async-out-triggers (o <foreign>))
  '())

(define-method (ast:async-out-triggers (o <system>))
  '())

(define-method (ast:async-out-triggers (o <component>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
                          (filter ast:out? (ast:event* (.type port)))))
                   (if (.behaviour o) (ast:port* (.behaviour o))
                       '()))))

(define-method (ast:in-triggers (o <component-model>))
  (append (ast:provided-in-triggers o) (ast:required-out-triggers o) (ast:async-out-triggers o)))

(define-method (ast:in-triggers (o <interface>))
  (map (lambda (event) (make <trigger> #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
       (filter ast:in? (ast:event* o))))

(define-method (ast:in? (o <event>))
  (eq? 'in (.direction o)))

(define-method (ast:in? (o <formal>))
  (eq? 'in (.direction o)))

(define-method (ast:in? (o <argument>))
  (eq? 'in (.direction o)))

(define-method (ast:in? (o <trigger>))
  (ast:in? (.event o)))

(define-method (ast:in? (o <variable>))
  #t)

(define-method (ast:out? (o <event>))
  (eq? 'out (.direction o)))

(define-method (ast:out? (o <formal>))
  (eq? 'out (.direction o)))

(define-method (ast:out? (o <argument>))
  (eq? 'out (.direction o)))

(define-method (ast:out? (o <trigger>))
  (ast:out? (.event o)))

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

(define-method (ast:provided-out-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
                          (filter ast:out? (ast:event* (.type port)))))
                   (filter ast:provides? (ast:port* o)))))

(define-method (ast:required-in-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) o)))
                          (filter ast:in? (ast:event* (.type port)))))
                   (filter ast:requires? (ast:port* o) ))))

(define-method (ast:out-triggers (o <component-model>))
  (append (ast:provided-out-triggers o) (ast:required-in-triggers o)))

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
   (lambda (t) (is-a? ((compose .type .signature .event) t) <void>))
   (ast:out-triggers-in-events o)))

(define-method (ast:out-triggers-valued-in-events (o <component-model>))
  (filter
   (lambda (t) (not (is-a? ((compose .type .signature .event) t) <void>)))
   (ast:out-triggers-in-events o)))

(define-method (ast:modeling? (o <event>))
  #f)

(define-method (ast:modeling? (o <modeling-event>))
  #t)

(define-method (ast:modeling? (o <trigger>))
  ((compose ast:modeling? .event) o))

(define-method (ast:optional* (o <ast>))
   (match o
     (($ <interface>) ((compose ast:optional* .behaviour) o))
     (($ <component>) '())
     (($ <behaviour>) (append-map ast:optional* (ast:statement* o)))
     (($ <guard>) ((compose ast:optional* .statement) o))
     (($ <on>) (filter (cut eq? 'optional <>) (map .event.name (ast:trigger* o))))
     ((? (disjoin (is? <declarative-compound>) (is? <compound>))) (append-map ast:optional* (ast:statement* o)))))
(define-method (ast:optional? (o <interface>))
 (pair? (ast:optional* o)))

(define-method (ast:typed? (o <event>))
  (let ((type ((compose .type .signature) o)))
    (not (as type <void>))))

(define-method (ast:typed? (o <signature>))
  (not (as (.type o) <void>)))

(define-method (ast:typed? (o <trigger>))
  ((compose ast:typed? .event) o))

(define-method (ast:typed? (o <modeling-event>))
  #f)

(define-method (ast:typed? (o <expression>))
  (match o
    (($ <literal>) (not (eq? 'void (.value o))))
    (_ #t)))

(define-method (ast:path (o <ast>))
  (ast:path o (negate identity)))

(define-method (ast:path (o <ast>) stop?)
  (unfold stop? identity .parent o))

(define-method (ast:id-path (o <ast>))
  (map .id (ast:path o (negate identity))))

(define-method (ast:eq? (a <ast>) (b <ast>))
  (equal? (ast:id-path a) (ast:id-path b)))

(define-method (ast:eq? (a <ast>) b)
  #f)

(define-method (ast:eq? a (b <ast>))
  #f)

(define-method (ast:eq? a b)
  (eq? a b))

(define-method (ast:equal? a b)
  #f)

(define-method (ast:equal? (a <ast>) (b <ast>))
  (eq? (.node a) (.node b)))

(define-method (ast:equal? (a <declaration>) (b <declaration>))
  (equal? (ast:full-name a) (ast:full-name b)))

(define-method (ast:equal? (a <named>) (b <named>))
  (ast:equal? (.name a) (.name b)))

(define-method (ast:equal? (a <scope.name>) (b <scope.name>))
  (and (equal? (.scope a) (.scope b))
       (eq? (.name a) (.name b))))

(define-method (ast:equal? (a <enum-literal>) (b <enum-literal>))
  (and (ast:equal? (.type.name a) (.type.name b))
       (eq? (.field a) (.field b))))

(define-method (ast:equal? (a <end-point>) (b <end-point>))
  (and (eq? (.instance.name a) (.instance.name b))
       (eq? (.port.name a) (.port.name b))))

(define-method (ast:equal? (a <field-test>) (b <field-test>))
  (eq? (.field a) (.field b)))

(define-method (ast:equal? (a <literal>) (b <literal>))
  (eq? (.value a) (.value b)))

(define-method (ast:equal? (a <not>) (b <not>))
  (ast:equal? (.expression a) (.expression b)))

(define-method (ast:equal? (a <binary>) (b <binary>))
  (and
   (eq? (class-of a) (class-of b))
   (ast:equal? (.expression (.left a)) (.expression (.left b)))
   (ast:equal? (.expression (.right a)) (.expression (.right b)))))

(define-method (ast:equal? (a <expression>) (b <expression>))
  (if (eq? (class-of a) (class-of b))
      (throw 'add-ast:equal?-overload-for-type (class-of a))
      #f))

(define-method (ast:equal? (a <signature>) (b <signature>))
  (and
   (ast:equal? (.type.name a) (.type.name b))
   (= (length (ast:formal* a)) (length (ast:formal* b)))
   (every ast:equal? (map .type.name (ast:formal* a)) (map .type.name (ast:formal* b)))))

(define-method (ast:type (o <action>))
  ((compose ast:type .event) o))
(define-method (ast:type (o <call>))
  ((compose ast:type .function) o))
(define-method (ast:type (o <bool>)) o)
(define-method (ast:type (o <enum>)) o)
(define-method (ast:type (o <enum-literal>))
  (or (parent o <enum>)
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
    ((or 'false 'true) (make <bool>))
    ((? number?) (make <int>))
    (_ (make <void>))))
(define-method (ast:type (o <literal>))
  (let ((value (.value o)))
    (if (number? value) (ast:expression->type o)
        (ast:literal-value->type value))))
(define-method (ast:type (o <port>))
  (.type o))
(define-method (ast:type (o <instance>))
  (.type o))
(define-method (ast:type (o <signature>))
  (.type o))
(define-method (ast:type (o <trigger>))
  ((compose ast:type .event) o))
(define-method (ast:type (o <on>))
  (map ast:type ((compose .elements .triggers) o)))
(define-method (ast:type (o <assign>))
  (ast:type (.variable o)))
(define-method (ast:type (o <variable>))
  (.type o))
(define-method (ast:type (o <var>))
  ((compose .type .variable) o))
(define-method (ast:type (o <void>)) o)

(define-method (ast:type (o <bool-expr>))
  (make <bool>))
(define-method (ast:type (o <data-expr>))
  (make <data>))
(define-method (ast:type (o <int-expr>))
  (ast:expression->type o))
(define-method (ast:type (o <group>))
  ((compose ast:type .expression) o))

(define-method (ast:type (o <reply>))
  (ast:type (.expression o)))

(define-method (ast:type (o <return>))
  (ast:type (.expression o)))


(define-method (ast:type (o <extern>))
  o)

(define-method (ast:argument->formal (o <expression>))
  (let* ((call (parent o <call>))
         (arguments (ast:argument* call))
         (index (list-index (cut ast:eq? o <>) arguments))
         (formals ((compose ast:formal* .function) call)))
    (list-ref formals index)))

(define-method (ast:formal->index (o <formal>))
  (let* ((formals (.elements (parent o <formals>)))
         (index (list-index (cut ast:eq? o <>) formals)))
    index))

(define-method (ast:expression->type (o <expression>))
  (cond ((parent o <call>) ((compose .type ast:argument->formal) o))
        ((is-a? o <action>) ((compose .type .signature .event) o))
        ((parent o <assign>) => (compose .type .variable))
        ((parent o <variable>) => .type)
        ((parent o <return>) ((compose .type .signature) (parent o <function>)))
        ((is-a? o <literal>) (ast:literal-value->type (.value o)))
        ((is-a? o <bool-expr>) (make <bool>))
        ((is-a? o <int-expr>) (make <int>))
        (else (make <void>))))

(define-method (ast:return-type (o <event>))
  ((compose .type .signature) o))

(define-method (ast:return-types (o <interface>))
  (delete-duplicates (map ast:return-type (ast:event* o)) ast:eq?))

(define-method (ast:return-types (o <component-model>))
  (delete-duplicates (append-map ast:return-types (map .type (ast:port* o))) ast:eq?))

(define-method (ast:return-values (o <event>))
  (let ((type ((compose .type .signature) o)))
    (cond ((as type <void>) '())
          ((as type <enum>) (map (cut make <enum-literal> #:type.name (.name type) #:field <>) (ast:field* type)))
          ((as type <bool>) (map (cut make <literal> #:value <>) '(true false)))
          ((as type <int>) (map (cut make <literal> #:value <>) (iota (1+ (- (.to (.range type)) (.from (.range type)))) (.from (.range type))))))))

(define-method (ast:location (o <locationed>))
  (.location o))

(define-method (ast:location (o <root>))
  (.location o))

(define-method (ast:location (o <ast-list>))
  (let ((elements (.elements o)))
    (if (null? elements) (ast:location (.parent o))
         (ast:location (car elements)))))

(define-method (ast:location o) #f)

(define-method (ast:source-file (o <ast>))
  (or (and=> (ast:location o) .file-name) (ast:source-file (.parent o))))

(define-method (ast:imported? (o <ast>))
  (not (equal? (ast:source-file o) (ast:source-file (parent o <root>)))))

(define-method (ast:name (o <named>))
  (let ((name (.name o)))
    (if (is-a? name <scope.name>) (.name name)
        name)))

(define-method (ast:literal-true? (e <ast>))
  (and (is-a? e <literal>)
       (eq? (.value e) 'true)))

(define-method (ast:literal-false? (e <ast>))
  (and (is-a? e <literal>)
       (eq? (.value e) 'false)))

(define-method (ast:other-end-point (o <port>))
  (let loop ((bindings (ast:binding* (parent o <system>))))
    (and (pair? bindings)
         (let* ((binding (car bindings))
                (left (.left binding))
                (right (.right binding))
                (port (.name o)))
           (cond ((and (not (.instance.name left))
                       (eq? (.port.name left) port))
                  right)
                 ((and (not (.instance.name right))
                       (eq? (.port.name right) port))
                  left)
                 (else (loop (cdr bindings))))))))

(define-method (ast:other-end-point (i <instance>) (o <port>))
  (let ((system (parent i <system>)))
    (let loop ((bindings (ast:binding* system)))
      (and (pair? bindings)
           (let* ((binding (car bindings))
                  (left (.left binding))
                  (right (.right binding))
                  (port (.name o)))
             (cond ((and (eq? (.instance.name left) (.name i))
                         (eq? (.port.name left) port))
                    right)
                   ((and (eq? (.instance.name right) (.name i))
                         (eq? (.port.name right) port))
                    left)
                   (else (loop (cdr bindings)))))))))

(define-method (ast:other-end-point-injected (system <system>) (o <port>))
  ;; pre: (and (.injected o) (not "o is directly bound"))
  (let loop ((bindings (ast:binding* system)))
    (and (pair? bindings)
         (let* ((binding (car bindings))
                (left (.left binding))
                (right (.right binding))
                (port (.name o)))
           (cond ((and (not (.instance.name left))
                       (eq? (.port.name left) '*)
                       (ast:eq? (.type (.port right)) (.type o)))
                  right)
                 ((and (not (.instance.name right))
                       (eq? (.port.name right) '*)
                       (ast:eq? (.type (.port left)) (.type o)))
                  left)
                 ;; todo: try j.*
                 (else (loop (cdr bindings))))))))

(define-method (ast:used-model* (root <root>) (o <model>)) (list o))

(define-method (ast:used-model* (root <root>) (o <system>))
  (cons o (append-map (compose (cut ast:used-model* root <>) .type) (ast:instance* o))))

(define-method (ast:filter-model (root <root>) (model <model>))
  (let ((used (ast:used-model* root model)))
    (tree-filter (lambda (o) (or (not (is-a? o <component-model>))
                                 (find (cut ast:eq? o <>) used)))
                 root)))

(define-method (ast:instance? (o <component-model>))
  (let* ((root (parent o <root>))
         (models (ast:model* root))
         (systems (filter (is? <system>) models)))
    (find (lambda (s) (find (lambda (i) (ast:eq? (.type i) o)) (ast:instance* s))) systems))
  )

(define* (ast:get-model root #:optional model-name)
  (let ((models (ast:model* root)))
    (or (and model-name (find (lambda (o) (eq? (ast:dotted-name o) model-name)) models))
        (let ((systems (filter (is? <system>) models)))
          (find (negate ast:instance?) systems))
        (find (is? <component>) models)
        (find (is? <interface>) models))))

(define-method (ast:dotted-name (o <ast>))
  (symbol-join (ast:full-name o) '.))

(define-method (ast:full-name (o <scope.name>))
  (append (if (null? (.scope o)) (ast:full-name (parent (.parent o) <scope>)) (.scope o))
          (list (.name o))))

(define-method (ast:full-name (o <bool>))
  '(bool))

(define-method (ast:full-name (o <data>))
  '(data))

(define-method (ast:full-name (o <int>))
  '(int))

(define-method (ast:full-name (o <void>))
  '(void))

(define-method (ast:full-name (o <named>))
  (ast:full-name (.name o)))

(define-method (ast:full-name (o <declaration>))
  (if (and (is-a? o <named>) (is-a? (.name o) <scope.name>))
      (append (ast:full-name (parent (.parent o) <scope>)) (list (.name (.name o))))
      (ast:full-name (parent (.parent o) <scope>))))

(define-method (ast:full-name (o <root>))
  '())

(define-method (ast:full-name (o <scope>))
  (if (and (is-a? o <named>) (is-a? (.name o) <scope.name>))
      (append (ast:full-name (parent (.parent o) <scope>)) (list (.name (.name o))))
      (ast:full-name (parent (.parent o) <scope>))))

(define-method (ast:full-name (o <namespace>))
  (append (ast:full-name (parent (.parent o) <scope>)) (list (ast:name o))))

(define-method (ast:full-name (o <ast>))
  (ast:full-name (parent (.parent o) <scope>)))

(define-method (ast:scope (o <ast>))
  (drop-right (ast:full-name o) 1))

(define-method (ast:scope (o <root>))
  '())

(define-method (ast:scope (o <field-test>))
  ((compose ast:scope .type .variable) o))

(define-method (rescope-name (o <ast>) (parent <model>))
  (let* ((name (ast:full-name o))
         (parent-name (ast:full-name parent))
         (scoped (let loop ((list1 name) (list2 parent-name))
                   (if (and (pair? list1) (pair? list2) (eq? (car list1) (car list2)))
                       (loop (cdr list1) (cdr list2))
                       list1))))
    (make <scope.name> #:scope (drop-right scoped 1) #:name (last scoped))))

(define-method (ast:rescope (o <ast>) (parent <model>))
  (match o
    ((and ($ <trigger-return>) (= .expression expression))
     (clone o #:expression (ast:rescope expression parent)))
    ((and ($ <reply>) (= .expression expression))
     (clone o #:expression (ast:rescope expression parent)))
    ((and ($ <enum-literal>) (= .type.name type.name))
     (clone o #:type.name (rescope-name (.type o) parent)))
    ((and ($ <formals>) (= .elements elements))
     (clone o #:elements (map (cut ast:rescope <> parent) elements)))
    (($ <formal>)
     (clone o #:type.name (rescope-name (.type o) parent)))
    (_ o)))

(define-method (ast:value (o <literal>))
  (.value o))
(define-method (ast:value (o <enum-literal>))
  (symbol-join (append (.scope (.type.name o)) (list (.name (.type.name o))) (list (.field o)))))

(define-method (ast:rescope (o <boolean>) x)
  o)

(define-method (ast:declarative? (o <declarative>))
  #t)

(define-method (ast:declarative? o)
  #f)

(define-method (ast:declarative? (o <compound>))
  (let ((statements (ast:statement* o)))
    (and (pair? statements)
         ((compose ast:declarative? car) statements))))

(define-method (ast:imperative? (o <imperative>))
  #t)

(define-method (ast:imperative? o)
  #f)

(define-method (ast:imperative? (o <compound>))
  (let ((statements (ast:statement* o)))
    (or (null? statements)
        ((compose ast:imperative? car) statements))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LOOKUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-method (ast:name-equal? (a <symbol>) (b <symbol>))
  (eq? a b))

(define-method (ast:name-equal? (a <scope.name>) (b <symbol>))
  (and=> (.name a) (cut ast:name-equal? <> b)))

(define-method (ast:name-equal? (b <symbol>) (a <scope.name>))
  (ast:name-equal? a b))

(define-method (ast:name-equal? (a <scope.name>) (b <scope.name>))
  (and (.name a) (.name b) (ast:name-equal? (.name a) (.name b))))

(define-method (ast:name-equal? (a <named>) (b <symbol>))
    (ast:name-equal? (.name a) b))

(define-method (ast:name-equal? (b <symbol>) (a <named>))
    (ast:name-equal? a b))

(define-method (ast:name-equal? a b)
  #f)

(define-method (ast:has-equal-name a (b <named>))
  (ast:name-equal? a (.name b)))

(define-method (ast:has-equal-name a b) #f)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define funcq-hash (@@ (ice-9 poe) funcq-hash))
(define funcq-assoc (@@ (ice-9 poe) funcq-assoc))
(define funcq-memo (@@ (ice-9 poe) funcq-memo))
(define funcq-buffer (@@ (ice-9 poe) funcq-buffer))
(define not-found (list 'not-found))

(define (ast:pure-funcq base-func)
  (lambda args
    (let* ((key (cons base-func (map ast:unwrap args)))
           (cached (hashx-ref funcq-hash funcq-assoc funcq-memo key not-found)))
      (if (not (eq? cached not-found))
	  (begin
	    (funcq-buffer key)
	    cached)

	  (let ((val (apply base-func args)))
	    (funcq-buffer key)
	    (hashx-set! funcq-hash funcq-assoc funcq-memo key val)
	    val)))))



(define-method (ast:lookup-n (o <scope>) (name <scope.name>))
;;  (stderr "ast:lookup-n[~s]: ~s\n" o name)
  (let ((scope (.scope name)))
    (if (null? scope) (if (ast:has-equal-name (.name name) o) (list o)
                          (ast:lookup-n o (.name name)))
        (let* ((first (car scope))
               (first-scopes (ast:lookup-n o first)))
          (if (null? first-scopes) '()
              (let ((name (clone name #:scope (cdr scope))))
                ;;(stderr "found first scopes:~s\n" first-scopes)
                (ast:lookdown first-scopes name)))))))

(define-method (ast:lookdown (o <list>) (name <scope.name>))
  (append-map (cut ast:lookdown <> name) o))

(define-method (ast:lookdown (o <scope>) (name <symbol>))
;;  (stderr "ast:lookdown 1[~s]: ~s\n" o name)
  (filter (lambda (decl) (ast:name-equal? (.name decl)  name)) (ast:declaration* o)))

(define-method (ast:lookdown (o <scope>) (name <scope.name>))
;;  (stderr "ast:lookdown 2[~s]: ~s\n" o name)
  (let ((scope (.scope name)))
    (if (null? scope) (ast:lookdown o (.name name))
        (let* ((first (car scope))
               (first-scopes (ast:lookdown o first)))
          (if (null? first-scopes) '()
              (let ((name (clone name #:scope (cdr scope))))
                ;;(stderr "found first scope:~s\n" first-scope)
                (ast:lookdown first-scopes name)))))))

(define-method (ast:lookdown (o <ast>) (name <scope.name>))
;;  (stderr "ast:lookdown <ast>[~s]: ~s\n" o name)
  '())

(define-method (ast:lookup-n (o <ast>) name)
;;  (stderr "ast:lookup-n <ast> 2 [~s]: ~s\n" o name)
  (ast:lookup-n (parent o <scope>) name))

(define-method (ast:lookup-n (o <scope>) (name <symbol>))
;;  (stderr "ast:lookup-n 3 [~s]: ~s\n" o name)
  (if (ast:empty-namespace? name) (list (parent o <root>))
      (let ((found (filter (lambda (decl) (ast:name-equal? (.name decl) name)) (ast:declaration* o)))
            (p (.parent o)))
        (cond
         ((pair? found) found)
         ((not p) '())
         (else (ast:lookup-n (parent p <scope>) name))))))

(define-method (ast:lookup-n (o <boolean>) name)
  '())

(define (ast:lookup- root o name)
  (let ((lookup (ast:lookup-n o name)))
    (if (null? lookup) #f (car lookup))))

(define (ast:lookup o name) ((ast:pure-funcq  ast:lookup-) (parent o <root>) o name))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(define-method (ast:declaration* (o <root>))
  (filter (cut is-a? <> <declaration>) (ast:top* o)))

(define-method (ast:declaration* (o <namespace>))
  (filter (cut is-a? <> <declaration>)
          (append-map ast:top* (filter (compose (cut equal? <> (ast:full-name o)) ast:full-name)
                                       (ast:namespace-recursive* (parent o <root>))))))

(define-method (ast:declaration* (o <interface>))
  (append (ast:type* o) (ast:event* o)))

(define-method (ast:declaration* (o <component-model>))
  (ast:port* o))

(define-method (ast:declaration* (o <system>))
  (append (ast:port* o) (ast:instance* o)))

(define-method (ast:declaration* (o <behaviour>))
  (append (ast:type* o) (ast:function* o) (ast:variable* o) (ast:port* o)))

(define-method (ast:declaration* (o <compound>))
  (ast:variable* o))

(define-method (ast:declaration* (o <functions>))
  (ast:function* o))

(define-method (ast:declaration* (o <function>))
  (ast:formal* o))

(define-method (ast:declaration* (o <trigger>))
  (ast:formal* o))

(define-method (ast:declaration* (o <enum>))
  (ast:field* o))

(define-method (.port (model <component-model>) (o <trigger>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (model <component-model>) (o <action>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <trigger>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <action>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <reply>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <trigger-return>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <end-point>))
  (if (.instance.name o)
      (let* ((instance (.instance o))
             (component (.type instance)))
        (ast:lookup component (.port.name o)))
      (ast:lookup o (.port.name o))))

(define-method (.instance (o <end-point>))
  (and (.instance.name o) (ast:lookup o (.instance.name o))))

(define-method (.event (o <action>))
  (let* ((port-name (.port.name o))
         (port (.port o))
         (interface (if port (.type port) (parent o <interface>))))
    (ast:lookup interface (.event.name o))))

(define-method (.event (o <trigger>))
  (let* ((port-name (.port.name o))
         (port (.port o))
         (interface (if port (.type port) (parent o <interface>))))
    (cond ((and (not port-name)
                (eq? (.event.name o) 'inevitable))
           (clone (ast:inevitable) #:parent interface))
          ((and (not port-name)
                (eq? (.event.name o) 'optional))
           (clone (ast:optional) #:parent interface))
          (else (ast:lookup interface (.event.name o))))))

(define-method (.event.direction (o <action>))
  ((compose .direction .event) o))

(define-method (.event.direction (o <trigger>))
  ((compose .direction .event) o))

(define-method (.function (model <model>) (o <call>))
  (and (.function.name o) (ast:lookup model (.function.name o))))

(define-method (.function (o <call>))
  (and (.function.name o) (ast:lookup o (.function.name o))))

(define-method (ast:lookup-var (o <ast>) name)
  (define (name? o) (and (eq? (.name o) name) o))
  (match o
    (($ <behaviour>) (find name? (ast:variable* o)))
    ((? (is? <compound>)) (or (find name? (filter (is? <variable>) (ast:statement* o))) (ast:lookup-var (.parent o) name)))
    (($ <function>) (or (find name? ((compose ast:formal* .signature) o)) (ast:lookup-var (.parent o) name)))
    (($ <formal>) (and (eq? (.name o) name) o))
    (($ <formal-binding>) (and (eq? (.name o) name) o))
    (($ <on>) (or (find (cut ast:lookup-var <> name) (append-map ast:formal* (ast:trigger* o))) (ast:lookup-var (.parent o) name)))
    (($ <variable>) (name? o))
    ((? (lambda (o) (is-a? (.parent o) <variable>))) (ast:lookup-var ((compose .parent .parent) o) name))
    (_ (ast:lookup-var (.parent o) name))))

(define-method (ast:lookup-var (o <boolean>) name)
  #f)

(define-method (.variable (o <assign>))
  (and=> (.variable.name o) (cut ast:lookup-var o <>)))

(define-method (.variable (o <field-test>))
  (and=> (.variable.name o) (cut ast:lookup-var o <>)))

(define-method (.variable (o <formal-binding>))
  (and=> (.variable.name o) (cut ast:lookup-var o <>)))

(define-method (.variable (o <var>))
  (and=> (.variable.name o) (cut ast:lookup-var o <>)))

(define-method (.type (o <argument>))
  (ast:lookup o (.type.name o)))

(define-method (.type (o <enum-field>))
  (or (parent o <enum>) ;; FIXME: ref vs decl!
      (ast:lookup o (.type.name o))))

(define-method (.type (o <enum-literal>))
  (or (parent o <enum>) ;; FIXME: ref vs decl!
      (ast:lookup o (.type.name o))))

(define-method (ast:event-formal (o <formal>))
  (let* ((trigger (parent o <trigger>))
         (event (.event trigger))
         (index (list-index (cut ast:eq? o <>) (reverse (.elements (.parent o))))))
    (and event (list-ref (reverse (ast:formal* event)) index))))

(define-method (ast:event-formal (o <formal-binding>))
  (let* ((on (parent o <on>))
         (trigger (car (ast:trigger* on)))
         (event (.event trigger))
         (index (list-index (cut ast:eq? o <>) (reverse (.elements (.parent o))))))
    (and event (list-ref (reverse (ast:formal* event)) index))))

(define-method (.type (o <formal>))
  (let ((type-name (.type.name o)))
    (if type-name (ast:lookup o (.type.name o))
        (let ((formal (ast:event-formal o)))
          (and formal (.type formal))))))

(define-method (.direction (o <formal>))
  (let ((type-name (.type.name o)))
    (if type-name (.direction (.node o))
        (let ((formal (ast:event-formal o)))
          (and formal (.direction formal))))))

(define-method (.type (o <instance>))
  (ast:lookup o (.type.name o)))

(define-method (.type (o <port>))
  (ast:lookup o (.type.name o)))

(define-method (.type (o <signature>))
  (ast:lookup o (.type.name o)))

(define-method (.type (o <variable>))
  (ast:lookup o (.type.name o)))

(define (topological-sort lst)

  (define (key x) ((compose .name .name) x))
  (define (sort dag)
    (if (null? dag)
        '()
        (let* ((adj-table (make-hash-table))
               (foo (for-each (lambda (def) (hashq-set! adj-table (key (car def)) (cdr def))) dag))
               (sorted '()))

          (define (visit node children)
            (if (eq? 'visited (hashq-ref adj-table (key node))) (error "double visit")
                (begin
                  (hashq-set! adj-table (key node) 'visited)
                  ;; Visit unvisited nodes which node connects to
                  (for-each (lambda (child)
                              (let ((val (hashq-ref adj-table (key child))))
                                ;;(stderr "val1: ~a ~a\n" (.name child) val)
                                (if (not (eq? val 'visited))
                                    (visit child (or val '())))))
                            children)
                  ;; Since all nodes downstream node are visited
                  ;; by now, we can safely put node on the output list
                  (set! sorted (cons node sorted)))))


          ;; Visit nodes
          (visit (caar dag) (cdar dag))
          (for-each (lambda (def)
                      (let ((val (hashq-ref adj-table (key (car def)))))
                        ;;(stderr "val2: ~a ~a\n" (.name (car def)) val)
                        (if (not (eq? val 'visited))
                            (visit (car def) (cdr def)))))
                    (cdr dag))
          sorted)))

  (receive (systems other) (partition (is? <system>) lst)
    (append
     (stable-sort other
                  (lambda (a b)
                    (or (and (is-a? a <data>)
                             (or (is-a? b <interface>)
                                 (is-a? b <component>)
                                 (is-a? b <foreign>)))
                        (and (is-a? a <interface>)
                             (or (is-a? b <component>)
                                 (is-a? b <foreign>))))))
     (reverse (sort (map (lambda (o) (cons o
                                           (filter (is? <system>)
                                                   (map .type (ast:instance* o)))))
                         systems))))))

(define (ast-> ast)
  ((compose
    pretty-print
    ) ast))
