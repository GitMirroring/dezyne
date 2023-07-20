;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2016, 2017, 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
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

(define-module (dzn code legacy code)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 curried-definitions)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast lookup)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code legacy dzn)
  #:use-module (dzn misc)

  #:export (code:arguments
            code:assign-reply
            code:bind-provides
            code:bind-requires
            code:class-member?
            code:capture-member
            code:component-port
            code:data*
            code:declarative-or-imperative
            code:default-true
            code:enum-definer
            code:enum-field-definer
            code:enum-literal
            code:enum-name
            code:enum-scope
            code:enum-short-name
            code:expand-on
            code:expression
            code:extension
            code:function-type
            code:functions
            code:global-enum-definer
            code:injected-bindings
            code:injected-instances
            code:injected-instances-system
            code:instance-name
            code:instance-port-name
            code:main-event-map-match-return
            code:main-out-arg
            code:main-out-arg-define
            code:member-equality
            code:model
            code:non-injected-bindings
            code:non-injected-instances
            code:ons
            code:out-argument
            code:port-bind?
            code:port-name
            code:port-release
            code:port-reply
            code:port-type
            code:reply
            code:reply-type
            code:return
            code:trace-q-out
            code:trigger
            code:upcase-model-name
            code:used-foreigns
            code:variable->argument
            code:variable-name
            string->enum-field))

;;;
;;; Top
;;;
(define-method (code:model (o <root>))
  (let* ((models (ast:model** o))
         (models (filter (negate (disjoin (is? <type>) (is? <namespace>)
                                          ast:imported?))
                         models))
         (models (ast:topological-model-sort models))
         (models (map code:annotate-shells models)))
    models))


;;;
;;; Names
;;;
(define-method (code:function-type (o <type>))
  o)

(define-method (code:function-type (o <trigger>))
  ((compose code:function-type .signature .event) o))

(define-method (code:function-type (o <signature>))
  ((compose code:function-type .type) o))

(define-method (code:function-type (o <function>))
  ((compose code:function-type .signature) o))

(define-method (code:port-name (o <on>))
  ((compose .port.name car ast:trigger*) o))

(define-method (code:port-name (o <instance>))
  (let ((component (.type o)))
    (.name (car (ast:provides-port* component)))))

(define-method (code:port-name (o <binding>))
  (let* ((model (ast:parent o <model>))
         (left (.left o))
         (right (.right o))
         (port (and (code:port-bind? o)
                    (if (not (.instance.name left)) (.port left) (.port right)))))
    port))

(define-method (code:port-type (o <trigger>))
  ((compose code:port-type .port) o))

(define-method (code:port-type (o <port>))
  (ast:full-name (.type o)))

(define-method (code:reply-type (o <ast>))
  (ast:full-name o))

(define-method (code:reply-type (o <int>))
  "int")

(define-method (code:reply-type (o <trigger>))
  (code:reply-type (ast:type o)))

(define-method (code:reply-type (o <reply>))
  ((compose code:reply-type ast:type .expression) o))

(define-method (code:variable-name (o <variable>))
  (if (code:class-member? o) o
      (make <local> #:name (.name o) #:type.name (.type.name o)
            #:expression (.expression o))))

(define (make-out-formal formal)
  (let* ((type (.type.name formal))
         (out-formal (make <out-formal> #:name (.name formal) #:type.name type))
         (out-formal (clone out-formal #:parent formal)))
    (if (ast:in? formal) formal out-formal)))

(define-method (code:variable-name (o <formal>))
  (make-out-formal o))

(define-method (code:variable-name (o <top>))
  o)

(define-method (code:variable-name (o <assign>))
  ((compose code:variable-name .variable) o))

(define-method (code:variable-name (o <field-test>))
  ((compose code:variable-name .variable) o))

(define-method (code:variable-name (o <var>))
  ((compose code:variable-name .variable) o))

(define-method (code:variable-name (o <argument>))
  o)

(define-method (code:upcase-model-name (o <model>))
  (map string-upcase (ast:full-name o)))

(define-method (code:upcase-model-name o)
  (code:upcase-model-name (ast:parent o <model>)))


;;;
;;; Accessors
;;;
(define-method (code:functions (o <component>))
  (ast:function* o))

(define-method (code:ons (o <component>))
  (let ((behavior (.behavior o)))
    (if (not behavior) '()
        (ast:statement* (.statement behavior)))))

(define-method (code:ons (o <port>))
  (let* ((component (ast:parent o <component>))
         (behavior (.behavior component))
         (ons (if (not behavior) '()
                  (ast:statement* (.statement behavior)))))
    (define (this-port? p)
      (equal? (.name o) (.port.name (car (ast:trigger* p)))))
    (filter this-port? ons)))

(define-method (code:reply (o <type>))
  o)

(define-method (code:trigger (o <on>))
  ((compose car ast:trigger*) o))

(define-method (code:trigger (o <port>))
  (map code:trigger (code:ons o)))

(define-method (code:capture-member (o <defer>))
  (ast:defer-variable* o))

(define-method (code:capture-member (o <variable>))
  o)

(define-method (code:member-equality (o <defer>))
  (code:defer-equality* o))


;;;
;;; Statements
;;;
(define-method (code:expand-on (o <statement>))
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (clone (make <otherwise-guard>
               #:expression (.expression o)
               #:statement (.statement o))
             #:parent (.parent o))
      o))

(define-method (code:expand-on (o <on>))
  (.statement o))

(define-method (code:assign-reply (o <reply>))
  (let ((expression (.expression o)))
    (if (is-a? (ast:type expression) <void>) '()
        o)))

(define-method (code:return (o <trigger>))
  (ast:type o))

(define-method (code:return (o <on>))
  (code:return (code:trigger o)))

(define-method (code:port-release o)
  (let ((trigger (and=> (ast:parent o <on>)
                        (compose car ast:trigger*))))
    (and (or (not trigger)
             (ast:requires? trigger)
             (or (not (ast:equal? (.port o) (.port trigger)))
                 (ast:parent o <blocking>)
                 (ast:parent o <blocking-compound>)))
         (code:blocking? o)
         o)))

(define-method (code:port-reply o)
  (let ((port (.port o)))
    (and (ast:provides? port)
         port)))

(define-method (code:default-true (o <defer>))
  (if (or (and=> (.arguments o) (compose null? .elements))
          (null? (ast:variable* (ast:parent o <component>)))) o
          '()))


;;;
;;; Expressions
;;;
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

(define-method (code:arguments (o <ast>) (signature <signature>))
  (map code:variable->argument
       (ast:argument* o)
       (ast:formal* signature)))

(define-method (code:arguments (o <call>))
  (code:arguments o (.signature (.function o))))

(define-method (code:arguments (o <action>))
  (code:arguments o (.signature (.event o))))

(define-method (code:arguments (o <trigger>))
  (ast:argument* o))

(define-method (code:out-argument (o <trigger>))
  (filter (disjoin ast:out? ast:inout?) (ast:formal* o)))

(define-method (code:variable->argument (o <expression>) (v <variable>) (f <formal>))
  (if (or (code:class-member? v) (eq? (.direction f) 'in)) v
      (let ((argument (make <argument>
                        #:name (.name v)
                        #:type.name (.type.name f)
                        #:direction (.direction f)
                        #:expression o)))
        (clone argument #:parent (.parent o)))))

(define-method (code:variable->argument (o <expression>) (v <formal>) (f <formal>))
  (if (eq? (.direction f) 'in) v
      (let ((argument (make <argument>
                        #:name (.name v)
                        #:type.name (.type.name v)
                        #:direction (.direction v)
                        #:expression o)))
        (clone argument #:parent (.parent o)))))

(define-method (code:variable->argument (o <var>) (f <formal>))
  (code:variable->argument o (.variable o) f))

(define-method (code:variable->argument (o <formal>) (f <formal>))
  (code:variable->argument o o f))

(define-method (code:variable->argument o f)
  o)

(define-method (code:data* (o <root>))
  (filter (negate ast:imported?) (ast:data* o)))


;;;
;;; Enum
;;;
(define ((string->enum-field enum) o i)
  (make <enum-field> #:type.name (.name enum) #:field o #:value i))

(define-method (code:enum-field-definer (o <enum>))
  (map (string->enum-field o) (ast:field* o) (iota (length (ast:field* o)))))

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

(define-method (code:enum-definer (o <interface>))
  (filter (is? <enum>) (ast:type** o)))

(define-method (code:enum-definer (o <component>))
  (filter (is? <enum>) (ast:type* (.behavior o))))

(define-method (code:global-enum-definer (o <root>))
  (filter (conjoin (is? <enum>)
                   (negate ast:imported?))
          (ast:type** o)))

(define-method (code:global-enum-definer (o <model>))
  (filter (is? <enum>) (ast:type** (ast:parent o <root>))))

(define-method (code:enum-literal (o <enum-literal>))
  (cons (code:type-name (.type o)) (list (.field o))))

(define-method (code:enum-scope (o <enum-literal>))
  (let* ((enum (.type o))
         (scope (ast:full-scope enum))
         (model-scope (and=> (ast:parent o <model>) ast:full-name)))
    (cond ((or (null? scope) (null? model-scope)) (ast:parent enum <root>))
          ((equal? scope model-scope) (make <model-scope> #:scope model-scope))
          (else enum))))

(define-method (code:enum-short-name (o <enum-field>))
  ((compose code:enum-short-name .type) o))

(define-method (code:enum-short-name (o <enum>))
  (ast:name o))

(define-method (code:enum-short-name (o <enum-literal>))
  (code:enum-short-name (.type o)))


;;;
;;; System
;;;
(define-method (code:component-port (o <port>))
  (ast:other-end-point o))

(define-method (code:instance-name (o <binding>))
  (let* ((model (ast:parent o <model>))
         (left (.left o))
         (right (.right o))
         (bind (and (code:port-bind? o)
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

(define (injected-instance-name binding)
  (or (.instance.name (.left binding)) (.instance.name (.right binding))))

(define (code:injected-instances model)
  (let ((injected-instance-names (map injected-instance-name (code:injected-bindings model))))
    (filter (lambda (instance) (member (.name instance) injected-instance-names))
            (ast:instance* model))))

(define (code:non-injected-instances model)
  (let ((injected-instance-names (map injected-instance-name (code:injected-bindings model))))
    (filter (lambda (instance) (not (member (.name instance) injected-instance-names)))
            (ast:instance* model))))

(define-method (code:injected-instances-system (o <system>))
  (if (null? (code:injected-bindings o)) '()
      (list o)))

(define (code:port-bind? bind)
  (and (code:port-binding? bind)
       bind))

(define (code:port-binding? bind)
  (or (and (not (.instance.name (.left bind)))
           (.left bind))
      (and (not (.instance.name (.right bind)))
           (.right bind))))

(define (injected-binding? binding)
  (or (equal? "*" (.port.name (.left binding)))
      (equal? "*" (.port.name (.right binding)))))

(define (code:injected-bindings model)
  (filter injected-binding? (ast:binding* model)))

(define-method (code:non-injected-bindings (o <system>))
  (filter code:port-bind? (filter (negate injected-binding?) (ast:binding* o))))

(define-method (code:bind-provides-required (o <binding>))
  (let* ((model (ast:parent o <model>))
         (left (.left o))
         (left-port (.port left))
         (right (.right o))
         (right-port (.port right)))
    (if (ast:provides? left-port)
        (cons left right)
        (cons right left))))

(define-method (code:bind-provides (o <binding>))
  ((compose car code:bind-provides-required) o))

(define-method (code:bind-requires (o <binding>))
  ((compose cdr code:bind-provides-required) o))

(define-method (code:trace-q-out o)
  (if ((compose ast:out? .event) o) o
      '()))

(define-method (code:type-name (o <binding>))
  ((compose code:type-name
            .type
            (cute ast:lookup (ast:parent o <model>) <>)
            injected-instance-name)
   o))


;;;
;;; Generated main
;;;
(define-method (code:main-out-arg (o <trigger>))
  (let* ((formals (ast:formal* o))
         (formals (map make-out-formal formals)))
    (map (lambda (f i) (clone f #:name i))
         formals (iota (length formals)))))

(define-method (code:main-out-arg-define (o <trigger>))
  (let* ((formals (ast:formal* o))
         (formals (map (lambda (f i) (clone f #:name i))
                       formals (iota (length formals)))))
    (filter (disjoin ast:out? ast:inout?) formals)))

(define-method (code:main-out-arg-define-formal (o <formal>))
  (let ((type ((compose .value .type) o)))
    (if (ast:in? o) ""
        o)))

(define-method (code:main-event-map-match-return (o <trigger>))
  (if (ast:in? (.event o)) o ""))


;;;
;;; Utility
;;;
(define-method (code:class-member? (o <variable>))
  (let ((p (.parent o)))
    (and (is-a? p <variables>)
         (is-a? (.parent p) <behavior>))))

(define-method (code:used-foreigns (o <root>))
  (let* ((systems (filter (conjoin (is? <system>) (negate ast:imported?)) (ast:model** o)))
         (models (map .type (append-map ast:instance* systems))))
    (filter (is? <foreign>) models)))
