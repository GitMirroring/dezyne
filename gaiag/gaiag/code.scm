;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2016, 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
;; Copyright © 2014, 2015, 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag code)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag ast)
  #:use-module (gaiag util)

  #:use-module (gaiag command-line)
  #:use-module (gaiag compare)
  #:use-module (gaiag dzn)
  #:use-module (gaiag misc)
  #:use-module (gaiag norm-event)
  #:use-module (gaiag parse)
  #:use-module (gaiag resolve)
  #:use-module (gaiag xpand)

  #:use-module (language dezyne location)

  #:export (<enum-field>
            asd-interfaces
            map-file
            injected-bindings
            injected-instances
            non-injected-instances
            injected-instance-name

            code:formals
            code:language
            code:instance-name
            code:annotate-shells
            code:skel-file
            event2->interface1-event1-alist

            code:expression
            code:trigger
            code:injected-instances
            code:non-injected-bindings
            code:injected-instances-system
            code:model2file?
            code:ons
            code:functions
            code:port-name
            code:instance-port-name
            code:instances
            code:reply-type
            code:reply-scope+name
            code:reply-types
            code:scope+name
            code:x:pand

            code-file
            code:file-name
            code:dump
            code:extension
            code:dump-main
            code:module
            code:om
            symbol->enum-field
            glue))

(define (ast-> ast)
  (let ((root (code:om ast)))
    (ast:set-scope root (code:root-> root)))
  "")

(define (code:root-> root)
  (parameterize ((language (code:language)))
    (if (code:model2file?) (code:model2file root)
        (code:file2file root))
    (let ((main (command-line:get 'model #f)))
      (when main
        (let* ((models (filter (is? <model>) (.elements root)))
               (main? (compose (cut eq? (string->symbol main) <>) (om:scope-name)))
               (main-model (and main (find main? models))))
          (and=> main-model code:dump-main))))))

(define (code:language)
  (string->symbol (command-line:get 'language "c++")))

(define (code:file2file root)
  (let* ((objects (filter (disjoin (is? <data>)
                                   (negate (disjoin dzn-async? om:imported? (is? <foreign>))))
                          (.elements root)))
         (root* (clone root #:elements objects)))
    (code:dump root*)
    (when (code:foreign?)
      (for-each code:dump (filter (is? <foreign>) (.elements root))))
    (when (glue) (for-each code:dump-glue (filter (is? <system>) objects)))))

(define (code:model2file root)
  (let* ((models (map (is? <model>) (.elements root)))
         (models (filter (negate om:imported?) models))
         ;; Generator-synthesized models look non-imported, filter harder
         (models (filter (negate dzn-async?) models)))
    (for-each code:dump models)))

;;; ast extension
(define-class <argument> (<named> <expression>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction))

(define-class <enum-field> (<ast>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

(define-class <file-name> (<ast>)
  (name #:getter .name #:init-form #f #:init-keyword #:name))

(define-class <local> (<variable>))

(define-class <model-scope> (<ast>))

(define-class <out-formal> (<variable>))

;;; ast accessors
(define (injected-binding? binding)
  (or (eq? '* (.port.name (.left binding)))
      (eq? '* (.port.name (.right binding)))))

(define (injected-binding binding)
  (cond ((eq? '* (.port.name (.left binding))) (.right binding))
        ((eq? '* (.port.name (.right binding))) (.left binding))
        (else #f)))

(define (injected-bindings model)
  (filter injected-binding? ((compose .elements .bindings) model)))

(define (injected-instance-name binding)
  (or (.instance.name (.left binding)) (.instance.name (.right binding))))

(define (injected-instances model)
  (let ((injected-instance-names (map injected-instance-name (injected-bindings model))))
    (filter (lambda (instance) (member (.name instance) injected-instance-names))
            ((compose .elements .instances) model))))

(define (non-injected-instances model)
  (let ((injected-instance-names (map injected-instance-name (injected-bindings model))))
    (filter (lambda (instance) (not (member (.name instance) injected-instance-names)))
            ((compose .elements .instances) model))))

(define (code:annotate-shells o)
  (if (and (is-a? o <system>)
           (equal? (command-line:get 'shell #f) (symbol->string (.name (.name o)))))
      (make <shell-system> #:ports (.ports o) #:name (.name o) #:instances (.instances o) #:bindings (.bindings o))
      o))

(define-method (code:class-member? (o <variable>)) ; MORTAL SIN HERE!!?
  ;; FIXME: is (.variable o) a member?
  ;; checking name (as done now) is not good enough
  ;; we schould check .variable pointer equality
  ;; that does not work, however; someone makes a copy is clone
  ;;(memq o (om:variables (ast:model-scope)))
  (memq (.name o) (map .name (om:variables (ast:model-scope)))))

(define-method (code:port-type (o <trigger>))
  (code:scope+name ((compose .type .port) o)))

(define-method (code:port-type (o <port>))
  (code:scope+name (.type o)))

(define-method (code:scope+name o)
  (om:scope+name o))

(define-method (code:scope+name (o <event>))
  ((compose code:scope+name .signature) o))

(define-method (code:scope+name (o <extern>))
  (list (.value o)))

(define-method (code:scope+name (o <int>))
  '(int))

(define-method (code:scope+name (o <signature>))
  ((compose code:scope+name .type) o))

(define-method (code:scope+name (o <trigger>))
  ((compose code:scope+name .event) o))

(define-method (code:scope+name (o <enum-field>))
  (append ((compose code:scope+name .type) o) (list (.field o))))

(define-method (code:scope+name (o <bind>))
  ((compose code:scope+name .type (cut om:instance (ast:model-scope) <>) injected-instance-name) o))

(define-method (code:non-injected-bindings (o <system>))
  (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) o))))

(define-method (code:injected-instances-system (o <system>))
  (if (null? (injected-bindings o)) ""
      o))

(define-method (code:injected-instances (o <system>))
  (if (null? (injected-bindings o)) ""
      (injected-instances o)))

;;; code:ast querying
(define (code:reply-types o)
  (let ((lst (om:reply-types o)))
    (delete-duplicates lst (lambda (a b) (or (and (is-a? a <bool>)
                                                  (is-a? b <bool>))
                                             (and (is-a? a <int>)
                                                  (is-a? b <int>))
                                             (and (is-a? a <void>)
                                                  (is-a? b <void>))
                                             (om:equal? a b))))))

(define-method (code:port-name (o <on>))
  ((compose .port.name car .elements .triggers) o))

(define-method (code:port-name (o <instance>))
  (.name (om:port (om:component (ast:model-scope) o))))

(define-method (code:port-name (o <bind>))
  (let* ((model (ast:model-scope))
         (left (.left o))
         (left-port (.port left))
         (right (.right o))
         (right-port (.port right))
         (port (and (om:port-bind? o)
                    (if (not (.instance left)) (.port left) (.port right)))))
    port))

(define-method (code:instance-name (o <bind>))
  (let* ((model (ast:model-scope))
         (left (.left o))
         (left-port (.port left))
         (right (.right o))
         (right-port (.port right))
         (bind (and (om:port-bind? o)
                    (if (.instance left) left right))))
    bind))

(define-method (code:instance-name (o <binding>))
  o)

(define-method (code:instance-name (o <port>))
  (.name (om:instance (ast:model-scope) o)))

(define-method (code:instance-name (o <trigger>))
  ((compose code:instance-name (cut .port (ast:model-scope) <>)) o))

(define-method (code:instance-port-name (o <port>))
  (let* ((bind (om:port-bind (ast:model-scope) o))
         (instance-bind (om:instance-binding? bind)))
    (.port.name instance-bind)))

(define-method (code:instance-port-name (o <trigger>))
  ((compose code:instance-port-name (cut .port (ast:model-scope) <>)) o))

(define-method (code:functions (o <component>))
  (om:functions o))

(define-method (code:ons (o <component>))
  (let ((behaviour (.behaviour o)))
    (if (not behaviour) '()
        ((compose .elements .statement) behaviour))))


(define-method (code:trigger (o <on>))
  ((compose car .elements .triggers) o))

(define-method (code:return (o <on>))
  ((compose .type .signature .event code:trigger) o))

(define-method (code:variable->argument (o <variable>) (f <formal>))
  (if (or (code:class-member? o)
          (eq? (.direction f) 'in)) o
      (make <argument> #:name (.name o) #:type (.type o))))

(define-method (code:variable->argument (o <var>) (f <formal>))
  (code:variable->argument (.variable o) f))

(define-method (code:variable->argument (o <formal>) (f <formal>))
  (if (eq? (.direction f) 'in) o
      (make <argument> #:name (.name o) #:type (.type o) #:direction (.direction o))))

(define-method (code:variable->argument o f)
  o)

(define-method (code:arguments (o <call>))
  (map code:variable->argument
       ((compose .elements .arguments) o)
       ((compose .elements .formals .signature .function) o)))

(define-method (code:arguments (o <action>))
  (map code:variable->argument
       ((compose .elements .arguments) o)
       ((compose .elements .formals .signature .event) o)))

(define-method (code:arguments (o <trigger>))
  (map .name (code:formals o)))

(define-method (code:out-argument (o <trigger>))
  (filter om:out-or-inout? (code:formals o)))

(define-method (code:parameters (o <event>))
  (map .name ((compose .elements .formals .signature) o)))

(define-method (code:formals (o <function>))
  ((compose .elements .formals .signature) o))

(define-method (code:formals (o <action>))
  ((compose .elements .formals .signature .event) o))

(define-method (code:formals (o <trigger>))
  ((compose .elements .formals) o))

(define-method (code:formals (o <signature>))
  ((compose .elements .formals) o))

(define-method (code:formals (o <event>))
  ((compose .elements .formals .signature) o))

(define-method (code:formals (o <on>))
  (let* ((trigger ((compose car .elements .triggers) o))
         (event (.event trigger)))
    (map (lambda (name formal)
           (clone formal #:name name))
         (map .name ((compose .elements .formals) trigger))
         ((compose .elements .formals .signature) event))))

(define-method (code:assign-reply (o <reply>))
  (let ((expression (.expression o)))
    (if (is-a? (ast:expression-type expression) <void>) ""
        o)))

(define-method (code:on-statement (o <statement>))
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
      o))
(define-method (code:on-statement (o <on>))
  (let ((o (.statement o)))
   (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
       (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
       o)))

(define-method (code:guard-statement (o <statement>))
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
      o))
(define-method (code:guard-statement (o <guard>))
  (let ((o (.statement o)))
   (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
       (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
       o)))

(define ((symbol->enum-field enum) o)
  (make <enum-field> #:type enum #:field o))

(define-method (.type.name (o <enum-field>))
  (symbol->string ((compose .name .name .type) o)))

(define-method (code:instances (o <component>))
  '())
(define-method (code:instances (o <system>))
  (om:instances o))

(define-method (code:bind-provided-required (o <bind>))
  (let* ((model (ast:model-scope))
         (left (.left o))
         (left-port (.port left))
         (right (.right o))
         (right-port (.port right)))
    (if (om:provides? left-port)
                                (cons left right)
                                (cons right left))))

(define-method (code:bind-provided (o <bind>))
  ((compose car code:bind-provided-required) o))

(define-method (code:bind-required (o <bind>))
  ((compose cdr code:bind-provided-required) o))

(define-method (code:component-port (o <port>)) ;; MORTAL SIN HERE!!?
  (let* ((model (ast:model-scope))
         (bind (om:port-bind model o)))
    (om:instance-binding? bind)))

(define-method (code:reply-type (o <ast>))
  ((compose code:scope+name ast:expression-type) o))

(define-method (code:reply-type (o <reply>))
  ((compose code:reply-type .expression) o))

(define-method (code:declarative-or-imperative (o <compound>))
  (if (om:imperative? o) o
      (make <declarative-compound> #:elements o)))

(define-method (code:scope.name (o <enum-literal>))
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
  (if (or (not (.expression o)) (eq? (.expression o) *unspecified*)) ""  ; MORTAL SIN HERE!!?
          (.expression o)))

(define-method (code:variable-name (o <argument>))
  o)

(define-method (code:variable-name (o <variable>))
  (cond ((memq (language) '(c++ c++03 c++-msvc11)) o) ; MORTAL SIN HERE!!?
        ((code:class-member? o) o)
        (else (make <local> #:name (.name o) #:type (.type o) #:expression (.expression o)))))

(define-method (code:variable-name (o <formal>))
  (cond ((memq (language) '(c++ c++03 c++-msvc11)) o) ; MORTAL SIN HERE!!?
        ((om:out-or-inout? o) (make <out-formal> #:name (.name o) #:type (.type o)))
        (else o)))

(define-method (code:variable-name (o <ast>))
  ((compose code:variable-name .variable) o))

;; type
(define (code:cons-empty-symbol o)
  (if (memq (language) '(c++ c++03 c++-msvc11)) (cons (symbol) o) ; MORTAL SIN HERE!!?
      o))

(define-method (code:type-name (o <bind>))
  ((compose code:type-name .type (cut om:instance (ast:model-scope) <>) injected-instance-name) o))

(define-method (code:type-name (o <enum-field>))
  (code:scope+name o))

(define (code:append-type-symbol o)
  (if (memq (language) '(c++ c++03 c++-msvc11)) (append o (list 'type)) ; MORTAL SIN HERE!!?
      o))

(define-method (code:type-name o)
  (let* ((type (or (as o <model>) (as o <type>) (.type o)))
         (scope+name (code:scope+name type)))
    (map dzn:->string
         (match type
           (($ <enum>) (code:cons-empty-symbol (code:append-type-symbol scope+name)))
           (($ <extern>) (list (.value type)))
           ((or ($ <bool>) ($ <int>) ($ <void>)) scope+name)
           (_ (code:cons-empty-symbol scope+name))))))

(define-method (code:type-name (o <event>))
  ((compose code:type-name .type .signature) o))

(define-method (code:type-name (o <enum-field>))
  (map dzn:->string (code:cons-empty-symbol (code:scope+name o))))

(define-method (code:type-name (o <enum-literal>))
  (map dzn:->string (code:cons-empty-symbol (code:scope+name o))))

(define-method (code:field-expression (o <field-test>))
  (map dzn:->string (code:cons-empty-symbol
                      (append (code:scope+name ((compose .type .variable) o))
                              (list (.field o))))))

(define-method (code:main-out-arg (o <trigger>)) ; MORTAL SIN HERE!!?
  (let ((formals ((compose .elements .formals) o)))
    (map
     (lambda (f i) (cond ((not (om:out-or-inout? f)) (clone f #:name i))
                         ((memq (language) '(c++ c++03 c++-msvc11)) (string-append "_" (number->string i)))
                         (else (make <out-formal> #:name i))))
     formals (iota (length formals)))))

(define-method (code:main-event-map-match-return (o <trigger>))
  (if (om:in? (.event o)) o ""))

(define-method (code:scope-type-scope o)
  ((compose .scope code:scope.name) o))

(define-method (code:scope-type-scope (o <field-test>))
  ((compose code:scope-type-scope .type .variable) o))

(define-method (code:scope-type-name o)
  ((compose .name code:scope.name) o))

(define-method (code:scope-type-name (o <field-test>))
  ((compose code:scope-type-name .type .variable) o))

(define (code:x-header- o) (filter (is? <interface>) (.elements o)))

;;

;;; code: generic templates
(define-template x:header- code:x-header-)

(define-template x:async-member-initializer (lambda (o) (om:ports (.behaviour o))))

(define-template x:scope (compose .scope .name) 'name-infix)
(define-template x:scope-type-scope code:scope-type-scope 'type-infix)
(define-template x:scope-type-name code:scope-type-name 'type-infix)
(define-template x:scope-prefix (compose .scope .name) 'name-suffix)

(define-template x:scope+name code:scope+name 'name-infix)
(define-template x:scoped-model-name code:scope+name 'name-infix);; c++ compat, junk me

(define-template x:type-name code:type-name 'type-infix)

(define-template x:port-name code:port-name)
(define-template x:port-type code:port-type 'type-infix)

(define (code:interface-include o)
  (map (compose (cut make <file-name> #:name <>) code:file-name) (om:ports o)))

(define (code:model2file-interface-include o)
  (or (and (code:model2file?) (code:interface-include o))
      ""))

(define (code:component-include o)
 (if (code:model2file?) (om:instances o)
     (filter (disjoin (compose (is? <foreign>) .type)
                      (conjoin om:imported? (lambda (i) (not (equal? (source-file o)
                                                                     (source-file (.type i)))))))
             (om:instances o))))

(define-template x:interface-include code:interface-include)
(define-template x:model2file-interface-include code:model2file-interface-include)
(define-template x:component-include code:component-include)

(define-template x:scope::name code:scope+name 'type-infix)

(define-template x:non-void-reply identity #f)

(define-method (code:enum-literal (o <enum-literal>))
  (map dzn:->string (code:cons-empty-symbol (code:scope+name o))))

(define-method (code:enum-scope (o <field-test>))
  ((compose code:enum-scope .type .variable) o))

(define-method (code:enum-scope (o <enum-literal>))
  ((compose code:enum-scope .type) o))

(define-method (code:enum-scope (o <enum>))
  (let ((scope ((compose .scope .name) o))
        (model-scope (om:scope+name (ast:model-scope))))
    (if (or (null? scope) (equal? scope model-scope)) (make <model-scope>)
        o)))

(define-template x:code-enum-literal code:enum-literal 'type-infix)
(define-template x:enum-scope code:enum-scope 'type-infix)

(define-template x:reply (lambda (o)
                           (if (is-a? o <void>)
                               ""
                               (begin (display " ") (x:non-void-reply o))))) ;; MORTAL SIN HERE!!?


(define-template x:capitalize-model-name (compose (cut string-upcase <> 0 1) symbol->string om:name (lambda (_) (ast:model-scope))))

(define-template x:upcase-model-name (compose string-upcase (->join "_") om:scope+name (lambda (_) (ast:model-scope))))

(define-template x:method code:trigger)

(define-template x:parameters code:parameters 'formal-infix)
(define-template x:formals code:formals 'formal-infix)
(define-template x:formals-type code:formals 'formal-infix)

(define-template x:methods code:ons)
(define-template x:functions code:functions)

(define-template x:reply-type code:reply-type 'name-infix)

(define-template x:declarative-or-imperative code:declarative-or-imperative)


(define-template x:guard-statements .elements #f <statement>)

(define-template x:out-bindings .elements)

(define-template x:statements .elements #f <statement>)

(define-template x:variable-name code:variable-name)

(define-template x:assign-reply code:assign-reply)

(define-template x:meta-child om:instances 'meta-child-infix)

(define-template x:block identity)
(define-template x:port-release (lambda (o) (if (om:blocking-compound? (ast:model-scope)) o "")))

(define-template x:on-statement code:on-statement)

(define-template x:guard-statement code:guard-statement)

(define-template x:all-ports-meta-list om:ports 'meta-infix)

(define-template x:in-event-definer (lambda (o) (filter om:in? (om:events o))) 'event-definer-infix)
(define-template x:out-event-definer (lambda (o) (filter om:out? (om:events o))) 'event-definer-infix)

(define-template x:enum-definer (lambda (o) (append (om:enums o) (filter (is? <enum>) (om:globals)))))


(define-template x:enum-field-definer (lambda (o) (map (symbol->enum-field o) ((compose .elements .fields) o))) 'comma-infix)

(define-template x:variable-member-initializer om:variables)

(define-template x:reply-member-initializer code:reply-types)

(define-template x:injected-member-initializer (lambda (o) (filter .injected (om:ports o))))

(define-template x:provided-member-initializer (lambda (o) (filter om:provides? (om:ports o))))

(define-template x:required-member-initializer (lambda (o) (filter (conjoin (negate .injected) om:requires?) (om:ports o))))

(define-template x:instance-name code:instance-name)
(define-template x:instance-port-name code:instance-port-name)

(define-template x:injected-instance-initializer code:injected-instances)

(define-template x:non-injected-instance-initializer non-injected-instances)
(define-template x:injected-binding-initializer injected-bindings)
(define-template x:instance-initializer om:instances)
(define-template x:bind-connect code:non-injected-bindings)

(define-template x:bind-provided code:bind-provided)
(define-template x:bind-required code:bind-required)

(define-template x:binding-name code:instance-name)

(define-template x:component-port code:component-port)

(define-template x:injected-instance-system-initializer code:injected-instances-system)

(define-template x:system-port-connect (lambda (o) (filter (negate om:port-bind?) ((compose .elements .bindings) o))))

(define-template x:code-arguments code:arguments 'argument-infix <expression>)

(define-template x:out-arguments code:out-argument 'argument-prefix <expression>)

(define-template x:return code:return #f <type>)

(define-method (code:return (o <on>))
  ((compose .type .signature .event code:trigger) o))

;; main
(define-template x:main-port-connect-in ast:out-triggers-in-events)
(define-template x:main-port-connect-in-void ast:out-triggers-void-in-events)
(define-template x:main-port-connect-in-valued ast:out-triggers-valued-in-events)
(define-template x:main-port-connect-out ast:out-triggers-out-events)
(define-template x:main-provided-port-init ast:provided)
(define-template x:main-required-port-init ast:required)
(define-template x:main-provided-flush-init om:provided)
(define-template x:main-required-flush-init om:required)

(define-template x:main-out-arg code:main-out-arg 'argument-infix)
(define-template x:main-event-map-void ast:void-in-triggers 'event-map-prefix)
(define-template x:main-event-map-valued ast:valued-in-triggers 'event-map-prefix)
(define-template x:main-event-map-flush ast:required 'event-map-prefix)

(define-template x:main-event-map-match-return code:main-event-map-match-return)
(define-template x:main-required-port-name ast:required 'main-port-name-infix)


;;; dump to file
(define-method (code:x:pand (o <ast>) template file-name)
  (let ((file-name (if (and file-name (symbol? file-name)) (symbol->string file-name) file-name))) ;; FIXME
    (dump-output (string-append (if (eq? template 'main) "" (dzn:dir o)) ;; FIXME AAARRRGH
                                file-name)
                 (code:x:pand-display o template))))

(define-method (code:x:pand-display (o <ast>) template)
  (let ((module (make-module 31 `(,(resolve-module '(gaiag dzn))
                                  ,(resolve-module '(gaiag code))
                                  ,(resolve-module `(gaiag ,(language)))))))
    (module-define! module 'root (ast:root-scope))
    (dzn:indent
     (lambda _
       (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
        (if (not (is-a? o <model>)) (x:pand (symbol-append template '@ (ast-name o)) o module)
            (ast:set-model-scope o (x:pand (symbol-append template '@ (ast-name o)) o module))))))))

(define-method (code:dump (o <root>))
  (let ((name (basename (symbol->string (source-file o)) ".dzn")))
    (code:x:pand o 'header (string-append name (symbol->string (dzn:extension (make <interface>)))))
    (when (pair? (filter (negate (disjoin (is? <data>) (is? <interface>))) (.elements o)))
      (code:x:pand o 'source (string-append name (symbol->string (dzn:extension (make <component>))))))))

;; FIXME:  'global todo
;; (define-method (code:dump (o <enum>))
;;   (code:x:pand o 'header (symbol-append name (dzn:extension (make <interface>))))
;;   (and-let* (((null-is-#f (filter (is? <enum>) (om:globals))))
;;              (template (template-file `(global ,(symbol-append (dzn:extension o) '.scm))))
;;              ((file-exists? (components->file-name template))))
;;             (dzn:dump-indented (list 'dzn 'global (dzn:extension o))
;;                            (lambda ()
;;                              (code-file 'global (code:module o))))))

(define-method (code:dump (o <interface>))
  (let ((name ((om:scope-name) o)))
    (if (code:header?) (code:x:pand o 'header (symbol-append name (dzn:extension (make <interface>))))
        (code:x:pand o 'source (symbol-append name (dzn:extension (make <interface>)))))))

(define-method (code:dump (o <component>))
  (let ((name ((om:scope-name) o)))
    (when (code:header?)
      (code:x:pand o 'header (symbol-append name (dzn:extension (make <interface>)))))
    (code:x:pand o 'source (symbol-append name (dzn:extension (make <component>))))))

(define-method (code:dump (o <foreign>))
  (let ((name (code:skel-file o)))
    (when (code:header?)
      (code:x:pand o 'foreign-header (symbol-append name (dzn:extension (make <interface>)))))
    (code:x:pand o 'foreign-source (symbol-append name (dzn:extension (make <component>)))))
  (when (map-file o)
    (let ((name ((om:scope-name) o)))
      (code:x:pand o 'glue-bottom-header (symbol-append name (dzn:extension (make <interface>))))
      (code:x:pand o 'glue-bottom-source (symbol-append name (dzn:extension (make <component>)))))))

(define-method (code:dump (o <system>))
  (let* ((name ((om:scope-name) o))
         (shell (command-line:get 'shell #f))
         (template (if (and shell (eq? name (string->symbol shell))) 'shell- (symbol))))
    (when (code:header?)
      (code:x:pand o (symbol-append template 'header) (symbol-append name (dzn:extension (make <interface>)))))
    (code:x:pand o (symbol-append template 'source) (symbol-append name (dzn:extension (make <component>)))))
  (when (map-file o)
    (code:dump-glue o)))

(define (code:dump-main o)
  (and-let* ((name ((om:scope-name) o))
             (model (and (and=> (command-line:get 'model #f) string->symbol)))
             ((is-a? o <component-model>))
             ((eq? model name)))
    (code:x:pand o 'main (symbol-append 'main (dzn:extension o)))))

(define-method (code:dump-glue (o <system>))
  (let ((name (om:name o)))
    (code:x:pand o 'glue-top-header (symbol-append name 'Component.h))
    (code:x:pand o 'glue-top-source (symbol-append name 'Component.cpp))))

(define (glue)
  (and=> (command-line:get 'glue #f) string->symbol))

(define (code:model2file?)
  (and=> (or (command-line:get 'deprecated #f) (getenv "DZN_DEPRECATED"))
         (cut string-contains <> "model2file")))

(define-method (code:file-name (o <port>))
  (code:file-name (.type o)))

(define-method (code:file-name (o <instance>))
  (code:file-name (.type o)))

(define-method (code:file-name (o <interface>))
  (if (code:model2file?)
      ((compose symbol->string (om:scope-name) .name) o)
      (basename (symbol->string (source-file o)) ".dzn")))

(define-method (code:file-name (o <foreign>))
  ((compose symbol->string (om:scope-name) .name) o))

(define-method (code:file-name (o <component>))
  (if (code:model2file?)
      ((compose symbol->string (om:scope-name) .name) o)
      (basename (symbol->string (source-file o)) ".dzn")))

(define-method (code:file-name (o <system>))
  (if (or (code:model2file?) (glue))
      ((compose symbol->string (om:scope-name) .name) o)
      (basename (symbol->string (source-file o)) ".dzn")))

(define-method (code:file-name (o <root>))
  (basename (symbol->string (source-file o)) ".dzn"))

(define (code:om ast)
  ((compose-root
    code-norm-event
    ast:resolve
    parse->om
    ) ast))

(define (code:foreign?)
  (member (language) '(c++ c++03 c++-msvc11)))

(define (code:header?)
  (member (language) '(c c++ c++03 c++-msvc11)))

(define (code:dir o)
  (if (member (language) '(javascript)) "dzn/" ""))

(define (code:module root)
  (let ((module (make-module 31 `(,(resolve-module '(gaiag code))
                                  ,(resolve-module `(gaiag ,(language)))))))
    (module-define! module 'root root)
    module))

(define (code:skel-file model)
  ((->symbol-join '_) (append (drop-right (code:scope+name model) 1) '(skel) (take-right (code:scope+name model) 1))))


;;  glue

(define (event2->interface1-event1-alist- string)
  (and-let* ((string string)
             (lst (string-split string #\newline))
             (lst (filter (lambda (x) (not (string-prefix? "//" x))) lst))
             (lst (map (lambda (o) (map string->symbol (string-tokenize o char-set:graphic))) lst))
             (lst (filter pair? lst)))
            (fold (lambda (e r) (acons (third e) (take e 2) r)) '() lst)))

(define (event2->interface1-event1-alist port-or-model)
  (event2->interface1-event1-alist-
   ((compose gulp-file map-file) port-or-model)))

(define* ((asd-interfaces #:optional (dir? identity)) model)
  (let* ((interfaces
          (filter dir? ((compose .elements .events) model)))
         (alist (event2->interface1-event1-alist model))
         (interfaces (filter-map (lambda (x) (assoc (.name x) alist)) interfaces)))
    (if (pair? interfaces) interfaces '())))

(define (map-file o)
  (let* ((files (command-line:get '() '()))
         (map-files (filter (cut string-suffix? ".map" <>) files))
         (map-file-name (string-append (symbol->string (map-file-name o)) ".map"))
         (map-files (if (pair? map-files) map-files (list map-file-name))))
    (and=> (find (lambda (f) (equal? (basename f) map-file-name)) map-files)
           try-find-file)))

(define (map-file-name o)
  (match o
    ((or ($ <foreign>) ($ <component>) ($ <system>)) (map-file-name (om:port o)))
    (_ ((om:scope-name) o)))) ;; dzn::IConsole ==> dzn_IConsole.map

(define (string->mapping string)
  (and-let* ((string string)
             (lst (string-split string #\newline))
             (lst (filter (lambda (x) (not (string-prefix? "//" x))) lst))
             (lst (map (lambda (o) (map string->symbol (string-tokenize o char-set:graphic))) lst))
             (lst (filter pair? lst)))
    lst))

(define (mapping->channel mapping)
  (let loop ((lst mapping))
    (if (null? lst) '()
        (let ((channel (caar lst)))
          (receive (same rest)
              (partition (lambda (m) (eq? (car m) channel)) lst)
            (append (list (cons (caar same) (map cdr same))) (loop rest)))))))
