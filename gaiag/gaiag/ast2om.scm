;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag ast2om)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)

  #:use-module (language dezyne location)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))

  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag util)

  #:use-module (gaiag annotate)
  #:use-module (gaiag misc)
  #:use-module (gaiag reader)

  #:export (
           ast->om
           ))

(define (ast:model? x)
  (and (pair? x) (member (car x) '(component import interface system type))))

(define (ast->om ast)
  (or (as ast <ast>)
      (let* ((ast (if (and (pair? ast)
                           (not (ast:model? ast))
                           (not (eq? (car ast) 'root))
                           (ast:model? (car ast)))
                      (make <root> #:elements ast)
                      ast))
             (ast (if (and (pair? ast) (assoc-ref ast 'locations))
                      (ast->annotate ast) ast)))
        (ast->om- ast))))

(define (ast->om- ast)
  (retain-source-properties ast (ast->om-- ast)))

(define (ast->om-- o)

  (match o
    (('action event) (make <action> #:event event))

    (('action port event) (make <action> #:port port #:event event))

    (('action port event arguments) (make <action> #:port port #:event event #:arguments (ast->om- arguments)))

    (('arguments arguments ...) (make <arguments>
                                  #:elements (map ast->om- arguments)))

    (('assign variable expression) (make <assign>
                                     #:variable variable
                                     #:expression (ast->om- expression)))

    (('behaviour) (make <behaviour>))

    (('behaviour name body ...)
     (make <behaviour>
       #:name name
       #:types (ast->om- (or (null-is-#f (assoc 'types body)) '(types)))
       #:ports (ast->om- (or (null-is-#f (assoc 'ports body)) '(ports)))
       #:variables (ast->om- (or (null-is-#f (assoc 'variables body)) '(variables)))
       #:functions (ast->om- (or (null-is-#f (assoc 'functions body)) '(functions)))
       #:statement (ast->om- (or (null-is-#f (assoc 'compound body)) '(compound)))))

    (('bind left right)
     (make <bind> #:left (ast->om- left) #:right (ast->om- right)))

    (('binding instance port) (make <binding> #:instance instance #:port port))

    (('bindings bindings ...)
     (make <bindings> #:elements (map ast->om- bindings)))

    (('blocking statement) (make <blocking> #:statement (ast->om- statement)))

    (('call identifier) (make <call> #:identifier identifier))

    (('call identifier arguments)
     (make <call>
       #:identifier identifier
       #:arguments (ast->om- (or (null-is-#f arguments) '(arguments)))))

    (('call identifier arguments last?)
     (make <call>
       #:identifier identifier
       #:arguments (ast->om- (or (null-is-#f arguments) '(arguments)))
       #:last? last?))

    (('component name body ...)
     (and=> (assoc 'imported body) (mark-imported o))
      (make <component>
        #:name (ast->om- name)
        #:ports (ast->om- (or (null-is-#f (assoc 'ports body)) '(ports)))
        #:behaviour (and=> (null-is-#f (assoc 'behaviour body)) ast->om-)))

    (('compound statements ...)
     (make <compound> #:elements (map ast->om- statements)))

    (('data value) (make <data> #:value value))

    (('enum name fields) (make <enum> #:name (ast->om- name) #:fields (ast->om- fields)))

    (('extern name value)
     (make <extern> #:name (ast->om- name) #:value value))

    (('event name signature direction)
     (make <event>
       #:name name
       #:signature (ast->om- signature)
       #:direction direction))

    (('events events ...) (make <events> #:elements (map ast->om- events)))

    (('expression) (make <expression>))

    (('expression expression) (make <expression> #:value (ast->om- expression)))

    (('field identifier field) (make <field> #:identifier identifier #:field field))

    (('fields fields ...) (make <fields> #:elements fields))

    (('function name signature recursive? statement)
     (make <function>
       #:name name
       #:signature (ast->om- signature)
       #:recursive recursive?
       #:statement (ast->om- statement)))

    (('functions functions ...)
     (make <functions> #:elements (map ast->om- functions)))

    (('guard expression statement)
     (make <guard>
       #:expression (ast->om- expression)
       #:statement (ast->om- statement)))

    (('if expression then)
     (make <if>
       #:expression (ast->om- expression)
       #:then (ast->om- then)))

    (('if expression then else)
     (make <if>
       #:expression (ast->om- expression)
       #:then (ast->om- then)
       #:else (ast->om- else)))

    (('illegal) (make <illegal>))

    (('import name) (make <import> #:name (ast->om- name)))

    (('int name range)
     (make <int> #:name (ast->om- name) #:range (ast->om- range)))

    (('instance name type) (make <instance> #:name name #:type (ast->om- type)))

    (('instances instances ...)
     (make <instances> #:elements (map ast->om- instances)))

    (('interface name types events #f)
     (make <interface>
       #:name (ast->om- name)
       #:types (ast->om- types)
       #:events (ast->om- events)
       #:behaviour #f))

    (('interface name body ...)
     (and=> (assoc 'imported body) (mark-imported o))
     (make <interface>
       #:name (ast->om- name)
       #:types (ast->om- (or (null-is-#f (assoc 'types body)) '(types)))
       #:events (ast->om- (or (null-is-#f (assoc 'events body)) '(events)))
       #:behaviour (and=> (null-is-#f (assoc 'behaviour body)) ast->om-)))

    (('literal name field) (make <literal> #:type (ast->om- name) #:field field))

    (('dotted name ...) o)

    (('scope.name scope name) (make <scope.name> #:scope scope #:name name))

    (('on triggers statement)
     (make <on> #:triggers (ast->om- triggers) #:statement (ast->om- statement)))

    (('otherwise) (make <otherwise> #:value 'otherwise))

    (('otherwise value) (make <otherwise> #:value value))

    (('formal name #f #f)
     (make <formal> #:name name))

    (('formal-binding name #f #f variable)
     (make <formal-binding> #:name name #:variable variable))

    (('formal name type)
     (make <formal> #:name name #:type (ast->om- type)))

    (('formal name type direction)
     (make <formal> #:name name #:type (ast->om- type) #:direction direction))

    (('formals formals ...)
     (make <formals> #:elements (map ast->om- formals)))

    (('port name type direction external-injected ...)
     (make <port>
       #:name name
       #:type (ast->om- type)
       #:direction direction
       #:external (find (lambda (x) (eq? x 'external)) external-injected)
       #:injected (find (lambda (x) (eq? x 'injected)) external-injected)))

    (('ports ports ...) (make <ports> #:elements (map ast->om- ports)))

    (('range from to) (make <range> #:from from #:to to))

    (('reply expression) (make <reply> #:expression (ast->om- expression)))

    (('reply expression port) (make <reply> #:expression (ast->om- expression) #:port port))

    (('return) (make <return>))

    (('return expression) (make <return> #:expression (ast->om- expression)))

    (('root elements ...) (make <root> #:elements (map ast->om- elements)))

    (('signature type formals)
     (make <signature> #:type (ast->om- type) #:formals (ast->om- formals)))

    (('signature type) (make <signature> #:type (ast->om- type)))

    (('system name ports instances bindings)
     (and=> (assoc 'imported (cddr o)) (mark-imported o))
     (make <system>
        #:name (ast->om- name)
        #:ports (ast->om- ports)
        #:instances (ast->om- instances)
        #:bindings (ast->om- bindings)))

    (('trigger port event) (make <trigger> #:port port #:event event))

    (('trigger port event arguments)
     (make <trigger>
       #:port port
       #:event event
       #:formals (ast->om- arguments)))

    (('triggers triggers ...)
     (make <triggers> #:elements (map ast->om- triggers)))

    (('type name) (make <type> #:name (ast->om- name)))

    (('types types ...) (make <types> #:elements (map ast->om- types)))

    (('var name) (make <var> #:variable name))

    (('variable name type)
     (make <variable> #:name name #:type (ast->om- type) #:expression (make <expression>)))

    (('variable name type expression)
     (make <variable> #:name name #:type (ast->om- type) #:expression (ast->om- expression)))

    (('variables variables ...)
     (make <variables> #:elements (map ast->om- variables)))

    (((? om:operator?) h t ...) (cons (car o) (map ast->om- (cdr o))))

    (('<- x y) (list '<- (ast->om- x) (ast->om- y)))

    ((? number?) o)

    ((? symbol?) o)

    ((? (is? <ast>)) o) ;; FIXME: csp.test:csp->om
    ))

(define ((mark-imported o) entry)
  (set-source-property! o 'imported? (cdr entry)))
