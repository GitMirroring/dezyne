;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  #:use-module (srfi srfi-26)

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
  (define (helper o)
    (match o

      ((? string?) (string->symbol o))

      (((and (? symbol?) type) body ... ('location pos end))
       (let ((ast (helper (cons type body)))
             (location (helper (last o))))
         (if (and location (or (is-a? ast <root-node>)
                               (is-a? ast <comment-node>)
                               (is-a? ast <named-node>)))
             (clone ast #:location location)
             ast)))

      (((and (? symbol?) type) body ... ('comment comment))
       (let ((ast (helper (cons type body))))
         (if (is-a? ast <ast-node>)
             (clone ast #:comment comment)
             ast))) ;; TODO ensure (is-a? ast <ast>) is invariant to prevent comment loss

      (('root elements)
       (make <root-node> #:elements (helper elements)))

      (('elements elements ...) (helper elements))

      (('import name)
       (make <import-node> #:name (helper name)))

      (('namespace name elements ...)
       (make <namespace-node>
         #:name (helper name)
         #:elements (helper elements)))

      (('enum name fields)
       (make <enum-node> #:name (helper name) #:fields (helper fields)))

      (('fields fields ...)
       (make <fields-node> #:elements (map helper fields)))

      (('fields field (fields ...))
       (make <fields-node> #:elements (helper (cons field fields))))

      (('int name range)
       (make <int-node> #:name (helper name) #:range (helper range)))

      (('range from to) (make <range-node> #:from from #:to to))

      (('extern name value)
       (make <extern-node> #:name (helper name) #:value value))


      (('interface name body ...)
       (let* ((sexp (helper (assoc 'types-or-events body))))
         (receive (events types) (partition (sexp-is? 'event) (.sexp sexp))
           (make <interface-node>
             #:name (helper name)
             #:types (helper (cons 'types types))
             #:events (helper (cons 'events events))
             #:behaviour (and=> (assoc 'behaviour body) helper)))))

      (('types-or-events types-or-events ...)
       (make <sexp-node> #:sexp types-or-events))

      (('events events ...)
       (make <events-node> #:elements (helper events)))

      (('event direction type name)
       (helper (append o '((formals)))))

      (('event direction type name formals)
       (make <event-node>
         #:name (helper name)
         #:signature (make <signature-node> #:type.name (helper type) #:formals (helper formals))
         #:direction (helper direction)))

      (('formal-list foo ...) #f) ;; TODO

      (('component name ports)
       (make <foreign-node>
         #:name (helper name)
         #:ports (helper ports)))

      (('component name ports (and ('behaviour elements ...) behaviour))
       (make <component-node>
         #:name (helper name)
         #:ports (helper ports)
         #:behaviour (helper behaviour)))

      (('component name ports ('system ('instances 'bindings) rest ...))
       (make <system-node>
         #:name (helper name)
         #:ports (helper ports)))

      (('component name ports ('system instances bindings rest ...))
       (make <system-node>
         #:name (helper name)
         #:ports (helper ports)
         #:instances (helper instances)
         #:bindings (helper bindings)))

      ('instances
       (make <instances-node>))

      (('instances elements ...)
       (make <instances-node> #:elements (helper elements)))

      ('bindings
       (make <bindings-node>))

      (('bindings elements ...)
       (make <bindings-node> #:elements (helper elements)))

      (('binding instance port)
       (make <binding-node> #:instance.name instance #:port.name port))

      ('ports (make <ports-node>))
      (('ports ports ...) (make <ports-node> #:elements (helper ports)))

      (('port direction type name external-injected ...)
       (make <port-node>
         #:name (helper name)
         #:type.name (helper type)
         #:direction (helper direction)
         #:external (find (lambda (x) (eq? x 'external)) external-injected)
         #:injected (find (lambda (x) (eq? x 'injected)) external-injected)))

      (('declarative-compound 'behaviour-statement-list)
       (make <error-node> #:message "empty declarative-compound"))

      (('skip-statement)
       (make <compound-node>))

      (('compound)
       (make <compound-node>))

      (('compound body ...)
       (let ((body (helper body)))
         (make (if (is-a? (car body) <declarative>) <declarative-compound-node>
                   <compound-node>)
           #:elements body)))

      (('on triggers statement)
       (make <on-node> #:triggers (helper triggers) #:statement (helper statement)))

      (('action-or-call action-or-call)
       (let ((action-or-call (helper action-or-call)))
         (make <action-node> #:port.name (.scope action-or-call) #:event.name (.name action-or-call))))


      (('triggers triggers ...)
       (make <triggers-node> #:elements (helper triggers)))

      (('trigger event)
       (make <trigger-node> #:event.name (helper event)))

      (('trigger port event)
       (make <trigger-node> #:port.name (helper port) #:event.name (helper event)))


      (('direction direction) (helper direction))

      (('port-direction direction) (helper direction))


      (('compound-name name)
       (make <scope.name-node> #:name (helper name)))

      (('compound-name scope name)
       (make <scope.name-node> #:scope (helper scope) #:name (helper name)))

      (('name name) (helper name))

      (('type-name name) (make <type-node> #:name (helper name)))
      (('event-name name) (helper name))
      (('identifier identifier) (helper identifier))

      (('interface-action event) (make <action-node> #:event.name (helper event)))

      (('illegal) (make <illegal-node>))

      (('action port event) (make <action-node> #:port.name (helper port) #:event.name (helper event)))

      (('action port event arguments) (make <action-node> #:port.name (helper port) #:event.name (helper event) #:arguments (helper arguments)))

      (('arguments arguments ...) (make <arguments-node>
                                    #:elements (helper arguments)))

      (('assign var expression) (make <assign-node>
                                  #:variable.name (helper var)
                                  #:expression (helper expression)))

      (('behaviour-compound statement ...)
       (make <compound-node> #:elements (helper statement)))

      (('behaviour compound)
       (let ((compound (helper compound)))
         (make <behaviour-node>
           #:types (make <types-node> #:elements (filter (is? <type-node>) (.elements compound)))
           #:ports (make <ports-node> #:elements (filter (is? <port-node>) (.elements compound)))
           #:variables (make <variables-node> #:elements (filter (is? <variable-node>) (.elements compound)))
           #:functions (make <functions-node> #:elements (filter (is? <function-node>) (.elements compound)))
           #:statement (clone compound #:elements (filter (is? <statement-node>) (.elements compound))))))

      (('bind left right)
       (make <bind-node> #:left (helper left) #:right (helper right)))


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
       (make <compound-node> #:elements (helper statements)))

      (('data value) (make <data-node> #:value value))


      (('field-test identifier field) (make <field-test-node> #:variable.name identifier #:field field))


      (('function name signature recursive? statement)
       (make <function-node>
         #:name name
         #:signature (helper signature)
         #:recursive recursive?
         #:statement (helper statement)))

      (('functions functions ...)
       (make <functions-node> #:elements (helper functions)))

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

      (('instance name type) (make <instance-node> #:name name #:type.name (helper type)))

      (('instances instances ...)
       (make <instances-node> #:elements (helper instances)))


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
       (make <formals-node> #:elements (helper formals)))



      (('reply expression) (make <reply-node> #:expression (helper expression)))

      (('reply expression port) (make <reply-node> #:expression (helper expression) #:port.name port))

      (('return) (make <return-node>))

      (('return expression) (make <return-node> #:expression (helper expression)))

      (('root elements ...) (make <root-node> #:elements (helper elements)))

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

      (('types types ...) (make <types-node> #:elements (helper types)))

      (('var name) (make <var-node> #:variable.name (helper name)))

      (('variable type name)
       (make <variable-node> #:name (helper name) #:type.name (helper type) #:expression (make <expression-node>)))

      (('variable type name expression)
       (make <variable-node> #:name (helper name) #:type.name (helper type) #:expression (helper expression)))

      (('variables variables ...)
       (make <variables-node> #:elements (helper variables)))

      ((left '<- right) (make <formal-binding> #:formal (helper left) #:name (helper right)))

      ((or 'bool 'void) o)

      ((left "or" right) (make <or-node> #:left (helper left) #:right (helper right)))
      ((left "and" right) (make <and-node> #:left (helper left) #:right (helper right)))

      ((left "+" right) (make <plus-node> #:left (helper left) #:right (helper right)))
      ((left "-" right) (make <minus-node> #:left (helper left) #:right (helper right)))
      ((left "<" right) (make <less-node> #:left (helper left) #:right (helper right)))
      ((left "<=" right) (make <less-equal-node> #:left (helper left) #:right (helper right)))
      ((left "==" right) (make <equal-node> #:left (helper left) #:right (helper right)))
      ((left "!=" right) (make <not-equal-node> #:left (helper left) #:right (helper right)))
      ((left ">"  right) (make <greater-node> #:left (helper left) #:right (helper right)))
      ((left ">=" right) (make <greater-equal-node> #:left (helper left) #:right (helper right)))
      (("!" expression) (make <not-node> #:expression (helper expression)))

      (('literal "true") (make <literal-node> #:value 'true))
      (('literal "false") (make <literal-node> #:value 'false))
      (('literal number-string) (make <literal-node> #:value (string->number number-string)))

      (('location pos end)
       (receive
           (line column) (line-column pos #t)
         (receive
             (end-line end-column) (line-column end #f)
           (make <location-node> #:file-name file-name #:line line #:column column #:end-line end-line #:end-column end-column #:offset pos #:length (- end pos)))))

      ((? (is? <ast>)) o)

      ((h ...) (filter-map helper o))
      (_ (format #f "LITERAL: \"~s\"" o))))

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
      (let* ((p (helper o))
             (l (tree-collect (negate (is? <ast-node>)) p)))
        (when (pair? l)
          (display "pt:\n")
          (pretty-print (om->list o))
          (newline)

          (display "ast:\n")
          (pretty-print (om->list p))
          (newline)
          (throw 'ast-is-not-fully-goopsy l))
        p)))
