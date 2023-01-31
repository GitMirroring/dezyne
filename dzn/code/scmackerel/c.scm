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
  #:use-module (dzn indent)
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
     (comment* (code:caption file-name))
     (comment* "\n")
     (comment*
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
    `(,(cpp-ifndef* guard)
      ,(cpp-define* guard)
      ,@(match code
          ((code ...) code)
          (code (list code)))
      ,(cpp-endif* guard))))

(define-method (c:guard (o <string>) code)
  (let ((guard (string-upcase o)))
    `(,(cpp-if* guard)
      ,@(match code
          ((code ...) code)
          (code (list code)))
      ,(cpp-endif* guard))))

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
    (typedef* (string-append "struct " name) name)))

(define-method (c:event-slot-call-name struct (trigger <trigger>))
  ;; FIXME: named like a method, but isn't
  (string-append (struct-name struct)
                 "_"
                 (code:event-slot-name trigger)
                 "_"
                 (code:direction trigger)))

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
    (define (field->switch-case field)
      (let ((str (simple-format #f "~a:~a" (ast:name o) field)))
        (switch-case
         (expression (simple-format #f "~a_~a" enum-type field))
         (statement (return* (simple-format #f "~s" str))))))
    (function
     (name (string-append "dzn_" enum-type "_to_string"))
     (type "char const*")
     (formals (list (formal (type enum-type)
                            (name "v"))))
     (statement
      (compound*
       (switch (expression "v")
               (cases (map field->switch-case (ast:field* o))))
       (return* (simple-format #f "~s" "")))))))

(define-method (c:enum->to-enum (o <enum>))
  (let ((enum-name (string-join (ast:full-name o) "_"))
        (enum-type (code:type-name o))
        (short-name (ast:name o)))
    (define (field->if field else)
      (let* ((value (simple-format #f "~a_~a" enum-type field))
             (str (simple-format #f "~a:~a" short-name field))
             (str (simple-format #f "~s" str)))
        (if* (not* (call (name "strcmp") (arguments (list "s" str))))
             (return* value)
             else)))
    (function
     (name (simple-format #f "dzn_string_to_~a" enum-name))
     (formals (list (formal (type "char const*")
                            (name "s"))))
     (type enum-type)
     (statement
      (compound*
       (if* "0" (compound*)
            (fold field->if
                  #f
                  (reverse (ast:field* o))))
       (return* "INT_MAX"))))))

(define-method (c:enum->enum (o <enum>))
  (let ((scope (c:type-name o)))
    (enum
     (name #f)
     (fields (map (cute string-append scope "_" <>) (ast:field* o))))))

(define-method (c:enum->statements (o <enum>))
  `(,(c:enum->to-enum o)
    ,(c:enum->to-string o)))

(define-method (c:enum->header-statements (o <enum>))
  (let* ((enum (c:enum->enum o))
         (scope (c:type-name o))
         (statements
          `(,(typedef* enum scope)
            ,@(c:enum->statements o))))
    (c:include-guard o statements)))

(define-method (c:->formal (o <formal>))
  (let* ((type (code:type-name o))
         (type (if (ast:in? o) type
                   (string-append type "*"))))
    (formal (type type)
            (name (.name o)))))

(define-method (c:self-formal (o <model>))
  (formal (type (string-append (c:type-name o) "*"))
          (name "self")))

(define-method (c:file-name->include (o <string>))
  (cpp-include* (string-append o ".h")))

(define-method (c:file-name->include (o <file-name>))
  (c:file-name->include (.name o)))

(define-method (c:file-name->include (o <import>))
  (c:file-name->include (code:file-name o)))

;;; XXX FIXME template system renmants
(define-method (c:file-name->include (o <instance>))
  (cpp-include* (string-append (code:file-name->string o) ".h")))

(define-method (c:statement* (o <compound>))
  (ast:statement* o))

(define (c:binding->connect binding)
  (let* ((provides
          requires
          (code:provides+requires-end-point binding))
         (port (.port provides))
         (interface (.type port)))
    (call (name (string-append (c:type-name interface) "_connect"))
          (arguments
           (list
            (member* (%member-prefix) (c:end-point->string provides))
            (member* (%member-prefix) (c:end-point->string requires)))))))

(define-method (c:malloc o)
  (call (name "malloc")
        (arguments
         (list
          (call (name "sizeof")
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
          (statements* (map ast->code statements))))
       ((is-a? statement <compound>)
        (statement*))
       (else
        (ast->code statement))))
     (else
      (if* (ast->expression expression)
           (ast->code statement))))))

(define-method (ast->code (o <action>))
  (let* ((action-name (c:event-name o))
         (arguments (code:argument* o))
         (arguments (map ast->expression arguments))
         (port-name (.port.name o))
         (typed? (ast:typed? o)))
    (call (name (member* action-name))
          (arguments
           (cons (member* port-name)
                 arguments)))))

(define-method (ast->code (o <call>))
  (let* ((model (ast:parent o <model>))
         (model-name (c:type-name model))
         (name (string-append model-name "_" (.function.name o)))
         (arguments (map ast->expression (code:argument* o)))
         (arguments (cons "self" arguments)))
    (call
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
    (if* (ast->expression (.expression o))
         (ast->code then)
         (and=> else ast->code))))

(define-method (ast->code (o <illegal>))
  (statement* "dzn_illegal (&self->dzn_info)"))

(define-method (ast->code (o <out-bindings>))
  (statement*))

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
(define-method (interface->statements-unmemoized (o <interface>))
  (define (event->slot event)
    (let ((type (c:type-name (ast:type event)))
          (formals (code:formal* event)))
      (function
       (type type)
       (name (string-append "(*" (.name event) ")"))
       (formals (cons (c:self-formal o) (map c:->formal formals)))
       (statement #f))))
  (let* ((public-enums (code:public-enum* o))
         (enums (append public-enums (code:enum* o)))
         (interface
          (struct
           (name (c:type-name o))
           (members
            `(,(variable (type "dzn_port_meta") (name "meta")
                         (expression "m"))
              ,(variable (type
                          (struct
                           (members
                            (map event->slot (ast:in-event* o)))))
                         (name "in"))
              ,(variable (type
                          (struct
                           (members
                            (map event->slot (ast:out-event* o)))))
                         (name "out"))))))
         (interface& (string-append
                      (string-join (cons "" (ast:full-name o)) "::")
                      "&")))
    (define (value->init value)
      (let* ((value (simple-format #f "~s" (.value value))))
        (generalized-initializer-list* value)))
    (let* ((interface
            (struct
             (inherit interface)
             (methods
              (cons*
               (constructor (struct interface)
                            (formals (list (formal (type "dzn_port_meta")
                                                   (name "m")))))))))
           (interface* (pointer* (c:type-name o)))
           (connect
            (function
             (name (string-append (c:type-name o) "_connect"))
             (type "void")
             (formals (list (formal (type interface*) (name "provided"))
                            (formal (type interface*) (name "required"))))
             (statement
              (compound*
               (assign* "provided->out" "required->out")
               (assign* "required->in" "provided->in")
               (assign* "provided->meta.requires" "required->meta.requires")
               (assign* "required->meta.provides" "provided->meta.provides"))))))
      `(,@(append-map c:enum->header-statements enums)
        ,interface
        ,connect))))

(define-method (interface->statements (o <interface>))
  ((ast:perfect-funcq interface->statements-unmemoized) o))

(define-method (model->header-statements (o <interface>))
  (c:include-guard o `(,(c:typedef o)
                       ,@(interface->statements o))))

(define-method (model->statements (o <interface>))
  (interface->statements o))


;;;
;;; Component.
;;;
(define-method (component-model->statements-unmemoized (o <component-model>))
  (define (provides->member port)
    (list
     (variable
      (type (code:type-name (.type port)))
      (name (string-append (.name port) "_")))
     (variable
      (type (string-append (code:type-name (.type port)) "*"))
      (name (.name port))
      ;;(expression (address* (member* (string-append name "_"))))
      (expression (string-append "&self->" name "_")))))
  (define (requires->member port)
    (list
     (variable
      (type (code:type-name (.type port)))
      (name (string-append (.name port) "_")))
     (variable
      (type (string-append (code:type-name (.type port)) "*"))
      (name (.name port))
      ;;(expression (address* (member* (string-append name "_"))))
      (expression (string-append "&self->" name "_")))))
  (define (provides->inits port)
    (let* ((name (.name port))
           (name-string (simple-format #f "~s" name))
           (p (string-append "self->" name)))
      `(,(assign* (string-append p "->meta.provides.component") "self")
        ,(assign* (string-append p "->meta.requires.component") "0")
        ,@(c:tracing-guard
           (list
            (assign* (string-append p "->meta.provides.name") name-string)
            (assign* (string-append p "->meta.provides.meta") "&self->dzn_meta")
            (assign* (string-append p "->meta.requires.name") "\"\"")
            (assign* (string-append p "->meta.requires.meta") 0))))))
  (define (requires->inits port)
    (let* ((name (.name port))
           (name-string (simple-format #f "~s" name))
           (p (string-append "self->" name)))
      `(,(assign* (string-append p "->meta.requires.component") "self")
        ,(assign* (string-append p "->meta.provides.component") "0")
        ,@(c:tracing-guard
           (list
            (assign* (string-append p "->meta.requires.name") name-string)
            (assign* (string-append p "->meta.requires.meta") "&self->dzn_meta")
            (assign* (string-append p "->meta.provides.name") "\"\"")
            (assign* (string-append p "->meta.provides.meta") 0))))))
  (define (in-trigger->init trigger)
    (let* ((port (.port trigger))
           (port-name (.name port))
           (p (string-append "self->" port-name))
           (event-name (.event.name trigger))
           (direction (code:direction trigger))
           (base-name (c:base-type-name o)))
      (assign* (string-append p "->" direction "." event-name)
               (string-append "&" base-name
                              "_" port-name
                              "_" event-name
                              "_" direction))))
  (define (type->reply-variable o)
    (variable
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
           (reply-var (member* (code:reply-var type)))
           (port (.port trigger))
           (interface (c:type-name (.type port)))
           (event-name (.event.name trigger))
           (self-info (if (is-a? o <foreign>) "&self->base.dzn_info"
                          "&self->dzn_info")))
      (list
       (method
        (struct component)
        (type (if (not (is-a? o <foreign>)) "static void"
                  (code:type-name type)))
        (name (code:event-slot-name trigger))
        (formals formals)
        (statement statement))
       (function
        (type (string-append "static " (code:type-name type)))
        (name (c:event-slot-call-name component trigger))
        (formals (cons (formal (type (pointer* interface))
                               (name "port"))
                       formals))
        (statement
         (compound*
          `(,(variable (type (pointer* (struct-name component)))
                       (name "self")
                       (expression "port->meta.provides.component"))
            ,@(c:tracing-guard
               (call (name "dzn_runtime_trace")
                     (arguments
                      (list "&port->meta"
                            (simple-format #f "~s" event-name)))))
            ,(call (name "dzn_runtime_start")
                   (arguments (list self-info)))
            ,(call (name (string-append
                          (struct-name component)
                          "_"
                          (code:event-slot-name trigger)))
                   (arguments (cons "self"
                                    arguments)))
            ,(call (name "dzn_runtime_finish")
                   (arguments (list self-info)))
            ,@(c:tracing-guard
               (call
                (name "dzn_runtime_trace_out")
                (arguments
                 (list "&port->meta"
                       (if (not typed?)
                           (simple-format #f "~s" "return")
                           (call
                            (name (string-append "dzn_" reply-type
                                                 "_to_string"))
                            (arguments (list reply-var))))))))
            ,@(if (not typed?) '()
                  `(,(return*
                      (member*
                       (code:reply-var (ast:type trigger)))))))))))))
  (define (requires-trigger->method component trigger)
    (define (formal->a-formal o)
      (formal (type (c:type-name (.type o)))
              (name (.name o))))
    (define (formal->assign formal i)
      (assign* (simple-format #f "dzn_c._~a" i) (.name formal)))
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
           (component-name (struct-name component))
           (closure-name (c:closure-name trigger)))
      (list
       (method
        (struct component)
        (name (code:event-slot-name trigger))
        (formals (map c:->formal formals))
        (statement statement))
       (function
        (type "static void")
        (name (c:event-slot-call-name component trigger))
        (formals `(,(formal (type (pointer* interface))
                            (name "port"))
                   ,@(map formal->a-formal formals)))
        (statement
         (compound*
          `(,(variable (type (pointer* (struct-name component)))
                       (name "self")
                       (expression "port->meta.requires.component"))
            ,(variable (type closure-name)
                       (name "dzn_c"))
            ,@(c:tracing-guard
               (call
                (name "dzn_runtime_trace_out")
                (arguments
                 (list "&port->meta"
                       (simple-format #f "~s" event-name)))))
            ,(assign* "dzn_c.size" (call (name "sizeof")
                                         (arguments (list closure-name))))
            ,(assign* "dzn_c.function"
                      (string-append
                       "(void(*)(" component-name "*)) "
                       (c:ref
                        (string-append
                         component-name
                         "_"
                         (code:event-slot-name trigger)))))
            ,(assign* "dzn_c.self" "self")
            ,@(let ((formals (code:formal* trigger)))
                (map formal->assign formals (iota (length formals))))
            ,(call (name "dzn_runtime_defer")
                   (arguments
                    `("port->meta.provides.component"
                      "self"
                      ,(string-append
                        "(void (*)(void*)) "
                        (c:ref (c:closure-name trigger))
                        "_helper")
                      "&dzn_c"))))))))))
  (define (function->method component function)
    (let* ((type (code:type-name (ast:type function)))
           (name (.name function))
           (formals (code:formal* function))
           (statement (.statement function))
           (statement (ast->code statement)))
      (method (struct component)
              (type type)
              (name name)
              (formals (map c:->formal formals))
              (statement statement))))
  (define (requires->assignment ports)
    (assign* (member* "dzn_meta.require")
             (generalized-initializer-list*
              (map (compose
                    (cute string-append "&" <> ".meta")
                    .name)
                   ports))))
  (define (trigger->closure-helper signature)
    (define (formal->variable formal i)
      (variable (type "int")
                (name (simple-format #f "_~a" i))))
    (let ((component-name (c:type-name o))
          (closure-name (c:closure-name signature))
          (formals (ast:formal* signature)))
      (list
       (typedef* (string-append "struct " closure-name) closure-name)
       (struct
        (name closure-name)
        (members
         `(,(variable (type "size_t")
                      (name "size"))
           ,(function (type "void")
                      (name "(*function)")
                      (formals (list
                                (formal (type (pointer* component-name))
                                        (name "self"))))
                      (statement #f))
           ,(variable (type (pointer* component-name)) (name "self"))
           ,@(map formal->variable formals (iota (length formals))))))
       (function (type "static void")
                 (name (string-append closure-name "_helper"))
                 (formals (list (formal (type "void*") (name "argument"))))
                 (statement
                  (compound*
                   (variable (type (pointer* closure-name))
                             (name "helper")
                             (expression "argument"))
                   (call (name "helper->function")
                         (arguments '("helper->self")))))))))
  (let* ((enums (filter (is? <enum>) (code:enum* o)))
         (closure-triggers (c:closure-triggers o))
         (component
          (struct
           (name (c:type-name o))
           (members
            `(,(variable
                (type "dzn_meta")
                (name "dzn_meta"))
              ,(variable
                (type "dzn_runtime_info")
                (name "dzn_info"))
              ,@(map code:member->variable (ast:member* o))
              ,@(map type->reply-variable (code:reply-types o))
              ,@(append-map provides->member (ast:provides-port* o))
              ,@(append-map requires->member (ast:requires-port* o))))))
         (base (if (not (is-a? o <foreign>)) component
                   (struct (inherit component)
                           (name (c:base-type-name o))))))
    `(,@(append-map c:enum->header-statements enums)
      ,(c:typedef o)
      ,component
      ,@(if (not (is-a? o <foreign>)) '()
            `(,(cpp-include* (string-append
                              (struct-name base)
                              ".h"))))
      ,@(append-map trigger->closure-helper closure-triggers)
      ,@(if (not (is-a? o <foreign>)) '()
            `(,(constructor
                (struct base)
                (formals (list (formal (type "dzn_locator*")
                                       (name "dzn_locator"))
                               (formal (type "dzn_meta*")
                                       (name "dzn_meta"))))
                (statement #f))))
      ,(constructor
        (struct component)
        (formals (list (formal (type "dzn_locator*")
                               (name "dzn_locator"))
                       (formal (type "dzn_meta*")
                               (name "dzn_meta"))))
        (statement
         (compound*
          `(,(call (name "dzn_runtime_info_init")
                   (arguments
                    (list ;;(address* (member* "dzn_info"))
                     "&self->dzn_info"
                     "dzn_locator")))
            ,(assign* (member* "dzn_info.performs_flush") "true")
            ,@(c:tracing-guard
               (call (name "memcpy")
                     (arguments
                      (list ;;(address* (member* "dzn_meta"))
                       "&self->dzn_meta"
                       "dzn_meta"
                       "sizeof (self->dzn_meta)"))))
            ,@(append-map provides->inits (ast:provides-port* o))
            ,@(map in-trigger->init (ast:in-triggers o))
            ,@(append-map requires->inits (ast:requires-port* o))))))
      ,@(map (cute function->method base <>) (ast:function* o))
      ,@(append-map (cute provides-trigger->method base <>)
                    (ast:provides-in-triggers o))
      ,@(append-map (cute requires-trigger->method base <>)
                    (ast:requires-out-triggers o)))))

(define-method (component-model->statements (o <component-model>))
  ((ast:perfect-funcq component-model->statements-unmemoized) o))

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
         (statements `(,(cpp-system-include* "dzn/locator.h")
                       ,(cpp-system-include* "dzn/runtime.h")
                       ,@(map c:file-name->include interface-includes)
                       ,@(model->foreign o))))
    (c:include-guard o statements)))

(define-method (model->statements (o <foreign>))
  (model->foreign o))


;;;
;;; System.
;;;
(define-method (system->statements-unmemoized (o <system>))
  (define (provides->member port)
    (let* ((other-end (ast:other-end-point port)))
      (variable
       (type (string-append (code:type-name (.type port)) "*"))
       (name (.name port))
       ;; XXX FIXME ordering problem
       ;; (expression (member*
       ;;              (string-append (.instance.name other-end)
       ;;                             "."
       ;;                             (.port.name other-end))))
       )))
  (define (requires->member port)
    (let ((other-end (ast:other-end-point port)))
      (variable
       (type (string-append (code:type-name (.type port)) "*"))
       (name (.name port))
       ;; XXX FIXME ordering problem
       ;; (expression (member*
       ;;              (string-append (.instance.name other-end)
       ;;                             "."
       ;;                             (.port.name other-end))))
       )))
  (define (instance->member instance)
    (variable
     (type (string-append (code:type-name (.type instance))))
     (name (.name instance))))
  (define (instance->assignments instance)
    (let* ((name (.name instance))
           (component (.type instance))
           (base-name (c:base-type-name component))
           (port-name (.port.name instance))
           (meta (string-append "dzn_meta_" name))
           (name-string (simple-format #f "~s" name)))
      `(,(variable (type "dzn_meta") (name meta))
        ,(assign* (string-append meta ".name") name-string)
        ,(assign* (string-append meta ".parent") "&self->dzn_meta")
        ,(call (name (string-append base-name "_init"))
               (arguments (list
                           ;; FIXME (call (function??) (arguments))
                           ;;(string-append "&self->" name)
                           (string-append "&self->" (.name instance))
                           "dzn_locator"
                           (string-append "&" meta)))))))
  (define (port->assignment port)
    (let* ((other-end (ast:other-end-point port))
           (instance (.instance other-end))
           (component (.type instance)))
      (assign* (member* (.name port))
               (member*
                (string-append (.name instance)
                               (if (not (is-a? component <foreign>)) ""
                                   ".base")
                               "."
                               (.port.name other-end))))))
  (let* ((instances (code:instance* o))
         (bindings (code:component-binding* o))
         (system
          (struct
           (name (c:type-name o))
           (members
            `(,(variable
                (type "dzn_meta")
                (expression "*dzn_meta_dzn")
                (name "dzn_meta"))
              ,@(map instance->member instances)
              ,@(map provides->member (ast:provides-port* o))
              ,@(map requires->member (ast:requires-port* o)))))))
    `(,(c:typedef o)
      ,system
      ,(constructor
        (struct system)
        (formals (list (formal (type "dzn_locator*")
                               (name "dzn_locator"))
                       (formal (type "dzn_meta*")
                               (name "dzn_meta_dzn"))))
        (statement
         (compound*
          `(,@(append-map instance->assignments instances)
            ,@(map port->assignment (ast:provides-port* o))
            ,@(map port->assignment (ast:requires-port* o))
            ,@(map c:binding->connect bindings))))))))

(define-method (system->statements (o <system>))
  ((ast:perfect-funcq system->statements-unmemoized) o))

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
    (function
     (type (code:type->string type))
     (name (c:log-event-name o))
     (formals (list (formal (type (pointer* interface)) (name "m"))))
     (statement
      (compound*
       (list
        (statement* "(void) m")
        (cond
         (typed?
          (return*
           (call (name "log_valued")
                 (arguments
                  `(,@arguments
                    ,(string-append
                      "(int (*) (char*)) "
                      "dzn_string_to_" type)
                    ,(string-append
                      "(char* (*) (int)) "
                      "dzn_" type "_to_string"))))))
         (else
          (call (name (if (ast:in? o) "log_in" "log_out"))
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
      `(,(assign* "c" (c:malloc "dzn_closure"))
        ,(assign* "c->function" "&log_flush")
        ,(assign* "flush_args" (c:malloc "flush_arguments"))
        ,(assign* "flush_args->info" "&comp->dzn_info")
        ,(assign* "flush_args->name" port-string)
        ,(assign* "c->argument" "flush_args")
        ,(assign* (string-append meta "component") "comp")
        ,@(c:tracing-guard
           (list
            (assign* (string-append meta "name") port-string)
            (assign* (string-append meta "meta") "&comp->dzn_meta")
            (if* "global_flush_p"
                 (assign* "comp->dzn_meta.name" external-string))))
        ,(call (name "dzn_map_put")
               (arguments (list "e" flush-string "c"))))))
  (define (requires->init port)
    (let* ((port-name (.name port))
           (port-string (simple-format #f "~s" port-name))
           (external-string (simple-format #f "~s" "<external>"))
           (flush (simple-format #f "~a.<flush>" port-name))
           (flush-string (simple-format #f "~s" flush))
           (meta (simple-format #f "m->~a->meta.provides." port-name)))
      `(,(assign* "c" (c:malloc "dzn_closure"))
        ,(assign* "c->function" "&log_flush")
        ,(assign* "flush_args" (c:malloc "flush_arguments"))
        ,(assign* "flush_args->info" "&comp->dzn_info")
        ,(assign* "flush_args->name" port-string)
        ,(assign* "c->argument" "flush_args")
        ,(assign* (string-append meta "component") "comp")
        ,@(c:tracing-guard
           (list
            (assign* (string-append meta "name") port-string)
            (assign* (string-append meta "meta") "&comp->dzn_meta")
            (if* "global_flush_p"
                 (assign* "comp->dzn_meta.name" external-string))))
        ,(call (name "dzn_map_put")
               (arguments (list "e" flush-string "c"))))))

  (define (in-trigger->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event)))
      (define (formal->variable formal)
        (variable (type "int")
                  (name (code:number-argument formal))
                  (expression (.name formal))))
      (list
       (assign* "c" (c:malloc "dzn_closure"))
       (assign* "c->function" (string-append
                               "(void (*)) m->" port "->"
                               (code:direction trigger) "."
                               event))
       (assign* "c->argument" (string-append "m->" port))
       (call (name "dzn_map_put")
             (arguments (list "e" port-event-string "c"))))))
  (define (out-trigger->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (formals (code:formal* trigger)))
      (assign* (string-append "m->" (c:event-name trigger))
               (string-append
                (c:log-event-type-cast trigger)
                " "
                (c:log-event-name trigger)))))
  (let ((external-string (simple-format #f "~s" "<external>")))
    (function
     (type "void")
     (name "fill_event_map")
     (formals (list (formal (type (pointer* (code:type-name o)))
                            (name "m"))
                    (formal (type "dzn_map*")
                            (name "e"))))
     (statement
      (compound*
       `(,(variable (type "dzn_closure*") (name "c"))
         ,(variable (type "flush_arguments*") (name "flush_args"))
         ,(variable (type "dzn_component*") (name "comp")
                    (expression (c:malloc "dzn_component")))
         ,(assign* "comp->dzn_info.performs_flush" "global_flush_p")
         ,@(c:tracing-guard
            `(,(assign* "comp->dzn_meta.parent" 0)
              ,(assign* "comp->dzn_meta.name" external-string)
              ,@(map out-trigger->init (ast:out-triggers o))))
         ,@(append-map provides->init (ast:provides-port* o))
         ,@(append-map requires->init (ast:requires-port* o))
         ,@(append-map in-trigger->init (ast:in-triggers o))))))))

(define-method (main (o <component-model>))
  (let ((model-name (code:type-name o))
        (flush-string (simple-format #f "~s" "--flush")))
    (function
     (name "main")
     (formals (list (formal (type "int") (name "argc"))
                    (formal (type "char const*") (name "argv[]"))))
     (statement
      (compound*
       `(,(variable (type "dzn_locator") (name "dzn_locator"))
         ,@(c:tracing-guard
            (variable (type "dzn_meta") (name "meta")))
         ,(variable (type "dzn_map") (name "event_map"))
         ,(variable (type "char*") (name "line"))
         ,(assign* "global_flush_p"
                   (call (name "getopt")
                         (arguments `("argc" "argv" ,flush-string))))
         ,(call (name "dzn_locator_init") (arguments '("&dzn_locator")))
         ,(assign* "dzn_locator.illegal" "&illegal_print")
         ,(variable (type model-name) (name "sut"))
         ,@(c:tracing-guard
            (list
             (assign* "meta.name" (simple-format #f "~s" "sut"))
             (assign* "meta.parent" 0)))
         ,(call (name (string-append model-name "_init"))
                (arguments '("&sut" "&dzn_locator" "&meta")))
         ,(call (name "dzn_map_init") (arguments '("&event_map")))
         ,(assign* "global_event_map" "&event_map")
         ,(call (name "fill_event_map")
                (arguments '("&sut" "&event_map")))
         ,(while*
           (not-equal*
            (group* (assign* "line" (call (name "read_line"))))
            0)
           (compound*
            (variable (type "void*") (name "p") (expression 0))
            (if* (not* (call (name "dzn_map_get")
                             (arguments '("&event_map" "line" "&p"))))
                 (compound*
                  (variable (type "dzn_closure*") (name "c")
                            (expression "p"))
                  (call (name "c->function")
                        (arguments '("c->argument")))
                  (call (name "free") (arguments '("line")))))))
         ,(return* 0)))))))


;;;
;;; Entry points.
;;;
(define-method (print-header-ast (o <root>))
  (let* ((models (code:model* o))
         (comment (dzn:comment o))
         (scmheader (scmheader
                     (statements
                      `(,(code:generated-comment o)
                        ,@(if (not comment) '()
                              (list (comment* comment)))
                        ,(cpp-system-include* "dzn/config.h")
                        ,(cpp-system-include* "dzn/runtime.h")
                        ,(cpp-system-include* "dzn/locator.h")
                        ,@(root->header-statements o)
                        ,@(append-map model->header-statements models)
                        ,(code:version-comment))))))
    (display scmheader)))

(define-method (print-code-ast (o <root>))
  (let* ((models (code:model* o))
         (comment (dzn:comment o))
         (header (string-append (code:file-name o) ".h"))
         (scmcode (scmcode
                   (statements
                    `(,(code:generated-comment o)
                      ,@(if (not comment) '()
                            (list (comment* comment)))
                      ,(cpp-include* header)
                      ,(cpp-system-include* "dzn/config.h")
                      ,(cpp-system-include* "dzn/locator.h")
                      ,(cpp-system-include* "dzn/runtime.h")
                      ,@(if (not (code:pump? o)) '()
                            (list (cpp-system-include* "dzn/pump.h")))
                      ,@(c:tracing-guard
                         (cpp-system-include* "string.h"))
                      ,@(root->statements o)
                      ,@(append-map model->statements models)
                      ,(code:version-comment))))))
    (display scmcode)))

(define-method (print-main-ast (o <component-model>))
  (let* ((header (string-append (code:file-name o) ".h"))
         (scmcode (scmcode
                   (statements
                    `(,(code:generated-comment o)
                      ,(cpp-define* "_GNU_SOURCE" 1)

                      ,(cpp-include* header)

                      ,(cpp-system-include* "assert.h")
                      ,(cpp-system-include* "stdio.h")
                      ,(cpp-system-include* "stdlib.h")
                      ,(cpp-system-include* "string.h")

                      ,(cpp-system-include* "dzn/closure.h")
                      ,(cpp-system-include* "dzn/locator.h")
                      ,(cpp-system-include* "dzn/map.h")
                      ,(cpp-system-include* "dzn/runtime.h")

                      ,@(file-comments "main.c")
                      ,@(main-log-out-trigger o)
                      ,(main-fill-event-map o)
                      ,(main o)
                      ,(code:version-comment))))))
    (display scmcode)))
