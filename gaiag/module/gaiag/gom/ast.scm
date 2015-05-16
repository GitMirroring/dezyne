;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

  :use-module (language dezyne location)

  :export (
           ast->gom
           ast->sugar
           ast->trigger-sugar
           ast:public
           ast:interface
           ))

(define (ast->sugar ast)
  (match ast
    ;; (('in 'void name) `(event ,name (signature (type void)) in))
    ;; (('out 'void name) `(event ,name (signature (type void)) out))
    ;; (('in signature name) `(event ,name ,signature in))
    ;; (('out signature name) `(event ,name ,signature out))
    ;; (('enum name scope ('fields fields ...)) `(enum ,name ,scope (fields ,fields)))
    ;; (('enum name scope fields) `(enum ,name ,scope (fields ,fields)))
    ;; (('enum name ('fields fields ...)) `(enum ,name #f (fields ,fields)))
    ;; (('enum name fields) `(enum ,name #f (fields ,fields)))
    ;; (('extern name value) `(extern ,name #f ,value))
    ;; (('int name range) `(int ,name #f ,range))    
    ;; (('events events ...) (cons 'events (map ast->sugar events)))

    (('provides type name) `(port ,name ,type provides))
    (('requires type name injected ...) `(port ,name ,type requires ,injected))
    (('on ('triggers t ...) statement) ast)
    (('on triggers statement) (list 'on (cons 'triggers (map ast->trigger-sugar triggers)) statement))
    (_ ast)))

(define (ast->trigger-sugar ast)
  (match ast
    ((port event) (cons 'trigger ast))
    ((? symbol?) (cons 'trigger (list #f ast)))
    (_ ast)))

(define (ast:model? x)
  (and (pair? x) (member (car x) '(component import interface system type))))

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

(define (ast->gom- ast)
  (retain-source-properties ast ((compose ast->gom-- ast->sugar) ast)))

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

    (('call identifier arguments last?)
     (make <call>
       :identifier identifier
       :arguments (ast->gom- (or (null-is-#f arguments) '(arguments)))
       :last? last?))

    (('component name body ...)
     (and=> (assoc 'imported body) (mark-imported ast))
      (make <component>
        :name name
        :ports (ast->gom- (or (null-is-#f (assoc 'ports body)) '(ports)))
        :behaviour (and=> (null-is-#f (assoc 'behaviour body)) ast->gom-)))

    (('compound statements ...)
     (make <compound> :elements (map ast->gom- statements)))

    (('data value) (make <data> :value value))

    (('enum name scope fields)
     (make <enum>
       :name name
       :scope scope
       :fields (ast->gom- fields)))

    (('extern name scope value)
     (make <extern> :name name :scope scope :value value))

    (('event name signature direction)
     (make <event>
       :name name
       :signature (ast->gom- signature)
       :direction direction))

    (('events events ...) (make <events> :elements (map ast->gom- events)))

    (('expression) (make <expression>))

    (('expression expression) (make <expression> :value (ast->gom- expression)))

    (('field identifier field) (make <field> :identifier identifier :field field))

    (('fields fields ...) (make <fields> :elements fields))    

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

    (('import name) (make <import> :name name))

    (('int name scope range)
     (make <int> :name name :scope scope :range (ast->gom- range)))

    (('instance name component) (make <instance> :name name :component component))

    (('instances instances ...)
     (make <instances> :elements (map ast->gom- instances)))

    (('interface name body ...)
     (and=> (assoc 'imported body) (mark-imported ast))
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

    (('otherwise value) (make <otherwise> :value value))    

    (('parameter name type)
     (make <gom:parameter> :name name :type (ast->gom- type)))

    (('parameter name type direction)
     (make <gom:parameter> :name name :type (ast->gom- type) :direction direction))

    (('parameters parameters ...)
     (make <parameters> :elements (map ast->gom- parameters)))

    (('port name type direction injected ...)
     (make <gom:port>
       :name name
       :type type
       :direction direction
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

    (('system name ports instances bindings)
     (and=> (assoc 'imported (cddr ast)) (mark-imported ast))
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

(define ((mark-imported o) entry)
  (set-source-property! o 'imported? (cdr entry)))

(define (ast:public ast)
;;  (stderr "public: ~a\n" ast)
  (match ast
    (($ <root>) ast)
    (('enum name fields) `(enum ,name ,fields))
    (('extern name value) `(extern ,name ,value))
    (('int name range) `(int ,name ,range))
    (('interface name types events behaviour) `(interface ,name ,types ,events))
;;    (('component name body ...) '(import))
;;    (('system name body ...) '(import))
    ((h t ...) (map ast:public ast))
    (_ '(import))))

(define (ast:interface ast)
;;  (stderr "interface: ~a\n" ast)
  (match ast
    (($ <root>) ast)
;;    (('enum name fields) `(enum ,name ,fields))
;;    (('extern name value) `(extern ,name ,value))
;;    (('int name range) `(int ,name ,range))
    (('interface name body ...) ast)
;;    (('component name body ...) '(import))
;;    (('system name body ...) '(import))
    ((h t ...) (map ast:interface ast))
    (_ '(import))))
