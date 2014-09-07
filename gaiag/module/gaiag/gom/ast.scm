;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (gaiag gom ast)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 match)
  :use-module (srfi srfi-1)

  :use-module (system base lalr)
  :use-module (gaiag ast:)
  :use-module (gaiag misc)
  :use-module (gaiag pretty)
  :use-module (gaiag reader)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom gom)

  :export (
           ast->gom
           ast->sugar
           ast->trigger-sugar
           ))

(define (ast->sugar ast)
  (match ast
    (('on ('triggers t ...) statement) ast)
    (('on triggers statement) (ast:make 'on (list (ast:make 'triggers (map ast->trigger-sugar triggers)) statement)))
    (_ ast)))

(define (ast->trigger-sugar ast)
  (match ast
    ((port event) (ast:make 'trigger ast))
    ((? symbol?) (ast:make 'trigger (list #f ast)))
    (_ ast)))

(define (ast->gom ast)
  (let ((gom ((compose ast->gom- ast->sugar) ast)))
        (and-let* ((loc (source-property ast 'loc)))
                  (set-source-property! gom 'loc loc))
    gom))

(define (ast->gom- ast)
  (match ast
    ((? ast:action?) (make <action>
                       :trigger (ast->gom (ast:trigger ast))))
    ((? ast:argument-list?) (make <arguments>
                           :elements (map ast->gom (ast:body ast))))
    ((? ast:assign?) (make <assign>
                       :identifier (ast:identifier ast)
                       :expression (ast->gom (ast:expression ast))))
    ((? ast:behaviour?) (make <behaviour>
                          :name (ast:name ast)
                          :types (ast->gom (or (null-is-#f (ast:type-list ast))
                                               '(types)))
                          :variables (ast->gom (or (null-is-#f (ast:variable-list ast))
                                                   '(variables)))
                          :functions (ast->gom (or (null-is-#f (ast:function-list ast))
                                                   '(functions)))
                          :statement (ast->gom (ast:statement ast))))
    ((? ast:bind?) (make <bind>
                      :left (ast->gom (ast:left ast))
                      :right (ast->gom (ast:right ast))))
    ((? ast:plug?) (make <plug>
                        :instance (ast:instance ast)
                        :port (ast:port ast)))
    ((? ast:binding-list?) (make <bindings>
                             :elements (map ast->gom (ast:body ast))))
    ((? ast:call?) (make <call>
                       :identifier (ast:identifier ast)
                       :arguments (ast->gom (or (null-is-#f
                                                  (ast:argument-list ast))
                                                 '(arguments)))))
    ((? ast:component?) (make <component>
                          :name (ast:name ast)
                          :ports (ast->gom (ast:port-list ast))
                          :behaviour (ast->gom (ast:behaviour ast))))
    ((? ast:enum?) (make <enum>
                     :name (ast:name ast)
                     :fields (make <fields> :elements (ast:fields ast))))
    ((? ast:event?) (make <event>
                      :name (ast:name ast)
                      :type (ast->gom (ast:signature ast))
                      :direction (ast:direction ast)))
    ((? ast:event-list?) (make <events>
                           :elements (map ast->gom (ast:body ast))))
    ((? ast:expression?)
     (make <expression>
       :value (ast->gom (ast:value ast))))
    ((? ast:field?) (make <field>
                      :identifier (ast:identifier ast)
                      :field (ast:field ast)))
    ((? ast:function?) (make <function>
                          :name (ast:name ast)
                          :signature (ast->gom (ast:signature ast))
                          :recursive (ast:recursive ast)
                          :statement (ast->gom (ast:statement ast))))
    ((? ast:function-list?) (make <functions>
                           :elements (map ast->gom (ast:body ast))))
    ((? ast:guard?) (make <guard>
                              :expression (ast->gom (ast:expression ast))
                              :statement (ast->gom (ast:statement ast))))
    ((? ast:if?) (make <if>
                       :expression (ast->gom (ast:expression ast))
                       :then (ast->gom (ast:then ast))
                       :else (ast->gom (ast:else ast))))
    ((? ast:illegal?) (make <illegal>))
    (('imports import ...) (make <imports> :elements (map ast->gom import)))
    (('import name) (make <import> :name name))
    ((? ast:int?) (make <int>
                    :name (ast:name ast)
                    :range (ast->gom (ast:range ast))))
    ((? ast:instance?) (make <instance>
                         :name (ast:name ast)
                         :type (ast:type ast)))
    ((? ast:instance-list?) (make <instances>
                           :elements (map ast->gom (ast:body ast))))
    ((? ast:interface?) (make <interface>
                          :name (ast:name ast)
                          :events (ast->gom (or (null-is-#f (ast:event-list ast))
                                                '(events)))
                          :types (ast->gom (or (null-is-#f (ast:type-list ast))
                                               '(types)))
                          :behaviour (ast->gom (ast:behaviour ast))))
    ((? ast:literal?) (make <literal>
                      :scope (ast:scope ast)
                      :type (ast:type ast)
                      :field (ast:field ast)))
    ((? ast:on?) (make <on>
                       :triggers (ast->gom (ast:trigger-list ast))
                       :statement (ast->gom (ast:statement ast))))
    ('(otherwise) (make <otherwise> :value 'otherwise))
    ((? ast:parameter?) (make <parameter>
                      :type (ast:type ast)
                      :identifier (ast:identifier ast)))
    ((? ast:parameter-list?) (make <parameters>
                               :elements (map ast->gom (ast:body ast))))
    ((? ast:port?) (make <port>
                      :name (ast:name ast)
                      :type (ast:type ast)
                      :direction (ast:direction ast)))
    ((? ast:port-list?) (make <ports>
                          :elements (map ast->gom (ast:body ast))))
    ((? ast:range?) (make <range>
                      :from (ast:from ast)
                      :to (ast:to ast)))
    ((? ast:reply?) (make <reply>
                      :expression (ast->gom (ast:expression ast))))
    ((? ast:return?) (make <return>
                       :expression (if (null? (ast:expression ast))
                                       #f
                                       (ast->gom (ast:expression ast)))))
    ((? ast:root?) (make <root>
                     :elements (ast->gom (ast:body ast))))
    ((? ast:signature?) (make <signature>
                          :type (ast:type ast)
                          :parameters (ast->gom (or (null-is-#f
                                                      (ast:parameter-list ast))
                                                     '(parameters)))))
    ((? ast:statement-list?) (make <compound>
                               :elements (map ast->gom (ast:body ast))))
    ((? ast:system?) (make <system>
                          :name (ast:name ast)
                          :ports (ast->gom (ast:port-list ast))
                          :instances (ast->gom (ast:instance-list ast))
                          :bindings (ast->gom (ast:binding-list ast))))
    ((? ast:trigger?) (make <trigger>
                       :port (ast:port-name ast)
                       :event (ast:event-name ast)))
    ((? ast:trigger-list?) (make <triggers>
                             :elements (map ast->gom (ast:body ast))))
    ((? ast:type-list?) (make <types>
                          :elements (map ast->gom (ast:body ast))))
    ((? ast:var?) (make <var>
                      :identifier (ast:identifier ast)))
    ((? ast:variable?) (make <variable>
                         :name (ast:name ast)
                         :type (ast:type ast)
                         :expression (ast->gom (ast:expression ast))))
    ((? ast:variable-list?) (make <variables>
                          :elements (map ast->gom (ast:body ast))))
    (('imports imports ...) ast)
    (('value type field) ast)
    ((h t ...) (map ast->gom ast))
    (_ ast)))
