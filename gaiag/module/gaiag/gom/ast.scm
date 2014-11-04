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
  :use-module (gaiag annotate)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom gom)

  :export (
           ast->gom
           ast->sugar
           ast->trigger-sugar
           ast:public
           ast:interface
           retain-source-location
           ))

(define (ast->sugar ast)
  (match ast
    (('in 'void name) `(in (signature (type void)) ,name))
    (('out 'void name) `(out (signature (type void)) ,name))
    (('on ('triggers t ...) statement) ast)
    (('on triggers statement) (list 'on (cons 'triggers (map ast->trigger-sugar triggers)) statement))
    (('events events ...) (cons 'events (map ast->sugar events)))
    (_ ast)))

(define (ast->trigger-sugar ast)
  (match ast
    ((port event) (cons 'trigger ast))
    ((? symbol?) (cons 'trigger (list #f ast)))
    (_ ast)))

(define (ast:model? x)
  (and (pair? x) (member (car x) '(component imports interface system))))

(define (ast->gom ast)
  (let* ((ast (if (and (pair? ast)
                      (not (ast:model? ast))
                      (not (eq? (car ast) 'root))
                      (find ast:model? ast))
                  (cons 'root ast)
                  ast))
         (ast (if (and (pair? ast) (assoc-ref ast 'locations))
                 (ast->annotate ast) ast)))
    (ast->gom- ast)))

(define (retain-source-location o t)
  (and-let* (((supports-source-properties? o))
             (loc (source-property o 'loc))
             ((supports-source-properties? t)))
            (set-source-property! t 'loc loc))
  t)

(define (ast->gom- ast)
  (retain-source-location ast ((compose ast->gom-- ast->sugar) ast)))

(define (ast->gom-- ast)
  (match ast

    (('action trigger) (make <action> :trigger (ast->gom- trigger)))

    (('arguments arguments ...) (make <arguments>
                                  :elements (map ast->gom- arguments)))

    (('assign identifier expression) (make <assign>
                                       :identifier identifier
                                       :expression (ast->gom- expression)))

    (('behaviour) (make <behaviour>))

    (('behaviour name body ...)
     (make <behaviour>
       :name name
       :types (ast->gom- (or (null-is-#f (assoc 'types body)) '(types)))
       :variables (ast->gom- (or (null-is-#f (assoc 'variables body)) '(variables)))
       :functions (ast->gom- (or (null-is-#f (assoc 'functions body)) '(functions)))
       :statement (ast->gom- (or (null-is-#f (assoc 'compound body)) '(compound)))))

    (('bind left right)
     (make <bind> :left (ast->gom- left) :right (ast->gom- right)))

    (('binding instance port) (make <binding> :instance instance :port port))

    (('bindings bindings ...)
     (make <bindings> :elements (map ast->gom- bindings)))

    (('call identifier) (make <call> :identifier identifier))

    (('call identifier arguments)
     (make <call>
       :identifier identifier
       :arguments (ast->gom- (or (null-is-#f arguments) '(arguments)))))

    (('component name ports ('system foo ('compound body ...)))
     (make <system>
       :name name
       :ports (ast->gom- ports)
       :instances (make <instances> :elements (ast->gom- body))))

    (('component name body ...)
     (make <component>
       :name name
       :ports (ast->gom- (or (null-is-#f (assoc 'ports body)) '(ports)))
       :behaviour (and=> (null-is-#f (assoc 'behaviour body)) ast->gom-)))

    (('compound statements ...)
     (make <compound> :elements (map ast->gom- statements)))

    (('data value) (make <data> :value value))

    (('enum name fields)
     (make <enum>
       :name name
       :fields (make <fields> :elements fields)))

    (('extern name value) (make <extern> :name name :value value))

    (((and (or 'in 'out) (get! direction)) signature name)
     (make <event>
       :name name
       :signature (ast->gom- signature)
       :direction (direction)))

    (('events events ...) (make <events> :elements (map ast->gom- events)))

    (('expression) (make <expression>))

    (('expression expression) (make <expression> :value (ast->gom- expression)))

    (('field identifier field) (make <field> :identifier identifier :field field))

    (('function name signature statement) ;; pre-resolving
     (make <function>
       :name name
       :signature (ast->gom- signature)
       :recursive #f
       :statement (ast->gom- statement)))

    (('function name signature recursive? statement)
     (make <function>
       :name name
       :signature (ast->gom- signature)
       :recursive recursive?
       :statement (ast->gom- statement)))

    (('functions functions ...)
     (make <functions> :elements (map ast->gom- functions)))

    (('guard expression statement)
     (make <guard>
       :expression (ast->gom- expression)
       :statement (ast->gom- statement)))

    (('if expression then)
     (make <if>
       :expression (ast->gom- expression)
       :then (ast->gom- then)))

    (('if expression then else)
     (make <if>
       :expression (ast->gom- expression)
       :then (ast->gom- then)
       :else (ast->gom- else)))

    (('illegal) (make <illegal>))

    (('imports import ...) (make <imports> :elements (map ast->gom- import)))

    (('import name) (make <import> :name name))

    (('imports imports ...) ast)

    (('int name range) (make <int> :name name :range (ast->gom- range)))

    (('instance component name) (make <instance> :name name :component component))

    (('instances instances ...)
     (make <instances> :elements (map ast->gom- instances)))

    (('interface name body ...)
     (make <interface>
       :name name
       :types (ast->gom- (or (null-is-#f (assoc 'types body)) '(types)))
       :events (ast->gom- (or (null-is-#f (assoc 'events body)) '(events)))
       :behaviour (and=> (null-is-#f (assoc 'behaviour body)) ast->gom-)))

    (('literal scope type field)
     (make <literal> :scope scope :type type :field field))

    (('on triggers statement)
     (make <on> :triggers (ast->gom- triggers) :statement (ast->gom- statement)))

    (('otherwise) (make <otherwise> :value 'otherwise))

    (('parameter name type)
     (make <gom:parameter> :name name :type (ast->gom- type)))

    (('parameter name type direction)
     (make <gom:parameter> :name name :type (ast->gom- type) :direction direction))

    (('parameters parameters ...)
     (make <parameters> :elements (map ast->gom- parameters)))

    (((and (or 'provides 'requires) (get! direction)) type name injected ...)
     (make <gom:port>
       :name name
       :type type
       :direction (direction)
       :injected (and=> (null-is-#f injected) car)))

    (('ports ports ...) (make <ports> :elements (map ast->gom- ports)))

    (('range from to) (make <range> :from from :to to))

    (('reply expression) (make <reply> :expression (ast->gom- expression)))

    (('return) (make <return>))

    (('return expression) (make <return> :expression (ast->gom- expression)))

    (('root elements ...) (make <root> :elements (map ast->gom- elements)))

    (('signature type parameters)
     (make <signature> :type (ast->gom- type) :parameters (ast->gom- parameters)))

    (('signature type) (make <signature> :type (ast->gom- type)))

    (('signature type parameters)
     (make <signature> :type (ast->gom- type) :parameters (ast->gom- parameters)))

    (('system name ports ('compound body ...))
     (make <system>
       :name name
       :ports (ast->gom- ports)
       :instances (make <instances> :elements (ast->gom- body))))

    (('system name ports instances bindings)
     (make <system>
       :name name
       :ports (ast->gom- ports)
       :instances (ast->gom- instances)
       :bindings (ast->gom- bindings)))

    (('trigger port event) (make <trigger> :port port :event event))

    (('trigger port event arguments)
     (make <trigger>
       :port port
       :event event
       :arguments (ast->gom- arguments)))

    (('triggers triggers ...)
     (make <triggers> :elements (map ast->gom- triggers)))

    (('type scope ('type name)) (make <type> :name name :scope scope))

    (('type name) (make <type> :name name))

    (('type name scope) (make <type> :name name :scope scope))

    (('types types ...) (make <types> :elements (map ast->gom- types)))

    (('var name) (make <var> :name name))

    (('variable name type expression)
     (make <variable> :name name :type (ast->gom- type) :expression (ast->gom- expression)))

    (('variables variables ...)
     (make <variables> :elements (map ast->gom- variables)))

    (('value type field) (make <value> :type type :field field))

    ((h t ...) (map ast->gom- ast))

    (_ ast)))

(define (ast:public ast)
;;  (stderr "public: ~a\n" ast)
  (match ast
    (($ <root>) ast)
    (('interface name types events behaviour) `(interface ,name ,types ,events))
    (('imports imports ...) '(imports))
    (('component name body ...) '(imports))
    (('system name body ...) '(imports))
    ((h t ...) (map ast:public ast))
    (_ '(imports))))

(define (ast:interface ast)
;;  (stderr "interface: ~a\n" ast)
  (match ast
    (($ <root>) ast)
    (('interface name body ...) ast)
    (('imports imports ...) '(imports))
    (('component name body ...) '(imports))
    (('system name body ...) '(imports))
    ((h t ...) (map ast:interface ast))
    (_ '(imports))))
