;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2018, 2020, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn ast accessor)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)

  #:use-module (dzn ast ast)
  #:use-module (dzn tree accessor)
  #:use-module (dzn tree context)
  #:use-module (dzn tree tree)
  ;;#:use-module (dzn tree util)
  #:use-module (dzn misc)

  #:export (ast:argument*
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
            ast:model**
            ast:namespace*
            ast:namespace**
            ast:port*
            ast:shared*
            ast:statement*
            ast:top*
            ast:top**
            ast:trigger*
            ast:type*
            ast:type**
            ast:variable*

            ast:dotted-name
            ast:full-name
            ast:full-scope)
  #:re-export (%root

               .variable.name
               tree:parent

               tree:memoize-context
               tree:ancestor
               tree:path))

;;;
;;; Direct accessors.
;;;
(define-method (.variable.name (o <action>))
  (let ((parent (tree:parent o)))
    (match parent
      (($ <assign>) (.variable.name parent))
      (($ <variable>) (.name parent)))))

(define-method (.variable.name (o <reference>))
  (.name o))

(define-method (ast:argument* (o <arguments>)) (.elements o))
(define-method (ast:binding* (o <bindings>)) (.elements o))
(define-method (ast:data* (o <namespace>)) (filter (is? <data>) (ast:top* o)))
(define-method (ast:import* (o <root>)) (filter (is? <import>) (ast:top* o)))
(define-method (ast:statement* (o <compound>)) (.elements o))
(define-method (ast:statement* (o <declarative-compound>)) (.elements o))
(define-method (ast:event* (o <events>)) (.elements o))
(define-method (ast:field* (o <fields>)) (.elements o))
(define-method (ast:formal* (o <formals>)) (.elements o))
(define-method (ast:function* (o <functions>)) (.elements o))
(define-method (ast:instance* (o <instances>)) (.elements o))
(define-method (ast:port* (o <ports>)) (.elements o))
(define-method (ast:top* (o <namespace>)) (.elements o))
(define-method (ast:member* (o <behavior>)) (ast:variable* o))
(define-method (ast:model* (o <namespace>)) (filter (is? <model>) (ast:top* o)))
(define-method (ast:namespace* (o <namespace>)) (filter (is? <namespace>) (ast:top* o)))
(define-method (ast:shared* (o <behavior>)) (filter (is? <shared-variable>) (ast:variable* o)))
(define-method (ast:trigger* (o <triggers>)) (.elements o))
(define-method (ast:type* (o <types>)) (.elements o))
(define-method (ast:type* (o <namespace>)) (filter (is? <type>) (ast:top* o)))
(define-method (ast:variable* (o <variables>)) (.elements o))


;;;
;;; Namespace-recursive accessors.
;;;
(define-method (ast:top** (o <namespace>)) (append (ast:top* o) (append-map ast:top** (ast:namespace* o))))
(define-method (ast:namespace** (o <namespace>)) (filter (is? <namespace>) (ast:top** o)))
(define-method (ast:model** (o <namespace>)) (filter (is? <model>) (ast:top** o)))
(define-method (ast:type** (o <namespace>)) (filter (is? <type>) (ast:top** o)))

(define-method (ast:type** (o <interface>)) (append (ast:type* o) (ast:type* (.behavior o))))

(define-method (ast:namespace* (o <scope>)) '())


;;;
;;; Secondary accessors.
;;;
(define-method (ast:argument* (o <action>)) ((compose ast:argument* .arguments) o))
(define-method (ast:argument* (o <call>)) ((compose ast:argument* .arguments) o))
(define-method (ast:argument* (o <defer>)) ((compose (cute and=> <> ast:argument*) .arguments) o))
(define-method (ast:binding* (o <system>)) ((compose ast:binding* .bindings) o))
(define-method (ast:event* (o <interface>)) ((compose ast:event* .events) o))
(define-method (ast:field* (o <enum>)) ((compose ast:field* .fields) o))
(define-method (ast:formal* (o <event>)) ((compose ast:formal* .signature) o))
(define-method (ast:formal* (o <function>)) ((compose ast:formal* .signature) o))
(define-method (ast:formal* (o <port>)) ((compose ast:formal* .formals) o))
(define-method (ast:formal* (o <signature>)) ((compose ast:formal* .formals) o))
(define-method (ast:formal* (o <trigger>)) ((compose ast:formal* .formals) o))
(define-method (ast:formal* (o <out-bindings>)) (.elements o))
(define-method (ast:function* (o <component>)) ((compose ast:function* .behavior) o))
(define-method (ast:function* (o <foreign>)) '())
(define-method (ast:function* (o <behavior>)) ((compose ast:function* .functions) o))
(define-method (ast:instance* (o <system>)) ((compose ast:instance* .instances) o))
(define-method (ast:member* (o <model>)) ((compose ast:member* .behavior) o))
(define-method (ast:member* (o <foreign>)) '())
(define-method (ast:member* (o <system>)) '())
(define-method (ast:port* (o <component-model>)) ((compose ast:port* .ports) o))
(define-method (ast:shared* (o <model>)) ((compose ast:shared* .behavior) o))
(define-method (ast:statement* (o <behavior>)) (list (.statement o)))
(define-method (ast:statement* (o <blocking>)) (list (.statement o)))
(define-method (ast:statement* (o <guard>)) (list (.statement o)))
(define-method (ast:statement* (o <on>)) (list (.statement o)))
(define-method (ast:statement* (o <if>)) `(,(.then o) ,@(if (.else o) (list (.else o)) '())))
(define-method (ast:statement* (o <statement>)) '())
(define-method (ast:trigger* (o <on>)) ((compose ast:trigger* .triggers) o))
(define-method (ast:trigger* (o <canonical-on>)) (list (.trigger o)))
(define-method (ast:type* (o <interface>)) ((compose ast:type* .types) o))
(define-method (ast:type* (o <behavior>)) ((compose ast:type* .types) o))
(define-method (ast:variable* (o <behavior>)) ((compose ast:variable* .variables) o))
(define-method (ast:variable* (o <model>)) ((compose ast:variable* .behavior) o))
(define-method (ast:variable* (o <compound>)) (filter (is? <variable>) (.elements o)))
(define-method (ast:variable* (o <statement>)) '())
(define-method (ast:variable* (o <variable>)) (list o))


;;;
;;; Full name
;;;
(define-method (ast:full-name (o <string>))
  (let ((name* (tree:name* o)))
    (if (pair? (cdr name*)) name*
        (list-head name* 1))))

(define-method (ast:full-name (o <string>))
  (tree:name* o))

(define-method (ast:full-name (o <named>))
  (let ((name (.name o)))
    (and name
         (let ((name* (tree:name* o)))
           (if (pair? (cdr name*)) name*
               (append (ast:full-name (tree:ancestor o <scope>))
                       (list-head name* 1)))))))

(define-method (ast:full-name (o <extern>))
  (let ((name (.name o)))
    (and name
         (let ((name* (tree:name* o)))
           (if (pair? (cdr name*)) name*
               (append (ast:full-name (tree:ancestor o <scope>))
                       (list-head name* 1)))))))

(define-method (ast:full-name (o <bool>))
  '("bool"))

(define-method (ast:full-name (o <data>))
  '("data"))

(define-method (ast:full-name (o <int>))
  (if (and (is-a? o <subint>) (tree:name o)) (next-method)
      '("<int>")))

(define-method (ast:full-name (o <void>))
  '("void"))

(define-method (ast:full-name (o <shared-variable>))
  (cons (.port.name o) (list (.name o))))

(define-method (ast:full-name (o <shared-reference>))
  (cons (.port.name o) (list (.name o))))

(define-method (ast:full-name (o <declaration>))
  (let ((scope (tree:ancestor o <scope>)))
    (cond
     ((not scope)
      #f)
     ((and (is-a? o <named>) (not (.name o)))
      #f)
     ((is-a? o <named>)
      (append (ast:full-name scope) (list (tree:name o))))
     (else
      (ast:full-name scope)))))

(define-method (ast:full-name (o <root>))
  '())

(define-method (ast:full-name (o <scope>))
  (let ((prefix (ast:full-name (tree:ancestor o <scope>))))
    (let ((name (and=> (as o <named>) tree:name)))
      (if name
          (append prefix (list name))
          prefix))))

(define-method (ast:full-name (o <namespace>))
  (append (ast:full-name (tree:ancestor o <scope>)) (list (tree:name o))))

(define-method (ast:full-name (o <ast>))
  (ast:full-name (tree:ancestor o <scope>)))

(define-method (ast:dotted-name (o <list>))
  (string-join o "."))

(define-method (ast:dotted-name (o <ast>))
  (string-join (ast:full-name o) "."))

(define-method (ast:full-scope (o <ast>))
  (drop-right (ast:full-name o) 1))

(define-method (ast:full-scope (o <root>))
  '())
