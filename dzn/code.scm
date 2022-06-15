;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (dzn display)
  #:use-module (dzn shell-util)
  #:use-module (dzn config)

  #:use-module (dzn ast)
  #:use-module (dzn code dzn)
  #:use-module (dzn normalize)
  #:use-module (dzn templates)
  #:use-module (dzn vm goops)

  #:export (<port-pair>
           .other
            %calling-context
            %queue-size
            %shell
            code
            code:add-calling-context
            code:add-calling-context-argument
            code:add-calling-context-formal
            code:annotate-shells
            code:arguments
            code:assign-reply
            code:bind-provides
            code:bind-requires
            code:capture-local
            code:capture-member
            code:class-member?
            code:component-include
            code:component-port
            code:declarative-or-imperative
            code:default-true
            code:defer-condition
            code:enum-definer
            code:enum-field-definer
            code:enum-literal
            code:enum-name
            code:enum-scope
            code:enum-short-name
            code:expand-on
            code:expression
            code:extension
            code:file-name
            code:formals
            code:function-type
            code:functions
            code:global-enum-definer
            code:injected-bindings
            code:injected-instances
            code:injected-instances-system
            code:instance*
            code:instance-name
            code:instance-port-name
            code:interface-include
            code:main-event-map-match-return
            code:main-out-arg
            code:main-out-arg-define
            code:model
            code:non-injected-bindings
            code:non-injected-instances
            code:om
            code:ons
            code:out-argument
            code:port-bind?
            code:port-name
            code:port-release
            code:port-type
            code:pump?
            code:reply
            code:reply-type
            code:reply-types
            code:requires-in-void-returns
            code:return
            code:return-values
            code:trace-q-out
            code:trigger
            code:type-name
            code:upcase-model-name
            code:used-foreigns
            code:variable->argument
            code:variable-name
            string->enum-field)
  #:re-export (.port
               .port.name))

;; The calling-context to insert.
(define %calling-context (make-parameter #f))

;; The size of the queue.
(define %queue-size (make-parameter #f))

;; The name of the thread-safe shell.
(define %shell (make-parameter #f))

;;;
;;; Ast extension.
;;;
(define-ast <port-pair> (<ast>)
  (port)
  (other))

(define-method (.port.name (o <port-pair>)) (.name (.port o)))
(define-method (.other.name (o <port-pair>)) (.name (.other o)))

;;;
;;; Top
;;;
(define-method (code:model (o <root>))
  (let* ((models (ast:model* o))
         (models (filter (negate (disjoin (is? <type>) (is? <namespace>)
                                          ast:imported?))
                         models))
         (models (ast:topological-model-sort models))
         (models (map code:annotate-shells models)))
    models))

(define-method (code:interface-include o)
  (map (compose (cut make <file-name> #:name <>) code:file-name)
       (delete-duplicates
        (filter (compose (cut (negate equal?) (ast:source-file o) <>) ast:source-file .type)
                (ast:port* o)))))

(define-method (code:interface-include (o <foreign>))
  (map (compose (cut make <file-name> #:name <>) code:file-name)
       (filter (compose (cut (negate equal?) (ast:source-file (parent o <root>)) <>) ast:source-file)
               (map .type (ast:port* o)))))

(define (code:component-include o)
 (filter (disjoin
          (compose (is? <foreign>) .type)
          (conjoin (compose ast:imported? .type) (lambda (i) (not (equal? (ast:source-file o)
                                                                          (ast:source-file (.type i)))))))
         (ast:instance* o)))

(define-method (code:pump? (o <root>))
  (filter (conjoin (negate ast:imported?) (is? <component>)
                   (compose pair? ast:req-events))
          (ast:model* o)))


;;;
;;; Names
;;;
(define-method (code:file-name (o <port>))
  (code:file-name (.type o)))

(define-method (code:file-name (o <instance>))
  (code:file-name (.type o)))

(define-method (code:file-name (o <foreign>))
  ((compose (cut string-join <> "_") ast:full-name) o))

(define-method (code:file-name (o <ast>))
  (basename (ast:source-file o) ".dzn"))

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
  (let* ((model (parent o <model>))
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

(define-method (code:type-name o)
  (let* ((type (or (as o <model>) (as o <type>) (ast:type o))))
    (match type
      (($ <enum>) (code:type-name type))
      (($ <extern>) (list (.value type)))
      (($ <bool>) '("bool"))
      (($ <int>) '("int"))
      (($ <void>) '("void"))
      (_ (ast:full-name type)))))

(define-method (code:type-name (o <event>))
  ((compose code:type-name .type .signature) o))

(define-method (code:type-name (o <enum-literal>))
  (code:type-name (.type o)))

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

(define-method (code:variable-name (o <ast>))
  ((compose code:variable-name .variable) o))

(define-method (code:upcase-model-name o)
  (map string-upcase (ast:full-name (parent o <model>))))


;;;
;;; Accessors
;;;
(define-method (code:functions (o <component>))
  (ast:function* o))

(define-method (code:ons (o <component>))
  (let ((behavior (.behavior o)))
    (if (not behavior) '()
        (ast:statement* behavior))))

(define-method (code:ons (o <port>))
  (let* ((component (parent o <component>))
         (behavior (.behavior component))
         (ons (if (not behavior) '()
                  (ast:statement* behavior))))
    (define (this-port? p)
      (equal? (.name o) (.port.name (car (ast:trigger* p)))))
    (filter this-port? ons)))

(define-method (code:reply (o <type>))
  o)

(define-method (code:return-type-eq? (a <int>) (b <int>))
  #t)
(define-method (code:return-type-eq? a b)
  (ast:eq? a b))
(define (code:reply-types o)
  (delete-duplicates (filter (negate (is? <void>)) (ast:return-types o)) code:return-type-eq?))

(define-method (code:trigger (o <on>))
  ((compose car ast:trigger*) o))

(define-method (code:trigger (o <port>))
  (map code:trigger (code:ons o)))


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
  (if (null? (tree-collect-filter
              (negate (disjoin (is? <imperative>)
                               (is? <expression>)
                               (is? <location>)))
              (disjoin (is? <blocking>) (is? <blocking-compound>))
              (parent o <model>))) '()
      o))

(define-method (code:default-true (o <defer>))
  (let ((p (parent o <component>)))
    (if (null? (ast:variable* p)) o
        '())))

(define-method (code:defer-condition (o <defer>))
  (let ((p (parent o <component>)))
    (if (pair? (ast:variable* p)) o
        '())))

(define-method (code:capture-local (o <defer>))
  (let* ((references (tree-collect (disjoin(is? <assign>)
                                           (is? <argument>)
                                           (is? <var>))
                                   (.statement o)))
         (variables (map .variable references)))
    (filter (negate ast:member?) variables)))

(define-method (code:capture-member (o <component>))
  (ast:variable* o))

(define-method (code:capture-member (o <defer>))
  (code:capture-member (parent o <component>)))

(define-method (code:capture-member (o <variable>))
  o)


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

(define-method (code:arguments (o <call>))
  (map code:variable->argument
       (code:add-calling-context-argument (ast:argument* o))
       (ast:formal* (code:add-calling-context-formal ((compose .formals .signature .function) o)))))

(define-method (code:arguments (o <action>))
  (if (and (ast:async? o)
           (equal? (.event.name o) "clr"))
      (map code:variable->argument
           (ast:argument* o)
           (ast:formal* ((compose .formals .signature .event) o)))
      (map code:variable->argument
           (code:add-calling-context-argument (ast:argument* o))
           (ast:formal* (code:add-calling-context-formal ((compose .formals .signature .event) o))))))

(define-method (code:arguments (o <trigger>))
  (code:formals o))

(define-method (code:out-argument (o <trigger>))
  (filter (disjoin ast:out? ast:inout?) (code:formals o)))

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

(define-method (code:variable-name (o <argument>))
  o)


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
  (filter (is? <enum>) (append (ast:type* o) (ast:type* (.behavior o)))))

(define-method (code:enum-definer (o <component>))
  (filter (is? <enum>) (ast:type* (.behavior o))))

(define-method (code:global-enum-definer (o <root>))
  (filter (is? <enum>) (ast:type* o)))

(define-method (code:global-enum-definer (o <model>))
  (filter (is? <enum>) (ast:type* (parent o <root>))))

(define-method (code:global-enum-definer (o <root>))
  (filter (is? <enum>) (ast:type* o)))

(define-method (code:enum-literal (o <enum-literal>))
  (append (code:type-name (.type o)) (list (.field o))))

(define-method (code:enum-scope (o <enum-literal>))
  (let* ((enum (.type o))
         (scope (ast:full-scope enum))
         (model-scope (and=> (parent o <model>) ast:full-name)))
    (cond ((or (null? scope) (null? model-scope)) (parent enum <root>))
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

(define-method (code:instance* (o <system>))
  (ast:instance* o))
(define-method (code:instance* o)
  '())

(define-method (code:instance-name (o <binding>))
  (let* ((model (parent o <model>))
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

;; (define-method (code:injected-instances (o <system>))
;;   (if (null? (code:injected-bindings o)) '()
;;       (injected-instances o)))

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

(define (injected-binding binding)
  (cond ((equal? "*" (.port.name (.left binding))) (.right binding))
        ((equal? "*" (.port.name (.right binding))) (.left binding))
        (else #f)))

(define (code:injected-bindings model)
  (filter injected-binding? (ast:binding* model)))

(define-method (code:non-injected-bindings (o <system>))
  (filter code:port-bind? (filter (negate injected-binding?) (ast:binding* o))))

(define-method (code:bind-provides-required (o <binding>))
  (let* ((model (parent o <model>))
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

(define-method (code:pump? (o <component>))
  (if ((compose pair? ast:req-events) o) o
      '()))

(define-method (code:trace-q-out o)
  (if ((compose ast:out? .event) o) o
      '()))


;;;
;;; Generated main
;;;
(define-method (code:main-out-arg (o <trigger>))
  (let* ((formals (ast:formal* o))
         (formals (map make-out-formal formals)))
    (map (lambda (f i) (clone f #:name i))
         formals (iota (length formals)))))

(define-method (code:main-out-arg-define (o <trigger>))
  (let ((formals (ast:formal* o)))
    (map (lambda (f i) (clone f #:name i))
         formals (iota (length formals)))))

(define-method (code:main-out-arg-define-formal (o <formal>))
  (let ((type ((compose .value .type) o)))
    (if (ast:in? o) ""
        o)))

(define-method (code:main-event-map-match-return (o <trigger>))
  (if (ast:in? (.event o)) o ""))


;;;
;;; Transform
;;;
(define-method (code:add-calling-context (o <root>))
  (if (%calling-context)
      (let ((extern (make <extern>
                      #:name (make <scope.name> #:ids '("*calling-context*"))
                      #:value (%calling-context))))
        (clone o #:elements (cons extern (ast:top* o))))
      o))

(define (code:add-calling-context-argument arguments)
  (if (%calling-context) (cons "dzn_cc" arguments)
      arguments))

(define-method (code:add-calling-context-formal (o <formals>))
  (if (not (%calling-context)) o
      (let* ((cc-formal (make <formal>
                          #:name "dzn_cc"
                          #:direction 'inout
                          #:type.name (make <scope.name>
                                        #:ids '("*calling-context*"))))
             (cc-formal (clone cc-formal #:parent o))
             (lst (cons cc-formal (ast:formal* o))))
        (clone o #:elements lst))))

(define (code:annotate-shells o)
  (if (and (is-a? o <system>)
           (equal? (%shell) (string-join (ast:full-name o) ".")))
      (clone (make <shell-system>
               #:ports (.ports o)
               #:name (.name o)
               #:instances (.instances o)
               #:bindings (.bindings o))
             #:parent (.parent o))
      o))

(define-method (code:return-values (o <component-model>))
  (define (trigger->port-pairs trigger)
    (map (cute make
               <port-pair>
               #:port (.port.name trigger)
               #:other <>)
         (map ->sexp (ast:return-values trigger))))
  (let* ((triggers (filter (compose not (is? <void>) ast:type)
                           (ast:requires-in-triggers o)))
         (pairs (append-map trigger->port-pairs triggers)))
    (delete-duplicates pairs (lambda (a b)
                               (and (ast:eq? (.port a) (.port b))
                                    (equal? (.other a) (.other b)))))))

(define-method (code:requires-in-void-returns (o <component-model>))
  (let ((triggers (ast:requires-in-void-triggers o)))
    (delete-duplicates triggers
                       (lambda (a b)
                         (ast:eq? (.port a) (.port b))))))

(define (code:om ast)
  (let ((root ((compose
                add-reply-port
                normalize:event+illegals
                remove-otherwise
                (binding-into-blocking)
                code:add-calling-context)
               ast)))
    (when (> (dzn:debugity) 1)
      (ast:pretty-print root (current-error-port)))
    root))


;;;
;;; Utility
;;;
(define-method (code:class-member? (o <variable>))
  (let ((p (.parent o)))
    (and (is-a? p <variables>)
         (is-a? (.parent p) <behavior>))))

(define-method (code:used-foreigns (o <root>))
  (let* ((systems (filter (conjoin (is? <system>) (negate ast:imported?)) (ast:model* o)))
         (models (map .type (append-map ast:instance* systems))))
    (filter (is? <foreign>) models)))


;;;
;;; Entry point.
;;;
(define* (code ast #:key (ast-> 'ast->) calling-context dir language locations?
               model queue-size shell)
  (let* ((module (resolve-module `(dzn code ,(string->symbol language))))
         (ast-> (false-if-exception (module-ref module ast->))))
    (unless ast->
      (format (current-error-port) "code: no such language: ~a\n" language)
      (exit EXIT_OTHER_FAILURE))
    (parameterize ((%calling-context calling-context)
                   (%locations? locations?)
                   (%queue-size queue-size)
                   (%shell shell))
      (ast-> ast #:dir dir #:model model))))
