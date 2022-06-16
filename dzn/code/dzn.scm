;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018, 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2018 Henk Katerberg <hank@mudball.nl>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
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

(define-module (dzn code dzn)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 optargs)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn misc)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn ast)
  #:use-module (dzn code-util)
  #:use-module (dzn config)
  #:use-module (dzn indent)
  #:use-module (dzn shell-util)
  #:use-module (dzn templates)

  #:export (ast->dzn
            dzn:blocking
            dzn:data
            dzn:define-type
            dzn:extension
            dzn:expression
            dzn:indent
            dzn:expand-statement
            dzn:expression-expand
            dzn:action-arguments
            dzn:direction
            dzn:enum-literal
            dzn:=expression
            dzn:external
            dzn:formal-type
            dzn:global
            dzn:injected
            dzn:instance
            dzn:model
            dzn:model-name
            dzn:model-full-name
            dzn:open-namespace
            dzn:port-prefix
            dzn:reply-port
            dzn:signature
            dzn:statement
            dzn:from
            dzn:to
            dzn:type))

;;;
;;; Top
;;;
(define-method (dzn:namespace (o <root>))
  (let ((dzn-file (ast:source-file o))
        (namespaces (filter (negate ast:imported?) (ast:namespace* o))))
    (if (null? namespaces) '()
        (ast:full-name (car namespaces)))))

(define-method (dzn:open-namespace (o <ast>))
  (cdr (reverse (ast:path (parent o <namespace>)))))

(define (dzn:global o)
  (filter (is? <type>) (ast:top* o)))

(define-method (dzn:model (o <root>))
  (let* ((models (ast:model* o))
         (models (filter (negate (disjoin (is? <type>) (is? <namespace>) ast:async?
                                          (conjoin ast:imported? (negate (is? <foreign>)))))
                         models))
         (models (ast:topological-model-sort models)))
    models))

(define-method (dzn:model (o <namespace>))
  (ast:top* o))

(define-method (dzn:model (o <ast>))
  o)


;;;
;;; Accessors
;;;
(define-method (dzn:data (o <data>))
  (if (.value o) (.value o)
      '()))

(define-method (dzn:instance (o <end-point>))
  (if (not (.instance.name o)) '()
      (list (.instance o))))


;;;
;;; Names
;;;
(define-method (dzn:define-type (o <scope>))
  (filter (conjoin (negate ast:imported?)
                   (negate (is? <bool>))
                   (negate (is? <void>)))
          (ast:type* o)))

(define-method (dzn:model-name (o <ast>))
  (ast:name (parent o <model>)))

(define-method (dzn:model-full-name (o <ast>))
  (or (and=> (parent o <model>) ast:full-name) '()))

(define-method (dzn:enum-literal (o <enum-literal>))
  (append (dzn:type o) (list (.field o))))

(define-method (dzn:type o)
  (if (as o <model>)
      (ast:full-name o)
      (let* ((type (or (as o <type>) (.type o)))
             (scope (ast:full-scope type))
             (model-scope (parent o <model>))
             (model-scope (or (and model-scope (ast:full-name model-scope)) '()))

             (common (or (list-index (negate equal?) scope model-scope) (min (length scope) (length model-scope)))))
        (drop (ast:full-name type) common))))

(define-method (dzn:type (o <bool>))
  o)

(define-method (dzn:type (o <void>))
  o)

(define-method (dzn:type (o <event>))
  ((compose dzn:type .type .signature) o))

(define-method (dzn:type (o <function>))
  ((compose dzn:type .type .signature) o))

(define-method (dzn:formal-type (o <formal>)) o)
(define-method (dzn:formal-type (o <event>)) ((compose ast:formal* .signature) o))
(define-method (dzn:formal-type (o <trigger>)) ((compose dzn:formal-type .event) o))
(define-method (dzn:formal-type (o <port>)) ((compose dzn:formal-type car ast:event*) o))

(define-method (dzn:direction (o <ast>))
  (if (not (.direction o)) '()
      (make <direction> #:name (.direction o))))

(define-method (dzn:direction (o <trigger>))
  ((compose dzn:direction .event) o))

(define-method (dzn:direction (o <action>))
  ((compose dzn:direction .event) o))

(define-method (dzn:direction (o <on>))
  ((compose dzn:direction car ast:trigger*) o))

(define-method (dzn:from (o <expression>))
  ((compose dzn:from ast:expression->type) o))

(define-method (dzn:from (o <type>))
  ((compose .from .range) o))

(define-method (dzn:to (o <expression>))
  ((compose dzn:to ast:expression->type) o))

(define-method (dzn:to (o <type>))
  ((compose .to .range) o))

(define-method (dzn:port-prefix (o <action>))
  (if (not (.port.name o)) '()
      (list (.port.name o))))

(define-method (dzn:port-prefix (o <end-point>))
  (if (not (.port.name o)) '()
      (list (.port.name o))))

(define-method (dzn:port-prefix (o <trigger>))
  (if (not (.port.name o)) '()
      (list (.port.name o))))

(define-method (dzn:signature (o <event>))
  (.signature o))

(define-method (dzn:signature (o <port>))
  (list ((compose ast:name .type) o) "t"))


;;;
;;; Statements
;;;
(define-method (dzn:signature (o <event>))
  (.signature o))

(define-method (dzn:statement (o <statement>))
  o)

(define-method (dzn:statement (o <compound>))
  (if (null? (ast:statement* o)) (make <skip>)
      o))

(define-method (dzn:statement (o <guard>))
  (cond ((is-a? (.expression o) <otherwise>)
         (clone (make <otherwise-guard> #:expression (.expression o)
                      #:statement (.statement o))
                #:parent (.parent o)))
        ((ast:literal-true? (.expression o))
         (.statement o))
        ((ast:literal-false? (.expression o))
         '())
        (else
         o)))

(define-method (dzn:statement (o <behavior>))
  ((compose dzn:expand-statement .statement) o))

(define-method (dzn:statement (o <function>))
  (.statement o))

(define-method (dzn:expand-statement (o <statement>))
  o)

(define-method (dzn:expand-statement (o <function>))
  ((compose dzn:expand-statement .statement) o))

(define-method (dzn:expand-statement (o <compound>))
  (if (null? (ast:statement* o)) (make <skip>)
      (ast:statement* o)))

(define-method (dzn:expand-statement (o <declarative-compound>))
  (if (null? (ast:statement* o)) (make <skip>)
      (ast:statement* o)))

(define-method (dzn:expand-statement (o <blocking>))
  (.statement o))

(define-method (dzn:expression (o <extern>))
  (if (.value o) (.value o)
      '()))

(define-method (dzn:expand-statement (o <on>))
  (.statement o))

(define-method (dzn:expand-statement (o <guard>))
  (.statement o))

(define-method (dzn:expression (o <top>))
  o)
(define-method (dzn:expression (o <assign>))
  (.expression o))
(define-method (dzn:expression (o <if>))
  (.expression o))
(define-method (dzn:expression (o <guard>))
  (.expression o))
(define-method (dzn:expression (o <reply>))
  (.expression o))

(define-method (dzn:expression (o <return>))
  (let ((type (ast:type o)))
    (if (is-a? type <void>) type
        (.expression o))))

(define-method (dzn:expression (o <var>))
  (.variable o))

(define-method (dzn:expression-expand (o <var>))
  (.variable o))

(define-method (dzn:expression-expand (o <field-test>))
  (clone (make <enum-literal> #:type.name ((compose .type.name .variable) o) #:field (.field o))
         #:parent (.parent o)))

(define-method (dzn:expression-expand (o <variable>))
  (let ((type ((compose ast:type .expression) o)))
    (if (is-a? type <void>) type
        (.expression o))))

(define-method (dzn:expression-expand (o <assign>))
  (.expression o))

(define-method (dzn:expression-expand (o <expression>))
  o)

(define-method (dzn:expression-expand (o <group>))
  (.expression o))

(define-method (dzn:=expression (o <ast>))
  o)

(define-method (dzn:=expression (o <literal>))
  (let ((value (.value o)))
    (if (equal? value "void") (make <void>)
        o)))
(define-method (dzn:=expression (o <variable>))
  ((compose dzn:=expression .expression) o))


;;;
;;; Component
;;;
(define-method (dzn:action-arguments (o <action>))
  (if (not (.port.name o)) '()
      (if (null? (ast:argument* o)) (list "")
          (ast:argument* o))))

(define-method (dzn:blocking (o <port>))
  (if (not (.blocking? o)) ""
      o))

(define-method (dzn:external (o <port>))
  (if (not (.external? o)) ""
      o))

(define-method (dzn:injected (o <port>))
  (if (not (.injected? o)) ""
      o))

(define-method (dzn:reply-port (o <reply>))
  (if (not (.port o)) ""
      (list (.port o))))


;;;
;;; Utility
;;;
(define-method (generator->string generator)
  (with-output-to-string (code-util:indenter generator)))

(define-templates-macro define-templates dzn)
(include-from-path "dzn/templates/dzn.scm")


;;;
;;; Entry points.
;;;

(define-method (ast->dzn (o <root>))
  (generator->string (cute x:source o)))
(define-method (ast->dzn (o <statement>))
  (generator->string(cute x:statement o)))
(define-method (ast->dzn (o <function>))
  (generator->string (cute x:source o)))
(define-method (ast->dzn (o <expression>))
  (generator->string (cute x:expression o)))

(define* (ast-> root #:key (dir ".") model)
  "Entry point."
  (let ((file-name (code-util:root-file-name root dir ".dzn"))
        (generator (code-util:indenter (cute x:source root))))
    (code-util:dump root generator #:file-name file-name)))
