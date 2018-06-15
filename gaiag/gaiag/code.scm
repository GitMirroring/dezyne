;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2016, 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
;; Copyright © 2014, 2015, 2016, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)
  #:use-module (gaiag config)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag resolve)
  #:use-module (gaiag shell-util)
  #:use-module (gaiag util)

  #:use-module (gaiag ast)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag compare)
  #:use-module (gaiag dzn)
  #:use-module (gaiag norm)
  #:use-module (gaiag norm-event)
  #:use-module (gaiag normalize)
  #:use-module (gaiag parse)
  #:use-module (gaiag templates)

  #:use-module (gaiag location)

  #:export (asd-interfaces
            map-file
            injected-bindings
            injected-instances
            non-injected-instances
            injected-instance-name

            code:formals
            code:language
            code:instance-name
            code:skel-file
            event2->interface1-event1-alist

            code:enum-definer
            code:enum-name
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
            code:pump?
            code:reply
            code:reply-type
            code:reply-scope+name
            code:reply-types
            code:scope+name
            code:x:pand

            code-file
            code:file-name
            code:dump
	    code:declarative-or-imperative
            code:extension
            code:dump-main
            code:module
            code:om
            code:port-type
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
            code:injected-instances
            code:injected-instances-system
            code:instance-name
            code:instance-port-name
            code:interface-include
            code:main-event-map-match-return
            code:main-out-arg
            code:main-out-arg-define
            code:model2file?
            code:model2file-interface-include
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
            code:scope-type-scope
            code:trigger
            code:type-name
            code:variable-name
            code:x-header-
            code:root->
            %x:header
            %x:main
            %x:glue-bottom-header
            %x:glue-bottom-source
            %x:glue-top-header
            %x:glue-top-source
            ))

(define %x:header (make-parameter #f))
(define %x:main (make-parameter #f))

(define %x:glue-bottom-header (make-parameter #f))
(define %x:glue-bottom-source (make-parameter #f))
(define %x:glue-top-header (make-parameter #f))
(define %x:glue-top-source (make-parameter #f))

(define (ast-> ast)
  (let ((root (code:om ast)))
    (code:root-> root))
  "")

(define (code:root-> root)
  (code:file2file root)
  (let ((main (command-line:get 'model #f)))
    (when main
      (let* ((models (ast:model* root))
             (main? (compose (cut eq? (string->symbol main) <>) (om:scope-name)))
             (main-model (and main (find main? models))))
        (and=> main-model code:dump-main)))))

(define (code:file2file root)
  (code:dump root)
  (when (dzn:glue)
    ;;(for-each code:dump (filter (is? <foreign>) (ast:model* root)))
    (for-each code:dump-glue (filter (conjoin (is? <system>) (negate om:imported?)) (ast:model* root)))))


(define (code:component-include o)
 (filter (disjoin
          (compose (is? <foreign>) .type)
          (conjoin om:imported? (lambda (i) (not (equal? (source-file o)
                                                         (source-file (.type i)))))))
         (om:instances o)))

(define (code:language)
  (string->symbol (command-line:get 'language "c++")))

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

(define-method (code:dzn-locator (o <instance>)) ;; MORTAL SIN HERE!!?
  (let* ((model (parent o <model>)))
    (if (null? (injected-bindings model)) ""
        "_local")))

(define-method (code:class-member? (o <variable>)) ; MORTAL SIN HERE!!?
  ;; FIXME: is (.variable o) a member?
  ;; checking name (as done now) is not good enough
  ;; we schould check .variable pointer equality
  ;; that does not work, however; someone makes a copy is clone
  ;;(memq o (om:variables (parent o <model>)))
  (memq (.name o) (map .name (om:variables (parent o <model>)))))

(define-method (code:port-type (o <trigger>))
  (code:scope+name ((compose .type .port) o)))

(define-method (code:port-type (o <port>))
  (code:scope+name (.type o)))

(define-method (code:scope+name o)
  (om:scope+name o))

(define-method (code:scope+name (o <root>))
  (code:file-name o))

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
  ((compose code:scope+name .type (cut resolve:instance (parent o <model>) <>) injected-instance-name) o))

(define-method (code:non-injected-bindings (o <system>))
  (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) o))))

(define-method (code:injected-instances-system (o <system>))
  (if (null? (injected-bindings o)) ""
      o))

(define-method (code:injected-instances (o <system>))
  (if (null? (injected-bindings o)) ""
      (injected-instances o)))

;;; code:ast querying
(define* (code:reply-types o #:key (pred om:typed?))
  (let ((lst (om:reply-types o #:pred pred)))
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
  (.name (om:port (resolve:component (parent o <model>) o))))

(define-method (code:port-name (o <bind>))
  (let* ((model (parent o <model>))
         (left (.left o))
         (right (.right o))
         (port (and (om:port-bind? o)
                    (if (not (.instance.name left)) (.port left) (.port right)))))
    port))

(define-method (code:instance-name (o <bind>))
  (let* ((model (parent o <model>))
         (left (.left o))
         (right (.right o))
         (bind (and (om:port-bind? o)
                    (if (.instance.name left) left right))))
    bind))

(define-method (code:instance-name (o <binding>))
  o)

(define-method (code:instance-name (o <port>))
  (.name (resolve:instance (parent o <model>) o)))

(define-method (code:instance-name (o <trigger>))
  ((compose code:instance-name (cut .port (parent o <model>) <>)) o))

(define-method (code:instance-port-name (o <port>))
  (let* ((bind (om:port-bind (parent o <model>) o))
         (instance-bind (om:instance-binding? bind)))
    (.port.name instance-bind)))

(define-method (code:instance-port-name (o <trigger>))
  ((compose code:instance-port-name (cut .port (parent o <model>) <>)) o))

(define-method (code:functions (o <component>))
  (om:functions o))

(define-method (code:ons (o <component>))
  (let ((behaviour (.behaviour o)))
    (if (not behaviour) '()
        ((compose .elements .statement) behaviour))))

(define-method (code:trigger (o <on>))
  ((compose car .elements .triggers) o))

(define-method (code:return (o <on>))
  ((compose ast:type code:trigger) o))

(define-method (code:variable->argument (o <variable>) (f <formal>))
  (if (or (code:class-member? o)
          (eq? (.direction f) 'in)) o
          (clone (make <argument> #:name (.name o) #:type.name (.type.name o))
                 #:parent (.parent o))))

(define-method (code:variable->argument (o <var>) (f <formal>))
  (code:variable->argument (.variable o) f))

(define-method (code:variable->argument (o <formal>) (f <formal>))
  (if (eq? (.direction f) 'in) o
      (clone (make <argument> #:name (.name o) #:type.name (.type.name o) #:direction (.direction o))
             #:parent (.parent o))))

(define-method (code:variable->argument o f)
  o)

(define (add-calling-context-argument arguments)
  (let ((calling-context (command-line:get 'calling-context #f)))
    (if calling-context (cons 'cc__ arguments)
        arguments)))

(define-method (code:arguments (o <call>))
  (map code:variable->argument
       (add-calling-context-argument (ast:argument* o))
       (ast:formal* (add-calling-context-formal ((compose .formals .signature .function) o)))))

(define-method (code:arguments (o <action>))
  (map code:variable->argument
       (add-calling-context-argument (ast:argument* o))
       (ast:formal* (add-calling-context-formal ((compose .formals .signature .event) o)))))

(define-method (code:arguments (o <trigger>))
  (map .name (code:formals o)))

(define-method (code:out-argument (o <trigger>))
  (filter om:out-or-inout? (code:formals o)))

(define-method (code:parameters (o <event>))
  (let ((parameters (map .name (ast:formal* o)))
        (calling-context (command-line:get 'calling-context #f)))
    (if calling-context
        (cons 'cc__ parameters)
        parameters)))

(define-method (add-calling-context-formal (o <formals>))
  (let ((calling-context (command-line:get 'calling-context #f)))
    (if calling-context (clone o #:elements (cons (clone (make <formal> #:name 'cc__ #:direction 'out #:type.name (make <scope.name> #:name '*calling-context*)) #:parent o)
                                                  (ast:formal* o)))
        o)))

(define-method (code:formals (o <function>))
  (ast:formal* (add-calling-context-formal ((compose .formals .signature) o))))

(define-method (code:formals (o <action>))
  (ast:formal* (add-calling-context-formal ((compose .formals .signature .event) o))))

(define-method (code:formals (o <trigger>))
  (ast:formal* (add-calling-context-formal ((compose .formals) o))))

(define-method (code:formals (o <signature>))
  (ast:formal* (add-calling-context-formal ((compose .formals) o))))

(define-method (code:formals (o <event>))
  (ast:formal* (add-calling-context-formal ((compose .formals .signature) o))))

(define-method (code:formals (o <on>))
  (ast:formal*
   (add-calling-context-formal
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
  (let ((o (.statement o)))
   (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
       (clone (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
              #:parent (.parent o))
       o)))

(define-method (code:assign-reply (o <reply>))
  (let ((expression (.expression o)))
    (if (is-a? (ast:type expression) <void>) '()
        o)))

(define ((symbol->enum-field enum) o)
  (make <enum-field> #:type.name (.name enum) #:field o))

(define-method (code:enum-name (o <enum-field>))
  ((compose code:scope-type-name .type) o))

(define-method (code:enum-definer (o <interface>))
  (filter (is? <enum>) (append (ast:type* o) (ast:type* (.behaviour o)))))

(define-method (code:enum-definer (o <component>))
  (filter (is? <enum>) (ast:type* (.behaviour o))))

(define-method (code:instances (o <component>))
  '())
(define-method (code:instances (o <system>))
  (om:instances o))

(define-method (code:bind-provided-required (o <bind>))
  (let* ((model (parent o <model>))
         (left (.left o))
         (left-port (.port left))
         (right (.right o))
         (right-port (.port right)))
    (if (ast:provides? left-port)
                                (cons left right)
                                (cons right left))))

(define-method (code:bind-provided (o <bind>))
  ((compose car code:bind-provided-required) o))

(define-method (code:bind-required (o <bind>))
  ((compose cdr code:bind-provided-required) o))

(define-method (code:component-port (o <port>)) ;; MORTAL SIN HERE!!?
  (let* ((model (parent o <model>))
         (bind (om:port-bind model o)))
    (om:instance-binding? bind)))

(define-method (code:reply-type (o <ast>))
  ((compose code:scope+name ast:type) o))

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
  (cond ((memq (language) '(c++ c++03 c++-msvc11)) o) ; MORTAL SIN HERE!!?
        ((code:class-member? o) o)
        (else (make <local> #:name (.name o) #:type.name (.type.name o) #:expression (.expression o)))))

(define-method (code:variable-name (o <formal>))
  (cond ((memq (language) '(c++ c++03 c++-msvc11)) o) ; MORTAL SIN HERE!!?
        ((om:out-or-inout? o) (make <out-formal> #:name (.name o) #:type.name (.type.name o)))
        (else o)))

(define-method (code:variable-name (o <ast>))
  ((compose code:variable-name .variable) o))

;; type
(define (code:cons-empty-symbol o)
  (if (memq (language) '(c++ c++03 c++-msvc11)) (cons (symbol) o) ; MORTAL SIN HERE!!?
      o))

(define-method (code:type-name (o <bind>))
  ((compose code:type-name .type (cut resolve:instance (parent o <model>) <>) injected-instance-name) o))

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

(define-method (code:main-out-arg-define (o <trigger>))
  (let ((formals ((compose .elements .formals) o)))
    (map (lambda (f i) (clone f #:name i))
         formals (iota (length formals)))))

(define-method (code:main-out-arg-define-formal (o <formal>)) ;; MORTAL SIN HERE!!?
  (let ((type ((compose .value .type) o)))
    (if (not (om:out-or-inout? o)) ""
        (if (equal? type 'int) o
            "/*FIXME*/"))))

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

(define (code:x-header- o) (filter (conjoin (negate om:imported?) (is? <interface>)) (.elements o)))

(define-method (code:reply (o <type>))
  o)

;;; code: generic templates

(use-modules (ice-9 pretty-print))

(define-method (scope (o <type>)) ((compose .scope .name) o))
(define-method (scope (o <event>)) ((compose scope .type .signature) o))
(define-method (scope (o <reply>)) (scope (.type (.expression o))))

(define (code:interface-include o)
  (map (compose (cut make <file-name> #:name <>) code:file-name)
       (delete-duplicates
        (filter (negate (compose (cut equal? (source-file o) <>) (compose source-file .type)))
                (om:ports o)))))

(define (code:model2file-interface-include o)
  (or (and (code:model2file?) (code:interface-include o))
      ""))

(define-method (code:enum-literal (o <enum-literal>))
  (map dzn:->string (code:cons-empty-symbol (code:scope+name o))))

(define-method (code:enum-scope (o <field-test>))
  ((compose (cut code:enum-model-scope <> (parent o <model>)) .type .variable) o))

(define-method (code:enum-scope (o <enum-literal>))
  ((compose (cut code:enum-model-scope <> (parent o <model>)) .type) o))

(define-method (code:enum-scope (o <enum>))
  ((compose (cut code:enum-model-scope <> (parent o <model>)) .type) o))

(define-method (code:enum-model-scope (o <enum>) model)
  (let ((scope ((compose .scope .name) o))
        (model-scope (and=> model om:scope+name)))
    (if (or (null? scope) (null? model-scope) (equal? scope model-scope)) (make <model-scope>)
        o)))

;; main

;;; dump to file

(define-method (have-non-interface-models? (o <root>))
  (let* ((objects
          (filter
           (disjoin (is? <data>)
                    (negate (disjoin dzn-async? ast:imported?)))
           ;; (disjoin (is? <data>)
           ;;          (conjoin (negate dzn-async?)
           ;;                   (disjoin (negate ast:imported?)
           ;;                            (conjoin (is? <foreign>)
           ;;                                     (compose negate
           ;;                                              (cut equal? (source-file o) <>)
           ;;                                              source-file)))))
                          (.elements o)))
         (non-interface-models (filter (negate (is? <interface>)) objects)))
    (pair? non-interface-models)))

(define-method (code:dump (o <root>))
  (let* ((dir (command-line:get 'output "."))
         (stdout? (equal? dir "-"))
         (dir (string-append dir "/" (dzn:dir o)))
         (base (basename (symbol->string (source-file o)) ".dzn"))
         (foreign-conflict? (find (lambda (o) (and (is-a? o <foreign>)
                                                   (not (ast:imported? o))
                                                   (equal? base (code:file-name o)))) (ast:model* o))))
    (when (and (not (dzn:glue)) foreign-conflict?)
      (stderr "cowardly refusing to clobber file with basename: ~a\n" base)
      (exit 0))
    (when (code:header?)
      (let* ((ext (symbol->string (dzn:extension (make <interface>))))
             (file-name (string-append dir base ext)))
        (if stdout? ((dzn:indent (cut (%x:header) o)))
            (begin
              (mkdir-p dir)
              (with-output-to-file file-name
                (dzn:indent (cut (%x:header) o)))))))
    (if (or (not (code:header?)) (have-non-interface-models? o))
        (let* ((ext (symbol->string (dzn:extension (make <component>))))
               (file-name (string-append dir base ext)))
          (if stdout? ((dzn:indent (cut (%x:source) o)))
              (begin
                (mkdir-p dir)
                (with-output-to-file file-name
                  (dzn:indent (cut (%x:source) o)))))))))

(define-method (code:dump (o <foreign>))
  (let* ((dir (command-line:get 'output "."))
         (stdout? (equal? dir "-"))
         (dir (string-append dir "/" (dzn:dir o)))
         (name (symbol->string ((om:scope-name) o)))
         (skel-name (symbol->string (code:skel-file o)))
         (iext (symbol->string (dzn:extension (make <interface>))))
         (cext (symbol->string (dzn:extension (make <component>)))))
    (when (map-file o)
      (if stdout?
          (begin (when (code:header?) ((%x:glue-bottom-header) o))
                 ((%x:glue-bottom-source) o))
          (begin (when (code:header?)
                   (with-output-to-file (string-append dir name iext) (cut (%x:glue-bottom-header) o)))
                 (with-output-to-file (string-append dir name cext) (cut (%x:glue-bottom-source) o)))))))


(define (code:dump-main o)
  (let* ((dir (command-line:get 'output "."))
         (stdout? (equal? dir "-"))
         (ext (symbol->string (dzn:extension o)))
         (dir (string-append dir "/"))
         (base "main")
         (file-name (string-append dir base ext)))
   (and-let* ((name ((om:scope-name) o))
              (model (and (and=> (command-line:get 'model #f) string->symbol)))
              ((is-a? o <component-model>))
              ((eq? model name)))
     (if stdout? ((dzn:indent (cut (%x:main) o)))
         (with-output-to-file file-name (dzn:indent (cut (%x:main) o)))))))

(define-method (code:dump-glue (o <system>))
  (let* ((dir (command-line:get 'output "."))
         (stdout? (equal? dir "-"))
         (dir (string-append dir "/" (dzn:dir o)))
         (name (symbol->string (om:name o))))
    (if stdout?
        (begin ((%x:glue-top-header) o)
               ((%x:glue-top-source) o))
        (begin (with-output-to-file (string-append dir name "Component.h") (cut (%x:glue-top-header) o))
               (with-output-to-file (string-append dir name "Component.cpp") (cut (%x:glue-top-source) o))))))

(define (code:model2file?)
  (and=> (or (command-line:get 'deprecated #f) (getenv "DZN_DEPRECATED"))
         (cut string-contains <> "model2file")))

(define-method (code:file-name (o <port>))
  (code:file-name (.type o)))

(define-method (code:file-name (o <instance>))
  (code:file-name (.type o)))

(define-generic source-file)
(define-method (source-file (o <ast>)) ((compose source-file .node) o))

(define-method (code:file-name (o <interface>))
  (basename (symbol->string (source-file o)) ".dzn"))

(define-method (code:file-name (o <foreign>))
  ((compose symbol->string (om:scope-name) .name) o))

(define-method (code:file-name (o <component>))
  (if (code:model2file?)
      ((compose symbol->string (om:scope-name) .name) o)
      (basename (symbol->string (source-file o)) ".dzn")))

(define-method (code:file-name (o <system>))
  (if (or (code:model2file?) (dzn:glue))
      ((compose symbol->string (om:scope-name) .name) o)
      (basename (symbol->string (source-file o)) ".dzn")))

(define-method (code:file-name (o <root>))
  (basename (symbol->string (source-file o)) ".dzn"))

(define (code:om ast)
  ((compose
    (lambda (o) (if (gdzn:command-line:get 'debug) (display (ast->dzn o) (current-error-port))) o)
    code-norm-event
    code:add-calling-context
    ast:resolve
    parse->om
    ) ast))

(define (code:om ast)
  ((compose
    (lambda (o) (if (gdzn:command-line:get 'debug) (display (ast->dzn o) (current-error-port))) o)
    add-reply-port
    triples:event-traversal
    (remove-otherwise)
    (binding-into-blocking)
    (rewrite-formals)
    code:add-calling-context
    ast:resolve
    parse->om
    ) ast))

(define-method (code:add-calling-context (o <root>))
  (let ((calling-context (command-line:get 'calling-context #f)))
    (if calling-context
        (let ((extern (make <extern> #:name (make <scope.name> #:name '*calling-context*) #:value calling-context)))
          (clone o #:elements (cons extern (.elements o))))
        o)))

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
         (map-file-name (map-file-name o)))
    (and map-file-name
        (let* ((map-file-name (string-append (symbol->string map-file-name) ".map"))
               (map-files (if (pair? map-files) map-files (list map-file-name))))
          (and=> (find (lambda (f) (equal? (basename f) map-file-name)) map-files)
                 try-find-file)))))

(define (map-file-name o)
  (match o
    ((or ($ <foreign>) ($ <component>) ($ <system>)) (and=> (om:port o) map-file-name))
    ((or ($ <interface>) ($ <port>)) ((om:scope-name) o)))) ;; dzn::IConsole ==> dzn_IConsole.map

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

(define-method (code:pump? (o <root>))
  (filter (conjoin (negate om:imported?) (is? <component>) (compose pair? ast:req-events)) (ast:model* o)))

(define-method (code:pump? (o <component>))
  (if ((compose pair? ast:req-events) o) o
      '()))
