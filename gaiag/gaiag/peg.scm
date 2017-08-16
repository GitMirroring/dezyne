;;; Dezyne --- Dezyne command line tools
;;;
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

(define-module (gaiag peg)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)
  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag util)
  #:use-module (gaiag misc)
  #:export (parse-tree->ast))

(define (ast-> o)
  ((compose
    pretty-print
    om->list
    ) o))

(define ((sexp-is? type) o)
  (and (pair? o)
       (eq? (car o) type)
       o))

(define* (parse-tree->ast o #:key string (file-name "<stdin>"))
  (peg-ast->ast (parse-tree->peg-ast o #:string string #:file-name file-name)))

(define (peg-ast->ast o)
  (match o
    ((? (is? <comment>)) o)
    ((? (is? <location>)) o)
    ((? (is? <behaviour>)) (clone o #:statement (make <compound> #:elements (list (.statement o)))))
    ((? (is? <ast>)) (tree-map peg-ast->ast o))
    ((? string?) (string->symbol o))
    (((? string?) ...) (map string->symbol o))
    (_ o)))

(define* (parse-tree->peg-ast o #:key string (file-name "<stdin>"))
  (define (helper o)
    (match o

      (((and (? symbol?) type) body ... ('location pos end))
       (let ((ast (helper (cons type body)))
             (location (helper (last o))))
         (if (and location (or (is-a? ast <root>)
                               (is-a? ast <comment-node>)
                               (is-a? ast <named-node>)))
             (clone ast #:location location)
             ast)))

      ((((or 'line-comment 'block-comment) comment ...) sexp)
       (let ((ast (helper sexp))
             (comment (helper (car o))))
         (if (is-a? ast <named-node>) (clone ast #:comment comment)
             ast)))

      (('root elements ...)
       (make <root> #:elements (map helper elements)))

      (('import name)
       (make <import-node> #:name (helper name)))

      (('namespace name)
       (helper (append o '(()))))

      (('namespace name elements)
       (make <namespace-node>
         #:name (helper name)
         #:elements (map helper elements)))

      (('enum name fields)
       (make <enum-node> #:name (helper name) #:fields (helper fields)))

      (('fields fields ...)
       (make <fields-node> #:elements (map helper fields)))

      (('int name range)
       (make <int-node> #:name (helper name) #:range (helper range)))

      (('range from to) (make <range-node> #:from from #:to to))

      (('extern name value)
       (make <extern-node> #:name (helper name) #:value value))

      (('interface name body ...)
       (let* ((sexp (helper (assoc 'types-and-events body))))
         (receive (events types) (partition (sexp-is? 'event) (.sexp sexp))
           (make <interface-node>
             #:name (helper name)
             #:types (helper (cons 'types types))
             #:events (helper (cons 'events events))
             #:behaviour (and=> (assoc 'behaviour body) helper)))))

      (('types-and-events types-and-events ...)
       (make <sexp-node> #:sexp types-and-events))

      (('events events ...)
       (make <events-node> #:elements (map helper events)))

      (('event direction type name)
       (helper (append o '((formals)))))

      (('event direction type name formals)
       (make <event-node>
         #:name (helper name)
         #:signature (make <signature> #:type.name (helper type) #:formals (helper formals))
         #:direction (helper direction)))

      (('component name body ...)
       (make <component-node>
         #:name (helper name)
         #:ports (helper (or (null-is-#f (assoc 'ports body)) '(ports)))
         #:behaviour (and=> (null-is-#f (assoc 'behaviour body)) helper)))

      (('ports ports ...) (make <ports-node> #:elements (map helper ports)))

      (('port direction type name external-injected ...)
       (make <port-node>
         #:name (helper name)
         #:type.name (helper type)
         #:direction (helper direction)
         #:external (find (lambda (x) (eq? x 'external)) external-injected)
         #:injected (find (lambda (x) (eq? x 'injected)) external-injected)))

      (('declarative-compound 'behaviour-statement-list)
       (make <error-node> #:message "empty declarative-compound"))

      (('declarative-compound body ...)
       (make <declarative-compound-node> #:elements (map helper body)))

      (('imperative-compound 'behaviour-statement-list)
       (make <skip-node>))

      (('imperative-compound body ...)
       (make <compound-node> #:elements (map helper body)))

      (('compound 'behaviour-statement-list)
       (make <skip-node>))

      (('compound body ...)
       (let ((statements (map helper body)))
         (make (if (and (pair? statements) (is-a? (car statements) <declarative>)) <declarative-compound-node>
                   <compound-node>) #:elements statements)))

      (('on triggers statement)
       (make <on-node> #:triggers (helper triggers) #:statement (helper statement)))

      (('action-or-call action-or-call)
       (let ((action-or-call (helper action-or-call)))
         (make <action-node> #:port.name (.scope action-or-call) #:event.name (.name action-or-call))))









      (('triggers triggers ...)
       (make <triggers-node> #:elements (map helper triggers)))

      (('trigger name)
       (let* ((name (helper name))
              (port-name (as (.scope name) <pair>)))
         (make <trigger-node> #:port.name port-name #:event.name (.name name))))


      (('block-comment comment)
       (make <block-comment> #:string comment))
      (('line-comment comment)
       (make <line-comment> #:string comment))



      (('direction direction)
       (string->symbol direction))

      (('port-direction direction)
       (string->symbol direction))


      ;; TODO: change grammar to be GOOPS'ier, buig hier om,
      ;; make AST more OM'ier?
      ;;(('compound-name scope name) )

      (('compound-with-arguments compound-with-arguments)
       (helper compound-with-arguments))


      (('compound-name name) (make <scope.name-node> #:name (helper name)))
      (('compound-name scope name) (make <scope.name-node> #:scope (helper scope) #:name (helper name)))

      (('type-name name) (helper name))
      (('name name) (helper name))
      (('identifier identifier) (helper identifier))
      ((? string?) o)



      (('action event) (make <action-node> #:event.name event))

      (('action port event) (make <action-node> #:port.name port #:event.name event))

      (('action port event arguments) (make <action-node> #:port.name port #:event.name event #:arguments (helper arguments)))

      (('arguments arguments ...) (make <arguments-node>
                                    #:elements (map helper arguments)))

      (('assign variable expression) (make <assign-node>
                                       #:variable.name variable
                                       #:expression (helper expression)))

      (('behaviour ('name name ...) body ...)
       (clone (helper (cons 'behaviour body))
              #:name (helper (cons 'name name))))

      (('behaviour body ...)
       (make <behaviour-node>
         #:types (helper (or (null-is-#f (assoc 'types body)) '(types)))
         #:ports (helper (or (null-is-#f (assoc 'ports body)) '(ports)))
         #:variables (helper (or (null-is-#f (assoc 'variables body)) '(variables)))
         #:functions (helper (or (null-is-#f (assoc 'functions body)) '(functions)))
         ;;#:statement (helper (and=> (find (sexp-is? 'statement) body) helper))
         #:statement (and=> (find (sexp-is? 'on) body) helper)))

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

      (('compound statements ...)
       (make <compound-node> #:elements (map helper statements)))

      (('data value) (make <data-node> #:value value))


      (('field-test identifier field) (make <field-test-node> #:variable.name identifier #:field field))


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


      (('instance name type) (make <instance-node> #:name name #:type.name (helper type)))

      (('instances instances ...)
       (make <instances-node> #:elements (map helper instances)))


      (('enum-literal name field) (make <enum-literal-node> #:type.name (helper name) #:field field))

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

      (('location pos end)
       (receive
        (line column) (line-column pos #t)
        (receive
         (end-line end-column) (line-column end #f)
         (make <location-node> #:file-name file-name #:line line #:column column #:end-line end-line #:end-column end-column #:offset pos #:length (- end pos)))))

      ((? (is? <ast>)) o)
      (_ (format #f "LITERAL: ~s\n" o))))
  (define (line-column pos skip?)
    (let* ((length (string-length string))
           (pos (if skip? pos
                    (let loop ((pos pos))
                      (if (and (< pos length) (char-whitespace? (string-ref string pos))) (loop (1+ pos)) pos)))))
      (let loop ((lines (string-split string #\newline)) (ln 1) (p 0))
      (if (null? lines) (values #f #f)
          (let* ((line (car lines))
                 (length (string-length line))
                 (end (+ p length 1)))
            (if (<= pos end) (values ln (- pos p))
                (loop (cdr lines) (1+ ln) end)))))))
  (or (as o <ast>)
      (helper o)))
