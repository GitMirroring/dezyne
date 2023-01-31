;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2019, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021, 2023 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2019 Johri van Eerd <vaneerd.johri@gmail.com>
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

(define-module (dzn parse ast)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 curried-definitions)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-43)
  #:use-module (srfi srfi-71)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn display)
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn parse)
  #:use-module (dzn parse silence)
  #:export (parse-tree->ast
            annotate-ast))

(define* (parse-tree->ast o #:key string (file-name "<stdin>") working-directory)
  "Return a root AST for parse-tree O."
  (define (make-list? o) (if (pair? o) o
                             (list o)))

  (define newlines ;; --> (vector (pos1 . pos2) (pos2+1 . pos3) ...) where posi is position of newline
    (let* ((last (string-length string))
           (lines (let loop ((current-pos 0) (result '()))
                    (let ((index (string-index string #\newline current-pos last)))
                      (if (not index) result
                          (loop (1+ index) (append result (list index)))))))
           (lines (let loop ((start 0) (todo lines) (result '()))
                    (if (null? todo) (cons (cons start last) result)
                        (loop (1+ (car todo)) (cdr todo) (cons (cons start (car todo)) result))))))
      (list->vector (reverse lines))))

  (define (compare-pos pos nl)
    (cond ((< (cdr pos) (car nl)) -1)
          ((> (car pos) (cdr nl)) 1)
          (else 0)))

  (define (line-number pos)
    (let ((index (vector-binary-search newlines (cons pos pos) compare-pos)))
      (if index (1+ index) (vector-length newlines))))

  (define (column-number line pos)
    (1+ (- pos (car (vector-ref newlines (1- line))))))

  (define (file-helper o file-name start-pos)

    (define (make-interface name types-and-events behavior comment)
      (let* ((types-and-events (helper types-and-events))
             (comments-t/e types-and-events
                           (partition (is? <comment-node>) types-and-events))
             (comment-t/e (and=> (as comments-t/e <pair>) car))
             (types events (partition (is? <type-node>) types-and-events))
             (types? (pair? types))
             (types (match types
                      ((type tail ...)
                       (cons (clone type #:comment comment-t/e) tail))
                      (_
                       types)))
             (types (make <types-node> #:elements types))
             (events (if types? events
                         (match events
                           ((event tail ...)
                            (cons (clone event #:comment comment-t/e) tail))
                           (_
                            events))))
             (events (make <events-node> #:elements events))
             (behavior (and behavior (annotate-functions (helper behavior)))))
        (make <interface-node>
          #:name (helper name)
          #:comment comment
          #:types types
          #:events events
          #:behavior behavior)))

    (define (comment-ast-list ast comment)
      (match (.elements ast)
        (((and (? (negate string?)) h) t ...)
         (let ((elements (cons (clone h #:comment comment) t)))
           (clone ast #:elements elements)))
        (_
         ast)))

    (define (comment-statement ast comment)
      (match ast
        (($ <compound>)
         (comment-ast-list ast comment))
        (_
         (clone ast #:comment comment))))

    (define (helper o)
      (let* ((ast location comment (strip o))
             (ast (if (and comment (is-a? ast <root-node>))
                      (clone ast #:comment comment)
                      ast)))
        (values ast location comment)))

    (define (strip o)
      "Strip comments and locations from the parse tree and add them as fields
to the AST element."
      (match o
        (((and (? symbol?) type) body ... (and ('location pos end) location))
         (let* ((ast x comment (strip (cons type body)))
                (location (and location (tree->ast location)))
                (ast (if (and location (is-a? ast <locationed-node>))
                         (clone ast #:location location)
                         ast)))
           (values ast location comment)))

        (((and (? symbol?) type) body ... (and ('comment c ...) comment))
         (let* ((comment (strip comment))
                (ast (tree->ast (cons type body) comment)))
           (cond ((is-a? ast <locationed-node>)
                  (clone ast #:comment comment))
                 ((is-a? ast <pair>)
                  (cons comment ast))
                 ((is-a? ast <ast-list-node>)
                  (comment-ast-list ast comment))
                 (else
                  ast))
           (values ast #f comment)))

        (((and (or 'root 'interface 'behavior 'component 'types 'events 'event)
               type) body ... (and (? string?) string))
         ;; FIXME: junking non-parsed STRING
         (values (tree->ast (cons type body)) #f #f))

        (((? symbol?) body ...)
         (values (tree->ast o) #f #f))

        ((or "in" "out" "inout")
         (values (string->symbol o) #f #f))

        ((and (? string?) (? string->number))
         (values (string->number o) #f #f))

        ((left (or "||" "&&" "+" "-" "-" "<" "<=" "==" "!=" ">" ">=") right)
         (values (tree->expression o) #f #f))

        ((or "bool" "void")
         (values o #f #f))

        ((h ...)
         (values (filter-map helper o) #f #f))

        (_
         (values o #f #f))))

    (define* (tree->ast o #:optional comment)
      (match o

        (('comment comment)
         (make <comment-node> #:string comment))

        (('elements elements ...)
         (helper elements))

        (('import name)
         (make <import-node> #:name (helper name)))

        (('namespace name root)
         (let* ((name location comment (helper name))
                (ids (.ids name))
                (elements (helper root)))
           (define (wrap-namespace name result)
             (let ((name (make <scope.name-node>
                           #:ids (list name)
                           #:comment comment
                           #:location location))
                   (elements (or (as result <null>)
                                 (as result <pair>)
                                 (list result))))
               (make <namespace-node>
                 #:name name
                 #:elements elements)))
           (fold-right wrap-namespace elements ids)))

        (('namespace-root elements ...)
         (map helper elements))

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

        (('interface name)
         (make <interface-node>
           #:name (helper name)
           #:comment comment))

        (('interface name (and ('types-and-events x ...) types-and-events))
         (make-interface name types-and-events #f comment))

        (('interface name (and ('behavior x ...) behavior comment))
         (make-interface name '() behavior comment))

        (('interface name types-and-events behavior)
         (make-interface name types-and-events behavior comment))

        (('types-and-events types-and-events ...)
         (helper types-and-events))

        (('event direction type name formals)
         (let* ((type location comment (helper type))
                (signature (make <signature-node>
                             #:type.name type
                             #:formals (helper formals)
                             #:location location)))
           (make <event-node>
             #:name (helper name)
             #:signature signature
             #:direction (helper direction))))

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
           #:comment comment
           #:name (helper name)
           #:ports (helper ports)))

        (('component name ports (and ('behavior elements ...) behavior))
         (make <component-node>
           #:comment comment
           #:name (helper name)
           #:ports (helper ports)
           #:behavior (annotate-functions (helper behavior))))

        (('component name ports ('system instances-and-bindings rest ...))
         (let* ((instances-and-bindings (helper instances-and-bindings))
                (instances
                 bindings (partition (is? <instance-node>) instances-and-bindings)))
           (make <system-node>
             #:comment comment
             #:name (helper name)
             #:ports (helper ports)
             #:instances (make <instances-node> #:elements instances)
             #:bindings (make <bindings-node> #:elements bindings))))

        (('instances-and-bindings instances-and-bindings ...)
         (helper instances-and-bindings))

        (('instance type name)
         (make <instance-node> #:name (helper name) #:type.name (helper type)))

        (('binding left right)
         (make <binding-node> #:left (helper left) #:right (helper right)))

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
                (type (helper type)))
           (make <port-node>
             #:name (helper name)
             #:type.name type
             #:direction direction)))

        (('port direction ('port-qualifiers qualifiers ...) type name)
         (let* ((direction (helper direction))
                (direction-list? (pair? direction))
                (type (helper type)))
           (make <port-node>
             #:name (helper name)
             #:type.name type
             #:direction direction
             #:blocking? (and=> (assq 'blocking-q qualifiers) helper)
             #:external? (and=> (assq 'external qualifiers) helper)
             #:injected? (and=> (assq 'injected qualifiers) helper))))

        (('port direction ('port-qualifiers qualifiers ...) type formals name)
         (let* ((direction (helper direction))
                (direction-list? (pair? direction))
                (formals (helper formals))
                (type (helper type))
                (type (async-interface-name type formals)))
           (make <port-node>
             #:name (helper name)
             #:type.name type
             #:formals formals
             #:direction direction
             #:blocking? (and=> (assq 'blocking-q qualifiers) helper)
             #:external? (and=> (assq 'external qualifiers) helper)
             #:injected? (and=> (assq 'injected qualifiers) helper))))

        (('provides) 'provides)
        (('requires) 'requires)
        (('blocking-q) 'blocking)
        (('external) 'external)
        (('injected) 'injected)

        (('declarative-compound 'behavior-statement-list)
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

        (('on triggers)
         (make <on-node> #:comment comment #:triggers (helper triggers)))

        (('on triggers statement)
         (make <on-node>
           #:comment comment
           #:triggers (helper triggers)
           #:statement (helper statement)))

        (('action-or-call action-or-call)
         (helper action-or-call))

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

        (('compound-name global scope name)
         (make <scope.name-node> #:ids (append (helper global) (helper scope) (list (helper name)))))

        (('scope name) (make-list? (helper name)))
        (('scope names ...) (helper names))

        (('global) '("/"))
        (('name name) (helper name))

        (('type-name name) (helper name))
        (('event-name name) (helper name))

        (('interface-action event)
         (make <action-node>
           #:event.name (helper event)))

        (('illegal)
         (make <illegal-node>))

        (('action port event)
         (make <action-node>
           #:port.name (helper port)
           #:event.name (helper event)))

        (('action port event arguments)
         (make <action-node>
           #:port.name (helper port)
           #:event.name (helper event)
           #:arguments (helper arguments)))

        (('assign var expression)
         (make <assign-node>
           #:variable.name (.name (helper var))
           #:expression (helper expression)))

        (('behavior-statements statement ...)
         (let ((statements (map helper statement)))
           (match statements
             ((h t ...)
              (cons (comment-statement h comment) t))
             (_
              statements))))

        (('behavior-compound statement)
         (make <compound-node> #:elements (helper statement)))

        (('behavior compound)
         (let ((compound (helper compound)))
           (make <behavior-node>
             #:types (make <types-node> #:elements (filter (is? <type-node>) (.elements compound)))
             #:ports (make <ports-node> #:elements (filter (is? <port-node>) (.elements compound)))
             #:variables (make <variables-node> #:elements (filter (is? <variable-node>) (.elements compound)))
             #:functions (make <functions-node> #:elements (filter (is? <function-node>) (.elements compound)))
             #:statement (clone compound #:elements (filter (conjoin (is? <statement-node>) (negate (is? <port-node>)) (negate (is? <variable-node>))) (.elements compound))))))

        (('behavior name compound)
         (let ((compound (helper compound)))
           (make <behavior-node>
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

        (('defer statement)
         (make <defer-node>
           #:statement (helper statement)))

        (('defer arguments statement)
         (make <defer-node>
           #:arguments (helper arguments)
           #:statement (helper statement)))

        (('arguments argument) (make <arguments-node> #:elements (list(helper argument))))
        (('arguments argument ...) (make <arguments-node> #:elements (helper argument)))
        (('argument expression) (helper expression))

        (('foreign name body ...)
         (make <foreign-node>
           #:name (helper name)
           #:ports (helper (or (assoc 'ports body) '(ports)))))

        (('compound statements ...)
         (make <compound-node> #:elements (helper statements)))

        (('dollars value) (make <data-node> #:value (helper value)))

        (('dollars) (make <data-node> #:value *unspecified*))

        (('field-test ('var name _ ...) field) (make <field-test-node> #:variable.name (helper name) #:field (helper field)))
        (('field-test ('unknown-identifier identifier _ ...) field) (make <field-test-node> #:variable.name identifier #:field (helper field)))

        (('function type name formals statement)
         (let* ((type location comment (helper type))
                (signature (make <signature-node>
                             #:type.name type
                             #:formals (helper formals)
                             #:location location)))
           (make <function-node>
             #:name (helper name)
             #:signature signature
             #:statement (helper statement))))

        (('functions functions ...)
         (make <functions-node> #:elements (helper functions)))

        (('guard expression)
         (make <guard-node>
           #:comment comment
           #:expression (helper expression)))

        (('guard expression statement)
         (make <guard-node>
           #:comment comment
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

        (('enum-literal type field)
         (let ((type (helper type)))
           (make <enum-literal-node> #:type.name (make <scope.name-node> #:ids type) #:field (helper field))))

        (('enum-literal global type field)
         (let ((type (append (helper global) (helper type))))
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
         (make <root-node> #:elements (make-list? (helper element)) #:working-directory working-directory))

        (('file-name file-name) (make <file-name> #:name file-name))

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
           (make <root-node> #:elements lst #:location location #:working-directory working-directory)))

        (('system name ports instances bindings)
         (make <system-node>
           #:name (helper name)
           #:ports (helper ports)
           #:instances (helper instances)
           #:bindings (helper bindings)))

        (('type name) (make <type-node> #:name (helper name)))

        (('types types ...) (make <types-node> #:elements (helper types)))

        (('unknown-identifier name) (make <undefined-node> #:name (helper name)))

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
        (('not expression) (make <not-node> #:expression (helper expression)))

        (('literal "true") (make <literal-node> #:value "true"))
        (('literal "false") (make <literal-node> #:value "false"))
        (('literal string) (make <literal-node> #:value (helper string)))

        (('location pos end)
         (let* ((start-line (line-number start-pos))
                (line (line-number pos))
                (column (column-number line pos))
                (end-line (line-number end))
                (end-column (column-number end-line end)))
           (make <location-node> #:file-name file-name #:line (1+ (- line start-line)) #:column column #:end-line (1+ (- end-line start-line)) #:end-column end-column #:offset (- pos start-pos) #:length (- end pos))))))

    (define (tree->expression o)
      (match o
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
        ((left ">=" right) (make <greater-equal-node> #:left (helper left) #:right (helper right)))))

    (helper o))

  (let* ((root-node (file-helper o file-name 0))
         (root (make <root> #:node root-node)))
    (tree-map make-namespaces root)))

(define-method (set-recursive (o <behavior>))
  (define (mark-recursive f)
    (if (ast:recursive? f) (clone f #:recursive? #t)
        f))
  (let* ((functions (.functions o))
         (function-list (.elements functions))
         (function-list (map mark-recursive function-list))
         (functions (clone functions #:elements function-list)))
    (clone o #:functions functions)))

(define-method (set-noisy (o <behavior>))
  (mark-noisy o))

(define-method (annotate-functions (o <behavior-node>))
  (let* ((o (set-recursive (make <behavior> #:node o)))
         (o (set-noisy o)))
   (.node o)))

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

(define (async-interface-name type formals)
  "Return a unique name for async TYPE, using the types of FORMALS."
  (let* ((scope (ast:scope type))
         (single (ast:name type))
         ;; FIXME: last??
         ;; Does 'last' mean that
         ;;   requires dzn.async(foo.T t) defer;
         ;;   requires dzn.async(bar.T t) defer;
         ;; are considered to be the same?
         ;; should they?
         ;; Why have (dzn async), (dzn async_T) at all, why don't we
         ;; (dzn async), (dzn async T)  (or dzn async foo T)
         (single (string-join (cons single (map (compose last .ids .type.name) (.elements formals))) "_")))
    (make <scope.name> #:ids (append scope (list single)))))

(define (make-async-refine-interface port)
  (let* ((void (make <scope.name> #:ids '("void")))
         (formals (.formals port))
         (signature (make <signature> #:type.name void #:formals formals))
         (true (make <literal> #:value "true"))
         (false (make <literal> #:value "false"))
         (name (.type.name port)))
    (make <interface>
      #:name name
      #:events (make <events> #:elements
                     (list (make <event> #:name "req" #:direction 'in #:signature signature)
                           (make <event> #:name "clr" #:direction 'in #:signature (make <signature> #:type.name void))
                           (make <event> #:name "ack" #:direction 'out #:signature signature)))
      #:behavior
      (make <behavior>
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

(define (annotate-ast root)
  "Return ROOT with synthesized elements, bool, void and async
interfaces."
  (define (async-port-equal? a b)
    (and
     (equal? (ast:full-name (.type.name a))
             (ast:full-name (.type.name b)))
     (every ast:equal?
            (map .type.name (ast:formal* a))
            (map (compose .type.name) (ast:formal* b)))))
  (let* ((types (list (make <bool>) (make <void>)))
         (components (filter (is? <component>) (ast:model* root)))
         (async-ports (append-map ast:async-port* components))
         (async-ports (delete-duplicates async-ports async-port-equal?))
         (async-interfaces (map make-async-refine-interface async-ports))
         (async-namespace (if (null? async-interfaces) '()
                              (list (make <namespace>
                                      #:name (make <scope.name> #:ids '("dzn"))
                                      #:elements async-interfaces)))))
    (clone root #:elements (append types async-namespace (.elements root)))))
