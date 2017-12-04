;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2017 Johri van Eerd <johri.van.eerd@verum.com>
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

  #:use-module (gaiag location)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag compare)
  #:use-module (gaiag resolve)
  #:use-module (gaiag util)

  #:use-module (gaiag annotate)
  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)

  #:export (
           ast:clr-events
           ast:direction
           ast:expression-type
           ast:in-triggers
           ast:other-direction
           ast:out-triggers
           ast:out-triggers-in-events
           ast:out-triggers-out-events
           ast:provided
           ast:provided-in-triggers
           ast:provided-out-triggers
           ast:req-events
           ast:required
           ast:required-in-triggers
           ast:required-out-triggers
           ast:valued-in-triggers
           ast:void-in-triggers
           ast:out-triggers-valued-in-events
           ast:out-triggers-void-in-events
           ast:modeling?
           ast:typed?
           ast:provides?
           ast:requires?

           ast:argument*
           ast:binding*
           ast:event*
           ast:field*
           ast:formal*
           ast:function*
           ast:instance*
           ast:model*
           ast:port*
           ast:statement*
           ast:trigger*
           ast:type*
           ast:variable*
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
(define-method (ast:port* (o <ports>)) (.elements o))
(define-method (ast:port* (o <behaviour>)) ((compose .elements .ports) o))
(define-method (ast:model* (o <root>)) (.elements o))
(define-method (ast:trigger* (o <triggers>)) (.elements o))
(define-method (ast:type* (o <types>)) (.elements o))
(define-method (ast:variable* (o <variables>)) (.elements o))

(define-method (ast:argument* (o <action>)) ((compose ast:argument* .arguments) o))
(define-method (ast:argument* (o <call>)) ((compose ast:argument* .arguments) o))
(define-method (ast:binding* (o <system>)) ((compose ast:binding* .bindings) o))
(define-method (ast:function* (o <behaviour>)) ((compose ast:function* .functions) o))
(define-method (ast:field* (o <enum>)) ((compose ast:field* .fields) o))
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

(define-method (ast:expression-type (o <ast>))
  (match o
    (($ <bool>) o)
    (($ <enum>) o)
    (($ <extern>) o)
    (($ <int>) o)
    (($ <void>) o)

    (($ <enum-literal>) (.type o))
    (($ <var>) ((compose .type .variable) o))

    ((? (is? <bool-expr>)) (make <bool>))
    ((? (is? <data-expr>)) (make <extern>))
    ((? (is? <enum-expr>)) (make <enum>))
    ((? (is? <int-expr>)) (make <int>))
    ((? (is? <void-expr>)) (make <void>))

    ((and ($ <literal>) (= .value o))
     (match o
       ((? number?) (make <int>))
       ((or 'true 'false) (make <bool>))
       ((? unspecified?) (make <void>))
       (#f (make <void>))))

    (($ <group>) (= (.expression o)) (ast:expression-type o))
    ((? unspecified?) (make <void>))
    (($ <expression>) (make <void>))

    (($ <signature>) (.type o))
    (($ <event>) ((compose ast:expression-type .signature) o))
    (($ <trigger>) ((compose ast:expression-type .event) o))
    ;; FIXME: async port only?
    (($ <port>) ((compose ast:expression-type car om:events) o))))

(define-method (ast:provides? (o <port>))
  (eq? (.direction o) 'provides))

(define-method (ast:requires? (o <port>))
  (eq? (.direction o) 'requires))

(define-method (ast:other-direction (o <event>))
  (assoc-ref `((in . out)
               (out . in))
             (.direction o)))

(define-method (ast:other-direction (o <trigger>))
  ((compose ast:other-direction .event) o))

(define-method (ast:provided (o <component-model>))
  (filter ast:provides? (ast:port* o)))

(define-method (ast:required (o <component-model>))
  (filter ast:requires? (ast:port* o)))

(define-method (ast:direction (o <trigger>))
  (.direction (.event o)))

(define-method (trigger-in-component (t <trigger>) (c <component-model>))
  (clone t #:parent c))

(define-method (ast:provided-in-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
                          (filter om:in? (om:events port))))
                   (filter ast:provides? (om:ports o)))))

(define-method (ast:req-events (o <component>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
                          (filter (conjoin om:in? (compose (cut eq? 'req <>) .name)) (om:events port))))
                   (om:ports (.behaviour o)))))

(define-method (ast:clr-events (o <component>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
                          (filter (conjoin om:in? (compose (cut eq? 'clr <>) .name)) (om:events port))))
                   (om:ports (.behaviour o)))))

(define-method (ast:required-out-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
                          (filter om:out? (om:events port))))
                   (filter ast:requires? (om:ports o) ))))

(define-method (ast:in-triggers (o <component-model>))
  (append (ast:provided-in-triggers o) (ast:required-out-triggers o)))

(define-method (ast:provided-out-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
                          (filter om:out? (om:events port))))
                   (filter ast:provides? (om:ports o)))))

(define-method (ast:required-in-triggers (o <component-model>))
  (map (cut trigger-in-component <> o)
       (append-map (lambda (port)
                     (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
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

(define-method (ast:typed? (o <event>))
  (let ((type ((compose .type .signature) o)))
    (not (as type <void>))))

(define-method (ast:typed? (o <signature>))
  (not (as (.type o) <void>)))

(define-method (ast:typed? (o <trigger>))
  ((compose ast:typed? .event) o))

(define-method (ast:typed? (o <modeling-event>))
  #f)

(define (ast-> ast)
  ((compose
    om->list
    parse->om
    ast->annotate
    ) ast))
