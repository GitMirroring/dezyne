;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
;;; Copyright © 2015, 2016, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  #:use-module (gaiag misc)

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
  (define (helper o)
    (match o
      (((and (? symbol?) type) (and location ('location file-name line column end-line end-column offset length)) body ...)
       (let ((ast (helper (cons type body)))
             (location (helper location)))
         (if (and location (is-a? ast <locationed-node>))
             (clone ast #:location location)
             ast)))

      (('location file-name line column end-line end-column offset length)
       (make <location-node> #:file-name file-name #:line line #:column column #:end-line end-line #:end-column end-column #:offset offset #:length length))

      (('action event) (make <action-node> #:event.name event))

      (('action port event) (make <action-node> #:port.name port #:event.name event))

      (('action port event arguments) (make <action-node> #:port.name port #:event.name event #:arguments (helper arguments)))

      (('arguments arguments ...) (make <arguments-node>
                                    #:elements (map helper arguments)))

      (('assign variable expression) (make <assign-node>
                                       #:variable.name variable
                                       #:expression (helper expression)))

      (('behaviour) (make <behaviour-node>))

      (('behaviour name body ...)
       (make <behaviour-node>
         #:name name
         #:types (helper (or (null-is-#f (assoc 'types body)) '(types)))
         #:ports (helper (or (null-is-#f (assoc 'ports body)) '(ports)))
         #:variables (helper (or (null-is-#f (assoc 'variables body)) '(variables)))
         #:functions (helper (or (null-is-#f (assoc 'functions body)) '(functions)))
         #:statement (helper (or (null-is-#f (assoc 'compound body)) '(compound)))))

      (('bind left right)
       (make <bind-node> #:left (helper left) #:right (helper right)))

      (('binding instance port) (make <binding-node> #:instance.name instance #:port.name port))

      (('bindings bindings ...)
       (make <bindings-node> #:elements (map helper bindings)))

      (('blocking statement) (make <blocking-node> #:statement (helper statement)))

      (('call function) (make <call-node> #:function.name function))

      (('call function arguments)
       (make <call-node>
         #:function.name function
         #:arguments (helper (or (null-is-#f arguments) '(arguments)))))

      (('call function arguments last?)
       (make <call-node>
         #:function.name function
         #:arguments (helper (or (null-is-#f arguments) '(arguments)))
         #:last? last?))

      (('foreign name body ...)
       (make <foreign-node>
         #:name (helper name)
         #:ports (helper (or (null-is-#f (assoc 'ports body)) '(ports)))))

      (('component name body ...)
       (make <component-node>
         #:name (helper name)
         #:ports (helper (or (null-is-#f (assoc 'ports body)) '(ports)))
         #:behaviour (and=> (null-is-#f (assoc 'behaviour body)) helper)))

      (('compound statements ...)
       (make <compound-node> #:elements (map helper statements)))

      (('data value) (make <data-node> #:value value))

      (('enum name fields) (make <enum-node> #:name (helper name) #:fields (helper fields)))

      (('extern name value)
       (make <extern-node> #:name (helper name) #:value value))

      (('event name signature direction)
       (make <event-node>
         #:name name
         #:signature (helper signature)
         #:direction direction))

      (('events events ...) (make <events-node> #:elements (map helper events)))

      (('field-test identifier field) (make <field-test-node> #:variable.name identifier #:field field))

      (('fields fields ...) (make <fields-node> #:elements fields))

      (('function name signature recursive? statement)
       (make <function-node>
         #:name name
         #:signature (helper signature)
         #:recursive recursive?
         #:statement (helper statement)))

      (('functions functions ...)
       (make <functions-node> #:elements (map helper functions)))

      (('guard expression statement)
       (make <guard-node>
         #:expression (helper expression)
         #:statement (helper statement)))

      (('if expression then)
       (make <if-node>
         #:expression (helper expression)
         #:then (helper then)))

      (('if expression then else)
       (make <if-node>
         #:expression (helper expression)
         #:then (helper then)
         #:else (helper else)))

      (('illegal) (make <illegal-node>))

      (('import name) (make <import-node> #:name (helper name)))

      (('int name range)
       (make <int-node> #:name (helper name) #:range (helper range)))

      (('instance name type) (make <instance-node> #:name name #:type.name (helper type)))

      (('instances instances ...)
       (make <instances-node> #:elements (map helper instances)))

      (('interface name types events #f)
       (make <interface-node>
         #:name (helper name)
         #:types (helper types)
         #:events (helper events)
         #:behaviour #f))

      (('interface name body ...)
       (make <interface-node>
         #:name (helper name)
         #:types (helper (or (null-is-#f (assoc 'types body)) '(types)))
         #:events (helper (or (null-is-#f (assoc 'events body)) '(events)))
         #:behaviour (and=> (null-is-#f (assoc 'behaviour body)) helper)))

      (('enum-literal name field) (make <enum-literal-node> #:type.name (helper name) #:field field))

      (('scope.name scope name) (make <scope.name-node> #:scope scope #:name name))

      (('on triggers statement)
       (make <on-node> #:triggers (helper triggers) #:statement (helper statement)))

      (('on triggers statement silent?)
       (make <on-node> #:triggers (helper triggers) #:statement (helper statement) #:silent? silent?))

      (('otherwise) (make <otherwise-node> #:value 'otherwise))

      (('otherwise value) (make <otherwise-node> #:value value))

      (('formal name #f #f)
       (make <formal-node> #:name name))

      (('formal name type)
       (make <formal-node> #:name name #:type.name (helper type)))

      (('formal name type direction)
       (make <formal-node> #:name name #:type.name (helper type) #:direction direction))

      (('formal-binding name #f #f variable)
       (make <formal-binding-node> #:name name #:variable.name variable))

      (('formal-binding name type #f variable)
       (make <formal-binding-node> #:name name #:type.name (helper type) #:variable.name variable))

      (('formal-binding name type direction variable)
       (make <formal-binding-node> #:name name #:type.name (helper type) #:direction direction #:variable.name variable))

      (('formals formals ...)
       (make <formals-node> #:elements (map helper formals)))

      (('port name type direction external-injected ...)
       (make <port-node>
         #:name name
         #:type.name (helper type)
         #:direction direction
         #:external (find (lambda (x) (eq? x 'external)) external-injected)
         #:injected (find (lambda (x) (eq? x 'injected)) external-injected)))

      (('ports ports ...) (make <ports-node> #:elements (map helper ports)))

      (('range from to) (make <range-node> #:from from #:to to))

      (('reply expression) (make <reply-node> #:expression (helper expression)))

      (('reply expression port) (make <reply-node> #:expression (helper expression) #:port.name port))

      (('return) (make <return-node>))

      (('return expression) (make <return-node> #:expression (helper expression)))

      (('root elements ...) (make <root-node> #:elements (map helper elements)))

      (('signature type formals)
       (make <signature-node> #:type.name (helper type) #:formals (helper formals)))

      (('signature type) (make <signature-node> #:type.name (helper type)))

      (('system name ports instances bindings)
       (make <system-node>
         #:name (helper name)
         #:ports (helper ports)
         #:instances (helper instances)
         #:bindings (helper bindings)))

      (('trigger port event) (make <trigger-node> #:port.name port #:event.name event))

      (('trigger port event arguments)
       (make <trigger-node>
         #:port.name port
         #:event.name event
         #:formals (helper arguments)))

      (('triggers triggers ...)
       (make <triggers-node> #:elements (map helper triggers)))

      (('type 'bool) (make <bool-node>))

      (('type 'void) (make <void-node>))

      (('type name) (make <type-node> #:name (helper name)))

      (('types types ...) (make <types-node> #:elements (map helper types)))

      (('var name) (make <var-node> #:variable.name name))

      (('variable name type)
       (make <variable-node> #:name name #:type.name (helper type) #:expression (make <expression-node>)))

      (('variable name type expression)
       (make <variable-node> #:name name #:type.name (helper type) #:expression (helper expression)))

      (('variables variables ...)
       (make <variables-node> #:elements (map helper variables)))

      (('<- x y) (list '<- (helper x) (helper y)))

      ((or 'bool 'void) o)

      (('expression) (make <literal-node>)) ;; FIXME: (make <expression-node>) ??
      (('expression expression) (helper expression))
      (('! expression) (make <not-node> #:expression (helper expression)))
      (('group expression) (make <group-node> #:expression (helper expression)))

      (('+ left right) (make <plus-node> #:left (helper left) #:right (helper right)))
      (('- left right) (make <minus-node> #:left (helper left) #:right (helper right)))
      (('< left right) (make <less-node> #:left (helper left) #:right (helper right)))
      (('<= left right) (make <less-equal-node> #:left (helper left) #:right (helper right)))
      (('== left right) (make <equal-node> #:left (helper left) #:right (helper right)))
      (('!= left right) (make <not-equal-node> #:left (helper left) #:right (helper right)))
      (('> left right) (make <greater-node> #:left (helper left) #:right (helper right)))
      (('>= left right) (make <greater-equal-node> #:left (helper left) #:right (helper right)))
      (('and left right) (make <and-node> #:left (helper left) #:right (helper right)))
      (('or left right) (make <or-node> #:left (helper left) #:right (helper right)))
      ;;(('expression (and (or (? number?) 'false 'true) (get! value))) (make <literal-node> #:value (value)))
      ((? number?) (make <literal-node> #:value o))
      ((? symbol?) (make <literal-node> #:value o))

      ((? (is? <ast>)) o)))

  (or (as ast <ast>)
      (let* ((ast (if (and (pair? ast)
                           (not (ast:model? ast))
                           (not (eq? (car ast) 'root))
                           (ast:model? (car ast)))
                      (make <root-node> #:elements ast)
                      ast))
             (ast (helper ast)))
        (make <root> #:node ast))))
