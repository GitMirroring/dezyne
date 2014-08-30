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

(define-module (language asd gom ast)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 match)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd pretty)
  :use-module (language asd reader)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (language asd gom gom)

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
  ((compose ast->gom- ast->sugar) ast))

(define (ast->gom- ast)
  (match ast
    ((? ast:action?) (make <action>
                       :trigger (ast->gom (ast:trigger ast))))
    ((? ast:argument-list?) (make <arguments>
                           :elements (map ast->gom (ast:body ast))))
    ((? ast:assign?) (make <assign>
                       :identifier (ast:identifier ast)
                       :expression (make <expression>
                                     :value (ast->gom (ast:expression ast)))))
    ((? ast:behaviour?) (make <behaviour>
                          :name (ast:name ast)
                          :types (ast->gom (ast:type-list ast))
                          :variables (ast->gom (ast:variable-list ast))
                          :functions (ast->gom (ast:function-list ast))
                          :statement (ast->gom (ast:statement ast))))
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
    ((? ast:field?) (make <field>
                      :identifier (ast:identifier ast)
                      :field (ast:field ast)))
    ((? ast:function?) (make <function>
                          :name (ast:name ast)
                          :signature (ast->gom (ast:signature ast))
                          :statement (ast->gom (ast:statement ast))))
    ((? ast:function-list?) (make <functions>
                           :elements (map ast->gom (ast:body ast))))
    ((? ast:guard?) (make <guard>
                       :expression (make <expression>
                                     :value (ast->gom (ast:expression ast)))
                       :statement (ast->gom (ast:statement ast))))
    ((? ast:if?) (make <if>
                       :expression (make <expression>
                                     :value (ast->gom (ast:expression ast)))
                       :then (ast->gom (ast:then ast))
                       :else (ast->gom (ast:else ast))))
    ((? ast:illegal?) (make <illegal>))
    ((? ast:interface?) (make <interface>
                          :name (ast:name ast)
                          :events (ast->gom (ast:event-list ast))
                          :types (ast->gom (ast:type-list ast))
                          :behaviour (ast->gom (ast:behaviour ast))))
    ((? ast:on?) (make <on>
                       :triggers (ast->gom (ast:trigger-list ast))
                       :statement (ast->gom (ast:statement ast))))
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
    ((? ast:reply?) (make <reply>
                      :expression (make <expression>
                                    :value (ast->gom (ast:expression ast)))))
    ((? ast:return?) (make <return>
                       :expression (if (null? (ast:expression ast))
                                       #f
                                       (make <expression>
                                         :value (ast->gom (ast:expression ast))))))

    ((? ast:signature?) (make <signature>
                          :type (ast:type ast)
                          :parameters (ast->gom (or (null-is-#f
                                                      (ast:parameter-list ast))
                                                     '(parameters)))))
    ((? ast:statement-list?) (make <compound>
                               :elements (map ast->gom (ast:body ast))))
    ((? ast:trigger?) (make <trigger>
                       :port (ast:port-name ast)
                       :event (ast:event-name ast)))
    ((? ast:trigger-list?) (make <triggers>
                             :elements (map ast->gom (ast:body ast))))
    ((? ast:type-list?) (make <types>
                          :elements (map ast->gom (ast:body ast))))
    ((? ast:variable?) (make <variable>
                         :name (ast:name ast)
                         :type (ast:type ast)
                         :expression (make <expression>
                                       :value (ast->gom (ast:expression ast)))))
    ((? ast:variable-list?) (make <variables>
                          :elements (map ast->gom (ast:body ast))))
    (('imports imports ...) ast)
    (('value type field) ast)
    ((h t ...) (map ast->gom ast))
;;    ((h t ...) (make <ast-list> :elements (map ast->gom ast)))
    (_ ast)))

(define (ast->gom ast)
  ((compose ast->gom- ast->sugar) ast))
