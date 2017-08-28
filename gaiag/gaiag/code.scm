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
  #:use-module (ice-9 peg)
  #:use-module (ice-9 peg codegen)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag lexicals)
  #:use-module (gaiag ast2om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag util)

  #:use-module (gaiag deprecated animate)
  #:use-module (gaiag deprecated code)

  #:use-module (gaiag command-line)
  #:use-module (gaiag compare)
  #:use-module (gaiag indent)
  #:use-module (gaiag misc)
  #:use-module (gaiag norm-event)
  #:use-module (gaiag resolve)
  #:use-module (gaiag xpand)

  #:use-module (language dezyne location)

  #:export (<enum-field>
            code:formals
            code:instance-name
            code:annotate-shells

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

            code-file
            code:file-name
            code:dump-file
            code:extension
            code:indenter
            code:module
            code:om
            code:->string
            symbol->enum-field
            dump
            dump-component
            dump-global
            dump-interface
            dump-indented
            dump-main
            dump-system
            glue
            language
            pipe))

;;; ast extension
(define-class <argument> (<named> <expression>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (direction #:getter .direction #:init-value #f #:init-keyword #:direction))

(define-class <enum-field> (<ast>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

(define-class <file-name> (<ast>)
  (name #:getter .name #:init-form #f #:init-keyword #:name))

(define-class <model-scope> (<ast>))

(define-class <out-formal> (<variable>))

(define-class <local> (<variable>))

(define (code:source o)
  (topological-sort (filter (negate (is? <type>)) (map code:annotate-shells (.elements o)))))

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

(define-method (code:formals (o <function>))
  ((compose .elements .formals .signature) o))

(define-method (code:formals (o <action>))
  ((compose .elements .formals .signature .event) o))

(define-method (code:formals (o <trigger>))
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

(define-method (.statement (o <statement>)) o)
(define-method (code:on-statement (o <statement>))
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
      o))
(define-method (code:on-statement (o <on>))
  (let ((o (.statement o)))
   (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
       (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
       o)))


(define-method (code:non-blocking-identity (o <function>))
  (.statement o))

(define-method (code:non-blocking-identity (o <statement>))
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
      o))

(define-method (code:statement (o <statement>)) o)


(define-method (code:guard-statement (o <statement>))
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
      o))
(define-method (code:guard-statement (o <guard>))
  (let ((o (.statement o)))
   (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
       (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
       o)))


(define-method (.expression (o <value>)) (.value o))

(define-method (.expression (o <top>)) #f)

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

(define (code:->string o)
  (match o
    ((? number?) (number->string o))
    ((? symbol?) (symbol->string o))
    ((? string?) o)))

(define-method (code:data (o <data>))
  (code:->string (.value o)))

(define-method (code:expression-expand (o <not>))
  (.expression o))

(define-method (code:expression-expand (o <var>))
  (.variable o))

(define-method (code:expression-expand (o <field>))
  (make <literal> #:type ((compose .type .variable) o) #:field (.field o)))

(define-method (code:expression-expand (o <variable>))
  (code:variable-name o))

(define-method (code:expression-expand (o <formal>))
  (code:variable-name o))

(define-method (code:expression-expand (o <reply>))
  o)

(define-method (code:expression (o <field>))
  o)

(define-method (code:expression (o <and>))
  o)

(define-method (code:expression (o <action>))
  o)

(define-method (code:expression (o <call>))
  o)

(define-method (code:expression (o <statement>))
  (.expression o))

(define-method (code:expression (o <formal>))
  (code:variable-name o))

(define-method (code:expression (o <variable>))
  (code:variable-name o))

(define-method (code:expression (o <return>))
  (if (or (not (.expression o)) (eq? (.expression o) *unspecified*)) ""  ; MORTAL SIN HERE!!?
          (.expression o)))

(define-method (code:expression (o <var>))
  (.variable o))

(define-method (code:expression (o <unary>))
  o)

(define-method (code:expression (o <top>))
  o)

(define-method (code:expression (o <reply>))
  (.expression o))

(define-class <unspecified> (<ast>))

(define-method (code:unspecified)
  (if (memq (language) '(c++ c++03 c++-msvc11)) "" ; MORTAL SIN HERE!!?
      (make <unspecified>))) ; FIXME: or javascript: "undefined"  here?

(define-method (code:=expression (o <ast>))
  (match (.expression o)
    ((and ($ <value>) (= .value (? unspecified?))) (code:unspecified))
    ((? unspecified?) (code:unspecified))
    (_ (.expression o))))

(define-method (code:reply-type (o <ast>))
  ((compose code:scope+name ast:expression-type) o))

(define-method (code:reply-type (o <reply>))
  ((compose code:reply-type .expression) o))

(define-method (code:declarative-or-imperative (o <compound>))
  (if (om:imperative? o) o
      (make <declarative-compound> #:elements o)))

(define-method (code:scope.name (o <literal>))
  (code:scope.name (.type o)))

(define-method (code:scope.name (o <ast>))
  (.name o))

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

(define-method (code:type-name o)
  (let* ((type (or (as o <model>) (as o <type>) (.type o)))
         (scope+name (code:scope+name type)))
    (map code:->string
         (match type
           (($ <enum>) (code:cons-empty-symbol (append scope+name (list 'type))))
           (($ <extern>) (list (.value type)))
           ((or ($ <bool>) ($ <int>) ($ <void>)) scope+name)
           (_ (code:cons-empty-symbol scope+name))))))

(define-method (code:type-name (o <event>))
  ((compose code:type-name .type .signature) o))

(define-method (code:type-name (o <enum-field>))
  (map code:->string (code:cons-empty-symbol (code:scope+name o))))

(define-method (code:type-name (o <literal>))
  (map code:->string (code:cons-empty-symbol (code:scope+name o))))

(define-method (code:field-expression (o <field>))
  (map code:->string (code:cons-empty-symbol
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

(define-method (code:scope-type-scope (o <field>))
  ((compose code:scope-type-scope .type .variable) o))

(define-method (code:scope-type-name o)
  ((compose .name code:scope.name) o))

(define-method (code:scope-type-name (o <field>))
  ((compose code:scope-type-name .type .variable) o))

(define (code:x-header- o) (filter (is? <interface>) (.elements o)))

;;

;;; code: generic templates
(define-template x:header- code:x-header-)
(define-template x:source code:source)

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

(define-template x:non-void-reply identity #f)

(define-method (code:enum-literal (o <literal>))
  (map code:->string (cons (symbol) (code:scope+name o))))

(define-method (code:enum-scope (o <field>))
  ((compose code:enum-scope .type .variable) o))

(define-method (code:enum-scope (o <literal>))
  ((compose code:enum-scope .type) o))

(define-method (code:enum-scope (o <enum>))
  (let ((scope ((compose .scope .name) o))
        (model-scope (om:scope+name (ast:model-scope))))
    (if (or (null? scope) (equal? scope model-scope)) (make <model-scope>)
        o)))

(define-template x:enum-literal code:enum-literal 'type-infix)
(define-template x:enum-scope code:enum-scope 'type-infix)

(define-template x:reply (lambda (o)
                           (if (is-a? o <void>)
                               ""
                               (begin (display " ") (x:non-void-reply o))))) ;; MORTAL SIN HERE!!?

(define-template x:model-name (compose om:name (lambda (_) (ast:model-scope))))

(define-template x:upcase-model-name (compose string-upcase (->join "_") code:scope+name (lambda (_) (ast:model-scope))))

(define-template x:capitalize-model-name (compose string-capitalize symbol->string .name .name (lambda (o) (ast:model-scope))))

(define-template x:method code:trigger)

(define-template x:formals code:formals 'formal-infix)
(define-template x:formals-type code:formals 'formal-infix)

(define-template x:methods code:ons)
(define-template x:functions code:functions)

(define-template x:field code:field-expression 'type-infix)

(define-template x:data code:data)

(define-template x:expression code:expression)

(define-template x:left (compose code:expression .left) #f <expression>)
(define-template x:right (compose code:expression .right) #f <expression>)

(define-template x:expression-expand code:expression-expand #f <expression>)



(define-template x:=expression code:=expression #f <expression>)
(define-template x:reply-type code:reply-type 'name-infix)
(define-template x:then .then #f <statement>)

(define-template x:else (lambda (o) (or (.else o) '())) #f <statement>)

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


(define-template x:statement code:non-blocking-identity)

(define-template x:all-ports-meta-list om:ports 'meta-infix)

(define-template x:in-event-definer (lambda (o) (filter om:in? (om:events o))) 'event-definer-infix)
(define-template x:out-event-definer (lambda (o) (filter om:out? (om:events o))) 'event-definer-infix)

(define-template x:enum-definer (lambda (o) (append (om:enums o) (om:enums))))


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

(define-template x:arguments code:arguments 'argument-infix <expression>)

(define-template x:out-arguments code:out-argument 'argument-prefix <expression>)

(define-template x:return code:return #f <type>)


;; main
(define-template x:main-port-connect-in ast:out-triggers-in-events)
(define-template x:main-port-connect-in-void ast:out-triggers-void-in-events)
(define-template x:main-port-connect-in-valued ast:out-triggers-valued-in-events)
(define-template x:main-port-connect-out ast:out-triggers-out-events)
(define-template x:main-provided-port-init ast:provided)
(define-template x:main-required-port-init ast:required)

(define-template x:main-out-arg code:main-out-arg 'argument-infix)
(define-template x:main-event-map-void ast:void-in-triggers 'event-map-prefix)
(define-template x:main-event-map-valued ast:valued-in-triggers 'event-map-prefix)
(define-template x:main-event-map-flush ast:required 'event-map-prefix)

(define-template x:main-event-map-match-return code:main-event-map-match-return)
(define-template x:main-required-port-name ast:required 'main-port-name-infix)


;;; dump to file

(define (code:dump-file file-name module) ;; FIXME: c++ (c-like?) only
  (dump-output (string-append file-name ".hh")
               (lambda ()
                 (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
                   (x:pand 'header-root (module-ref module 'root) module))))
  (if (pair? (filter (negate (disjoin (is? <data>) (is? <interface>))) (.elements (module-ref module 'root))))
      (dump-output (string-append file-name ".cc")
                   (lambda ()
                     (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
                       (x:pand 'source-root (module-ref module 'root) module))))))

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

(define code:indenter (make-parameter indent))

(define (code:om ast)
  ((compose-root
    (lambda (o)
      (let ((model-names (map (compose .name car) (@@ (gaiag om) *ast-alist*))))
        (if (and (member (language) '(c++ c++03 c++-msvc11 javascript))
                 (not (member 'iclient_socket model-names))
                 (not (member 'imodelchecker model-names)))
            (code-norm-event o)
            (code-norm-event-auwe-meuk o))))
    ast:resolve
    ast->om
    ) ast))

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define (dump-indented file-name thunk)
  (dump-output file-name
               (if (code:indenter)
                   (lambda () (pipe thunk (lambda () ((code:indenter)))))
                   thunk)))


(define (dump-global o)
  (and-let* (((null-is-#f (om:enums)))
             (template (template-file `(global ,(symbol-append (code:extension o) '.scm))))
             ((file-exists? (components->file-name template))))
            (dump-indented (list 'dzn 'global (code:extension o))
                           (lambda ()
                             (code-file 'global (code:module o))))))

(define (dump o)
  (match o
    (($ <interface>) (dump-interface o))
    ((or ($ <component>) ($ <foreign>)) (dump-component o))
    (($ <system>) (dump-system o))))

(define (dump-interface o)
  (dump-global o)
  (let ((name ((om:scope-name) o)))
    (dump-indented `(,@(code:dir o) ,name ,(code:extension o))
                   (lambda ()
                     (code-file 'interface (code:module o))))))

(define (code:dir o)
  (if (eq? (language) 'cs) '()
      '(dzn)))

(define (dump-component o)
  (dump-global o)
  (let ((name ((om:scope-name) o))
        (interfaces (map .type ((compose .elements .ports) o))))
    (when (not (is-a? o <foreign>))
      (map dump interfaces)
      (dump-indented `(,@(code:dir o) ,name ,(code:extension o))
                     (lambda ()
                       (code-file 'component (code:module o)))))
    (dump-main o)))

(define (dump-main o)
  (and-let* ((name ((om:scope-name) o))
             (model (and (and=> (command-line:get 'model #f) string->symbol)))
             ((is-a? o <component-model>))
             ((eq? model name)))
            (dump-indented (symbol-append 'main (code:extension o))
                           (lambda ()
                             (code-file 'main (code:module o))))))

(define (dump-system o)
  (let* ((name ((om:scope-name) o))
         (model (and (and=> (command-line:get 'model #f) string->symbol)))
         (interfaces (map .type ((compose .elements .ports) o)))
         (shell (command-line:get 'shell #f))
         (template (if (and shell (eq? name (string->symbol shell))) 'shell 'system)))
    (dump-indented `(,@(code:dir o) ,name ,(code:extension o))
                   (lambda ()
                     (code-file template (code:module o))))
    (dump-main o)))

(define (code-file file-name module)
  (let ((model (module-ref module 'model)))
   (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
     (code:animate-file (symbol-append file-name (code:extension model) '.scm) module))))

(define (language)
  (string->symbol (command-line:get 'language "c++")))

(define (code:extension o)
  (match o
    (($ <interface>)
     (assoc-ref '((c . .h)
                  (c++ . .hh)
                  (c++03 . .hh)
                  (c++-msvc11 . .hh)
                  (dzn . .dzn)
                  (scheme . .scm)
                  (java . .java)
                  (java7 . .java)
                  (javascript . .js)
                  (cs . .cs)
                  (python . .py))
                (language)))
    ((or ($ <foreign>) ($ <component>) ($ <system>))
     (assoc-ref '((c . .c)
                  (c++ . .cc)
                  (c++03 . .cc)
                  (c++-msvc11 . .cc)
                  (dzn . .dzn)
                  (scheme . .scm)
                  (java . .java)
                  (java7 . .java)
                  (javascript . .js)
                  (cs . .cs)
                  (python . .py))
                (language)))))

(define (code:dir o)
  (if (eq? (language) 'cs) '()
      '(dzn)))

(define* (code:module o)
  (let ((module (make-module 31 (list
                                 (resolve-module (list 'gaiag (language)))
                                 (resolve-module '(gaiag lexicals))
                                 (resolve-module '(gaiag misc))
                                 (resolve-module '(oop goops))
                                 (resolve-module '(gaiag goops))
                                 (resolve-module '(gaiag deprecated code))))))
    (module-define! module 'model o)
    (module-define! module '.model (om:name o))
    (module-define! module '.scope_model ((om:scope-name) o))
    (match o
      (($ <interface>)
       (module-define! module '.interface (om:name o))
       (let ((events (.events o)))
         (module-define! module 'events events)
         (module-define! module 'in-events (filter om:in? (.elements events)))
         (module-define! module 'out-events (filter om:out? (.elements events))))
       (module-define! module '.scope_interface ((om:scope-name) o))
       (module-define! module '.INTERFACE (string-upcase (symbol->string ((om:scope-name) o)))))
      ((? (is? <model>))
       (module-define! module '.COMPONENT (string-upcase (symbol->string ((om:scope-name) o))))))
      module))
