;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn code scmackerel c)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (scmackerel c)
  #:use-module (scmackerel c-header)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code goops)
  #:use-module (dzn code scmackerel code)
  #:use-module (dzn code language dzn)
  #:use-module (dzn code language c)
  #:use-module (dzn code util)
  #:use-module (dzn command-line)
  #:use-module (dzn config)
  #:use-module (dzn misc)
  #:export (c:statement*
            print-code-ast
            print-header-ast
            print-main-ast))

;;;
;;; Helpers.
;;;
(define (file-comments file-name)
  (let ((dir (string-append %template-dir "/c")))
    (list
     (sm:comment* (code:caption file-name))
     (sm:comment* "\n")
     (sm:comment*
      (with-input-from-file (string-append dir "/" file-name)
        read-string)))))

(define-method (c:include-guard (o <ast>) code)
  (let* ((name (ast:full-name o))
         (name (if (not (is-a? o <foreign>)) name
                   (cons "SKEL" name)))
         (name (if (is-a? o <enum>) (cons "ENUM" name)
                   (append name '("h"))))
         (name (string-join name "_"))
         (guard (string-upcase name)))
    `(,(sm:cpp-ifndef* guard)
      ,(sm:cpp-define* guard)
      ,@(match code
          ((code ...) code)
          (code (list code)))
      ,(sm:cpp-endif* guard))))

(define-method (c:guard (o <string>) code)
  (let ((guard (string-upcase o)))
    `(,(sm:cpp-if* guard)
      ,@(match code
          ((code ...) code)
          (code (list code)))
      ,(sm:cpp-endif* guard))))

(define-method (c:guard (o <ast>) code)
  (let* ((name (ast:full-name o))
         (name (if (not (is-a? o <foreign>)) name
                   (cons "SKEL" name)))
         (name (if (is-a? o <enum>) (cons "ENUM" name)
                   (append name '("h"))))
         (name (string-join name "_")))
    (c:guard name code)))

(define-method (c:tracing-guard code)
  (c:guard "DZN_TRACING" code))

(define-method (c:typedef (o <model>))
  (let ((name (c:type-name o)))
    (sm:typedef* (string-append "struct " name) name)))

(define-method (c:log-event-name (o <trigger>))
  (let* ((port-name (.port.name o))
         (event-name (.event.name o))
         (port-event-name (string-append port-name
                                         "_" (code:direction o)
                                         "_" event-name)))
    (string-append "log_event_" port-event-name)))

(define-method (c:log-event-type-cast (o <trigger>))
  (let* ((type (ast:type o))
         (interface (.type (.port o)))
         (formals (ast:formal* o))
         (types (map .type formals))
         (types (map c:type-name types)))
    (simple-format #f "(~a (*) (~a*~a))"
                   (c:type-name type)
                   (c:type-name interface)
                   (string-join types ", " 'prefix))))

(define-method (c:enum->to-string (o <enum>))
  (let ((enum-type (code:type-name o)))
    (define (field->sm:switch-case field)
      (let ((str (simple-format #f "~a:~a" (ast:name o) field)))
        (sm:switch-case
         (expression (simple-format #f "~a_~a" enum-type field))
         (statement (sm:return* (simple-format #f "~s" str))))))
    (sm:function
     (name (string-append "dzn_" enum-type "_to_string"))
     (type "char const*")
     (formals (list (sm:formal (type enum-type)
                               (name "v"))))
     (statement
      (sm:compound*
       (sm:switch (expression "v")
                  (cases (map field->sm:switch-case (ast:field* o))))
       (sm:return* (simple-format #f "~s" "")))))))

(define-method (c:enum->to-enum (o <enum>))
  (let ((enum-name (string-join (ast:full-name o) "_"))
        (enum-type (code:type-name o))
        (short-name (ast:name o)))
    (define (field->if field else)
      (let* ((value (simple-format #f "~a_~a" enum-type field))
             (str (simple-format #f "~a:~a" short-name field))
             (str (simple-format #f "~s" str)))
        (sm:if* (sm:not* (sm:call (name "strcmp") (arguments (list "s" str))))
                (sm:return* value)
                else)))
    (sm:function
     (name (simple-format #f "dzn_string_to_~a" enum-name))
     (formals (list (sm:formal (type "char const*")
                               (name "s"))))
     (type enum-type)
     (statement
      (sm:compound*
       (sm:if* "0" (sm:compound*)
               (fold field->if
                     #f
                     (reverse (ast:field* o))))
       (sm:return* "INT_MAX"))))))

(define-method (c:enum->enum (o <enum>))
  (let ((scope (c:type-name o)))
    (sm:enum
     (name #f)
     (fields (map (cute string-append scope "_" <>) (ast:field* o))))))

(define-method (c:enum->statements (o <enum>))
  `(,(c:enum->to-enum o)
    ,(c:enum->to-string o)))

(define-method (c:enum->header-statements (o <enum>))
  (let* ((enum (c:enum->enum o))
         (scope (c:type-name o))
         (statements
          `(,(sm:typedef* enum scope)
            ,@(c:enum->statements o))))
    (c:include-guard o statements)))

(define-method (c:->formal (o <formal>))
  (let* ((type (code:type-name o))
         (type (if (ast:in? o) type
                   (string-append type "*"))))
    (sm:formal (type type)
               (name (.name o)))))

(define-method (c:self-formal (o <model>))
  (sm:formal (type (string-append (c:type-name o) "*"))
             (name "self")))

(define-method (c:file-name->include (o <string>))
  (sm:cpp-include* (string-append o ".h")))

(define-method (c:file-name->include (o <file-name>))
  (c:file-name->include (.name o)))

(define-method (c:file-name->include (o <import>))
  (c:file-name->include (code:file-name o)))

;;; XXX FIXME template system renmants
(define-method (c:file-name->include (o <instance>))
  (sm:cpp-include* (string-append (code:file-name->string o) ".h")))

(define-method (c:statement* (o <compound>))
  (ast:statement* o))

;; XXX FIXME: introduce <block> statement instead of
;; <blocking-compound>, like VM?
(define-method (c:statement* (o <blocking-compound>))
  (let* ((port-name (.port.name o))
         (block (sm:call (name "dzn_port_block")
                         (arguments
                          (list "(dzn_component*) self"
                                (string-append
                                 "(dzn_interface*) "
                                 (%member-prefix)
                                 port-name))))))
    `(,@(ast:statement* o)
      ,block)))
(define (c:binding->connect binding)
  (let* ((provides
          requires
          (code:provides+requires-end-point binding))
         (port (.port provides))
         (interface (.type port)))
    (sm:call (name (string-append (c:type-name interface) "_connect"))
             (arguments
              (list
               (sm:member* (%member-prefix) (c:end-point->string provides))
               (sm:member* (%member-prefix) (c:end-point->string requires)))))))

(define (c:injected-binding->connect binding)
  (let* ((provides
          requires
          (code:provides+requires-end-point binding))
         (port (.port provides))
         (interface (.type port))
         (model (ast:parent binding <model>))
         (instances (code:instance* model)))
    (define (port->connect instance port)
      (sm:call (name (string-append (c:type-name interface) "_connect"))
               (arguments
                (list
                 (sm:member* (c:end-point->string provides))
                 (sm:member* (string-append
                              (.name instance)
                              (if (not (is-a? (.type instance) <foreign>)) ""
                                  ".base")
                              "."
                              (.name port)))))))
    (define (instance->connect instance)
      (let* ((component (.type instance))
             (ports (ast:injected-port* component))
             (ports (filter (compose (cute ast:eq? <> interface) .type) ports)))
        (map (cute port->connect instance <>) ports)))
    (append-map instance->connect instances)))

(define-method (c:malloc o)
  (sm:call (name "malloc")
           (arguments
            (list
             (sm:call (name "sizeof")
                      (arguments (list o)))))))


;;;
;;; Ast->code.
;;;
(define-method (ast->code (o <guard>))
  (let ((expression (.expression o))
        (statement (.statement o)))
    (cond
     ((is-a? expression <otherwise>)
      (ast->code statement))
     ((ast:literal-true? expression)
      (cond
       ((and (is-a? statement <compound>)
             (as (c:statement* statement) <pair>))
        =>
        (lambda (statements)
          (sm:statements* (map ast->code statements))))
       ((is-a? statement <compound>)
        (sm:statement*))
       (else
        (ast->code statement))))
     (else
      (let ((statement (if (not (is-a? statement <if>)) statement
                           (code:wrap-compound statement) )))
        (sm:if* (ast->expression expression)
                (ast->code statement)))))))

;;; imperative
(define-method (ast->code (o <blocking-compound>))
  (let ((statements (c:statement* o)))
    (sm:compound* (map ast->code statements)))) ;;; XXX new sm:compound*

(define-method (ast->code (o <action>))
  (let* ((action-name (c:event-name o))
         (arguments (code:argument* o))
         (arguments (map ast->expression arguments))
         (port-name (.port.name o))
         (typed? (ast:typed? o)))
    (sm:call (name (sm:member* action-name))
             (arguments
              (cons (sm:member* port-name)
                    arguments)))))

(define-method (ast->code (o <call>))
  (let* ((model (ast:parent o <model>))
         (model-name (c:type-name model))
         (name (string-append model-name "_" (.function.name o)))
         (arguments (map ast->expression (code:argument* o)))
         (arguments (cons "self" arguments)))
    (sm:call
     (name name)
     (arguments arguments))))

(define-method (ast->code (o <if>))
  "C99 Does not allow if (1) int foo = 0;"
  (let* ((then (.then o))
         (then (if (not (is-a? then <variable>)) then
                   (code:wrap-compound then)))
         (else (.else o))
         (else (if (not (is-a? then <variable>)) else
                   (code:wrap-compound else))))
    (sm:if* (ast->expression (.expression o))
            (ast->code then)
            (and=> else ast->code))))

(define-method (ast->code (o <defer>))
  (define (argument-assign variable)
    (let* ((name (if (string? variable) variable
                     (.name variable)))
           (var (if (ast:member? variable) (sm:member* name)
                    name)))
      (sm:assign* (string-append "dzn_arguments->" name) var)))
  (let* ((variables (ast:defer-variable* o))
         (locals (code:capture-local o))
         (model (ast:parent o <model>))
         (model-name (c:type-name model))
         (name (c:defer-name o))
         (arguments-type (c:defer-arguments-name o))
         (predicate-type (c:defer-predicate-name o))
         (malloc-closure (c:malloc "dzn_closure")))
    (sm:compound*
     `(,(sm:variable (type "dzn_closure*") (name "dzn_predicate")
                     (expression malloc-closure))
       ,(sm:assign* "dzn_predicate->function"
                    (string-append "(void (*)(void *)) "
                                   predicate-type))
       ,(sm:variable (type (sm:pointer* arguments-type)) (name "dzn_arguments")
                     (expression (c:malloc arguments-type)))
       ,(argument-assign "self")
       ,@(map argument-assign variables)
       ,@(map argument-assign locals)
       ,(sm:assign* "dzn_predicate->argument" "dzn_arguments")
       ,(sm:variable (type "dzn_closure*") (name "dzn_defer_closure")
                     (expression malloc-closure))
       ,(sm:assign* "dzn_defer_closure->function" name)
       ,(sm:assign* "dzn_defer_closure->argument" "dzn_arguments")
       ,(sm:call (name "dzn_defer")
                 (arguments '("(dzn_component*) self"
                              "dzn_predicate"
                              "dzn_defer_closure")))))))

(define-method (ast->code (o <reply>))
  (let ((p (.parent o)))
    (cond
     ((or (is-a? p <guard>) (is-a? p <if>))
      (ast->code (code:wrap-compound o)))
     (else
      (let* ((type (ast:type o))
             (reply-port (.port o))
             (port-name (.name reply-port))
             (out-binding (string-append (%member-prefix)
                                         (code:out-binding (.port o)))))
        (sm:statements*
         `(,@(if (is-a? type <void>) '()
                 `(,(sm:assign* (sm:member* (%member-prefix) (code:reply-var type))
                                (ast->expression (.expression o)))))
           ,@(if (not (code:port-release? o)) '()
                 `(,(sm:call (name "dzn_port_release")
                             (arguments
                              (list "(dzn_component*) self"
                                    (string-append
                                     "(dzn_interface*) "
                                     (%member-prefix)
                                     (.port.name o))))))))))))))

(define-method (ast->code (o <illegal>))
  (sm:statement* "dzn_illegal (&self->dzn_info)"))

(define-method (ast->code (o <out-bindings>))
  (sm:statement*))

(define-method (ast->expression (o <var>))
  (let* ((name (.name o))
         (name (if (ast:member? (.variable o)) (string-append "self->" name)
                   name))
         (variable (.variable o))
         (argument? (ast:parent o <arguments>))
         (formal (or (as variable <formal>)
                     (and argument? (ast:argument->formal o))))
         (modifier (cond ((and (not formal)
                               variable
                               (not (ast:in? variable)))
                          "*")
                         ((and formal
                               (not (ast:in? formal))
                               (not argument?))
                          "*")
                         ((not formal)
                          "")
                         ((and (is-a? variable <formal>)
                               (not (ast:in? variable))
                               (ast:in? formal))
                          "")
                         ((and (or (is-a? variable <variable>)
                                   (and (is-a? variable <formal>)
                                        (ast:in? variable)))
                               (not (ast:in? formal)))
                          "&")
                         (else
                          "")))
         (name (string-append modifier name)))
    name))

(define-method (ast->expression (o <formal>))
  (let* ((name (.name o))
         (modifier (if (ast:in? o) ""
                       "*"))
         (name (string-append modifier name)))
    name))


;;;
;;; Root.
;;;
(define-method (root->header-statements (o <root>))
  (let ((imports (ast:unique-import* o))
        (enums (c:enum* o)))
    (append
     (map c:file-name->include imports)
     (map .value (ast:data* o))
     (append-map c:enum->header-statements enums))))

(define-method (root->statements (o <root>))
  (let ((enums (c:enum* o)))
    (append-map c:enum->statements enums)))


;;;
;;; Interface.
;;;
(define-method (interface->sm:statements-unmemoized (o <interface>))
  (define (event->slot event)
    (let ((type (c:type-name (ast:type event)))
          (formals (code:formal* event)))
      (sm:function
       (type type)
       (name (string-append "(*" (.name event) ")"))
       (formals (cons (c:self-formal o) (map c:->formal formals)))
       (statement #f))))
  (let* ((public-enums (code:public-enum* o))
         (enums (append public-enums (code:enum* o)))
         (interface
          (sm:struct
            (name (c:type-name o))
            (members
             `(,(sm:variable (type "dzn_port_meta") (name "meta")
                             (expression "m"))
               ,(sm:variable (type
                              (sm:struct
                                (members
                                 (map event->slot (ast:in-event* o)))))
                             (name "in"))
               ,(sm:variable (type
                              (sm:struct
                                (members
                                 (map event->slot (ast:out-event* o)))))
                             (name "out"))))))
         (interface& (string-append
                      (string-join (cons "" (ast:full-name o)) "::")
                      "&")))
    (define (value->init value)
      (let* ((value (simple-format #f "~s" (.value value))))
        (sm:generalized-initializer-list* value)))
    (let* ((interface
            (sm:struct
              (inherit interface)
              (methods
               (cons*
                (sm:constructor (struct interface)
                                (formals (list (sm:formal (type "dzn_port_meta")
                                                          (name "m")))))))))
           (interface* (sm:pointer* (c:type-name o)))
           (connect
            (sm:function
             (name (string-append (c:type-name o) "_connect"))
             (type "void")
             (formals (list (sm:formal (type interface*) (name "provided"))
                            (sm:formal (type interface*) (name "required"))))
             (statement
              (sm:compound*
               (sm:assign* "provided->out" "required->out")
               (sm:assign* "required->in" "provided->in")
               (sm:assign* "provided->meta.requires" "required->meta.requires")
               (sm:assign* "required->meta.provides" "provided->meta.provides"))))))
      `(,@(append-map c:enum->header-statements enums)
        ,interface
        ,connect))))

(define-method (interface->statements (o <interface>))
  ((ast:perfect-funcq interface->sm:statements-unmemoized) o))

(define-method (model->header-statements (o <interface>))
  (c:include-guard o `(,(c:typedef o)
                       ,@(interface->statements o))))

(define-method (model->statements (o <interface>))
  (interface->statements o))


;;;
;;; Component.
;;;
(define-method (component-model->sm:statements-unmemoized (o <component-model>))
  (define (provides->member port)
    (list
     (sm:variable
      (type (code:type-name (.type port)))
      (name (string-append (.name port) "_")))
     (sm:variable
      (type (string-append (code:type-name (.type port)) "*"))
      (name (.name port))
      ;;(expression (address* (sm:member* (string-append name "_"))))
      (expression (string-append "&self->" name "_")))))
  (define (requires->member port)
    (list
     (sm:variable
      (type (code:type-name (.type port)))
      (name (string-append (.name port) "_")))
     (sm:variable
      (type (string-append (code:type-name (.type port)) "*"))
      (name (.name port))
      ;;(expression (address* (sm:member* (string-append name "_"))))
      (expression (string-append "&self->" name "_")))))
  (define (provides->inits port)
    (let* ((name (.name port))
           (name-string (simple-format #f "~s" name))
           (p (string-append "self->" name)))
      `(,(sm:assign* (string-append p "->meta.provides.component") "self")
        ,(sm:assign* (string-append p "->meta.requires.component") "0")
        ,@(c:tracing-guard
           (list
            (sm:assign* (string-append p "->meta.provides.name") name-string)
            (sm:assign* (string-append p "->meta.provides.meta") "&self->dzn_meta")
            (sm:assign* (string-append p "->meta.requires.name") "\"\"")
            (sm:assign* (string-append p "->meta.requires.meta") 0))))))
  (define (requires->inits port)
    (let* ((name (.name port))
           (name-string (simple-format #f "~s" name))
           (p (string-append "self->" name)))
      `(,(sm:assign* (string-append p "->meta.requires.component") "self")
        ,(sm:assign* (string-append p "->meta.provides.component") "0")
        ,@(c:tracing-guard
           (list
            (sm:assign* (string-append p "->meta.requires.name") name-string)
            (sm:assign* (string-append p "->meta.requires.meta") "&self->dzn_meta")
            (sm:assign* (string-append p "->meta.provides.name") "\"\"")
            (sm:assign* (string-append p "->meta.provides.meta") 0))))))
  (define (in-trigger->init trigger)
    (let* ((port (.port trigger))
           (port-name (.name port))
           (p (string-append "self->" port-name))
           (event-name (.event.name trigger))
           (direction (code:direction trigger))
           (base-name (c:base-type-name o)))
      (sm:assign* (string-append p "->" direction "." event-name)
                  (c:event-slot-call-name base-name trigger))))
  (define (type->reply-variable o)
    (sm:variable
     (type (code:type-name o))
     (name (code:reply-var o))))
  (define (provides-trigger->method component trigger)
    (let* ((trigger
            statement
            (match o
              (($ <foreign>)
               (values trigger #f))
              (($ <component>)
               (let* ((on (code:on trigger))
                      (trigger (car (ast:trigger* on)))
                      (statement (.statement on)))
                 (values trigger (ast->code statement))))))
           (formals (code:formal* trigger))
           (arguments (map .name formals))
           (formals (map c:->formal formals))
           (typed? (ast:typed? trigger))
           (type (ast:type trigger))
           (reply-type (code:type->string type))
           (reply-var (sm:member* (code:reply-var type)))
           (port (.port trigger))
           (interface (c:type-name (.type port)))
           (event-name (.event.name trigger))
           (self-info (if (is-a? o <foreign>) "&self->base.dzn_info"
                          "&self->dzn_info"))
           (root (ast:parent o <root>))
           (pump? (code:pump? root)))
      (list
       (sm:method
        (struct component)
        (type (if (not (is-a? o <foreign>)) "static void"
                  (code:type-name type)))
        (name (code:event-slot-name trigger))
        (formals formals)
        (statement statement))
       (sm:function
        (type (string-append "static " (code:type-name type)))
        (name (c:event-slot-call-name (sm:struct-name component) trigger))
        (formals (cons (sm:formal (type (sm:pointer* interface))
                                  (name "port"))
                       formals))
        (statement
         (sm:compound*
          `(,(sm:variable (type (sm:pointer* (sm:struct-name component)))
                          (name "self")
                          (expression "port->meta.provides.component"))
            ,@(if (not pump?) '()
                  `(,(sm:call (name "dzn_runtime_call_in")
                              (arguments '("(dzn_component*) self"
                                           "(dzn_interface*) port")))))
            ,@(c:tracing-guard
               (sm:call (name "dzn_runtime_trace")
                        (arguments
                         (list "&port->meta"
                               (simple-format #f "~s" event-name)))))
            ,(sm:call (name "dzn_runtime_start")
                      (arguments (list self-info)))
            ,(sm:call (name (string-append
                             (sm:struct-name component)
                             "_"
                             (code:event-slot-name trigger)))
                      (arguments (cons "self"
                                       arguments)))
            ,(sm:call (name "dzn_runtime_finish")
                      (arguments (list self-info)))
            ,@(if (not (code:pump? o)) '()
                  `(,(sm:call (name "dzn_prune_deferred")
                              (arguments '("(dzn_component*) self")))))
            ,@(c:tracing-guard
               (sm:call
                (name "dzn_runtime_trace_out")
                (arguments
                 (list "&port->meta"
                       (if (not typed?)
                           (simple-format #f "~s" "return")
                           (sm:call
                            (name (string-append "dzn_" reply-type
                                                 "_to_string"))
                            (arguments (list reply-var))))))))
            ,@(if (not typed?) '()
                  `(,(sm:return*
                      (sm:member*
                       (code:reply-var (ast:type trigger)))))))))))))
  (define (requires-trigger->method component trigger)
    (define (formal->a-formal o)
      (sm:formal (type (c:type-name (.type o)))
                 (name (.name o))))
    (define (formal->assign formal i)
      (sm:assign* (simple-format #f "dzn_c._~a" i) (.name formal)))
    (let* ((trigger
            statement
            (match o
              (($ <foreign>)
               (values trigger #f))
              (($ <component>)
               (let* ((on (code:on trigger))
                      (trigger (car (ast:trigger* on)))
                      (statement (.statement on)))
                 (values trigger (ast->code statement))))))
           (formals (code:formal* trigger))
           (port (.port trigger))
           (interface (c:type-name (.type port)))
           (event-name (.event.name trigger))
           (component-name (sm:struct-name component))
           (closure-name (c:closure-name trigger))
           (closure-type-name (string-append closure-name "_closure")))
      (list
       (sm:method
        (struct component)
        (name (code:event-slot-name trigger))
        (formals (map c:->formal formals))
        (statement statement))
       (sm:function
        (type "static void")
        (name (c:event-slot-call-name (sm:struct-name component) trigger))
        (formals `(,(sm:formal (type (sm:pointer* interface))
                               (name "port"))
                   ,@(map formal->a-formal formals)))
        (statement
         (sm:compound*
          `(,(sm:variable (type (sm:pointer* (sm:struct-name component)))
                          (name "self")
                          (expression "port->meta.requires.component"))
            ,(sm:variable (type closure-type-name)
                          (name "dzn_c"))
            ,@(c:tracing-guard
               (sm:call
                (name "dzn_runtime_trace_out")
                (arguments
                 (list "&port->meta"
                       (simple-format #f "~s" event-name)))))
            ,(sm:assign* "dzn_c.size"
                         (sm:call (name "sizeof")
                                  (arguments (list closure-type-name))))
            ,(sm:assign* "dzn_c.function"
                         (string-append
                          "(void(*)(" component-name "*)) "
                          (c:ref
                           (string-append
                            component-name
                            "_"
                            (code:event-slot-name trigger)))))
            ,(sm:assign* "dzn_c.self" "self")
            ,@(let ((formals (code:formal* trigger)))
                (map formal->assign formals (iota (length formals))))
            ,(sm:call (name "dzn_runtime_enqueue")
                      (arguments
                       `("port->meta.provides.component"
                         "self"
                         ,(string-append
                           "(void (*)(void*)) "
                           (c:ref (c:closure-name trigger)))
                         "&dzn_c")))
            ,@(if (not (code:pump? o)) '()
                  `(,(sm:call (name "dzn_prune_deferred")
                              (arguments '("(dzn_component*) self"))))))))))))
  (define (function->method component function)
    (let* ((type (code:type-name (ast:type function)))
           (name (.name function))
           (formals (code:formal* function))
           (statement (.statement function))
           (statement (ast->code statement)))
      (sm:method (struct component)
                 (type type)
                 (name name)
                 (formals (map c:->formal formals))
                 (statement statement))))
  (define (requires->assignment ports)
    (sm:assign* (sm:member* "dzn_meta.require")
                (sm:generalized-initializer-list*
                 (map (compose
                       (cute string-append "&" <> ".meta")
                       .name)
                      ports))))
  (define (trigger->closure-helper signature)
    (define (formal->variable formal i)
      (sm:variable (type "int")
                   (name (simple-format #f "_~a" i))))
    (let* ((component-name (c:type-name o))
           (closure-name (c:closure-name signature))
           (closure-type-name (string-append closure-name "_closure"))
           (formals (ast:formal* signature)))
      (list
       (sm:typedef* (string-append "struct " closure-type-name) closure-type-name)
       (sm:struct
         (name closure-type-name)
         (members
          `(,(sm:variable (type "size_t")
                          (name "size"))
            ,(sm:function (type "void")
                          (name "(*function)")
                          (formals (list
                                    (sm:formal (type (sm:pointer* component-name))
                                               (name "self"))))
                          (statement #f))
            ,(sm:variable (type (sm:pointer* component-name)) (name "self"))
            ,@(map formal->variable formals (iota (length formals))))))
       (sm:function (type "static void")
                    (name closure-name)
                    (formals (list (sm:formal (type "void*") (name "argument"))))
                    (statement
                     (sm:compound*
                      (sm:variable (type (sm:pointer* closure-type-name))
                                   (name "closure")
                                   (expression "argument"))
                      (sm:call (name "closure->function")
                               (arguments '("closure->self")))))))))
  (define (defer-arguments-struct)
    (define argument-variable
      (match-lambda*
        ((type name)
         (sm:variable (type type) (name name)
                      (expression (string-append "dzn_capture->" name))))
        ((variable)
         (argument-variable (c:type-name (.type variable))
                            (.name variable)))))
    (let* ((model-name (c:type-name o))
           (arguments-type (c:defer-arguments-name o))
           (variables (ast:variable* o))
           (defers (c:defer* o))
           (locals (append-map code:capture-local defers))
           (locals (delete-duplicates locals
                                      (lambda (a b)
                                        (equal? (.name a) (.name b))))))
      (list
       (sm:typedef* (string-append "struct " arguments-type) arguments-type)
       (sm:struct
         (name arguments-type)
         (members `(,(argument-variable (sm:pointer* model-name) "self")
                    ,@(map argument-variable variables)
                    ,@(map argument-variable locals)))))))
  (define (defer->helper-functions defer)
    (define argument-variable
      (match-lambda*
        ((type name)
         (sm:variable (type type) (name name)
                      (expression (string-append "dzn_capture->" name))))
        ((variable)
         (argument-variable (c:type-name (.type variable))
                            (.name variable)))))
    (define (variable->equality o)
      (sm:equal* (ast->expression o) (.name o)))
    (let* ((name (c:defer-name defer))
           (variables (ast:defer-variable* defer))
           (locals (code:capture-local defer))
           (model (ast:parent defer <model>))
           (model-name (c:type-name model))
           (arguments-type (c:defer-arguments-name o))
           (predicate-type (c:defer-predicate-name defer))
           (equality (code:defer-equality* defer))
           (condition (if (not (code:defer-condition defer)) "true"
                          (sm:and*
                           (map variable->equality equality))))
           (statement (.statement defer))
           (statements (if (not (is-a? statement <compound>)) (list statement)
                           (ast:statement* statement)))
           (statements (map ast->code statements)))
      (list
       (sm:function (type "static bool")
                    (name (c:defer-predicate-name defer))
                    (formals (list (sm:formal (type "void*") (name "argument"))))
                    (statement
                     (sm:compound*
                      `(,(sm:variable (type (sm:pointer* arguments-type))
                                      (name "dzn_capture")
                                      (expression "argument"))
                        ,(argument-variable (sm:pointer* model-name) "self")
                        ,@(map argument-variable variables)
                        ,(sm:return* condition)))))
       (sm:function (type "static void")
                    (name name)
                    (formals (list (sm:formal (type "void*") (name "argument"))))
                    (statement
                     (sm:compound*
                      `(,(sm:variable (type (sm:pointer* arguments-type))
                                      (name "dzn_capture")
                                      (expression "argument"))
                        ,(argument-variable (sm:pointer* model-name) "self")
                        ,@(map argument-variable variables)
                        ,@(map argument-variable locals)
                        ,@statements)))))))
  (let* ((enums (filter (is? <enum>) (code:enum* o)))
         (closure-triggers (c:closure-triggers o))
         (component
          (sm:struct
            (name (c:type-name o))
            (members
             `(,(sm:variable
                 (type "dzn_meta")
                 (name "dzn_meta"))
               ,(sm:variable
                 (type "dzn_runtime_info")
                 (name "dzn_info"))
               ,@(map code:member->variable (ast:member* o))
               ,@(map type->reply-variable (code:reply-types o))
               ,@(append-map provides->member (ast:provides-port* o))
               ,@(append-map requires->member (ast:requires-port* o))))))
         (base (if (not (is-a? o <foreign>)) component
                   (sm:struct (inherit component)
                              (name (c:base-type-name o))))))
    `(,@(append-map c:enum->header-statements enums)
      ,(c:typedef o)
      ,component
      ,@(if (not (is-a? o <foreign>)) '()
            `(,(sm:cpp-include* (string-append
                                 (sm:struct-name base)
                                 ".h"))))
      ,@(append-map trigger->closure-helper closure-triggers)
      ,@(if (not (is-a? o <foreign>)) '()
            `(,(sm:constructor
                (struct base)
                (formals (list (sm:formal (type "dzn_locator*")
                                          (name "dzn_locator"))
                               (sm:formal (type "dzn_meta*")
                                          (name "dzn_meta"))))
                (statement #f))))
      ,(sm:constructor
        (struct component)
        (formals (list (sm:formal (type "dzn_locator*")
                                  (name "dzn_locator"))
                       (sm:formal (type "dzn_meta*")
                                  (name "dzn_meta"))))
        (statement
         (sm:compound*
          `(,(sm:call (name "dzn_runtime_info_init")
                      (arguments
                       (list ;;(address* (sm:member* "dzn_info"))
                        "&self->dzn_info"
                        "dzn_locator")))
            ,(sm:assign* (sm:member* "dzn_info.performs_flush") "true")
            ,@(c:tracing-guard
               (sm:call (name "memcpy")
                        (arguments
                         (list ;;(address* (sm:member* "dzn_meta"))
                          "&self->dzn_meta"
                          "dzn_meta"
                          "sizeof (self->dzn_meta)"))))
            ,@(append-map provides->inits (ast:provides-port* o))
            ,@(map in-trigger->init (ast:in-triggers o))
            ,@(append-map requires->inits (ast:requires-port* o))))))
      ,@(append-map defer->helper-functions (c:defer* o))
      ,@(map (cute function->method base <>) (ast:function* o))
      ,@(append-map (cute provides-trigger->method base <>)
                    (ast:provides-in-triggers o))
      ,@(append-map (cute requires-trigger->method base <>)
                    (ast:requires-out-triggers o))
      ,@(if (is-a? o <foreign>) '()
            (defer-arguments-struct)))))

(define-method (component-model->statements (o <component-model>))
  ((ast:perfect-funcq component-model->sm:statements-unmemoized) o))

(define-method (model->header-statements (o <component>))
  (let ((interface-includes (code:interface-include* o)))
    (c:include-guard
     o
     `(,@(map c:file-name->include interface-includes)
       ,@(component-model->statements o)))))

(define-method (model->statements (o <component>))
  (component-model->statements o))


;;;
;;; Foreign.
;;;
(define-method (model->foreign (o <foreign>))
  (let ((foreign (component-model->statements o)))
    foreign))

(define-method (model->header-statements (o <foreign>))
  (let* ((interface-includes (code:interface-include* o))
         (statements `(,(sm:cpp-system-include* "dzn/locator.h")
                       ,(sm:cpp-system-include* "dzn/runtime.h")
                       ,@(map c:file-name->include interface-includes)
                       ,@(model->foreign o))))
    (c:include-guard o statements)))

(define-method (model->statements (o <foreign>))
  (model->foreign o))


;;;
;;; System.
;;;
(define-method (system->sm:statements-unmemoized (o <system>))
  (define (provides->member port)
    (let* ((other-end (ast:other-end-point port)))
      (sm:variable
       (type (string-append (code:type-name (.type port)) "*"))
       (name (.name port))
       ;; XXX FIXME ordering problem
       ;; (expression (sm:member*
       ;;              (string-append (.instance.name other-end)
       ;;                             "."
       ;;                             (.port.name other-end))))
       )))
  (define (requires->member port)
    (let ((other-end (ast:other-end-point port)))
      (sm:variable
       (type (string-append (code:type-name (.type port)) "*"))
       (name (.name port))
       ;; XXX FIXME ordering problem
       ;; (expression (sm:member*
       ;;              (string-append (.instance.name other-end)
       ;;                             "."
       ;;                             (.port.name other-end))))
       )))
  (define (instance->member instance)
    (sm:variable
     (type (string-append (code:type-name (.type instance))))
     (name (.name instance))))
  (define (instance->assignments instance)
    (let* ((name (.name instance))
           (component (.type instance))
           (base-name (c:base-type-name component))
           (port-name (.port.name instance))
           (meta (string-append "dzn_meta_" name))
           (name-string (simple-format #f "~s" name)))
      `(,(sm:variable (type "dzn_meta") (name meta))
        ,(sm:assign* (string-append meta ".name") name-string)
        ,(sm:assign* (string-append meta ".parent") "&self->dzn_meta")
        ,(sm:call (name (string-append base-name "_init"))
                  (arguments (list
                              ;; FIXME (sm:call (sm:function??) (arguments))
                              ;;(string-append "&self->" name)
                              (string-append "&self->" (.name instance))
                              "dzn_locator"
                              (string-append "&" meta)))))))
  (define (port->assignment port)
    (let* ((other-end (ast:other-end-point port))
           (instance (.instance other-end))
           (component (.type instance)))
      (sm:assign* (sm:member* (.name port))
                  (sm:member*
                   (string-append (.name instance)
                                  (if (not (is-a? component <foreign>)) ""
                                      ".base")
                                  "."
                                  (.port.name other-end))))))
  (let* ((instances (code:instance* o))
         (injected-instances (code:injected-instance* o))
         (bindings (code:component-binding* o))
         (injected-bindings (code:injected-binding* o))
         (system
          (sm:struct
            (name (c:type-name o))
            (members
             `(,(sm:variable
                 (type "dzn_meta")
                 (expression "*dzn_meta_dzn")
                 (name "dzn_meta"))
               ,@(map instance->member instances)
               ,@(map instance->member injected-instances)
               ,@(map provides->member (ast:provides-port* o))
               ,@(map requires->member (ast:requires-port* o)))))))
    `(,(c:typedef o)
      ,system
      ,(sm:constructor
        (struct system)
        (formals (list (sm:formal (type "dzn_locator*")
                                  (name "dzn_locator"))
                       (sm:formal (type "dzn_meta*")
                                  (name "dzn_meta_dzn"))))
        (statement
         (sm:compound*
          `(,@(append-map instance->assignments instances)
            ,@(append-map instance->assignments injected-instances)
            ,@(map port->assignment (ast:provides-port* o))
            ,@(map port->assignment (ast:requires-port* o))
            ,@(map c:binding->connect bindings)
            ,@(append-map c:injected-binding->connect injected-bindings))))))))

(define-method (system->statements (o <system>))
  ((ast:perfect-funcq system->sm:statements-unmemoized) o))

(define-method (model->header-statements (o <system>))
  (let* ((component-includes (code:component-include* o))
         (statements `(,@(map c:file-name->include component-includes)
                       ,@(system->statements o))))
    (c:include-guard o statements)))

(define-method (model->statements (o <system>))
  (system->statements o))


;;;
;;; Main.
;;;
(define-method (main-log-out-trigger (o <trigger>))
  (let* ((port (.port o))
         (port-name (.name port))
         (interface (c:type-name (.type port)))
         (event-name (.event.name o))
         (port-dot (string-append port-name "."))
         (port-dot-string (simple-format #f "~s" port-dot))
         (event-name-string (simple-format #f "~s" event-name))
         (type (ast:type o))
         (typed? (ast:typed? o))
         (arguments `(,port-dot-string
                      ,event-name-string
                      "global_event_map")))
    (sm:function
     (type (code:type->string type))
     (name (c:log-event-name o))
     (formals (list (sm:formal (type (sm:pointer* interface)) (name "m"))))
     (statement
      (sm:compound*
       (list
        (sm:statement* "(void) m")
        (cond
         (typed?
          (sm:return*
           (sm:call (name "log_typed")
                    (arguments
                     `(,@arguments
                       ,(string-append
                         "(int (*) (char*)) "
                         "dzn_string_to_" type)
                       ,(string-append
                         "(char* (*) (int)) "
                         "dzn_" type "_to_string"))))))
         (else
          (sm:call (name (if (ast:in? o) "log_in" "log_out"))
                   (arguments arguments))))))))))

(define-method (main-log-out-trigger (o <component-model>))
  (map main-log-out-trigger (ast:out-triggers o)))

(define-method (main-fill-event-map (o <component-model>))
  (define (provides->init port)
    (let* ((port-name (.name port))
           (port-string (simple-format #f "~s" port-name))
           (external-string (simple-format #f "~s" "<external>"))
           (flush (simple-format #f "~a.<flush>" port-name))
           (flush-string (simple-format #f "~s" flush))
           (meta (simple-format #f "m->~a->meta.requires." port-name)))
      `(,(sm:assign* "c" (c:malloc "dzn_closure"))
        ,(sm:assign* "c->function" "&log_flush")
        ,(sm:assign* "flush_args" (c:malloc "flush_arguments"))
        ,(sm:assign* "flush_args->info" "&comp->dzn_info")
        ,(sm:assign* "flush_args->name" port-string)
        ,(sm:assign* "c->argument" "flush_args")
        ,(sm:assign* (string-append meta "component") "comp")
        ,@(c:tracing-guard
           (list
            (sm:assign* (string-append meta "name") port-string)
            (sm:assign* (string-append meta "meta") "&comp->dzn_meta")
            (sm:if* "global_flush_p"
                    (sm:assign* "comp->dzn_meta.name" external-string))))
        ,(sm:call (name "dzn_map_put")
                  (arguments (list "e" flush-string "c"))))))
  (define (requires->init port)
    (let* ((port-name (.name port))
           (port-string (simple-format #f "~s" port-name))
           (external-string (simple-format #f "~s" "<external>"))
           (flush (simple-format #f "~a.<flush>" port-name))
           (flush-string (simple-format #f "~s" flush))
           (meta (simple-format #f "m->~a->meta.provides." port-name)))
      `(,(sm:assign* "c" (c:malloc "dzn_closure"))
        ,(sm:assign* "c->function" "&log_flush")
        ,(sm:assign* "flush_args" (c:malloc "flush_arguments"))
        ,(sm:assign* "flush_args->info" "&comp->dzn_info")
        ,(sm:assign* "flush_args->name" port-string)
        ,(sm:assign* "c->argument" "flush_args")
        ,(sm:assign* (string-append meta "component") "comp")
        ,@(c:tracing-guard
           (list
            (sm:assign* (string-append meta "name") port-string)
            (sm:assign* (string-append meta "meta") "&comp->dzn_meta")
            (sm:if* "global_flush_p"
                    (sm:assign* "comp->dzn_meta.name" external-string))))
        ,(sm:call (name "dzn_map_put")
                  (arguments (list "e" flush-string "c"))))))

  (define (in-trigger->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event)))
      (define (formal->variable formal)
        (sm:variable (type "int")
                     (name (code:number-argument formal))
                     (expression (.name formal))))
      (list
       (sm:assign* "c" (c:malloc "dzn_closure"))
       (sm:assign* "c->function" (string-append
                                  "(void (*)) m->" port "->"
                                  (code:direction trigger) "."
                                  event))
       (sm:assign* "c->argument" (string-append "m->" port))
       (sm:call (name "dzn_map_put")
                (arguments (list "e" port-event-string "c"))))))
  (define (out-trigger->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (formals (code:formal* trigger)))
      (sm:assign* (string-append "m->" (c:event-name trigger))
                  (string-append
                   (c:log-event-type-cast trigger)
                   " "
                   (c:log-event-name trigger)))))
  (define (defer->init)
    (let ((defer-string (simple-format #f "~s" "<defer>"))
          (pump-string (simple-format #f "~s" "pump")))
      `(,(sm:assign* "c" (c:malloc "dzn_closure"))
        ,(sm:assign* "c->function" "(void (*) (void*)) dzn_pump_run_defer")
        ,(sm:assign* "c->argument" "pump")
        ,(sm:call (name "dzn_map_put")
                  (arguments (list "e" defer-string "c"))))))
  (let ((external-string (simple-format #f "~s" "<external>"))
        (pump? (code:pump? o)))
    (sm:function
     (type "void")
     (name "fill_event_map")
     (formals `(,(sm:formal (type (sm:pointer* (code:type-name o)))
                            (name "m"))
                ,(sm:formal (type "dzn_map*")
                            (name "e"))
                ,@(if (not pump?) '()
                      `(,(sm:formal (type "dzn_pump*")
                                    (name "pump"))))))
     (statement
      (sm:compound*
       `(,(sm:variable (type "dzn_closure*") (name "c"))
         ,(sm:variable (type "flush_arguments*") (name "flush_args"))
         ,(sm:variable (type "dzn_component*") (name "comp")
                       (expression (c:malloc "dzn_component")))
         ,(sm:assign* "comp->dzn_info.performs_flush" "global_flush_p")
         ,@(c:tracing-guard
            `(,(sm:assign* "comp->dzn_meta.parent" 0)
              ,(sm:assign* "comp->dzn_meta.name" external-string)
              ,@(map out-trigger->init (ast:out-triggers o))))
         ,@(append-map provides->init (ast:provides-port* o))
         ,@(append-map requires->init (ast:requires-port* o))
         ,@(append-map in-trigger->init (ast:in-triggers o))
         ,@(if (not (code:pump? o)) '()
               (defer->init))))))))

(define-method (main (o <component-model>))
  (let ((model-name (code:type-name o))
        (flush-string (simple-format #f "~s" "--flush"))
        (pump? (code:pump? o)))
    (sm:function
     (name "main")
     (formals (list (sm:formal (type "int") (name "argc"))
                    (sm:formal (type "char const*") (name "argv[]"))))
     (statement
      (sm:compound*
       `(,(sm:variable (type "dzn_locator") (name "dzn_locator"))
         ,@(c:tracing-guard
            (sm:variable (type "dzn_meta") (name "meta")))
         ,(sm:variable (type "dzn_map") (name "event_map"))
         ,(sm:variable (type "char*") (name "line"))
         ,(sm:assign* "global_flush_p"
                      (sm:call (name "dzn_getopt")
                               (arguments `("argc" "argv" ,flush-string))))
         ,(sm:call (name "dzn_locator_init") (arguments '("&dzn_locator")))
         ,(sm:assign* "dzn_locator.illegal" "&illegal_print")
         ,@(if (not pump?) '()
               `(,(sm:variable (type "dzn_pump") (name "pump"))
                 ,(sm:call (name "dzn_pump_init") (arguments '("&pump")))
                 ,(sm:call (name "dzn_locator_set")
                           (arguments `("&dzn_locator"
                                        ,(simple-format #f "~s" "pump")
                                        "&pump")))))
         ,(sm:variable (type model-name) (name "sut"))
         ,@(c:tracing-guard
            (list
             (sm:assign* "meta.name" (simple-format #f "~s" "sut"))
             (sm:assign* "meta.parent" 0)))
         ,(sm:call (name (string-append model-name "_init"))
                   (arguments '("&sut" "&dzn_locator" "&meta")))
         ,(sm:call (name "dzn_map_init") (arguments '("&event_map")))
         ,(sm:assign* "global_event_map" "&event_map")
         ,(sm:call (name "fill_event_map")
                   (arguments `("&sut" "&event_map"
                                ,@(if (not pump?) '()
                                      '("&pump")))))
         ,(sm:while*
           (sm:not-equal*
            (sm:group* (sm:assign* "line" (sm:call (name "read_line"))))
            0)
           (sm:compound*
            (sm:variable (type "void*") (name "p") (expression 0))
            (sm:if* (sm:not* (sm:call (name "dzn_map_get")
                                      (arguments '("&event_map" "line" "&p"))))
                    (sm:compound*
                     `(,(sm:variable (type "dzn_closure*") (name "c")
                                     (expression "p"))
                       ,@(if (not pump?) `(,(sm:call (name "c->function")
                                                     (arguments '("c->argument"))))
                             `(,(sm:call (name "dzn_pump_run")
                                         (arguments '("&pump" "c")))))
                       ,(sm:call (name "free") (arguments '("line"))))))))
         ,@(if (not pump?) '()
               `(,(sm:call (name "dzn_pump_finalize")
                           (arguments '("&pump")))))
         ,(sm:return* 0)))))))


;;;
;;; Entry points.
;;;
(define-method (print-header-ast (o <root>))
  (let* ((models (code:model* o))
         (comment (dzn:comment o))
         (header (sm:header
                   (statements
                    `(,(code:generated-comment o)
                      ,@(if (not comment) '()
                            (list (sm:comment* comment)))
                      ,(sm:cpp-system-include* "dzn/config.h")
                      ,(sm:cpp-system-include* "dzn/runtime.h")
                      ,(sm:cpp-system-include* "dzn/locator.h")
                      ,@(root->header-statements o)
                      ,@(append-map model->header-statements models)
                      ,(code:version-comment))))))
    (display header)))

(define-method (print-code-ast (o <root>))
  (let* ((models (code:model* o))
         (comment (dzn:comment o))
         (header (string-append (code:file-name o) ".h"))
         (code (sm:code
                 (statements
                  `(,(code:generated-comment o)
                    ,@(if (not comment) '()
                          (list (sm:comment* comment)))
                    ,(sm:cpp-include* header)
                    ,(sm:cpp-system-include* "dzn/config.h")
                    ,(sm:cpp-system-include* "dzn/locator.h")
                    ,(sm:cpp-system-include* "dzn/runtime.h")
                    ,@(if (not (code:pump? o)) '()
                          (list (sm:cpp-system-include* "dzn/pump.h")
                                (sm:cpp-system-include* "stdlib.h")))
                    ,@(c:tracing-guard
                       (sm:cpp-system-include* "string.h"))
                    ,@(root->statements o)
                    ,@(append-map model->statements models)
                    ,(code:version-comment))))))
    (display code)))

(define-method (print-main-ast (o <component-model>))
  (let* ((header (string-append (code:file-name o) ".h"))
         (code (sm:code
                 (statements
                  `(,(code:generated-comment o)
                    ,(sm:cpp-define* "_GNU_SOURCE" 1)

                    ,(sm:cpp-include* header)

                    ,(sm:cpp-system-include* "assert.h")
                    ,(sm:cpp-system-include* "stdio.h")
                    ,(sm:cpp-system-include* "stdlib.h")
                    ,(sm:cpp-system-include* "string.h")

                    ,(sm:cpp-system-include* "dzn/closure.h")
                    ,(sm:cpp-system-include* "dzn/locator.h")
                    ,(sm:cpp-system-include* "dzn/map.h")
                    ,(sm:cpp-system-include* "dzn/runtime.h")
                    ,@(if (not (code:pump? o)) '()
                          `(,(sm:cpp-system-include* "dzn/pump.h")))

                    ,@(file-comments "main.c")
                    ,@(main-log-out-trigger o)
                    ,(main-fill-event-map o)
                    ,(main o)
                    ,(code:version-comment))))))
    (display code)))
