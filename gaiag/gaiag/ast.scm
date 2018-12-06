;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag compare)
  #:use-module (gaiag resolve)
  #:use-module (gaiag util)

  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)

  #:export (
           ast:argument->formal
           ast:async-out-triggers
           ast:async?
           ast:async-port*
           ast:clr-events
           ast:direction
           ast:dzn-scope?
           ast:eq?
           ast:expression->type
           ast:id-path
           ast:in?
           ast:inout?
           ast:in-triggers
           ast:imported?
           ast:literal-false?
           ast:literal-true?
           ast:location
           ast:name
           ast:optional?
           ast:other-direction
           ast:out?
           ast:out-triggers
           ast:out-triggers-in-events
           ast:out-triggers-out-events
           ast:provided
           ast:provided-in-triggers
           ast:provided-out-triggers
           ast:req-events
           ast:required
           ast:required+async
           ast:required-in-triggers
           ast:required-out-triggers
           ast:source-file
           ast:valued-in-triggers
           ast:void-in-triggers
           ast:out-triggers-valued-in-events
           ast:out-triggers-void-in-events
           ast:modeling?
           ast:typed?
           ast:path
           ast:provides?
           ast:requires?
           ast:external?
           ast:type

           ast:argument*
           ast:binding*
           ast:event*
           ast:field*
           ast:formal*
           ast:function*
           ast:global*
           ast:instance*
           ast:member*
           ast:model*
           ast:port*
           ast:statement*
           ast:trigger*
           ast:type*
           ast:variable*
	   ast:void?
           ))

(define (deprecated . where)
  (stderr "DEPRECATED:~a\n" where))

;;; ast: accessors

(define-method (ast:argument* (o <arguments>)) (.elements o))
(define-method (ast:binding* (o <bindings>)) (.elements o))
(define-method (ast:statement* (o <compound>)) (.elements o))
(define-method (ast:statement* (o <declarative-compound>)) (.elements o))
(define-method (ast:event* (o <events>)) (.elements o))
(define-method (ast:event* (o <interface>)) ((compose ast:event* .events) o))
(define-method (ast:field* (o <fields>)) (.elements o))
(define-method (ast:formal* (o <formals>)) (.elements o))
(define-method (ast:function* (o <functions>)) (.elements o))
(define-method (ast:instance* (o <instances>)) (.elements o))
(define-method (ast:async? (o <trigger>)) (parent (.port o) <behaviour>))
(define-method (ast:async-port* (o <component-model>)) ((compose .elements .ports .behaviour) o))
(define-method (ast:port* (o <ports>)) (.elements o))
(define-method (ast:port* (o <behaviour>)) ((compose .elements .ports) o))
(define-method (ast:global* (o <root>)) (.elements o))
(define-method (ast:member* (o <behaviour>)) (ast:variable* o))
(define-method (ast:member* (o <model>)) ((compose ast:member* .behaviour) o))
(define-method (ast:model* (o <root>)) (filter (is? <model>) (.elements o)))
(define-method (ast:trigger* (o <triggers>)) (.elements o))
(define-method (ast:type* (o <types>)) (.elements o))
(define-method (ast:variable* (o <variables>)) (.elements o))

(define-method (ast:argument* (o <action>)) ((compose ast:argument* .arguments) o))
(define-method (ast:argument* (o <call>)) ((compose ast:argument* .arguments) o))
(define-method (ast:binding* (o <system>)) ((compose ast:binding* .bindings) o))
(define-method (ast:function* (o <behaviour>)) ((compose ast:function* .functions) o))
(define-method (ast:field* (o <enum>)) ((compose ast:field* .fields) o))
(define-method (ast:formal* (o <event>)) ((compose ast:formal* .signature) o))
(define-method (ast:formal* (o <function>)) ((compose ast:formal* .signature) o))
(define-method (ast:formal* (o <signature>)) ((compose ast:formal* .formals) o))
(define-method (ast:formal* (o <trigger>)) ((compose ast:formal* .formals) o))
(define-method (ast:function* (o <behaviour>)) ((compose ast:function* .functions) o))
(define-method (ast:instance* (o <system>)) ((compose ast:instance* .instances) o))
(define-method (ast:port* (o <component-model>)) ((compose ast:port* .ports) o))
(define-method (ast:statement* (o <behaviour>)) ((compose ast:statement* .statement) o))
(define-method (ast:variable* (o <behaviour>)) ((compose ast:variable* .variables) o))
(define-method (ast:trigger* (o <on>)) ((compose ast:trigger* .triggers) o))
(define-method (ast:type* (o <interface>)) ((compose ast:type* .types) o))
(define-method (ast:type* (o <behaviour>)) ((compose ast:type* .types) o))
(define-method (ast:variable* (o <behaviour>)) ((compose ast:variable* .variables) o))
(define-method (ast:variable* (o <model>)) ((compose ast:variable* .behaviour) o))
(define-method (ast:variable* (o <compound>)) (filter (is? <variable>) (.elements o)))
(define-method (ast:type* (o <root>)) (filter (is? <type>) (ast:global* o)))

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

(define-method (ast:external? (o <port>))
  (and (.external o) o))

(define-method (ast:other-direction (o <event>))
  (assoc-ref `((in . out)
               (out . in))
             (.direction o)))

(define-method (ast:other-direction (o <trigger>))
  ((compose ast:other-direction .event) o))

(define-method (ast:provided (o <port>))
  (ast:provided (parent o <component-model>)))

(define-method (ast:provided (o <component-model>))
  (filter ast:provides? (ast:port* o)))

(define-method (ast:required (o <component-model>))
  (filter ast:requires? (ast:port* o)))

(define-method (ast:required+async (o <component-model>))
  (append (ast:required o) (ast:async-port* o)))

(define-method (ast:direction (o <trigger>))
  (.direction (.event o)))

(define-method (trigger-in-component (t <trigger>) (c <component-model>))
  (clone t #:parent c))

(define-method (ast:provided-in-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals ((compose .formals .signature) event)))
                          (filter om:in? (om:events port))))
                   (filter ast:provides? (om:ports o)))))

(define-method (ast:req-events (o <component>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals ((compose .formals .signature) event)))
                          (filter (conjoin om:in? (compose (cut eq? 'req <>) .name)) (om:events port))))
                   (om:ports (.behaviour o)))))

(define-method (ast:clr-events (o <component>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals ((compose .formals .signature) event)))
                          (filter (conjoin om:in? (compose (cut eq? 'clr <>) .name)) (om:events port))))
                   (om:ports (.behaviour o)))))

(define-method (ast:required-out-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals ((compose .formals .signature) event)))
                          (filter om:out? (om:events port))))
                   (filter ast:requires? (om:ports o)))))

(define-method (ast:async-out-triggers (o <foreign>))
  '())

(define-method (ast:async-out-triggers (o <system>))
  '())

(define-method (ast:async-out-triggers (o <component>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals ((compose .formals .signature) event)))
                          (filter om:out? (om:events port))))
                   (let ((behaviour (.behaviour o)))
                     (if behaviour (om:ports behaviour) '())))))

(define-method (ast:in-triggers (o <component-model>))
  (append (ast:provided-in-triggers o) (ast:required-out-triggers o) (ast:async-out-triggers o)))

(define-method (ast:in-triggers (o <interface>))
  (map (lambda (event) (make <trigger> #:event.name (.name event) #:formals ((compose .formals .signature) event)))
       (filter ast:in? (ast:event* o))))

(define-method (ast:in? (o <event>))
  (eq? 'in (.direction o)))

(define-method (ast:in? (o <formal>))
  (eq? 'in (.direction o)))

(define-method (ast:in? (o <argument>))
  (eq? 'in (.direction o)))

(define-method (ast:in? (o <variable>))
  #t)

(define-method (ast:out? (o <event>))
  (eq? 'out (.direction o)))

(define-method (ast:out? (o <formal>))
  (eq? 'out (.direction o)))

(define-method (ast:out? (o <argument>))
  (eq? 'out (.direction o)))

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
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals ((compose .formals .signature) event)))
                          (filter om:out? (om:events port))))
                   (filter ast:provides? (om:ports o)))))

(define-method (ast:required-in-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port.name (.name port) #:event.name (.name event) #:formals ((compose .formals .signature) event)))
                          (filter om:in? (om:events port))))
                   (filter ast:requires? (om:ports o) ))))

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
  ((compose om:in? .event) o))

(define-method (ast:out-triggers-in-events (o <component-model>))
  (filter (compose om:in? .event) (ast:out-triggers o)))

(define-method (ast:out-triggers-out-events (o <component-model>))
  (filter (compose om:out? .event) (ast:out-triggers o)))

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

(define-method (ast:type (o <action>))
  ((compose ast:type .event) o))
(define-method (ast:type (o <bool>)) o)
(define-method (ast:type (o <enum>)) o)
(define-method (ast:type (o <enum-literal>))
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
  ((compose .name .name) o))

(define-method (ast:literal-true? (e <ast>))
  (and (is-a? e <literal>)
       (eq? (.value e) 'true)))

(define-method (ast:literal-false? (e <ast>))
  (and (is-a? e <literal>)
       (eq? (.value e) 'false)))

(define (ast-> ast)
  ((compose
    pretty-print
    ) ast))
