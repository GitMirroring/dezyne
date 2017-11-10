;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
;;; Copyright © 2015, 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag om)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag util)
  #:use-module (gaiag annotate)
  #:use-module (gaiag misc)

  #:use-module (language dezyne location)

  #:export (parse->om))

(define (ast-> o)
  ((compose
    pretty-print
    om->list
    parse->om
    ) o))

(define (ast:model? x)
  (and (pair? x) (member (car x) '(component import interface system type))))

(define (parse->om ast)
  (or (as ast <ast>)
      (let* ((ast (if (and (pair? ast)
                           (not (ast:model? ast))
                           (not (eq? (car ast) 'root))
                           (ast:model? (car ast)))
                      (make <root-node> #:elements ast)
                      ast))
             (ast (if (and (pair? ast) (assoc-ref ast 'locations))
                      (ast->annotate ast) ast))
             (ast (parse->om- ast)))
        (make <root> #:node ast)
        )))

(define (parse->om- ast)
  (retain-source-properties ast (parse->om-- ast)))

(define (parse->om-- o)
  (match o
    (('action event) (make <action-node> #:event event))

    (('action port event) (make <action-node> #:port port #:event event))

    (('action port event arguments) (make <action-node> #:port port #:event event #:arguments (parse->om- arguments)))

    (('arguments arguments ...) (make <arguments-node>
                                  #:elements (map parse->om- arguments)))

    (('assign variable expression) (make <assign-node>
                                     #:variable variable
                                     #:expression (parse->om- expression)))

    (('behaviour) (make <behaviour-node>))

    (('behaviour name body ...)
     (make <behaviour-node>
       #:name name
       #:types (parse->om- (or (null-is-#f (assoc 'types body)) '(types)))
       #:ports (parse->om- (or (null-is-#f (assoc 'ports body)) '(ports)))
       #:variables (parse->om- (or (null-is-#f (assoc 'variables body)) '(variables)))
       #:functions (parse->om- (or (null-is-#f (assoc 'functions body)) '(functions)))
       #:statement (parse->om- (or (null-is-#f (assoc 'compound body)) '(compound)))))

    (('bind left right)
     (make <bind-node> #:left (parse->om- left) #:right (parse->om- right)))

    (('binding instance port) (make <binding-node> #:instance instance #:port port))

    (('bindings bindings ...)
     (make <bindings-node> #:elements (map parse->om- bindings)))

    (('blocking statement) (make <blocking-node> #:statement (parse->om- statement)))

    (('call function) (make <call-node> #:function function))

    (('call function arguments)
     (make <call-node>
       #:function function
       #:arguments (parse->om- (or (null-is-#f arguments) '(arguments)))))

    (('call function arguments last?)
     (make <call-node>
       #:function function
       #:arguments (parse->om- (or (null-is-#f arguments) '(arguments)))
       #:last? last?))

    (('foreign name body ...)
     (and=> (assoc 'imported body) (mark-imported o))
     (make <foreign-node>
       #:name (parse->om- name)
       #:ports (parse->om- (or (null-is-#f (assoc 'ports body)) '(ports)))))

    (('component name body ...)
     (and=> (assoc 'imported body) (mark-imported o))
     (make <component-node>
       #:name (parse->om- name)
       #:ports (parse->om- (or (null-is-#f (assoc 'ports body)) '(ports)))
       #:behaviour (and=> (null-is-#f (assoc 'behaviour body)) parse->om-)))

    (('compound statements ...)
     (make <compound-node> #:elements (map parse->om- statements)))

    (('data value) (make <data-node> #:value value))

    (('enum name fields) (make <enum-node> #:name (parse->om- name) #:fields (parse->om- fields)))

    (('extern name value)
     (make <extern-node> #:name (parse->om- name) #:value value))

    (('event name signature direction)
     (make <event-node>
       #:name name
       #:signature (parse->om- signature)
       #:direction direction))

    (('events events ...) (make <events-node> #:elements (map parse->om- events)))

    (('field-test identifier field) (make <field-test-node> #:variable identifier #:field field))

    (('fields fields ...) (make <fields-node> #:elements fields))

    (('function name signature recursive? statement)
     (make <function-node>
       #:name name
       #:signature (parse->om- signature)
       #:recursive recursive?
       #:statement (parse->om- statement)))

    (('functions functions ...)
     (make <functions-node> #:elements (map parse->om- functions)))

    (('guard expression statement)
     (make <guard-node>
       #:expression (parse->om- expression)
       #:statement (parse->om- statement)))

    (('if expression then)
     (make <if-node>
       #:expression (parse->om- expression)
       #:then (parse->om- then)))

    (('if expression then else)
     (make <if-node>
       #:expression (parse->om- expression)
       #:then (parse->om- then)
       #:else (parse->om- else)))

    (('illegal) (make <illegal-node>))

    (('import name) (make <import-node> #:name (parse->om- name)))

    (('int name range)
     (make <int-node> #:name (parse->om- name) #:range (parse->om- range)))

    (('instance name type) (make <instance-node> #:name name #:type (parse->om- type)))

    (('instances instances ...)
     (make <instances-node> #:elements (map parse->om- instances)))

    (('interface name types events #f)
     (make <interface-node>
       #:name (parse->om- name)
       #:types (parse->om- types)
       #:events (parse->om- events)
       #:behaviour #f))

    (('interface name body ...)
     (and=> (assoc 'imported body) (mark-imported o))
     (make <interface-node>
       #:name (parse->om- name)
       #:types (parse->om- (or (null-is-#f (assoc 'types body)) '(types)))
       #:events (parse->om- (or (null-is-#f (assoc 'events body)) '(events)))
       #:behaviour (and=> (null-is-#f (assoc 'behaviour body)) parse->om-)))

    (('enum-literal name field) (make <enum-literal-node> #:type (parse->om- name) #:field field))

    (('dotted name ...) o)

    (('scope.name scope name) (make <scope.name-node> #:scope scope #:name name))

    (('on triggers statement)
     (make <on-node> #:triggers (parse->om- triggers) #:statement (parse->om- statement)))

    (('otherwise) (make <otherwise-node> #:value 'otherwise))

    (('otherwise value) (make <otherwise-node> #:value value))

    (('formal name #f #f)
     (make <formal-node> #:name name))

    (('formal-binding name #f #f variable)
     (make <formal-binding-node> #:name name #:variable variable))

    (('formal name type)
     (make <formal-node> #:name name #:type (parse->om- type)))

    (('formal name type direction)
     (make <formal-node> #:name name #:type (parse->om- type) #:direction direction))

    (('formals formals ...)
     (make <formals-node> #:elements (map parse->om- formals)))

    (('port name type direction external-injected ...)
     (make <port-node>
       #:name name
       #:type (parse->om- type)
       #:direction direction
       #:external (find (lambda (x) (eq? x 'external)) external-injected)
       #:injected (find (lambda (x) (eq? x 'injected)) external-injected)))

    (('ports ports ...) (make <ports-node> #:elements (map parse->om- ports)))

    (('range from to) (make <range-node> #:from from #:to to))

    (('reply expression) (make <reply-node> #:expression (parse->om- expression)))

    (('reply expression port) (make <reply-node> #:expression (parse->om- expression) #:port port))

    (('return) (make <return-node>))

    (('return expression) (make <return-node> #:expression (parse->om- expression)))

    (('root elements ...) (make <root-node> #:elements (map parse->om- elements)))

    (('signature type formals)
     (make <signature-node> #:type (parse->om- type) #:formals (parse->om- formals)))

    (('signature type) (make <signature-node> #:type (parse->om- type)))

    (('system name ports instances bindings)
     (and=> (assoc 'imported (cddr o)) (mark-imported o))
     (make <system-node>
        #:name (parse->om- name)
        #:ports (parse->om- ports)
        #:instances (parse->om- instances)
        #:bindings (parse->om- bindings)))

    (('trigger port event) (make <trigger-node> #:port port #:event event))

    (('trigger port event arguments)
     (make <trigger-node>
       #:port port
       #:event event
       #:formals (parse->om- arguments)))

    (('triggers triggers ...)
     (make <triggers-node> #:elements (map parse->om- triggers)))

    (('type name) (make <type-node> #:name (parse->om- name)))

    (('types types ...) (make <types-node> #:elements (map parse->om- types)))

    (('var name) (make <var-node> #:variable name))

    (('variable name type)
     (make <variable-node> #:name name #:type (parse->om- type) #:expression (make <expression-node>)))

    (('variable name type expression)
     (make <variable-node> #:name name #:type (parse->om- type) #:expression (parse->om- expression)))

    (('variables variables ...)
     (make <variables-node> #:elements (map parse->om- variables)))

    (('<- x y) (list '<- (parse->om- x) (parse->om- y)))

    ((or 'bool 'void) o)

    (('expression) (make <literal-node>))
    (('expression expression) (parse->om- expression))
    (('! expression) (make <not-node> #:expression (parse->om- expression)))
    (('group expression) (make <group-node> #:expression (parse->om- expression)))

    (('+ left right) (make <plus-node> #:left (parse->om- left) #:right (parse->om- right)))
    (('- left right) (make <minus-node> #:left (parse->om- left) #:right (parse->om- right)))
    (('< left right) (make <less-node> #:left (parse->om- left) #:right (parse->om- right)))
    (('<= left right) (make <less-equal-node> #:left (parse->om- left) #:right (parse->om- right)))
    (('== left right) (make <equal-node> #:left (parse->om- left) #:right (parse->om- right)))
    (('!= left right) (make <not-equal-node> #:left (parse->om- left) #:right (parse->om- right)))
    (('> left right) (make <greater-node> #:left (parse->om- left) #:right (parse->om- right)))
    (('>= left right) (make <greater-equal-node> #:left (parse->om- left) #:right (parse->om- right)))
    (('and left right) (make <and-node> #:left (parse->om- left) #:right (parse->om- right)))
    (('or left right) (make <or-node> #:left (parse->om- left) #:right (parse->om- right)))
    ;;(('expression (and (or (? number?) 'false 'true) (get! value))) (make <literal-node> #:value (value)))
    ((? number?) (make <literal-node> #:value o))
    ((? symbol?) (make <literal-node> #:value o))

    ((? (is? <ast>)) o)))

(define ((mark-imported o) entry)
  (set-source-property! o 'imported? (cdr entry)))
