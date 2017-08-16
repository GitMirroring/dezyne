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

  #:use-module (gaiag animate)
  #:use-module (gaiag animate-code)
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

            code:expression
            code:trigger
            code:non-injected-bindings
            model2file
            code:ons
            code:functions
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
(define-class <enum-field> (<ast>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

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

(define-method (code:arguments (o <trigger>))
  (map .name (code:formals o)))

(define-method (code:arguments (o <call>))
  ((compose .elements .arguments) o))

(define-method (code:arguments (o <action>))
  ((compose .elements .arguments) o))

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

(define-method (code:field-expression (o <field>))
  (string-join
   (cons "" (map symbol->string (append (code:scope+name ((compose .type .variable) o))
                                        (list (.field o)))))
   "::"))



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
  o)

(define-method (code:expression-expand (o <field>))
  o)

(define-method (code:expression-expand (o <variable>))
  o)

(define-method (code:expression-expand (o <reply>))
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
  (.name o))

(define-method (code:expression (o <variable>))
  (.name o))

(define-method (code:expression (o <return>))
  (if (or (not (.expression o)) (eq? (.expression o) *unspecified*)) ""
          (.expression o)))

(define-method (code:expression (o <var>))
  (.variable o))

(define-method (code:expression (o <unary>))
  o)

(define-method (code:expression (o <top>))
  o)

(define-method (code:expression (o <reply>))
  (.expression o))

(define-method (code:=expression (o <ast>))
  (match (.expression o)
    ((and ($ <value>) (= .value (? unspecified?))) "")
    ((? unspecified?) "")
    (_ (.expression o))))

(define-method (code:reply-type (o <ast>))
  ((compose code:scope+name ast:expression-type) o))

(define-method (code:reply-type (o <reply>))
  ((compose code:reply-type .expression) o))

(define-method (code:declarative-or-imperative (o <compound>))
  (if (om:imperative? o) o
      (make <declarative-compound> #:elements o)))

;;; code: generic templates
(define-template x:scope+name code:scope+name 'name-infix)

(define-template x:non-void-reply identity #f)

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

(define-template x:field code:field-expression)

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

(define-template x:member-name identity)

(define-template x:variable-name (lambda (o)
                                   ;; FIXME: is (.variable o) a member?
                                   ;; checking name (as done now) is not good enough
                                   ;; we schould check .variable pointer equality
                                   ;; that does not work, however; someone makes a copy is clone
                                   ;; (memq o (om:variables (ast:model-scope))
                                   (if (memq (.variable.name o) (map .name (om:variables (ast:model-scope))))
                                       (x:member-name (.variable o))
                                       (symbol->string (.variable.name o)))))

(define-template x:assign-reply code:assign-reply)

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

(define-template x:variable-member-initializer (lambda (o) (om:variables o)))

(define-template x:injected-member-initializer (lambda (o) (filter .injected (om:ports o))))

(define-template x:provided-member-initializer (lambda (o) (filter om:provides? (om:ports o))))

(define-template x:required-member-initializer (lambda (o) (filter (conjoin (negate .injected) om:requires?) (om:ports o))))

(define-template x:non-injected-instance-initializer non-injected-instances)
(define-template x:injected-binding-initializer injected-bindings)
(define-template x:instance-initializer om:instances)
(define-template x:bind-connect code:non-injected-bindings)

(define-template x:bind-provided code:bind-provided)
(define-template x:bind-required code:bind-required)


(define-template x:binding-name code:instance-name)

(define-template x:system-port-connect (lambda (o) (filter (negate om:port-bind?) ((compose .elements .bindings) o))))

(define-template x:arguments code:arguments 'argument-infix <expression>)

(define-template x:out-arguments code:out-argument 'argument-prefix <expression>)

(define-template x:return code:return #f <type>)



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

(define-method (code:file-name (o <port>))
  (code:file-name (.type o)))

(define-method (code:file-name (o <instance>))
  (code:file-name (.type o)))

(define (glue)
  (and=> (command-line:get 'glue #f) string->symbol))

(define (model2file)
  (let ((deprecated (command-line:get 'deprecated #f)))
    (and deprecated (string-contains deprecated "model2file"))))

(define-method (code:file-name (o <interface>))
  (if (model2file)
      ((compose symbol->string (om:scope-name) .name) o)
      (basename (symbol->string (source-file o)) ".dzn")))

(define-method (code:file-name (o <foreign>))
  ((compose symbol->string (om:scope-name) .name) o))

(define-method (code:file-name (o <component>))
  (if (model2file)
      ((compose symbol->string (om:scope-name) .name) o)
      (basename (symbol->string (source-file o)) ".dzn")))

(define-method (code:file-name (o <system>))
  (if (or (model2file) (glue))
      ((compose symbol->string (om:scope-name) .name) o)
      (basename (symbol->string (source-file o)) ".dzn")))

(define-method (code:file-name (o <root>))
  (basename (symbol->string (source-file o)) ".dzn"))

(define code:indenter (make-parameter indent))

(define (code:om ast)
  ((compose-root
    (lambda (o)
      (let ((model-names (map (compose .name car) (@@ (gaiag om) *ast-alist*))))
        (if (and (member (language) '(c++ c++03 c++-msvc11 xjavascript))
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
                                 (resolve-module '(gaiag animate-code))))))
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
