;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn ast serialize)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 pretty-print)

  #:use-module (dzn ast goops)
  #:use-module (dzn code goops)
  #:use-module (dzn vm goops)
  #:use-module (dzn command-line) ;%locations?
  #:use-module (dzn goops serialize)
  #:use-module (dzn goops unserialize)
  #:use-module (dzn misc)

  #:export (ast:serialize
            ast:serialize-skip?
            ast:serialize:pretty-print
            ast:unserialize))

;; TODO: generate.
;; dzn/ast/goops.scm
(define-unserialize-class <ast-list>)
(define-unserialize-class <location>)
(define-unserialize-class <locationed>)
(define-unserialize-class <comment>)
(define-unserialize-class <named>)
(define-unserialize-class <name>)
(define-unserialize-class <declaration>)
(define-unserialize-class <scope>)
(define-unserialize-class <namespace>)
(define-unserialize-class <root>)
(define-unserialize-class <block-comment>)
(define-unserialize-class <line-comment>)
(define-unserialize-class <statement>)
(define-unserialize-class <declarative>)
(define-unserialize-class <imperative>)
(define-unserialize-class <arguments>)
(define-unserialize-class <bindings>)
(define-unserialize-class <compound>)
(define-unserialize-class <blocking-compound>)
(define-unserialize-class <declarative-compound>)
(define-unserialize-class <events>)
(define-unserialize-class <fields>)
(define-unserialize-class <formals>)
(define-unserialize-class <out-bindings>)
(define-unserialize-class <functions>)
(define-unserialize-class <instances>)
(define-unserialize-class <ports>)
(define-unserialize-class <triggers>)
(define-unserialize-class <types>)
(define-unserialize-class <variables>)
(define-unserialize-class <import>)
(define-unserialize-class <model>)
(define-unserialize-class <interface>)
(define-unserialize-class <type>)
(define-unserialize-class <enum>)
(define-unserialize-class <extern>)
(define-unserialize-class <bool>)
(define-unserialize-class <void>)
(define-unserialize-class <int>)
(define-unserialize-class <subint>)
(define-unserialize-class <range>)
(define-unserialize-class <signature>)
(define-unserialize-class <event>)
(define-unserialize-class <modeling-event>)
(define-unserialize-class <inevitable>)
(define-unserialize-class <optional>)
(define-unserialize-class <instance>)
(define-unserialize-class <port>)
(define-unserialize-class <trigger>)
(define-unserialize-class <silent-trigger>)
(define-unserialize-class <expression>)
(define-unserialize-class <binary>)
(define-unserialize-class <unary>)
(define-unserialize-class <literal>)
(define-unserialize-class <group>)
(define-unserialize-class <bool-expr>)
(define-unserialize-class <enum-expr>)
(define-unserialize-class <int-expr>)
(define-unserialize-class <data-expr>)
(define-unserialize-class <not>)
(define-unserialize-class <and>)
(define-unserialize-class <equal>)
(define-unserialize-class <greater-equal>)
(define-unserialize-class <greater>)
(define-unserialize-class <less-equal>)
(define-unserialize-class <less>)
(define-unserialize-class <minus>)
(define-unserialize-class <not-equal>)
(define-unserialize-class <or>)
(define-unserialize-class <plus>)
(define-unserialize-class <data>)
(define-unserialize-class <reference>)
(define-unserialize-class <undefined>)
(define-unserialize-class <shared>)
(define-unserialize-class <shared-reference>)
(define-unserialize-class <variable>)
(define-unserialize-class <shared-variable>)
(define-unserialize-class <field-test>)
(define-unserialize-class <shared-field-test>)
(define-unserialize-class <enum-literal>)
(define-unserialize-class <otherwise>)
(define-unserialize-class <formal>)
(define-unserialize-class <formal-binding>)
(define-unserialize-class <formal-reference>)
(define-unserialize-class <formal-reference-binding>)
(define-unserialize-class <component-model>)
(define-unserialize-class <foreign>)
(define-unserialize-class <component>)
(define-unserialize-class <system>)
(define-unserialize-class <shell-system>)
(define-unserialize-class <behavior>)
(define-unserialize-class <function>)
(define-unserialize-class <action>)
(define-unserialize-class <defer>)
(define-unserialize-class <defer-end>)
(define-unserialize-class <assign>)
(define-unserialize-class <call>)
(define-unserialize-class <guard>)
(define-unserialize-class <otherwise-guard>)
(define-unserialize-class <if>)
(define-unserialize-class <declarative-illegal>)
(define-unserialize-class <illegal>)
(define-unserialize-class <blocking>)
(define-unserialize-class <on>)
(define-unserialize-class <canonical-on>)
(define-unserialize-class <reply>)
(define-unserialize-class <return>)
(define-unserialize-class <stack>)
(define-unserialize-class <return-value>)
(define-unserialize-class <binding>)
(define-unserialize-class <end-point>)
(define-unserialize-class <status>)
(define-unserialize-class <message>)
(define-unserialize-class <error>)
(define-unserialize-class <info>)
(define-unserialize-class <warning>)
(define-unserialize-class <skip>)
(define-unserialize-class <tag>)
(define-unserialize-class <the-end>)
(define-unserialize-class <the-end-blocking>)
(define-unserialize-class <voidreply>)
(define-unserialize-class <argument>)
(define-unserialize-class <enum-field>)
(define-unserialize-class <file-name>)
(define-unserialize-class <local>)
(define-unserialize-class <model-scope>)
(define-unserialize-class <out-formal>)
(define-unserialize-class <direction>)
(define-unserialize-class <unspecified>)

;; dzn/code/goops.scm
(define-unserialize-class <port-pair>)
(define-unserialize-class <action-reply>)
(define-unserialize-class <shared-transition>)
(define-unserialize-class <shared-state>)
(define-unserialize-class <shared-value>)

;; dzn/vm/goops.scm
(define-unserialize-class <block>)
(define-unserialize-class <end-of-on>)
(define-unserialize-class <flush-return>)
(define-unserialize-class <initial-compound>)
(define-unserialize-class <defer-qout>)
(define-unserialize-class <q-in>)
(define-unserialize-class <q-out>)
(define-unserialize-class <q-trigger>)
(define-unserialize-class <silent-step>)
(define-unserialize-class <synth-trigger>)
(define-unserialize-class <trigger-return>)
(define-unserialize-class <acceptances>)
(define-unserialize-class <blocked-error>)
(define-unserialize-class <compliance-error>)
(define-unserialize-class <deadlock-error>)
(define-unserialize-class <determinism-error>)
(define-unserialize-class <labels>)
(define-unserialize-class <end-of-trail>)
(define-unserialize-class <fork-error>)
(define-unserialize-class <illegal-error>)
(define-unserialize-class <implicit-illegal-error>)
(define-unserialize-class <livelock-error>)
(define-unserialize-class <match-error>)
(define-unserialize-class <missing-reply-error>)
(define-unserialize-class <postponed-match>)
(define-unserialize-class <queue-full-error>)
(define-unserialize-class <range-error>)
(define-unserialize-class <refusals-error>)
(define-unserialize-class <second-reply-error>)

;; (define* (clone-module #:optional (module (current-module)))
;;   (let ((clone (make-module 31)))
;;     (for-each (cute module-use! clone <>) (module-uses module))
;;     ;; (module-for-each (lambda (symbol var)
;;     ;;                    (module-add! clone symbol var)) module)
;;     clone))

(define ast:serialize-skip?
  (disjoin (negate identity)
           (cute eq? <> *unspecified*)
           null?
           (compose null?
                    (conjoin (is? <ast-list>)
                             (negate (is? <compound>))
                             (negate (is? <namespace>))
                             .elements))))


;;;
;;; Entry points.
;;;
(define (ast:serialize ast)
  (parameterize ((%serialize:skip? ast:serialize-skip?))
    (serialize ast)))

(define* (ast:serialize:pretty-print ast #:optional port
                                     #:key (width 79))
  (pretty-print (ast:serialize ast) port #:width 79))

(define-method (ast:unserialize (o <top>))
  (let ((module (resolve-module '(dzn ast serialize))))
    (eval o module)))

(define-method (ast:unserialize (text <string>))
  (let ((scm (with-input-from-string text read)))
    (ast:unserialize scm)))
