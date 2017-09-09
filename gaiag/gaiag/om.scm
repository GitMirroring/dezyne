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

(define (ast-> o) (parse->om o))

(define (ast:model? x)
  (and (pair? x) (member (car x) '(component import interface system type))))

(define (parse->om ast)
  (or (as ast <ast>)
      (let* ((ast (if (and (pair? ast)
                           (not (ast:model? ast))
                           (not (eq? (car ast) 'root))
                           (ast:model? (car ast)))
                      (make <root> #:elements ast)
                      ast))
             (ast (if (and (pair? ast) (assoc-ref ast 'locations))
                      (ast->annotate ast) ast)))
        (parse->om- ast))))

(define (parse->om- ast)
  (retain-source-properties ast (parse->om-- ast)))

(define (parse->om-- o)
  (match o
    (('action event) (make <action> #:event event))

    (('action port event) (make <action> #:port port #:event event))

    (('action port event arguments) (make <action> #:port port #:event event #:arguments (parse->om- arguments)))

    (('arguments arguments ...) (make <arguments>
                                  #:elements (map parse->om- arguments)))

    (('assign variable expression) (make <assign>
                                     #:variable variable
                                     #:expression (parse->om- expression)))

    (('behaviour) (make <behaviour>))

    (('behaviour name body ...)
     (make <behaviour>
       #:name name
       #:types (parse->om- (or (null-is-#f (assoc 'types body)) '(types)))
       #:ports (parse->om- (or (null-is-#f (assoc 'ports body)) '(ports)))
       #:variables (parse->om- (or (null-is-#f (assoc 'variables body)) '(variables)))
       #:functions (parse->om- (or (null-is-#f (assoc 'functions body)) '(functions)))
       #:statement (parse->om- (or (null-is-#f (assoc 'compound body)) '(compound)))))

    (('bind left right)
     (make <bind> #:left (parse->om- left) #:right (parse->om- right)))

    (('binding instance port) (make <binding> #:instance instance #:port port))

    (('bindings bindings ...)
     (make <bindings> #:elements (map parse->om- bindings)))

    (('blocking statement) (make <blocking> #:statement (parse->om- statement)))

    (('call function) (make <call> #:function function))

    (('call function arguments)
     (make <call>
       #:function function
       #:arguments (parse->om- (or (null-is-#f arguments) '(arguments)))))

    (('call function arguments last?)
     (make <call>
       #:function function
       #:arguments (parse->om- (or (null-is-#f arguments) '(arguments)))
       #:last? last?))

    (('foreign name body ...)
     (and=> (assoc 'imported body) (mark-imported o))
     (make <foreign>
       #:name (parse->om- name)
       #:ports (parse->om- (or (null-is-#f (assoc 'ports body)) '(ports)))))

    (('component name body ...)
     (and=> (assoc 'imported body) (mark-imported o))
      (make <component>
        #:name (parse->om- name)
        #:ports (parse->om- (or (null-is-#f (assoc 'ports body)) '(ports)))
        #:behaviour (and=> (null-is-#f (assoc 'behaviour body)) parse->om-)))

    (('compound statements ...)
     (make <compound> #:elements (map parse->om- statements)))

    (('data value) (make <data> #:value value))

    (('enum name fields) (make <enum> #:name (parse->om- name) #:fields (parse->om- fields)))

    (('extern name value)
     (make <extern> #:name (parse->om- name) #:value value))

    (('event name signature direction)
     (make <event>
       #:name name
       #:signature (parse->om- signature)
       #:direction direction))

    (('events events ...) (make <events> #:elements (map parse->om- events)))

    (('field identifier field) (make <field> #:variable identifier #:field field))

    (('fields fields ...) (make <fields> #:elements fields))

    (('function name signature recursive? statement)
     (make <function>
       #:name name
       #:signature (parse->om- signature)
       #:recursive recursive?
       #:statement (parse->om- statement)))

    (('functions functions ...)
     (make <functions> #:elements (map parse->om- functions)))

    (('guard expression statement)
     (make <guard>
       #:expression (parse->om- expression)
       #:statement (parse->om- statement)))

    (('if expression then)
     (make <if>
       #:expression (parse->om- expression)
       #:then (parse->om- then)))

    (('if expression then else)
     (make <if>
       #:expression (parse->om- expression)
       #:then (parse->om- then)
       #:else (parse->om- else)))

    (('illegal) (make <illegal>))

    (('import name) (make <import> #:name (parse->om- name)))

    (('int name range)
     (make <int> #:name (parse->om- name) #:range (parse->om- range)))

    (('instance name type) (make <instance> #:name name #:type (parse->om- type)))

    (('instances instances ...)
     (make <instances> #:elements (map parse->om- instances)))

    (('interface name types events #f)
     (make <interface>
       #:name (parse->om- name)
       #:types (parse->om- types)
       #:events (parse->om- events)
       #:behaviour #f))

    (('interface name body ...)
     (and=> (assoc 'imported body) (mark-imported o))
     (make <interface>
       #:name (parse->om- name)
       #:types (parse->om- (or (null-is-#f (assoc 'types body)) '(types)))
       #:events (parse->om- (or (null-is-#f (assoc 'events body)) '(events)))
       #:behaviour (and=> (null-is-#f (assoc 'behaviour body)) parse->om-)))

    (('enum-literal name field) (make <enum-literal> #:type (parse->om- name) #:field field))

    (('dotted name ...) o)

    (('scope.name scope name) (make <scope.name> #:scope scope #:name name))

    (('on triggers statement)
     (make <on> #:triggers (parse->om- triggers) #:statement (parse->om- statement)))

    (('otherwise) (make <otherwise> #:value 'otherwise))

    (('otherwise value) (make <otherwise> #:value value))

    (('formal name #f #f)
     (make <formal> #:name name))

    (('formal-binding name #f #f variable)
     (make <formal-binding> #:name name #:variable variable))

    (('formal name type)
     (make <formal> #:name name #:type (parse->om- type)))

    (('formal name type direction)
     (make <formal> #:name name #:type (parse->om- type) #:direction direction))

    (('formals formals ...)
     (make <formals> #:elements (map parse->om- formals)))

    (('port name type direction external-injected ...)
     (make <port>
       #:name name
       #:type (parse->om- type)
       #:direction direction
       #:external (find (lambda (x) (eq? x 'external)) external-injected)
       #:injected (find (lambda (x) (eq? x 'injected)) external-injected)))

    (('ports ports ...) (make <ports> #:elements (map parse->om- ports)))

    (('range from to) (make <range> #:from from #:to to))

    (('reply expression) (make <reply> #:expression (parse->om- expression)))

    (('reply expression port) (make <reply> #:expression (parse->om- expression) #:port port))

    (('return) (make <return>))

    (('return expression) (make <return> #:expression (parse->om- expression)))

    (('root elements ...) (make <root> #:elements (map parse->om- elements)))

    (('signature type formals)
     (make <signature> #:type (parse->om- type) #:formals (parse->om- formals)))

    (('signature type) (make <signature> #:type (parse->om- type)))

    (('system name ports instances bindings)
     (and=> (assoc 'imported (cddr o)) (mark-imported o))
     (make <system>
        #:name (parse->om- name)
        #:ports (parse->om- ports)
        #:instances (parse->om- instances)
        #:bindings (parse->om- bindings)))

    (('trigger port event) (make <trigger> #:port port #:event event))

    (('trigger port event arguments)
     (make <trigger>
       #:port port
       #:event event
       #:formals (parse->om- arguments)))

    (('triggers triggers ...)
     (make <triggers> #:elements (map parse->om- triggers)))

    (('type name) (make <type> #:name (parse->om- name)))

    (('types types ...) (make <types> #:elements (map parse->om- types)))

    (('var name) (make <var> #:variable name))

    (('variable name type)
     (make <variable> #:name name #:type (parse->om- type) #:expression (make <expression>)))

    (('variable name type expression)
     (make <variable> #:name name #:type (parse->om- type) #:expression (parse->om- expression)))

    (('variables variables ...)
     (make <variables> #:elements (map parse->om- variables)))

    (('<- x y) (list '<- (parse->om- x) (parse->om- y)))

    ((or 'bool 'void) o)

    (('expression) (make <literal>))
    (('expression expression) (parse->om- expression))
    (('! expression) (make <not> #:expression (parse->om- expression)))
    (('group expression) (make <group> #:expression (parse->om- expression)))

    (('+ left right) (make <plus> #:left (parse->om- left) #:right (parse->om- right)))
    (('- left right) (make <minus> #:left (parse->om- left) #:right (parse->om- right)))
    (('< left right) (make <less> #:left (parse->om- left) #:right (parse->om- right)))
    (('<= left right) (make <less-equal> #:left (parse->om- left) #:right (parse->om- right)))
    (('== left right) (make <equal> #:left (parse->om- left) #:right (parse->om- right)))
    (('!= left right) (make <not-equal> #:left (parse->om- left) #:right (parse->om- right)))
    (('> left right) (make <greater> #:left (parse->om- left) #:right (parse->om- right)))
    (('>= left right) (make <greater-equal> #:left (parse->om- left) #:right (parse->om- right)))
    (('and left right) (make <and> #:left (parse->om- left) #:right (parse->om- right)))
    (('or left right) (make <or> #:left (parse->om- left) #:right (parse->om- right)))
    ;;(('expression (and (or (? number?) 'false 'true) (get! value))) (make <literal> #:value (value)))
    ((? number?) (make <literal> #:value o))
    ((? symbol?) (make <literal> #:value o))

    ((? (is? <ast>)) o)))

(define ((mark-imported o) entry)
  (set-source-property! o 'imported? (cdr entry)))
