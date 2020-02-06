;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag parse ast)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 curried-definitions)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag display)
  #:use-module (gaiag ast)
  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  ;;#:use-module (gaiag parse)
  #:use-module (gaiag parse peg)
  #:use-module (gaiag parse silence)
  #:export (parse-tree->ast
            parse-root->ast))

(define (ast-> o)
  ((compose
    pretty-print
    om->list
    ) o))

(define* (parse-tree->ast o #:key string (file-name "<stdin>"))
  (define async-interfaces
    (let ((interfaces '()))
      (lambda (command . rest)
        (case command
          ((add) (unless (find
                          (lambda (x) (equal? (ast:scope x) (ast:scope (car rest))))
                          interfaces)
                   (set! interfaces (append interfaces rest) )))
          ((get) interfaces)))))
  (define (make-list? o) (if (pair? o) o
                             (list o)))
  (define (file-helper o file-name start-pos)
    (define (get-location o)
      (match o
        (((and (? symbol?) type) body ... ('location pos end))
         (let* ((ast (helper (cons type body)))
                (location (helper (last o)))
                (location (if (and (is-a? ast <root-node>)
                                   (.location ast)) (clone location #:file-name (.file-name (.location ast)))
                              location)))
           location))
        (_ #f)))
    (define (helper o)
      (match o
        ;; ("bool" (make <scope.name-node> #:ids '("bool")))
        ;; ("void" (make <scope.name-node> #:ids '("void")))
        ("bool" "bool")
        ("void" "void")

        ("in" 'in)
        ("out" 'out)
        ("inout" 'inout)

        ((and (? string?) (? string->number)) (string->number o))

        ((? string?) o)

        (((and (? symbol?) type) body ... ('comment comment))
         (let ((ast (helper (cons type body))))
           ast)) ;; TODO ensure (is-a? ast <ast>) is invariant to prevent comment loss

        (((and (? symbol?) type) body ... ('location pos end))
         (let* ((ast (helper (cons type body)))
                (location (helper (last o)))
                (location (if (and (is-a? ast <root-node>)
                                   (.location ast)) (clone location #:file-name (.file-name (.location ast)))
                                   location)))
           (if (and location (or (is-a? ast <locationed-node>)))
               (clone ast #:location location)
               ast)))

        (((and (or 'root 'interface 'behaviour 'component 'types 'events 'event) type) body ... (? string?))
         ;; FIXME: junking non-comment-parsed string
         (helper (cons type body)))

        (('comment comment)
         (make <comment-node> #:comment comment))

        (('elements elements ...) (helper elements))

        (('import name #f)
         (make <import-node> #:name (helper name) #:root (make <root-node>)))

        (('import name root)
         (make <import-node> #:name (helper name) #:root (helper root)))

        (('namespace name)
         (make <namespace-node>
           #:name (helper name)))

        (('namespace name elements)
         (make <namespace-node>
           #:name (helper name)
           #:elements (make-list? (helper elements))))

        (('enum name fields)
         (make <enum-node> #:name (helper name) #:fields (helper fields)))

        (('fields names ...)
         (make <fields-node> #:elements (helper names)))

        (('int name range)
         (make <int-node> #:name (helper name) #:range (helper range)))

        (('range from to) (make <range-node> #:from (helper from) #:to (helper to)))

        (('from string) (string->number string))
        (('to string) (string->number string))

        (('extern name)
         (make <extern-node> #:name (helper name)))

        (('extern name data)
         (make <extern-node> #:name (helper name) #:value (helper data)))

        (('interface name types-or-events behaviour)
         (let* ((types-or-events (helper types-or-events))
                (types (filter (is? <type-node>) types-or-events))
                (events (filter (is? <event-node>) types-or-events))
                (behaviour (set-recursive (helper behaviour))))
           (make <interface-node>
             #:name (helper name)
             #:types (make <types-node> #:elements types)
             #:events (make <events-node> #:elements events)
             #:behaviour (and behaviour (.node ((mark-silent) (make <behaviour> #:node behaviour)))))))

        (('types-or-events types-or-events ...) (helper types-or-events))

        (('event direction type name formals)
         (make <event-node>
           #:name (helper name)
           #:signature (make <signature-node> #:type.name (helper type) #:formals (helper formals) #:location (get-location type))
           #:direction (helper direction)))

        (('formals formal) (make <formals-node> #:elements (list (helper formal))))
        (('formals formals ...) (make <formals-node> #:elements (helper formals)))
        (('formal name)
         (make <formal-node> #:name (helper name)))

        (('formal type name)
         (make <formal-node> #:name (helper name) #:type.name (helper type)))

        (('formal direction type name)
         (make <formal-node> #:name (helper name) #:type.name (helper type) #:direction (helper direction)))


        (('trigger-formals formal) (make <formals-node> #:elements (list (helper formal))))
        (('trigger-formals formals ...) (make <formals-node> #:elements (helper formals)))
        (('trigger-formal name) (make <formal-node> #:name (helper name)))
        (('trigger-formal var-a ('var var-b _ ...)) (make <formal-binding-node> #:name (helper var-a) #:variable.name (helper var-b)))

        (('component name ports)
         (make <foreign-node>
           #:name (helper name)
           #:ports (helper ports)))

        (('component name ports (and ('behaviour elements ...) behaviour))
         (make <component-node>
           #:name (helper name)
           #:ports (helper ports)
           #:behaviour (set-recursive (helper behaviour))))

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

        (('binding left right)
         (make <binding-node> #:left (helper left) #:right (helper right)))

        ;; (('end-point)
        ;;  (make <end-point-node> #:port.name "*"))

        (('end-point "*")
         (make <end-point-node> #:port.name "*"))

        (('end-point name "*")
         (let* ((name (helper name))
                (ids (.ids name))
                (instance (and (pair? (cdr ids)) (car ids))))
           (make <end-point-node> #:instance instance #:port.name "*")))

        (('end-point name)
         (let* ((name (helper name))
                (ids (.ids name))
                (instance (and (pair? (cdr ids)) (car ids)))
                (port (if (pair? (cdr ids)) (cadr ids) (car ids))))
           (make <end-point-node> #:instance.name instance #:port.name port)))

        ('ports (make <ports-node>))
        (('ports ports ...) (make <ports-node> #:elements (helper ports)))

        (('port direction type name)
         (let* ((direction (helper direction))
                (direction-list? (pair? direction))
                (type (helper type))
                (async? (equal? (.ids type) '("dzn" "async")))
                (async-interface (and async? (make-async-refine-interface type (make <formals>))))
                (type (if async-interface (.name async-interface) type)))
           (when async?
             (async-interfaces 'add async-interface))
           (make <port-node>
             #:name (helper name)
             #:type.name type
             #:direction (if direction-list? (car direction) direction)
             #:external (and direction-list? (find (lambda (x) (eq? x 'external)) direction))
             #:injected (and direction-list? (find (lambda (x) (eq? x 'injected)) direction)))))

        (('port direction type formals name)
         (let* ((direction (helper direction))
                (direction-list? (pair? direction))
                (type (helper type))
                (formals (helper formals))
                (async-interface (make-async-refine-interface type formals)))
           (async-interfaces 'add async-interface)
           (make <port-node>
             #:name (helper name)
             #:type.name (.name async-interface)
             #:direction (if direction-list? (car direction) direction)
             #:external (and direction-list? (find (lambda (x) (eq? x 'external)) direction))
             #:injected (and direction-list? (find (lambda (x) (eq? x 'injected)) direction)))))

        (('provides) 'provides)
        (('requires) 'requires)
        (('external) 'external)
        (('injected) 'injected)

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
           (make <action-node> #:port.name (car (.ids action-or-call)) #:event.name (cadr (.ids action-or-call)))))

        (('triggers triggers ...)
         (make <triggers-node> #:elements (helper triggers)))

        (('illegal-triggers triggers ...)
         (make <triggers-node> #:elements (helper triggers)))

        (('trigger event-name)
         (make <trigger-node> #:event.name (helper event-name)))

        (('trigger port-name event-name formals)
         (make <trigger-node> #:event.name (helper event-name) #:port.name (helper port-name) #:formals (helper formals)))

        (('illegal-trigger event-name)
         (make <trigger-node> #:event.name (helper event-name)))

        (('illegal-trigger port-name event-name formals)
         (make <trigger-node> #:event.name (helper event-name) #:port.name (helper port-name) #:formals (helper formals)))

        (('illegal-trigger port-name event-name)
         (make <trigger-node> #:event.name (helper event-name) #:port.name (helper port-name)))

        (('direction direction) (helper direction))

        (('compound-name name)
         (make <scope.name-node> #:ids (list (helper name))))

        (('compound-name scope name)
         (make <scope.name-node> #:ids (append (helper scope) (list (helper name)))))

        (('scope ('global rest ...) names) (cons "/" (make-list? (helper names))))
        (('scope name) (make-list? (helper name)))
        (('scope names ...) (helper names))

        (('name name) (helper name))
        (('add-var name) (helper name))

        (('type-name name) (helper name))
        (('event-name name) (helper name))
        (('identifier identifier) (helper identifier))

        (('interface-action event) (make <action-node> #:event.name (helper event)))

        (('illegal) (make <illegal-node>))

        (('action (port event)) (make <action-node> #:port.name (helper port) #:event.name (helper event)))

        (('action (port event) arguments) (make <action-node> #:port.name (helper port) #:event.name (helper event) #:arguments (helper arguments)))

        (('action port event) (make <action-node> #:port.name (helper port) #:event.name (helper event)))

        (('action port event arguments) (make <action-node> #:port.name (helper port) #:event.name (helper event) #:arguments (helper arguments)))

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
             #:statement (clone compound #:elements (filter (conjoin (is? <statement-node>) (negate (is? <port-node>)) (negate (is? <variable-node>))) (.elements compound))))))

        (('behaviour name compound)
         (let ((compound (helper compound)))
           (make <behaviour-node>
             #:types (make <types-node> #:elements (filter (is? <type-node>) (.elements compound)))
             #:ports (make <ports-node> #:elements (filter (is? <port-node>) (.elements compound)))
             #:variables (make <variables-node> #:elements (filter (is? <variable-node>) (.elements compound)))
             #:functions (make <functions-node> #:elements (filter (is? <function-node>) (.elements compound)))
             #:statement (clone compound #:elements (filter (conjoin (is? <statement-node>) (negate (is? <port-node>)) (negate (is? <variable-node>))) (.elements compound))))))

        (('blocking statement) (make <blocking-node> #:statement (helper statement)))

        (('interface-call function) (make <call-node> #:function.name (helper function)))
        (('call function) (make <call-node> #:function.name (helper function)))

        (('call function arguments)
         (make <call-node>
           #:function.name (helper function)
           #:arguments (helper arguments)))


        (('arguments argument) (make <arguments-node> #:elements (list(helper argument))))
        (('arguments argument ...) (make <arguments-node> #:elements (helper argument)))
        (('argument expression) (helper expression))

        (('foreign name body ...)
         (make <foreign-node>
           #:name (helper name)
           #:ports (helper (or (null-is-#f (assoc 'ports body)) '(ports)))))

        (('compound statements ...)
         (make <compound-node> #:elements (helper statements)))

        (('data value) (make <data-node> #:value (helper value)))

        (('data) (make <data-node> #:value *unspecified*))

        (('field-test ('var identifier _ ...) field) (make <field-test-node> #:variable.name identifier #:field (helper field)))

        (('function type name formals)
         (make <function-node>
           #:name (helper name)
           #:signature (make <signature-node> #:type.name (helper type) #:formals (helper formals) #:location (get-location type))
           #:statement (make <compound-node>)))

        (('function type name formals statement)
         (let ((name (helper name))
               (statement (make <compound-node> #:elements (make-list? (helper statement)))))
           (make <function-node>
             #:name name
             #:signature (make <signature-node> #:type.name (helper type) #:formals (helper formals) #:location (get-location type))
             #:statement statement)))

        (('functions functions ...)
         (make <functions-node> #:elements (helper functions)))

        (('guard expression statement)
         (make <guard-node>
           #:expression (helper expression)
           #:statement (helper statement)))

        (('if-statement expression then)
         (make <if-node>
           #:expression (helper expression)
           #:then (helper then)))

        (('if-statement expression then else)
         (make <if-node>
           #:expression (helper expression)
           #:then (helper then)
           #:else (helper else)))

        (('instance type name) (make <instance-node> #:name (helper name) #:type.name (helper type)))

        (('instances instances ...)
         (make <instances-node> #:elements (helper instances)))

        (('enum-literal type field)
         (let ((type (helper type)))
           (make <enum-literal-node> #:type.name (make <scope.name-node> #:ids type) #:field (helper field))))

        (('otherwise) (make <otherwise-node> #:value "otherwise"))

        (('otherwise value) (make <otherwise-node> #:value value))

        (('reply port "reply") (make <reply-node> #:port.name (helper port)))
        (('reply port "reply" expression) (make <reply-node> #:port.name (helper port) #:expression (helper expression)))
        (('reply "reply" expression) (make <reply-node> #:expression (helper expression)))
        (('reply "reply") (make <reply-node> #:expression (make <literal-node>)))

        (('return) (make <return-node>))

        (('return expression) (make <return-node> #:expression (helper expression)))

        (('root element)
         (make <root-node> #:elements (make-list? (helper element))))

        (('root elements ...)
         (let* ((lst (let loop ((elements elements) (file-name file-name) (start-pos 0))
                       (if (null? elements) '()
                           (let* ((elt (car elements))
                                  (rest (cdr elements)))
                             (match elt
                               (((or 'file-command 'imported-command) file-name location)
                                (let ((start-pos (1+ (third location))))
                                  (loop rest file-name start-pos)))
                               (_ (cons (file-helper elt file-name start-pos)
                                        (loop rest file-name start-pos))))))))
                (location (match elements
                            ((('file-command file-name location) rest ...)
                             (make <location-node> #:file-name file-name))
                            (_ #f))))
           (make <root-node> #:elements lst #:location location)))

        (('system name ports instances bindings)
         (make <system-node>
           #:name (helper name)
           #:ports (helper ports)
           #:instances (helper instances)
           #:bindings (helper bindings)))

        (('type name) (make <type-node> #:name (helper name)))

        (('types types ...) (make <types-node> #:elements (helper types)))

        (('var name) (make <var-node> #:name (helper name)))

        (('variable type name)
         (make <variable-node> #:name (helper name) #:type.name (helper type) #:expression (make <literal-node>)))

        (('variable type name expression)
         (make <variable-node> #:name (helper name) #:type.name (helper type) #:expression (helper expression)))

        (('variables variables ...)
         (make <variables-node> #:elements (helper variables)))

        (('expression expression) (helper expression))
        (('expression expression ...) (helper expression))
        (('group expression) (make <group-node> #:expression (helper expression)))
        ((left "||" right) (make <or-node> #:left (helper left) #:right (helper right)))
        ((left "&&" right) (make <and-node> #:left (helper left) #:right (helper right)))

        ((left "+" right) (make <plus-node> #:left (helper left) #:right (helper right)))
        ((left "-" right) (make <minus-node> #:left (helper left) #:right (helper right)))
        ((left "-" right) (make <minus-node> #:left (helper left) #:right (helper right)))
        ((left "<" right) (make <less-node> #:left (helper left) #:right (helper right)))
        ((left "<=" right) (make <less-equal-node> #:left (helper left) #:right (helper right)))
        ((left "==" right) (make <equal-node> #:left (helper left) #:right (helper right)))
        ((left "!=" right) (make <not-equal-node> #:left (helper left) #:right (helper right)))
        ((left ">"  right) (make <greater-node> #:left (helper left) #:right (helper right)))
        ((left ">=" right) (make <greater-equal-node> #:left (helper left) #:right (helper right)))
        (('not expression) (make <not-node> #:expression (helper expression)))

        (('literal "true") (make <literal-node> #:value "true"))
        (('literal "false") (make <literal-node> #:value "false"))
        (('literal string) (make <literal-node> #:value (helper string)))

        (('location pos end)
         (let* ((start-line (peg:line-number string start-pos))
                (line (peg:line-number string  pos))
                (column (peg:column-number string pos))
                (end-line (peg:line-number string end))
                (end-column (peg:column-number string end)))
           (make <location-node> #:file-name file-name #:line (1+ (- line start-line)) #:column column #:end-line (1+ (- end-line start-line)) #:end-column end-column #:offset (- pos start-pos) #:length (- end pos))))

        ((? (is? <ast>)) o)

        ((h ...) (filter-map helper o))
        (_ (format #f "LITERAL: \"~s\"" o))))
    (helper o))

  (when (> (gdzn:debugity) 1)
    (pretty-print o))

  (let* ((root-node (file-helper o file-name 0))
         (elements (append (async-interfaces 'get) (.elements root-node)))
         (root (make <root> #:node (clone root-node #:elements elements)))
         (imports (tree-collect (is? <import>) root))
         (root (clone root
                      #:elements (filter (negate (is? <import>))
                                         (append (.elements root)
                                                 (append-map (compose .elements .root) imports))))))
    (tree-map make-namespaces root)))

(define* (parse-root->ast o #:key string (file-name "<stdin>"))
  (let* ((root (parse-tree->ast o #:string string #:file-name file-name))
         (elements (append (make-constants) (.elements root))))
    (clone root #:elements elements)))

(define* (recurses? behaviour function #:optional (seen '()))
  (define (return-call ast)
    (match ast
      (($ <call>) ast)
      ((and ($ <assign>) (? (compose (is? <call>) .expression)) (= .expression call)) call)
      ((and ($ <variable>) (? (compose (is? <call>) .expression)) (= .expression call)) call)
      (_ #f)))
  (define (.function-name call)
    (or (and=> (as (.function call) <function>) .name) ""))
  (or (member (.name function) seen)
      (let* ((compound (.statement function))
             (calls (tree-collect return-call compound))
             (names (delete-duplicates (sort (map (compose .function-name return-call) calls)
                                             string<))))
        (any identity
             (map (lambda (n)
                    (let ((fn (ast:lookup behaviour n)))
                      (and fn (recurses? behaviour fn (cons (.name function) seen)))))
                  names)))))

(define-method (set-recursive (o <behaviour>))
  (let* ((functions (.functions o))
         (function-list (.elements functions))
         (function-list (map (lambda (f) (if (recurses? o f) (clone f #:recursive #t) f))
                              function-list))
         (functions (clone functions #:elements function-list)))
    (clone o #:functions functions)))

(define-method (set-recursive (o <behaviour-node>))
  (.node (set-recursive (make <behaviour> #:node o))))


(define-method (make-namespaces (o <ast>))
  o)

(define-method (make-namespaces (o <model>))
  (let ((scope (ast:scope o)))
    (let loop ((scope scope))
      (if (null? scope) o
          (make <namespace> #:name (make <scope.name> #:ids (list (car scope))) #:elements (list (loop (cdr scope))))))))

(define-method (make-namespaces (o <type>))
  (if (parent o <model>) o
      (let ((scope (ast:scope o)))
        (let loop ((scope scope))
          (if (null? scope) o
              (make <namespace> #:name (make <scope.name> #:ids (list (car scope))) #:elements (list (loop (cdr scope)))))))))

(define (make-async-refine-interface name formals)
  (let* ((void (make <scope.name> #:ids '("void")))
         (signature (make <signature> #:type.name void #:formals formals))
         (true (make <literal> #:value "true"))
         (false (make <literal> #:value "false"))
         (scope (ast:scope name))
         (single (ast:name name))
         (single (string-join (cons single (map (compose last .ids .type.name) (.elements formals))) "_"))
         (name (make <scope.name> #:ids (append scope (list single)))))
    (make <interface>
      #:name name
      #:events (make <events> #:elements
                     (list (make <event> #:name "req" #:direction 'in #:signature signature)
                           (make <event> #:name "clr" #:direction 'in #:signature (make <signature> #:type.name void))
                           (make <event> #:name "ack" #:direction 'out #:signature signature)))
      #:behaviour
      (make <behaviour>
        #:variables (make <variables>
                      #:elements (list (make <variable> #:type.name "bool" #:name "idle" #:expression true)))
        #:statement
        (make <compound>
          #:elements
          (list
           (make <guard>
             #:expression (make <var> #:name "idle")
             #:statement
             (make <compound>
               #:elements
               (list
                (make <on> #:triggers (make <triggers> #:elements (list (make <trigger> #:event.name "req")))
                      #:statement (make <assign> #:variable.name "idle" #:expression false))
                (make <on> #:triggers (make <triggers> #:elements (list (make <trigger> #:event.name "clr")))
                      #:statement (make <compound>)))))
           (make <guard>
             #:expression (make <not> #:expression (make <var> #:name "idle"))
             #:statement
             (make <compound>
               #:elements
               (list
                (make <on> #:triggers (make <triggers> #:elements (list (make <trigger> #:event.name "clr")))
                      #:statement (make <assign> #:variable.name "idle" #:expression true))
                (make <on> #:triggers (make <triggers> #:elements (list (make <trigger> #:event.name "inevitable")))
                      #:statement
                      (make <compound>
                        #:elements
                        (list
                         (make <action> #:event.name "ack")
                         (make <assign> #:variable.name "idle" #:expression true)))))))))))))
