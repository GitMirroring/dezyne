;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn code scmackerel cs)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)
  #:use-module (scmackerel cs)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code goops)
  #:use-module (dzn code scmackerel code)
  #:use-module (dzn code language dzn)
  #:use-module (dzn code language cs)
  #:use-module (dzn misc)
  #:export (print-code-ast
            print-main-ast))

;;;
;;; Helpers.
;;;
(define (cs:binding->connect binding)
  (let* ((provides
          requires
          (code:provides+requires-end-point binding))
         (port (code:type-name (.type (.port provides)))))
    (sm:call (name (string-append port ".connect"))
             (arguments (list (code:end-point->string provides)
                              (code:end-point->string requires))))))

(define-method (cs:sm:statement* (o <compound>))
  (ast:statement* o))

;; XXX FIXME: introduce <block> statement instead of
;; <blocking-compound>, like VM?
(define-method (cs:sm:statement* (o <blocking-compound>))
  (let* ((port-name (.port.name o))
         (block (sm:call (name "dzn.pump.port_block")
                         (arguments
                          (list "dzn_locator"
                                "this"
                                (string-append
                                 (%member-prefix)
                                 port-name))))))
    `(,@(ast:statement* o)
      ,block)))

(define (cs:sm:formal->temp formal)
  (let ((name (.name formal))
        (type (code:type-name formal)))
    (sm:variable (type type)
                 (expression (if (ast:inout? formal) name
                                 (sm:call (name "default")
                                          (arguments (list type)))))
                 (name (string-append "dzn_" name)))))

(define (cs:temp->formal formal)
  (let ((name (.name formal)))
    (sm:assign* name (string-append "dzn_" name))))

(define-method (cs:dzn-meta-assignments (o <component-model>))
  (let ((instances (if (not (is-a? o <system>)) '()
                       (ast:instance* o))))
    (list
     (sm:assign* (sm:member* "dzn_meta.require")
                 (string-append
                  "new List<dzn.port.Meta>"
                  (sm:code->string
                   (sm:generalized-initializer-list*
                    (map (cute string-append "this." <> ".meta")
                         (map .name (ast:requires-port* o)))))))
     (sm:assign* (sm:member* "dzn_meta.children")
                 (string-append
                  "new List<dzn.Meta>"
                  (sm:code->string
                   (sm:generalized-initializer-list*
                    (map (cute string-append "this." <> ".dzn_meta")
                         (map .name instances))))))
     (sm:assign* (sm:member* "dzn_meta.ports_connected")
                 (string-append
                  "new List<Action>"
                  (sm:code->string
                   (sm:generalized-initializer-list*
                    (map (cute string-append <> ".dzn_check_bindings")
                         (map .name (ast:port* o))))))))))


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
             (as (cs:sm:statement* statement) <pair>))
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
  (let ((statements (cs:sm:statement* o)))
    (sm:compound* (map ast->code statements)))) ;;; XXX new sm:compound*

(define-method (ast->expression (o <top>) (sm:formal <formal>))
  (ast->expression o))

(define-method (ast->expression (name <string>) (formal <formal>))
  (cs:out-ref formal name))

(define-method (ast->expression (o <var>) (formal <formal>))
  (ast->expression (.name o) formal))

(define-method (ast->code (o <action>))
  (let* ((action-name (code:event-name o))
         (formals (code:formal* (.event o)))
         (arguments (code:argument* o))
         (arguments (map ast->expression arguments formals))
         (action (sm:call (name action-name)
                          (arguments arguments))))
    action))

(define-method (ast->code (o <call>))
  (let* ((formals (code:formal* (.function o)))
         (arguments (code:argument* o))
         (arguments (map ast->expression arguments formals)))
    (sm:call-method
     (name (.function.name o))
     (arguments arguments))))

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
           ,(sm:if* (sm:not-equal* out-binding "null") (sm:call (name out-binding)))
           ,(sm:assign* out-binding "null")
           ,@(if (not (code:port-release? o)) '()
                 `(,(sm:call (name "dzn.pump.port_release")
                             (arguments
                              (list "dzn_locator"
                                    "this"
                                    (string-append
                                     (%member-prefix)
                                     (.port.name o))))))))))))))

(define-method (ast->code (o <illegal>))
  (sm:call (name (sm:member* (%member-prefix) "dzn_runtime.illegal"))))

(define-method (cs:->formal (o <formal>))
  (let* ((type (code:type-name o))
         (type (cs:out-ref o type)))
    (sm:formal (type type)
               (name (.name o)))))

;; FIXME: c&p from c++
(define-method (ast->code (o <defer>))
  (define (variable->defer-variable o)
    (sm:variable
     (type (code:type-name (ast:type o)))
     (name (cs:capture-name o))
     (expression (code:member-name o))))
  (define (variable->equality o)
    (sm:equal* (ast->expression o)
               (cs:capture-name o)))
  (let* ((variables (cs:defer-variable* o))
         (locals (code:capture-local o))
         (equality (cs:defer-equality* o))
         (condition (if (not (code:defer-condition o)) "true"
                        (sm:and*
                         (map variable->equality equality))))
         (statement (.statement o))
         (statement (if (is-a? statement <compound>) statement
                        (code:wrap-compound statement)))
         (statement (ast->code statement))
         (statement
          (sm:compound*
           `(,@(map variable->defer-variable variables)
             ,(sm:call (name "dzn.Runtime.defer")
                       (arguments
                        (list "this"
                              (sm:function
                               (captures
                                (cons* "this"
                                       (map cs:capture-name variables)))
                               (statement
                                (sm:compound*
                                 (sm:return* condition))))
                              (sm:function
                               (captures
                                (cons* "&" (map .name locals)))
                               (statement statement)))))))))
    statement))

(define-method (cs:->argument (o <formal>))
  (let* ((name (.name o))
         (name (if (ast:in? o) name
                   (string-append "dzn_" name))))
    (cs:out-ref o name)))

(define-method (ast->code (o <out-bindings>))
  (define (formal->assign formal)
    (let* ((name (.name formal))
           (name (if (ast:in? formal) name
                     (string-append "dzn_" name))))
      (sm:assign* name
                  (sm:member* (%member-prefix) (.variable.name formal)))))
  (let ((formals (ast:formal* o)))
    (if (null? formals) (sm:statement*)
        (sm:assign*
         (sm:member* (%member-prefix) (code:out-binding (.port o)))
         (sm:function
          (statement
           (sm:compound*
            (map formal->assign formals))))))))


;;;
;;; Root.
;;;
(define-method (root->statements (o <root>))
  (let ((enums (code:enum* o)))
    (append
     (map .value (ast:data* o))
     (append-map code:->namespace
                 enums
                 (map code:enum->sm:enum-struct enums)))))


;;;
;;; Interface.
;;;

;; C&$ from c++:model->statements
(define-method (interface->statements (o <interface>))
  (define (event->slot-method port event)
    (let* ((name (.name event))
           (signature-name (string-append "signature_" name))
           (type (code:type-name (ast:type event)))
           (formals (code:formal* event)))
      (sm:method
       (struct port)
       (type (string-append "delegate " type))
       (name signature-name)
       (formals (map cs:->formal formals))
       (statement #f))))
  (define (event->slot-member port event)
    (let* ((name (.name event))
           (signature-name (string-append "signature_" name)))
      (sm:variable
       (type signature-name)
       (name name))))
  (define (event->check-binding event)
    (let ((event-name (code:event-name event)))
      (sm:if* (sm:equal* (sm:member* event-name) "null")
              (sm:statement*
               (format #f "throw new dzn.binding_error (this.meta, ~s)"
                       event-name)))))
  (let* ((public-enums (code:public-enum* o))
         (enums (append public-enums (code:enum* o)))
         (in-events (sm:struct (name "in_events")))
         (out-events (sm:struct (name "out_events")))
         (interface
          (sm:struct
            (parents (list "dzn.Port"))
            (name (dzn:model-name o))
            (types
             `(,@(map code:enum->sm:enum-struct enums)
               ,(sm:struct
                  (inherit in-events)
                  (methods
                   (map (cute event->slot-method in-events <>) (ast:in-event* o)))
                  (members
                   (map (cute event->slot-member in-events <>) (ast:in-event* o))))
               ,(sm:struct
                  (inherit out-events)
                  (methods
                   (map (cute event->slot-method in-events <>) (ast:out-event* o)))
                  (members
                   (map (cute event->slot-member out-events <>) (ast:out-event* o))))))
            (members
             (list
              (sm:variable (type "in_events")
                           (name "in_port")
                           (expression (sm:call (name (string-append "new " type)))))
              (sm:variable (type "out_events")
                           (name "out_port")
                           (expression (sm:call (name (string-append "new " type)))))))))
         (interface& (code:type-name o)))
    (let* ((interface
            (sm:struct
              (inherit interface)
              (methods
               (list
                (sm:constructor (struct interface))
                (sm:destructor (struct interface)
                               (type "virtual")
                               (statement (sm:compound*)))
                (sm:method
                 (struct interface)
                 (type "static string")
                 (name "to_string")
                 (formals (list (sm:formal (type "bool") (name "b"))))
                 (statement
                  (sm:compound*
                   (sm:return*
                    (sm:conditional* "b" "\"true\"" "\"false\"")))))
                (sm:method
                 (struct interface) (type "void") (name "dzn_check_bindings")
                 (statement
                  (sm:compound*
                   (append
                    (map event->check-binding (ast:in-event* o))
                    (map event->check-binding (ast:out-event* o))))))
                (sm:method
                 (struct interface) (type "static void") (name "connect")
                 (formals (list (sm:formal (type interface&) (name "provided"))
                                (sm:formal (type interface&) (name "required"))))
                 (statement
                  (sm:compound*
                   (sm:assign* "provided.out_port" "required.out_port")
                   (sm:assign* "required.in_port" "provided.in_port")
                   (sm:assign* "provided.meta.require" "required.meta.require")
                   (sm:assign* "required.meta.provide" "provided.meta.provide"))))))))
           ;;(sm:enum-to-string (map cs:sm:enum->to-string public-enums))
           ;;(to-enum (map cs:sm:enum->to-enum public-enums))
           )
      `(,@(code:->namespace o interface)
        ;;,@sm:enum-to-string
        ;;,@to-enum
        ))))


;;;
;;; Component.
;;;

;; C&P from c++:component-model->statements
(define-method (component-model->statements (o <component-model>))
  (define (provides->member port)
    (let* ((interface (.type port))
           (type-name (code:type-name interface)))
      (sm:variable
       (type (code:type-name interface))
       (name (.name port))
       (expression (sm:call (name (string-append "new " type-name)))))))
  (define (requires->member port)
    (let* ((interface (.type port))
           (type-name (code:type-name interface)))
      (sm:variable
       (type (code:type-name interface))
       (name (.name port))
       (expression (sm:call (name (string-append "new " type-name)))))))
  (define (injected->member port)
    (let ((interface (.type port)))
      (sm:variable
       (type (code:type-name interface))
       (name (.name port))
       (expression (sm:member* (simple-format #f "dzn_locator.get< ~a> ()" type))))))
  (define (port->out-binding port)
    (sm:variable
     (type "Action")
     (name (code:out-binding port))))
  (define (type->reply-variable o)
    (sm:variable
     (type (code:type-name o))
     (name (code:reply-var o))))
  (define (port->injected-require-override port)
    (let* ((type (.type port))
           (type (code:type-name type)))
      (sm:assign* (sm:member* (simple-format #f "dzn_locator.get< ~a> ()" type))
                  (.name port))))
  (define (trigger->event-slot trigger)
    (let* ((port (.port trigger))
           (port-name (.name port))
           (event (.event trigger))
           (event-name (.name event))
           (event-name-string (simple-format #f "~s" event-name))
           (formals (code:formal* trigger))
           (arguments (map cs:->argument formals))
           (out-formals (filter (negate ast:in?) formals))
           ;; (out-arguments (map .name out-formals))
           (formals (map cs:->formal formals))
           (on (code:on trigger))
           (on-triggers (and=> on ast:trigger*))
           (on-trigger (or (and=> on-triggers car) trigger))
           (formal-bindings (filter (is? <formal-binding>) (ast:formal* on-trigger)))
           (out-bindings (make <out-bindings>
                           #:elements formal-bindings
                           #:port (.port trigger)))
           (out-bindings (clone out-bindings #:parent on))
           (out-binding (code:out-binding port))
           (this-out-binding (code:member out-binding))
           (type (ast:type trigger))
           (typed? (not (is-a? type <void>)))
           (reply-var (and typed?
                           (sm:member* (code:reply-var (ast:type trigger)))))
           (sm:call-slot (sm:call-method
                          (name (code:event-slot-name trigger))
                          (arguments arguments)))
           (sm:call-in/out
            (sm:call
             (name (string-append "dzn_runtime.call_" (code:direction event)))
             (arguments
              `("this"
                ,(sm:function
                  (statement
                   (sm:compound*
                    `(,(ast->code out-bindings)
                      ,(cond ((and typed? (is-a? o <foreign>))
                              (sm:assign* reply-var sm:call-slot))
                             (else
                              sm:call-slot))
                      ,@(if (ast:out? event) '()
                            `(,(sm:call-method
                                (name "dzn_runtime.flush")
                                (arguments
                                 '("this"
                                   "dzn.pump.coroutine_id (this.dzn_locator)")))
                              ,@(if (is-a? o <foreign>) '()
                                    (list
                                     (sm:if* (sm:not-equal* this-out-binding "null")
                                             (sm:call-method (name out-binding)))
                                     (sm:assign* this-out-binding "null")))
                              ,(sm:return (expression reply-var))))))))
                ,(simple-format #f "this.~a" port-name)
                ,(simple-format #f "~s" event-name))))))
      (sm:assign*
       (sm:member* (code:event-name trigger))
       (sm:function
        (formals formals)
        (statement
         (sm:compound*
          ;; FIXME: This is ridiculous
          `(,@(map cs:sm:formal->temp out-formals)
            ,(cond ((not typed?)
                    sm:call-in/out)
                   ((pair? out-formals)
                    (let ((type (code:type-name type)))
                      (sm:variable (type type) (name "dzn_return")
                                   (expression sm:call-in/out))))
                   (else
                    (sm:return* sm:call-in/out)))
            ,@(map cs:temp->formal out-formals)
            ,@(if (or (not typed?) (null? out-formals)) '()
                  `(,(sm:return* "dzn_return"))))))))))
  (define (trigger->method component trigger)
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
           (formals (map cs:->formal formals))
           (type (ast:type trigger)))
      (sm:method (struct component)
                 (type (if (not (is-a? o <foreign>)) "void"
                           (string-append "virtual " (code:type-name type))))
                 (name (code:event-slot-name trigger))
                 (formals formals)
                 (statement statement))))
  (define (function->method component function)
    (let* ((type (code:type-name (ast:type function)))
           (name (.name function))
           (formals (code:formal* function))
           (formals (map cs:->formal formals))
           (statement (.statement function))
           (statement (ast->code statement)))
      (sm:method (struct component)
                 (type type)
                 (name name)
                 (formals formals)
                 (statement statement))))
  (define (provides->assignments port)
    (let* ((name (.name port))
           (meta (string-append name ".meta.provide"))
           (name-string (simple-format #f "~s" name)))
      `(,(sm:assign* (sm:member* (string-append meta ".meta")) (sm:member* "dzn_meta"))
        ,(sm:assign* (sm:member* (string-append meta ".name")) name-string)
        ,(sm:assign* (sm:member* (string-append meta ".component")) "this")
        ,(sm:assign* (sm:member* (string-append meta ".port")) (sm:member* name)))))
  (define (requires->assignments port)
    (let* ((name (.name port))
           (meta (string-append name ".meta.require"))
           (name-string (simple-format #f "~s" name)))
      `(,(sm:assign* (sm:member* (string-append meta ".meta")) (sm:member* "dzn_meta"))
        ,(sm:assign* (sm:member* (string-append meta ".name")) name-string)
        ,(sm:assign* (sm:member* (string-append meta ".component")) "this")
        ,(sm:assign* (sm:member* (string-append meta ".port")) (sm:member* name)))))
  (define injected->assignments requires->assignments)
  (let* ((enums (filter (is? <enum>) (code:enum* o)))
         (check-bindings-list
          (map
           (compose
            (cute string-append "[this]{" <> ".dzn_check_bindings ();}")
            .name)
           (ast:port* o)))
         (component
          (sm:struct
            (name (dzn:model-name o))
            (partial? (is-a? o <foreign>))
            (parents '("dzn.Component"))
            (inits (list (sm:parent-init
                          (name "base")
                          (arguments '("locator" "name" "parent")))))
            (types (map code:enum->sm:enum-struct enums))
            (members
             `(,@(map code:member->variable (ast:member* o))
               ,@(map type->reply-variable (code:reply-types o))
               ,@(map provides->member (ast:provides-port* o))
               ,@(map requires->member (ast:requires-no-injected-port* o))
               ,@(map injected->member (ast:injected-port* o))
               ,@(if (is-a? o <foreign>) '()
                     (map port->out-binding (ast:provides-port* o)))))))
         (component
          (sm:struct
            (inherit component)
            (methods
             `(,(sm:constructor
                 (struct component)
                 (formals (list (sm:formal (type "dzn.Locator") (name "locator"))
                                (sm:formal (type "String") (name "name"))
                                (sm:formal (type "dzn.Meta") (name "parent")
                                           (default "null"))))
                 (statement
                  (sm:compound*
                   `(,@(append-map provides->assignments
                                   (ast:provides-port* o))
                     ,@(append-map requires->assignments
                                   (ast:requires-no-injected-port* o))
                     ,@(append-map injected->assignments
                                   (ast:injected-port* o))
                     ,@(cs:dzn-meta-assignments o)
                     ,@(if (is-a? o <foreign>) '()
                           `(,(sm:assign* (sm:member* "dzn_runtime.states[this].flushes")
                                          "true")))
                     ,@(map trigger->event-slot (ast:in-triggers o))))))
               ,@(if (not (is-a? o <foreign>)) '()
                     (list
                      (sm:destructor (struct component)
                                     (type "virtual")
                                     (statement (sm:compound*)))))
               ,(sm:method
                 (struct component) (type "void") (name "dzn_check_bindings")
                 (statement
                  (sm:compound*
                   (sm:call (name "dzn.RuntimeHelper.check_bindings")
                            (arguments (list (sm:member* "dzn_meta")))))))
               ,@(if (is-a? o <foreign>) '()
                     (map (cute trigger->method component <>) (ast:in-triggers o)))
               ,@(map (cute function->method component <>) (ast:function* o)))))))
    (code:->namespace o component)))

(define-method (interface->statements (o <component>))
  (component-model->statements o))


;;;
;;; Foreign.
;;;
(define-method (interface->statements (o <foreign>))
  (component-model->statements o))


;;;
;;; System.
;;;

;;; C&P from c++:main-*
(define-method (system->statements (o <system>))
  (let* ((injected-instances (code:injected-instance* o))
         (injected? (pair? injected-instances)))
    (define (port->expression port)
      (let ((other-end (ast:other-end-point port)))
        (string-append (%member-prefix)
                       (.instance.name other-end)
                       "."
                       (.port.name other-end))))
    (define (port->member port)
      (let ((other-end (ast:other-end-point port)))
        (sm:variable
         (type (code:type-name (.type port)))
         (name (.name port))
         (expression (and (not injected?)
                          (port->expression port))))))
    (define (injected-instance? instance)
      (member instance injected-instances ast:eq?))
    (define (instance->expression instance)
      (let ((instance-name (.name instance))
            (type (code:type-name (.type instance))))
        (sm:call (name (string-append "new " type))
                 (arguments
                  (list "locator"
                        (simple-format #f "~s" instance-name)
                        "this.dzn_meta")))))
    (define (instance->member instance)
      (let ((local? (and injected?
                         (not (injected-instance? instance))))
            (instance-name (.name instance)))
        (sm:variable
         (type (code:type-name (.type instance)))
         (name instance-name)
         (expression (and (or (not injected?)
                              (member instance injected-instances ast:eq?))
                          (instance->expression instance))))))
    (define (instance->assignment instance)
      (let ((name (.name instance)))
        (sm:assign* (sm:member* name)
                    (instance->expression instance))))
    (define (port->assignment port)
      (let ((name (.name port)))
        (sm:assign* (sm:member* name)
                    (port->expression port))))
    (define (injected->assignment instance)
      (let* ((name (.name instance))
             (port-name (.port.name instance))
             (meta (string-append name ".dzn_meta."))
             (name-string (simple-format #f "~s" name))
             (meta (simple-format #f "~a.~a.meta." name port-name)))
        (sm:assign* (string-append meta "require.name")
                    name-string)))
    (define (binding->injected-initializer binding)
      (let ((end-point (code:instance-end-point binding)))
        (string-append ".set ("
                       (code:end-point->string end-point)
                       ")")))
    (let* ((instances (code:instance* o))
           (bindings (code:component-binding* o))
           (injected-bindings (code:injected-binding* o))
           (check-bindings-list
            (map
             (compose
              (cute string-append "[this]{" <> ".dzn_check_bindings ();}")
              .name)
             (ast:port* o)))
           (system
            (sm:struct
              (name (dzn:model-name o))
              (parents '("dzn.SystemComponent"))
              ;; C&P from component
              (inits (list (sm:parent-init
                            (name "base")
                            (arguments '("locator" "name" "parent")))))
              (members
               `(,@(map instance->member injected-instances)
                 ,@(map instance->member instances)
                 ,@(map port->member (ast:provides-port* o))
                 ,@(map port->member (ast:requires-port* o))))))
           (system
            (sm:struct
              (inherit system)
              (methods
               (list
                (sm:constructor
                 (struct system)
                 ;; C&P from component
                 (formals (list (sm:formal (type "dzn.Locator") (name "locator"))
                                (sm:formal (type "String") (name "name"))
                                (sm:formal (type "dzn.Meta") (name "parent")
                                           (default "null"))))
                 (statement
                  (sm:compound*
                   `(,@(if (not injected?) '()
                           `(,(sm:assign*
                               "locator"
                               (string-append
                                "locator.clone ()"
                                (string-join
                                 (map binding->injected-initializer
                                      injected-bindings)
                                 "")))))
                     ,@(map injected->assignment injected-instances)
                     ,@(if (not injected?) '()
                           `(,@(map instance->assignment instances)
                             ,@(map port->assignment (ast:provides-port* o))
                             ,@(map port->assignment (ast:requires-port* o))))
                     ,@(cs:dzn-meta-assignments o)
                     ,@(map cs:binding->connect bindings)))))
                ;; C&P from component
                (sm:method
                 (struct system) (type "void") (name "dzn_check_bindings")
                 (statement
                  (sm:compound*
                   (sm:call (name "dzn.RuntimeHelper.check_bindings")
                            (arguments (list (sm:member* "dzn_meta"))))))))))))
      (code:->namespace o system))))

(define-method (interface->statements (o <system>))
  (system->statements o))


;;;
;;; Shell-system.
;;;

;;; C&P from c++:main-*
(define-method (shell-system->statements (o <shell-system>))
  (let* ((injected-instances (code:injected-instance* o))
         (injected? (pair? injected-instances)))
    (define (port->expression port)
      (let* ((interface (.type port))
             (type-name (code:type-name interface)))
        (sm:call (name (string-append "new " type-name)))))
    (define (port->member port)
      (let ((other-end (ast:other-end-point port)))
        (sm:variable
         (type (code:type-name (.type port)))
         (name (.name port))
         (expression (and (not injected?)
                          (port->expression port))))))
    (define (injected-instance? instance)
      (member instance injected-instances ast:eq?))
    (define (instance->expression instance)
      (let ((instance-name (.name instance))
            (type (code:type-name (.type instance))))
        (sm:call (name (string-append "new " type))
                 (arguments
                  (list "locator"
                        (simple-format #f "~s" instance-name)
                        "this.dzn_meta")))))
    (define (instance->member instance)
      (let ((local? (and injected?
                         (not (injected-instance? instance))))
            (instance-name (.name instance)))
        (sm:variable
         (type (code:type-name (.type instance)))
         (name instance-name)
         (expression (and (or (not injected?)
                              (member instance injected-instances ast:eq?))
                          (instance->expression instance))))))
    (define (instance->assignment instance)
      (let ((name (.name instance)))
        (sm:assign* (sm:member* name)
                    (instance->expression instance))))
    (define (provides->assignments port)
      (let* ((name (.name port))
             (meta (string-append name ".meta.provide"))
             (name-string (simple-format #f "~s" name)))
        `(,@(if (not injected?) '()
                `(,(sm:assign* (sm:member* name)
                               (port->expression port))))
          ,(sm:assign* (sm:member* (string-append meta ".meta")) (sm:member* "dzn_meta"))
          ,(sm:assign* (sm:member* (string-append meta ".name")) name-string)
          ,(sm:assign* (sm:member* (string-append meta ".component")) "this")
          ,(sm:assign* (sm:member* (string-append meta ".port")) (sm:member* name)))))
    (define (requires->assignments port)
      (let* ((name (.name port))
             (meta (string-append name ".meta.require"))
             (name-string (simple-format #f "~s" name)))
        `(,@(if (not injected?) '()
                `(,(sm:assign* (sm:member* name)
                               (port->expression port))))
          ,(sm:assign* (sm:member* (string-append meta ".meta")) (sm:member* "dzn_meta"))
          ,(sm:assign* (sm:member* (string-append meta ".name")) name-string)
          ,(sm:assign* (sm:member* (string-append meta ".component")) "this")
          ,(sm:assign* (sm:member* (string-append meta ".port")) (sm:member* name)))))
    (define (injected->assignment instance)
      (let* ((name (.name instance))
             (port-name (.port.name instance))
             (meta (string-append name ".dzn_meta."))
             (name-string (simple-format #f "~s" name))
             (meta (simple-format #f "~a.~a.meta." name port-name)))
        (sm:assign* (string-append meta "require.name")
                    name-string)))
    (define (provides->init port)
      (let ((other-end (ast:other-end-point port)))
        (sm:assign*
         (string-append (.instance.name other-end)
                        "." (.port.name other-end)
                        ".meta.require.name")
         (simple-format #f "~s" (.name port)))))
    (define (requires->init port)
      (let ((other-end (ast:other-end-point port)))
        (sm:assign*
         (string-append (.instance.name other-end)
                        "." (.port.name other-end)
                        ".meta.provide.name")
         (simple-format #f "~s" (.name port)))))
    (define (trigger->event-slot trigger)
      (let* ((port (.port trigger))
             (other-end (ast:other-end-point port))
             (port-name (.name port))
             (event (.event trigger))
             (event-name (.name event))
             (formals (code:formal* trigger))
             (arguments (map cs:->argument formals))
             (out-formals (filter (negate ast:in?) formals))
             ;; (out-arguments (map .name out-formals))
             (in-formals (filter ast:in? formals))
             (in-arguments (map .name in-formals))
             (formals (map cs:->formal formals))
             (type (ast:type trigger))
             (typed? (not (is-a? type <void>)))
             (sm:call-slot
              (sm:call (name
                        (string-append ;;; XXX FIXME code:foo-name
                         (.instance.name other-end)
                         "."
                         (.port.name other-end)
                         "."
                         (code:event-name event)))
                       (arguments arguments)))
             (sm:call-pump
              (sm:call
               (name (if (ast:in? event) "this.dzn_pump.shell"
                         "this.dzn_pump.execute"))
               (arguments
                (list
                 (sm:function
                  (statement
                   (sm:compound*
                    (if (not typed?) sm:call-slot
                        (sm:return* sm:call-slot))))))))))
        (sm:assign*
         (code:event-name trigger)
         (sm:function
          (formals formals)
          (statement
           (sm:compound*
            ;; FIXME: This is ridiculous
            `(,@(map cs:sm:formal->temp out-formals)
              ,(cond ((not typed?)
                      sm:call-pump)
                     ((pair? out-formals)
                      (let ((type (code:type-name type)))
                        (sm:variable (type type) (name "dzn_return")
                                     (expression sm:call-pump))))
                     (else
                      (sm:return* sm:call-pump)))
              ,@(map cs:temp->formal out-formals)
              ,@(if (or (not typed?) (null? out-formals)) '()
                    `(,(sm:return* "dzn_return"))))))))))
    (define (trigger->out-event-slot trigger)
      (let* ((port (.port trigger))
             (other-end (ast:other-end-point port))
             (event (.event trigger))
             (event-name (.name event))
             (formals (code:formal* trigger))
             (arguments (map cs:->argument formals))
             (out-formals (filter (negate ast:in?) formals))
             (formals (map cs:->formal formals))
             (type (ast:type trigger))
             (typed? (not (is-a? type <void>)))
             (call (sm:call (name (code:event-name trigger))
                            (arguments arguments))))
        (sm:assign*
         (string-append ;;; XXX FIXME code:foo-name
          (.instance.name other-end)
          "."
          (.port.name other-end)
          "."
          (code:event-name event))
         (sm:function
          (formals formals)
          (statement
           (if (and (not typed?) (null? out-formals)) call
               (sm:compound*
                ;; FIXME: This is ridiculous
                `(,@(map cs:sm:formal->temp out-formals)
                  ,(cond ((not typed?)
                          call)
                         ((pair? out-formals)
                          (let ((type (code:type-name type)))
                            (sm:variable (type type) (name "dzn_return")
                                         (expression call))))
                         (else
                          (sm:return* call)))
                  ,@(map cs:temp->formal out-formals)
                  ,@(if (or (not typed?) (null? out-formals)) '()
                        `(,(sm:return* "dzn_return")))))))))))
    (define (binding->injected-initializer binding)
      (let ((end-point (code:instance-end-point binding)))
        (string-append ".set ("
                       (code:end-point->string end-point)
                       ")")))
    (let* ((instances (code:instance* o))
           (bindings (code:component-binding* o))
           (injected-bindings (code:injected-binding* o))
           (check-bindings-list
            (map
             (compose
              (cute string-append "[this]{" <> ".dzn_check_bindings ();}")
              .name)
             (ast:port* o)))
           (shell
            (sm:struct
              (name (dzn:model-name o))
              (parents '("dzn.SystemComponent" "System.IDisposable"))
              ;; C&P from component
              (inits (list (sm:parent-init
                            (name "base")
                            (arguments '("locator" "name" "parent")))))
              (members
               `(,@(map instance->member injected-instances)
                 ,@(map instance->member instances)
                 ,@(map port->member (ast:provides-port* o))
                 ,@(map port->member (ast:requires-port* o))
                 ,(sm:variable
                   (type "dzn.pump")
                   (name "dzn_pump")
                   (expression (sm:call (name "new dzn.pump"))))))))
           (shell
            (sm:struct
              (inherit shell)
              (methods
               (list
                (sm:constructor
                 (struct shell)
                 ;; C&P from component
                 (formals (list (sm:formal (type "dzn.Locator") (name "locator"))
                                (sm:formal (type "String") (name "name"))
                                (sm:formal (type "dzn.Meta") (name "parent")
                                           (default "null"))))
                 (statement
                  (sm:compound*
                   `(,(sm:call (name "locator.set")
                               (arguments '("this.dzn_pump")))
                     ,@(if (not injected?) '()
                           `(,(sm:assign*
                               "locator"
                               (string-append
                                "locator.clone ()"
                                (string-join
                                 (map binding->injected-initializer
                                      injected-bindings)
                                 "")))))
                     ,@(map injected->assignment injected-instances)
                     ,@(if (not injected?) '()
                           `(,@(map instance->assignment instances)))
                     ,@(append-map provides->assignments (ast:provides-port* o))
                     ,@(append-map requires->assignments (ast:requires-port* o))
                     ,@(map provides->init (ast:provides-port* o))
                     ,@(map requires->init (ast:requires-port* o))
                     ,@(map trigger->event-slot (ast:provides-in-triggers o))
                     ,@(map trigger->event-slot (ast:requires-out-triggers o))
                     ,@(map trigger->out-event-slot (ast:provides-out-triggers o))
                     ,@(map trigger->out-event-slot (ast:requires-in-triggers o))
                     ,@(map cs:binding->connect bindings)))))
                (sm:method
                 (struct shell) (type "virtual void") (name "Dispose")
                 (formals (list (sm:formal (type "bool") (name "gc"))))
                 (statement
                  (sm:compound*
                   (sm:if* "gc"
                           (sm:call (name "this.dzn_pump.Dispose"))))))
                (sm:method
                 (struct shell) (type "void") (name "Dispose")
                 (statement
                  (sm:compound*
                   (sm:call (name "Dispose") (arguments '("true")))
                   (sm:call (name "GC.SuppressFinalize") (arguments '("this"))))))
                ;; C&P from component
                (sm:method
                 (struct shell) (type "void") (name "dzn_check_bindings")
                 (statement
                  (sm:compound*
                   (sm:call (name "dzn.RuntimeHelper.check_bindings")
                            (arguments (list (sm:member* "dzn_meta"))))))))))))
      (code:->namespace o shell))))

(define-method (interface->statements (o <shell-system>))
  (shell-system->statements o))


;;;
;;; Main.
;;;

;;; C&P from c++:main-*
(define-method (main-connect-ports (o <component-model>) container)
  (define (return-expression trigger)
    (let* ((type (ast:type trigger))
           (type-name (code:type-name type)))
      (and (not (is-a? type <void>))
           (sm:call (name (string-append container
                                         "."
                                         "string_to_value<"
                                         type-name
                                         ">"))
                    (arguments (list "tmp"))))))
  (define (formal->sm:assign-default formal)
    (let ((type (code:type-name formal)))
      (sm:assign* (.name formal)
                  (sm:call (name "default")
                           (arguments (list type))))))
  (define (trigger-in-event->assign trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (direction (ast:direction trigger))
           (formals (code:formal* trigger))
           (out-formals (filter (negate ast:in?) formals))
           (formals (map cs:->formal formals))
           (system-port (string-append "c.system." port))
           (meta (string-append system-port ".meta"))
           (port-event (string-append port "." event))
           (function
            (sm:function
             (formals formals)
             (statement
              (sm:compound*
               `(,(sm:call (name "dzn.Runtime.trace")
                           (arguments
                            (list meta
                                  (simple-format #f "~s" event))))
                 ,(sm:call (name "c.match")
                           (arguments
                            (list (simple-format #f "~s" port-event))))
                 ,(sm:call (name "dzn.pump.port_block")
                           (arguments
                            (list "c.dzn_locator" "c.nullptr"
                                  (simple-format #f "c.system.~a" port))))
                 ,(sm:variable (type "string")
                               (name "tmp")
                               (expression
                                (sm:call (name "c.trail_expect"))))
                 ,(sm:assign (variable "tmp")
                             (expression "tmp.Split ('.')[1]"))
                 ,(sm:call (name "dzn.Runtime.trace_out")
                           (arguments
                            (list meta "tmp")))
                 ,@(map formal->sm:assign-default out-formals)
                 ,(sm:return* (return-expression trigger))))))))
      (sm:assign (variable (string-append "c.system." (code:event-name trigger)))
                 (expression function))))
  (define (trigger-out-event->assign trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (direction (ast:direction trigger))
           (system-port (simple-format #f "c.system.~a" port))
           (meta (simple-format #f "~a.meta" system-port))
           (port-event (simple-format #f "~a.~a" port event))
           (flush-event (simple-format #f "~a.<flush>" port))
           (flush-string (simple-format #f "~s" flush-event))
           (formals (code:formal* trigger))
           (formals (map cs:->formal formals))
           (sm:call-out
            (sm:call
             (name "c.dzn_runtime.call_out")
             (arguments
              `("c"
                ,(sm:function
                  (statement
                   (sm:compound*
                    (sm:if* "c.flush"
                            (sm:call
                             (name "c.dzn_runtime.queue (c).Enqueue")
                             (arguments
                              (list
                               (sm:function
                                (statement
                                 (sm:compound*
                                  (sm:if* (sm:equal* "c.dzn_runtime.queue (c).Count" 0)
                                          (sm:compound*
                                           (sm:call (name "Console.Error.WriteLine")
                                                    (arguments (list flush-string)))
                                           (sm:call
                                            (name "c.match")
                                            (arguments
                                             (list flush-string)))))))))))))))
                ,system-port
                ,(simple-format #f "~s" event))))))
      (sm:assign (variable (string-append "c.system." (code:event-name trigger)))
                 (expression
                  (sm:function
                   (formals formals)
                   (statement
                    (sm:compound*
                     (sm:call (name "c.match")
                              (arguments
                               (list (simple-format #f "~s" port-event))))
                     (if (not (ast:typed? trigger)) sm:call-out
                         (sm:return* sm:call-out)))))))))
  (sm:function
   (type "static void")
   (name "connect_ports")
   (formals (list (sm:formal (type container) (name "c"))))
   (statement
    (sm:compound*
     (cons*
      (append
       (map trigger-in-event->assign (ast:out-triggers-in-events o))
       (map trigger-out-event->assign (ast:out-triggers-out-events o))))))))

(define-method (main-event-map (o <component-model>) container)
  (define (provides->init port)
    (let* ((port-name (.name port))
           (system-port (simple-format #f "c.system.~a" port-name))
           (meta (simple-format #f "~a.meta.require" system-port)))
      (list
       (sm:assign (variable (simple-format #f "~a.component" meta))
                  (expression "c"))
       (sm:assign (variable (simple-format #f "~a.meta" meta))
                  (expression "c.dzn_meta"))
       (sm:assign (variable (simple-format #f "~a.name" meta))
                  (expression (simple-format #f "~s" port-name))))))
  (define (requires->init port)
    (let* ((port-name (.name port))
           (system-port (simple-format #f "c.system.~a" port-name))
           (meta (simple-format #f "~a.meta.provide" system-port)))
      (list
       (sm:assign (variable (simple-format #f "~a.component" meta))
                  (expression "c"))
       (sm:assign (variable (simple-format #f "~a.meta" meta))
                  (expression "c.dzn_meta"))
       (sm:assign (variable (simple-format #f "~a.name" meta))
                  (expression (simple-format #f "~s" port-name))))))
  (define (void-provides-in->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (formals (code:formal* trigger))
           (formals (code:number-formals formals))
           (arguments (map cs:number-argument formals))
           (out-formals (filter (negate ast:in?) formals))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (port-return (simple-format #f "~a.return" port))
           (port-sm:return-string (simple-format #f "~s" port-return)))
      (define (formal->variable formal)
        (sm:variable (type "int")
                     (name (code:number-argument formal))
                     (expression (.name formal))))
      (sm:call
       (name "lookup.Add")
       (arguments
        (list
         port-event-string
         (sm:function
          (statement
           (sm:compound*
            `(
              ,(sm:call (name "c.match")
                        (arguments (list port-event-string)))
              ,@(map formal->variable out-formals)
              ,(sm:call (name (string-append "c.system." (code:event-name trigger)))
                        (arguments arguments))
              ,(sm:call (name "c.match")
                        (arguments (list port-sm:return-string))))))))))))
  (define (typed-provides-in->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (type (ast:type trigger))
           (event-type (code:type-name type))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (port-return (simple-format #f "~a.return" port))
           (port-sm:return-string (simple-format #f "~s" port-return))
           (port-prefix (simple-format #f "~a." port))
           (event-slot (string-append "c.system." (code:event-name trigger)))
           (formals (code:formal* trigger))
           (invoke (sm:code->string (sm:call (name event-slot)
                                             (arguments (iota (length formals)))))))
      (sm:call
       (name "lookup.Add")
       (arguments
        (list
         port-event-string
         (sm:function
          (statement
           (sm:compound*
            (sm:call (name "c.match")
                     (arguments (list port-event-string)))
            (sm:variable (type "string")
                         (name "tmp")
                         (expression
                          (simple-format
                           #f
                           "~s + c.to_string<~a> (~a)" port-prefix event-type invoke)))
            (sm:call (name "c.match")
                     (arguments (list "tmp")))))))))))
  (define (void-requires-in->init trigger)
    (let* ((port (.port.name trigger))
           (port-return (simple-format #f "~a.return" port))
           (port-sm:return-string (simple-format #f "~s" port-return))
           (port-prefix (simple-format #f "~a." port))
           (system-port (simple-format #f "c.system.~a" port)))
      (sm:call
       (name "lookup.Add")
       (arguments
        (list
         port-sm:return-string
         (sm:function
          (statement
           (sm:compound*
            (sm:call (name "dzn.pump.port_release")
                     (arguments
                      (list "c.dzn_locator"
                            "c.system"
                            system-port)))))))))))
  (define (typed-in->init port-pair) ;; FIXME: get rid of port-pair?
    (let* ((port (.port port-pair))
           (other (.other port-pair))
           (port-other (simple-format #f "~a.~a" port other)))
      (sm:call
       (name "lookup.Add")
       (arguments
        (list
         (simple-format #f "~s" port-other)
         (sm:function
          (statement
           (sm:compound*
            (sm:call (name "dzn.pump.port_release")
                     (arguments
                      (list "c.dzn_locator"
                            "c.system"
                            (simple-format #f "c.system.~a" (.port port-pair)))))))))))))
  (define (out->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (formals (code:formal* trigger)))
      (sm:call
       (name "lookup.Add")
       (arguments
        (list
         port-event-string
         (sm:function
          (statement
           (sm:compound*
            (sm:call (name "c.match")
                     (arguments (list port-event-string)))
            (sm:call (name (string-append "c.system." (code:event-name trigger)))
                     (arguments (iota (length formals))))))))))))
  (define (flush->init port)
    (let* ((port (.name port))
           (flush (simple-format #f "~a.<flush>" port))
           (flush-string (simple-format #f "~s" flush)))
      (sm:call
       (name "lookup.Add")
       (arguments
        (list
         flush-string
         (sm:function
          (statement
           (sm:compound*
            (sm:call (name "c.match")
                     (arguments (list flush-string)))
            (sm:call (name "System.Console.Error.WriteLine")
                     (arguments (list flush-string)))
            (sm:call (name "c.dzn_runtime.flush")
                     (arguments (list "c")))))))))))
  (let ((map-type "Dictionary<String, Action>"))
    (sm:function
     (type (string-append "static " map-type))
     (name "event_map")
     (formals (list (sm:formal (type container) (name "c"))))
     (statement
      (sm:compound*
       `(,@(append-map provides->init (ast:provides-port* o))
         ,@(append-map requires->init (ast:requires-port* o))
         ,(sm:variable (type map-type) (name "lookup")
                       (expression (sm:call (name (string-append "new " type)))))
         ,(sm:call (name "lookup.Add")
                   (arguments
                    (list "\"illegal\""
                          (sm:function
                           (statement
                            (sm:compound*
                             (sm:call (name "Console.Error.WriteLine")
                                      (arguments '("\"illegal\"")))
                             (sm:call (name "Environment.Exit")
                                      (arguments '(0)))))))))
         ,(sm:call (name "lookup.Add")
                   (arguments
                    (list "\"error\""
                          (sm:function
                           (statement
                            (sm:compound*
                             (sm:call (name "Console.Error.WriteLine")
                                      (arguments '("\"sut.error -> sut.error\"")))
                             (sm:call (name "Environment.Exit")
                                      (arguments '(0)))))))))
         ,@(map void-provides-in->init (ast:provides-in-void-triggers o))
         ,@(map typed-provides-in->init (ast:provides-in-typed-triggers o))
         ,@(map void-requires-in->init (code:requires-in-void-returns o))
         ,@(map typed-in->init (code:return-values o))
         ,@(map out->init (ast:requires-out-triggers o))
         ,@(map flush->init (ast:requires-port* o))
         ,(sm:return* "lookup")))))))

(define-method (main-getopt)
  (sm:function
   (type "static bool")
   (name "dzn_getopt")
   (formals (list (sm:formal (type "String[]") (name "args"))
                  (sm:formal (type "String") (name "option"))))
   (statement
    (sm:compound*
     (sm:return*
      (sm:call (name "Array.Exists")
               (arguments (list "args"
                                (sm:function (formals '("s"))
                                             (statement (sm:equal* "s" "option")))))))))))

(define-method (main (o <component-model>) container)
  (sm:function
   (type "static void")
   (name "Main")
   (formals (list (sm:formal (type "String[]") (name "argv"))))
   (statement
    (sm:compound*
     (let ((option (simple-format #f "~s" "--flush")))
       (sm:variable (type "bool") (name "flush")
                    (expression (sm:call (name "dzn_getopt")
                                         (arguments (list "argv" option))))))
     (let ((call-rdbuf (sm:call (name "new TextWriterTraceListener")
                                (arguments '("Console.Error"))))
           (option (simple-format #f "~s" "--debug")))
       (sm:if* (sm:call (name "dzn_getopt") (arguments (list "argv" option)))
               (sm:compound*
                (sm:call (name "Debug.Listeners.Add")
                         (arguments (list call-rdbuf))
                         ;; (arguments (sm:call (name "new TextWriterTraceListener")
                         ;; (arguments '("Console.Error"))))
                         )
                (sm:assign* "Debug.AutoFlush" "true"))))
     (let ((type-name (code:type-name o)))
       (sm:using
        (variables
         (list
          (sm:variable
           (type container)
           (name "c")
           (expression
            (sm:call (name (string-append "new " container))
                     (arguments
                      (list
                       (sm:function
                        (formals '("locator" "name"))
                        (statement
                         (sm:compound*
                          (sm:return*
                           (sm:call
                            (name (string-append "new " type-name))
                            (arguments formals))))))
                       "flush")))))))
        (statement
         (sm:compound*
          (sm:call (name "connect_ports") (arguments '("c")))
          (sm:call (name "c.run") (arguments '("event_map (c)")))))))))))

(define-method (main-struct (o <component-model>))
  (let* ((type-name (code:type-name o))
         (container (string-append "dzn.container< " type-name ">"))
         (struct
          (sm:struct (name "main")
                     (types '())
                     (members '())
                     (methods
                      `(,(main-connect-ports o container)
                        ,(main-event-map o container)
                        ,(main-getopt)
                        ,(main o container))))))
    struct))


;;;
;;; Entry points.
;;;
(define-method (print-code-ast (o <root>))
  (let* ((models (code:model* o))
         (comment (dzn:comment o))
         (code (sm:code
                 (statements
                  `(,(code:generated-comment o)
                    ,@(if (not comment) '()
                          (list (sm:comment* comment)))
                    ,(sm:cpp-sm:using* "System")
                    ,(sm:cpp-sm:using* "System.Collections.Generic")
                    ,@(root->statements o)
                    ,@(append-map interface->statements models)
                    ,(code:version-comment))))))
    ((@@ (scmackerel cs) set-record-printers!))
    (display code)))

(define-method (print-main-ast (o <component-model>))
  (let ((code (sm:code
                (statements
                 `(,(code:generated-comment o)
                   ,(sm:cpp-sm:using* "System")
                   ,(sm:cpp-sm:using* "System.Collections.Generic")
                   ,(sm:cpp-sm:using* "System.Diagnostics")
                   ,(main-struct o)
                   ,(code:version-comment))))))
    ((@@ (scmackerel cs) set-record-printers!))
    (display code)))
