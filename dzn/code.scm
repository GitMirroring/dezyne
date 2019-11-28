;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2016, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2016, 2017, 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
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

(define-module (dzn code)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn misc)
  #:use-module (dzn command-line)
  #:use-module (dzn config)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn shell-util)
  #:use-module (dzn config)

  #:use-module (dzn ast)
  #:use-module (dzn code dzn)
  #:use-module (dzn normalize)
  #:use-module (dzn templates)


  #:export (injected-bindings
            injected-instances
            non-injected-instances
            injected-instance-name

            code:header?
            code:language
            code:instance-name
            code:skel-file

            code:add-calling-context
            code:add-calling-context-formal
            code:add-calling-context-argument

            code:class-member?
            code:enum-definer
            code:global-enum-definer
            code:enum-name
            code:enum-short-name
            code:expression
            code:trigger
            code:injected-instances
            code:instance*
            code:name
            code:non-injected-bindings
            code:injected-instances-system
            code:name.name
            code:ons
            code:port-release
            code:functions
            code:port-name
            code:instance-port-name
            code:instances
            code:pump?
            code:reply
            code:reply-type
            code:reply-scope+name
            code:reply-types
            code:scope+name
            code:trace-q-out

            code:file-name
            code:dump
            code:declarative-or-imperative
            code:extension
            code:dump-main
            code:model
            code:module
            code:om
            code:port-type
            code:enum-field-definer
            symbol->enum-field

            code:arguments
            code:assign-reply
            code:bind-provided
            code:bind-required
            code:component-include
            code:component-port
            code:dzn-locator
            code:enum-literal
            code:enum-scope
            code:expand-on
            code:file-name
            code:formals
            code:functions
	    code:function-type
            code:injected-instances
            code:injected-instances-system
            code:instance-name
            code:instance-port-name
            code:interface-include
            code:main-event-map-match-return
            code:main-out-arg
            code:main-out-arg-define
            code:non-injected-bindings
            code:ons
            code:out-argument
            code:parameters
            code:port-name
            code:port-type
            code:reply-type
            code:reply-types
            code:return
            code:scope+name
            code:scope-type-name
            code:trigger
            code:type-name
            code:used-foreigns
            code:upcase-model-name
            code:variable-name
            code:variable->argument
            code:x-header-
            code:root->

            om:port-bind?
            %x:header
            %x:main
            ))

(define %x:header (make-parameter #f))
(define %x:main (make-parameter #f))

(define (ast-> ast)
  (let ((root (code:om ast)))
    (code:root-> root))
  "")

(define (code:root-> root)
  (code:dump root)
  (code:dump-main root))

(define-method (code:dump-main (root <root>))
  (let ((main (command-line:get 'model #f)))
    (when main
      (let* ((main-name (string-split main #\.))
             (main-model (ast:lookup root (make <scope.name> #:ids main-name))))
        ;; FIXME: error if not found?
        (and=> main-model code:dump-main)))))

(define (code:component-include o)
 (filter (disjoin
          (compose (is? <foreign>) .type)
          (conjoin (compose ast:imported? .type) (lambda (i) (not (equal? (ast:source-file o)
                                                                          (ast:source-file (.type i)))))))
         (ast:instance* o)))

(define (code:language)
  (command-line:get 'language "c++"))

;;; ast accessors
(define-method (code:instance* (o <system>))
  (ast:instance* o))
(define-method (code:instance* o)
  '())

(define (om:port-bind? bind)
  (and (om:port-binding? bind)
       bind))

(define (om:port-binding? bind)
  (or (and (not (.instance.name (.left bind)))
           (.left bind))
      (and (not (.instance.name (.right bind)))
           (.right bind))))

(define (om:port-bind system port)
  (find (lambda (bind) (and=> (om:port-bind? bind)
                              (lambda (b)
				(ast:equal? (.port (om:port-binding? b)) port))))
        (ast:binding* system)))

(define (om:bind system o)
  (let* ((binds (ast:binding* system)))
    (match o
      ((? string?) ;; FIXME: port need not be unique
       (error "obsolete code")
       (find (lambda (bind) (or (ast:equal? (.port.name (.left bind)) o)
                                (ast:equal? (.port.name (.right bind)) o)))
           binds))
      ((and ($ <end-point>) (= .instance.name instance-name) (= .port.name port-name))
       (find (lambda (bind)
               (or (and (equal? (.instance.name (.left bind)) instance-name)
                                     (equal? (.port.name (.left bind)) port-name))
                                (and (equal? (.instance.name (.right bind)) instance-name)
                                     (equal? (.port.name (.right bind)) port-name))))
             binds)))))

(define (injected-binding? binding)
  (or (equal? "*" (.port.name (.left binding)))
      (equal? "*" (.port.name (.right binding)))))

(define (injected-binding binding)
  (cond ((equal? "*" (.port.name (.left binding))) (.right binding))
        ((equal? "*" (.port.name (.right binding))) (.left binding))
        (else #f)))

(define (injected-bindings model)
  (filter injected-binding? (ast:binding* model)))

(define (injected-instance-name binding)
  (or (.instance.name (.left binding)) (.instance.name (.right binding))))

(define (injected-instances model)
  (let ((injected-instance-names (map injected-instance-name (injected-bindings model))))
    (filter (lambda (instance) (member (.name instance) injected-instance-names))
            (ast:instance* model))))

(define (non-injected-instances model)
  (let ((injected-instance-names (map injected-instance-name (injected-bindings model))))
    (filter (lambda (instance) (not (member (.name instance) injected-instance-names)))
            (ast:instance* model))))

(define-method (code:dzn-locator (o <instance>)) ;; MORTAL SIN HERE!!?
  (let* ((model (parent o <model>)))
    (if (null? (injected-bindings model)) ""
        "_local")))

(define-method (code:name (o <binding>))
  (injected-instance-name o))

(define-method (code:class-member? (o <variable>))
  (dzn:class-member? o))

(define-method (code:port-type (o <trigger>))
  ((compose code:port-type .port) o))

(define-method (code:port-type (o <port>))
  (ast:full-name (.type o)))

(define-method (code:fullscope (o <ast>))

  (define (name o)
    (let ((n (.name o)))
      (if (is-a? n <scope.name>) (ast:name n) n)))

  (define (fullscope o)
    (let ((p (.parent o)))
     (match p
       (($ <root>) '())
       (($ <namespace>) (append (fullscope p) (list (name p))))
       ((? (is? <model>)) (append (fullscope p) (list (name p))))
       (_ (fullscope p)))))

  (let ((scope (fullscope o)))
    (unless (every string? scope)
      (throw 'scope 'not-string scope))
    scope))

(define-method (code:scope+name o) ;; REMOVEME
  (match o
    (($ <bool>) '("bool"))
    (($ <void>) '("void"))
    (($ <event>) ((compose code:scope+name .signature) o))
    (($ <formal>) ((compose code:scope+name .type.name) o))
    (($ <instance>) (code:scope+name (.type.name o)))
    (($ <enum-literal>) (append (code:scope+name (.type o)) (list (.field o))))
    (($ <port>) (code:scope+name (.type.name o)))
    (($ <scope.name>) (.ids o))
    (($ <signature>) ((compose code:scope+name .type.name) o))
    (($ <trigger>) ((compose code:scope+name .event) o))
    ((? (is? <named>)) ((compose code:scope+name .name) o))
    ))

(define-method (code:scope+name (o <root>))
  (code:file-name o))

(define-method (code:scope+name (o <reply>))
  ((compose code:scope+name ast:type .expression) o))

(define-method (code:scope+name (o <event>))
  ((compose code:scope+name .signature) o))

(define-method (code:scope+name (o <extern>))
  (list (.value o)))

(define-method (code:scope+name (o <int>))
  '("int"))

(define-method (code:scope+name (o <signature>))
  ((compose code:scope+name .type) o))

(define-method (code:scope+name (o <trigger>))
  ((compose code:scope+name .event) o))

(define-method (code:scope+name (o <enum-field>))
  (append ((compose code:scope+name .type) o) (list (.field o))))

(define-method (code:scope+name (o <binding>))
  ((compose code:scope+name .type (cut ast:lookup (parent o <model>) <>) injected-instance-name) o))

(define-method (code:non-injected-bindings (o <system>))
  (filter om:port-bind? (filter (negate injected-binding?) (ast:binding* o))))

(define-method (code:injected-instances-system (o <system>))
  (if (null? (injected-bindings o)) ""
      o))

(define-method (code:injected-instances (o <system>))
  (if (null? (injected-bindings o)) ""
      (injected-instances o)))

;;; code:ast querying
(define-method (code:return-type-eq? (a <int>) (b <int>))
  #t)
(define-method (code:return-type-eq? a b)
  (ast:eq? a b))
(define (code:reply-types o)
  (delete-duplicates (filter (negate (is? <void>)) (ast:return-types o)) code:return-type-eq?))

(define-method (code:port-name (o <on>))
  ((compose .port.name car ast:trigger*) o))

(define-method (code:port-name (o <instance>))
  (let ((component (.type o)))
    (.name (car (ast:provides-port* component)))))

(define-method (code:port-name (o <binding>))
  (let* ((model (parent o <model>))
         (left (.left o))
         (right (.right o))
         (port (and (om:port-bind? o)
                    (if (not (.instance.name left)) (.port left) (.port right)))))
    port))

(define-method (code:instance-name (o <binding>))
  (let* ((model (parent o <model>))
         (left (.left o))
         (right (.right o))
         (bind (and (om:port-bind? o)
                    (if (.instance.name left) left right))))
    bind))

(define-method (code:instance-name (o <end-point>))
  o)

(define-method (code:instance-name (o <port>))
  (.instance.name (ast:other-end-point o)))

(define-method (code:instance-name (o <trigger>))
  (code:instance-name (.port o)))

(define-method (code:instance-port-name (o <port>))
  (.port.name (ast:other-end-point o)))

(define-method (code:instance-port-name (o <trigger>))
  (code:instance-port-name (.port o)))

(define-method (code:function-type (o <type>))
  o)

(define-method (code:function-type (o <trigger>))
  ((compose code:function-type .signature .event) o))

(define-method (code:function-type (o <signature>))
  ((compose code:function-type .type) o))

(define-method (code:function-type (o <function>))
  ((compose code:function-type .signature) o))


(define-method (code:functions (o <component>))
  (ast:function* o))

(define-method (code:ons (o <component>))
  (let ((behaviour (.behaviour o)))
    (if (not behaviour) '()
        (ast:statement* behaviour))))

(define-method (code:ons (o <port>))
  (let* ((component (parent o <component>))
         (behaviour (.behaviour component))
         (ons (if (not behaviour) '()
                  (ast:statement* behaviour))))
    (define (this-port? p)
      (equal? (.name o) (.port.name (car (ast:trigger* p)))))
    (filter this-port? ons)))

(define-method (code:trigger (o <on>))
  ((compose car ast:trigger*) o))

(define-method (code:trigger (o <port>))
  (map code:trigger (code:ons o)))

(define-method (code:return (o <on>))
  ((compose ast:type code:trigger) o))

(define-method (code:variable->argument (o <variable>) (f <formal>))
  (if (or (code:class-member? o)
          (eq? (.direction f) 'in)) o
          (clone (make <argument> #:name (.name o) #:type.name (.type.name f) #:direction (.direction f))
                 #:parent (.parent o))))

(define-method (code:variable->argument (o <var>) (f <formal>))
  (code:variable->argument (.variable o) f))

(define-method (code:variable->argument (o <formal>) (f <formal>))
  (if (eq? (.direction f) 'in) o
      (clone (make <argument> #:name (.name o) #:type.name (.type.name o) #:direction (.direction o))
             #:parent (.parent o))))

(define-method (code:variable->argument o f)
  o)

(define (code:add-calling-context-argument arguments)
  (let ((calling-context (command-line:get 'calling-context #f)))
    (if calling-context (cons "dzn_cc" arguments)
        arguments)))

(define-method (code:arguments (o <call>))
  (map code:variable->argument
       (code:add-calling-context-argument (ast:argument* o))
       (ast:formal* (code:add-calling-context-formal ((compose .formals .signature .function) o)))))

(define-method (code:arguments (o <action>))
  (map code:variable->argument
       (code:add-calling-context-argument (ast:argument* o))
       (ast:formal* (code:add-calling-context-formal ((compose .formals .signature .event) o)))))

(define-method (code:arguments (o <trigger>))
  (code:formals o))

(define-method (code:out-argument (o <trigger>))
  (filter (disjoin ast:out? ast:inout?) (code:formals o)))

(define-method (code:parameters (o <event>))
  (let ((parameters (map .name (ast:formal* o)))
        (calling-context (command-line:get 'calling-context #f)))
    (if calling-context
        (cons "dzn_cc" parameters)
        parameters)))

(define-method (code:add-calling-context-formal (o <formals>))
  (let ((calling-context (command-line:get 'calling-context #f)))
    (if calling-context (clone o #:elements (cons (clone (make <formal> #:name "dzn_cc" #:direction 'inout #:type.name (make <scope.name> #:ids '("*calling-context*"))) #:parent o)
                                                  (ast:formal* o)))
        o)))

(define-method (code:formals (o <function>))
  (ast:formal* (code:add-calling-context-formal ((compose .formals .signature) o))))

(define-method (code:formals (o <action>))
  (ast:formal* (code:add-calling-context-formal ((compose .formals .signature .event) o))))

(define-method (code:formals (o <trigger>))
  (ast:formal* (code:add-calling-context-formal ((compose .formals) o))))

(define-method (code:formals (o <signature>))
  (ast:formal* (code:add-calling-context-formal ((compose .formals) o))))

(define-method (code:formals (o <event>))
  (ast:formal* (code:add-calling-context-formal ((compose .formals .signature) o))))

(define-method (code:formals (o <on>))
  (ast:formal*
   (code:add-calling-context-formal
    (let* ((trigger ((compose car ast:trigger*) o))
           (formals ((compose .formals .signature) trigger))
           (event (.event trigger)))
      (clone formals
             #:elements (map (lambda (name formal)
                               (clone formal #:name name))
                             (map .name (ast:formal* formals))
                             (ast:formal* event)))))))

(define-method (code:expand-on (o <statement>))
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (clone (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
             #:parent (.parent o))
      o))

(define-method (code:expand-on (o <on>))
  (.statement o))

(define-method (code:assign-reply (o <reply>))
  (let ((expression (.expression o)))
    (if (is-a? (ast:type expression) <void>) '()
        o)))

(define-method (code:enum-field-definer (o <enum>))
  (map (symbol->enum-field o) (ast:field* o) (iota (length (ast:field* o)))))

(define ((symbol->enum-field enum) o i)
  (make <enum-field> #:type.name (.name enum) #:field o #:value i))

(define-method (code:enum-name (o <enum-field>))
  ((compose code:enum-name .type) o))

(define-method (code:enum-name (o <enum>))
  (ast:full-name o))

(define-method (code:enum-name (o <enum-literal>))
  ((compose code:enum-name .type) o))

(define-method (code:enum-name (o <reply>))
  ((compose code:enum-name .expression) o))

(define-method (code:enum-name (o <variable>))
  ((compose code:enum-name .type) o))

(define-method (code:enum-name o)
  ((compose code:enum-name .variable) o))

(define-method (code:enum-short-name (o <enum-field>))
  ((compose code:enum-short-name .type) o))

(define-method (code:enum-short-name (o <enum>))
  (ast:name o))

(define-method (code:enum-definer (o <interface>))
  (filter (is? <enum>) (append (ast:type* o) (ast:type* (.behaviour o)))))

(define-method (code:enum-definer (o <component>))
  (filter (is? <enum>) (ast:type* (.behaviour o))))

(define-method (code:global-enum-definer (o <root>))
  (filter (is? <enum>) (ast:type* o)))

(define-method (code:global-enum-definer (o <model>))
  (filter (is? <enum>) (ast:type* (parent o <root>))))

(define-method (code:global-enum-definer (o <root>))
  (filter (is? <enum>) (ast:type* o)))

(define-method (code:instances (o <component>))
  '())

(define-method (code:instances (o <system>))
  (ast:instance* o))

(define-method (code:bind-provided-required (o <binding>))
  (let* ((model (parent o <model>))
         (left (.left o))
         (left-port (.port left))
         (right (.right o))
         (right-port (.port right)))
    (if (ast:provides? left-port)
        (cons left right)
        (cons right left))))

(define-method (code:bind-provided (o <binding>))
  ((compose car code:bind-provided-required) o))

(define-method (code:bind-required (o <binding>))
  ((compose cdr code:bind-provided-required) o))

(define-method (code:component-port (o <port>))
  (ast:other-end-point o))

(define-method (code:reply-type (o <ast>))
  ((compose ast:full-name ast:type) o))

(define-method (code:reply-type (o <reply>))
  ((compose code:reply-type .expression) o))

(define-method (code:scope.name (o <enum-literal>))
  (code:scope.name (.type o)))

(define-method (code:scope.name (o <enum-field>))
  (code:scope.name (.type o)))

(define-method (code:scope.name (o <ast>))
  (.name o))

(define-method (code:expression (o <top>))
  (dzn:expression o))

(define-method (code:expression (o <formal>))
  (code:variable-name o))

(define-method (code:expression (o <variable>))
  (code:variable-name o))

(define-method (code:expression (o <return>))
  (dzn:expression o))

(define-method (code:expression (o <return>))
  (or (as (ast:type (.expression o)) <void>)
      (.expression o)))

(define-method (code:variable-name (o <argument>))
  o)

(define-method (code:variable-name (o <variable>))
  (cond ((member (%language) '("c++" "c++03" "c++-msvc11")) o) ; MORTAL SIN HERE!!?
        ((code:class-member? o) o)
        (else (make <local> #:name (.name o) #:type.name (.type.name o) #:expression (.expression o)))))

(define-method (code:variable-name (o <formal>))
  (cond ((member (%language) '("c++" "c++03" "c++-msvc11")) o) ; MORTAL SIN HERE!!?
        (((disjoin ast:out? ast:inout?) o) (make <out-formal> #:name (.name o) #:type.name (.type.name o)))
        (else o)))

(define-method (code:variable-name (o <ast>))
  ((compose code:variable-name .variable) o))

(define-method (code:type-name (o <variable>))
  (code:type-name (.type o)))

(define-method (code:type-name (o <enum>))
  (ast:full-name o))

(define-method (code:type-name (o <binding>))
  ((compose code:type-name .type (cut ast:lookup (parent o <model>) <>) injected-instance-name) o))

(define-method (code:type-name (o <enum-field>))
  (append (code:type-name (.type o)) (list (.field o))))

(define-method (code:type-name (o <enum-literal>))
  (append (code:type-name (.type o)) (list (.field o))))

(define-method (code:type-name (o <model>))
  (ast:full-name o))

(define-method (code:type-name o) ; MORTAL SIN HERE!!?
  (let* ((type (or (as o <model>) (as o <type>) (ast:type o))))
    (map dzn:->string
         (match type
           (($ <enum>) (code:type-name type))
           (($ <extern>) (list (.value type)))
           ((or ($ <bool>) ($ <int>) ($ <void>)) (ast:full-name type))
           (_ (ast:full-name type))))))

(define-method (code:type-name (o <event>))
  ((compose code:type-name .type .signature) o))

(define-method (code:type-name (o <enum-literal>))
  (code:type-name (.type o)))

(define-method (code:main-out-arg (o <trigger>)) ; MORTAL SIN HERE!!?
  (let ((formals (ast:formal* o)))
    (map
     (lambda (f i) (cond ((ast:in? f) (clone f #:name i))
                         ((member (%language) '("c++" "c++03" "c++-msvc11" "cs")) (string-append "_" (number->string i)))
                         (else (make <out-formal> #:name i))))
     formals (iota (length formals)))))

(define-method (code:main-out-arg-define (o <trigger>))
  (let ((formals (ast:formal* o)))
    (map (lambda (f i) (clone f #:name i))
         formals (iota (length formals)))))

(define-method (code:main-out-arg-define-formal (o <formal>)) ;; MORTAL SIN HERE!!?
  (let ((type ((compose .value .type) o)))
    (if (not ((disjoin ast:out? ast:inout?) o)) ""
        (if (equal? type "int") o
            "/*FIXME*/"))))

(define-method (code:main-event-map-match-return (o <trigger>))
  (if (ast:in? (.event o)) o ""))

(define-method (code:scope-type-name o)
  ((compose ast:name code:scope.name) o))

(define-method (code:scope-type-name (o <field-test>))
  ((compose code:scope-type-name .type .variable) o))

(define (code:x-header- o) (filter (conjoin (negate ast:imported?) (is? <interface>)) (ast:model* o)))

(define-method (code:reply (o <type>))
  o)

;;; code: generic templates

(use-modules (ice-9 pretty-print))

(define-method (scope (o <type>)) ((compose ast:scope .name) o))
(define-method (scope (o <event>)) ((compose scope .type .signature) o))
(define-method (scope (o <reply>)) (scope (.type (.expression o))))

(define-method (code:interface-include o)
  (map (compose (cut make <file-name> #:name <>) code:file-name)
       (delete-duplicates
        (filter (compose (cut (negate equal?) (ast:source-file o) <>) ast:source-file .type)
                (ast:port* o)))))

(define-method (code:interface-include (o <foreign>))
  (map (compose (cut make <file-name> #:name <>) code:file-name)
       (filter (compose (cut (negate equal?) (ast:source-file (parent o <root>)) <>) ast:source-file)
               (map .type (ast:port* o)))))

(define-method (code:enum-literal (o <enum-literal>))
  (append (code:type-name (.type o)) (list (.field o))))

(define-method (code:enum-scope (o <field-test>))
  ((compose (cut code:enum-model-scope <> (parent o <model>)) .type .variable) o))

(define-method (code:enum-scope (o <enum-literal>))
  ((compose (cut code:enum-model-scope <> (parent o <model>)) .type) o))

(define-method (code:enum-scope (o <enum>))
  ((compose (cut code:enum-model-scope <> (parent o <model>)) .type) o))

(define-method (code:enum-model-scope (o <enum>) model)
  (let ((scope (ast:full-scope o))
        (model-scope (and=> model ast:full-name)))
    (cond ((or (null? scope) (null? model-scope)) (parent o <root>))
          ((equal? scope model-scope) (make <model-scope> #:scope model-scope))
          (else o))))

(define-method (code:trace-q-out o) ;; MORTAL SIN HERE
  (if ((compose ast:out? .event) o) o
      ""))

;; main

;;; dump to file

(define-method (have-non-interface-models? (o <root>))
  (let* ((objects
          (filter
           (disjoin (is? <extern>)
                    (negate (disjoin dzn-async? ast:imported?)))
           (ast:model* o)))
         (non-interface-models (filter (negate (is? <interface>)) objects)))
    (pair? non-interface-models)))

(define (code:glue)
  (command-line:get 'glue #f))

(define-method (code:dump (o <root>))
  (let* ((dir (command-line:get 'output "."))
         (stdout? (equal? dir "-"))
         (base (basename (ast:source-file o) ".dzn"))
         (foreign-conflict? (find (lambda (o) (and (is-a? o <foreign>)
                                                   (not (ast:imported? o))
                                                   (equal? base (code:file-name o)))) (ast:model* o))))
    (when (and (not (code:glue)) foreign-conflict?)
      (stderr "cowardly refusing to clobber file with basename: ~a\n" base)
      (exit EXIT_SUCCESS))
    (when (code:header?)
      (let* ((ext (dzn:extension (make <interface>)))
             (file-name (string-append dir "/" base ext)))
        (if stdout? ((dzn:indent (cut (%x:header) o)))
            (begin
              (mkdir-p dir)
              (with-output-to-file file-name
                (dzn:indent (cut (%x:header) o)))))))
    (if (or (not (code:header?)) (have-non-interface-models? o))
        (let* ((ext (dzn:extension (make <component>)))
               (file-name (string-append dir "/" base ext)))
          (if stdout? ((dzn:indent (cut (%x:source) o)))
              (begin
                (mkdir-p dir)
                (with-output-to-file file-name
                  (dzn:indent (cut (%x:source) o)))))))))

(define-method (code:dump (o <foreign>))
  #f)

(define-method (code:dump-main (o <interface>))
  #f)

(define-method (code:dump-main (o <component-model>))
  (let* ((dir (command-line:get 'output "."))
         (stdout? (equal? dir "-"))
         (ext (dzn:extension o))
         (dir (string-append dir "/"))
         (base "main")
         (file-name (string-append dir base ext)))
   (if stdout? ((dzn:indent (cut (%x:main) o)))
       (with-output-to-file file-name (dzn:indent (cut (%x:main) o))))))

(define-method (code:file-name (o <port>))
  (code:file-name (.type o)))

(define-method (code:file-name (o <instance>))
  (code:file-name (.type o)))

(define-method (code:file-name (o <foreign>))
  ((compose (cut string-join <> "_") ast:full-name) o))

(define-method (code:file-name (o <ast>))
  (basename (ast:source-file o) ".dzn"))

(define (code:om ast)
  ((compose
    (lambda (o) (if (dzn:command-line:get 'debug) (display (ast->dzn o) (current-error-port))) o)
    add-reply-port
    triples:event-traversal
    (remove-otherwise)
    (binding-into-blocking)
    code:add-calling-context)
   ast))

(define-method (code:add-calling-context (o <root>))
  (let ((calling-context (command-line:get 'calling-context #f)))
    (if calling-context
        (let ((extern (make <extern> #:name (make <scope.name> #:ids '("*calling-context*")) #:value calling-context)))
          (clone o #:elements (cons extern (ast:top* o))))
        o)))

(define (code:foreign?)
  (member (%language) '("c++" "c++03" "c++-msvc11")))

(define (code:header?)
  (member (%language) '("c" "c++" "c++03" "c++-msvc11")))

(define (code:module root)
  (let ((module (make-module 31 `(,(resolve-module '(dzn code))
                                  ,(resolve-module `(dzn code ,(%language)))))))
    (module-define! module 'root root)
    module))

(define (code:skel-file model)
  ((->string-join "_") (append (drop-right (code:scope+name model) 1) '("skel") (take-right (code:scope+name model) 1))))

(define-method (code:pump? (o <root>))
  (filter (conjoin (negate ast:imported?) (is? <component>) (compose pair? ast:req-events)) (ast:model* o)))

(define-method (code:pump? (o <component>))
  (if ((compose pair? ast:req-events) o) o
      '()))

(define-method (code:model (o <root>))
  (let* ((models (ast:model* o))
         (models (filter (negate (disjoin (is? <type>) (is? <namespace>)
                                          (conjoin ast:imported? (negate (is? <foreign>)))))
                         models))
         (models (ast:topological-model-sort models))
         (models (map dzn:annotate-shells models)))
    models))

(define-method (code:upcase-model-name o)
  (map string-upcase (ast:full-name (parent o <model>))))

(define-method (code:port-release o)
  (if (null? (tree-collect-filter (negate (disjoin (is? <imperative>) (is? <expression>) (is? <location>)))
                                  (disjoin (is? <blocking>) (is? <blocking-compound>))
                                  (parent o <model>))) '()
      o))

(define-method (code:name.name (o <enum>)) ;; FIXME: remove code:name.name
  (ast:name o))

(define-method (code:name.name (o <extern>))
  (ast:name o))

(define-method (code:name.name (o <int>))
  (ast:name o))

(define-method (code:name.name (o <namespace>))
  (ast:name o))

(define-method (code:used-foreigns (o <root>))
  (let* ((systems (filter (conjoin (is? <system>) (negate ast:imported?)) (ast:model* o)))
         (models (map .type (append-map ast:instance* systems))))
    (filter (is? <foreign>) models)))
