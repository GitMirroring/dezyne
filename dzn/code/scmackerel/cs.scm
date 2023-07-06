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
    (call (name (string-append port ".connect"))
          (arguments (list (code:end-point->string provides)
                           (code:end-point->string requires))))))

(define-method (cs:statement* (o <compound>))
  (ast:statement* o))

;; XXX FIXME: introduce <block> statement instead of
;; <blocking-compound>, like VM?
(define-method (cs:statement* (o <blocking-compound>))
  (let* ((port-name (.port.name o))
         (block (call (name "dzn.pump.port_block")
                      (arguments
                       (list "dzn_locator"
                             "this"
                             (string-append
                              (%member-prefix)
                              port-name))))))
    `(,@(ast:statement* o)
      ,block)))

(define (cs:formal->temp formal)
  (let ((name (.name formal))
        (type (code:type-name formal)))
    (variable (type type)
              (expression (if (ast:inout? formal) name
                              (call (name "default")
                                    (arguments (list type)))))
              (name (string-append "dzn_" name)))))

(define (cs:temp->formal formal)
  (let ((name (.name formal)))
    (assign* name (string-append "dzn_" name))))

(define-method (cs:dzn-meta-assignments (o <component-model>))
  (let ((instances (if (not (is-a? o <system>)) '()
                       (ast:instance* o))))
    (list
     (assign* (member* "dzn_meta.require")
              (string-append
               "new List<dzn.port.Meta>"
               (code->string
                (generalized-initializer-list*
                 (map (cute string-append "this." <> ".meta")
                      (map .name (ast:requires-port* o)))))))
     (assign* (member* "dzn_meta.children")
              (string-append
               "new List<dzn.Meta>"
               (code->string
                (generalized-initializer-list*
                 (map (cute string-append "this." <> ".dzn_meta")
                      (map .name instances))))))
     (assign* (member* "dzn_meta.ports_connected")
              (string-append
               "new List<Action>"
               (code->string
                (generalized-initializer-list*
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
             (as (cs:statement* statement) <pair>))
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

;;; imperative
(define-method (ast->code (o <blocking-compound>))
  (let ((statements (cs:statement* o)))
    (compound* (map ast->code statements)))) ;;; XXX new compound*

(define-method (ast->expression (o <top>) (formal <formal>))
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
         (action (call (name action-name)
                       (arguments arguments))))
    action))

(define-method (ast->code (o <call>))
  (let* ((formals (code:formal* (.function o)))
         (arguments (code:argument* o))
         (arguments (map ast->expression arguments formals)))
    (call-method
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
        (statements*
         `(,@(if (is-a? type <void>) '()
                 `(,(assign* (member* (%member-prefix) (code:reply-var type))
                             (ast->expression (.expression o)))))
           ,(if* (not-equal* out-binding "null") (call (name out-binding)))
           ,(assign* out-binding "null")
           ,@(if (not (code:port-release? o)) '()
                 `(,(call (name "dzn.pump.port_release")
                          (arguments
                           (list "dzn_locator"
                                 "this"
                                 (string-append
                                  (%member-prefix)
                                  (.port.name o))))))))))))))

(define-method (ast->code (o <illegal>))
  (call (name (member* (%member-prefix) "dzn_runtime.illegal"))))

(define-method (cs:->formal (o <formal>))
  (let* ((type (code:type-name o))
         (type (cs:out-ref o type)))
    (formal (type type)
            (name (.name o)))))

;; FIXME: c&p from c++
(define-method (ast->code (o <defer>))
  (define (variable->defer-variable o)
    (variable
     (type (code:type-name (ast:type o)))
     (name (cs:capture-name o))
     (expression (code:member-name o))))
  (define (variable->equality o)
    (equal* (ast->expression o)
            (cs:capture-name o)))
  (let* ((variables (cs:defer-variable* o))
         (locals (code:capture-local o))
         (equality (cs:defer-equality* o))
         (condition (if (not (code:defer-condition o)) "true"
                        (and*
                         (map variable->equality equality))))
         (statement (.statement o))
         (statement (if (is-a? statement <compound>) statement
                        (code:wrap-compound statement)))
         (statement (ast->code statement))
         (statement
          (compound*
           `(,@(map variable->defer-variable variables)
             ,(call (name "dzn.Runtime.defer")
                    (arguments
                     (list "this"
                           (function
                            (captures
                             (cons* "this"
                                    (map cs:capture-name variables)))
                            (statement
                             (compound*
                              (return* condition))))
                           (function
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
      (assign* name
               (member* (%member-prefix) (.variable.name formal)))))
  (let ((formals (ast:formal* o)))
    (if (null? formals) (statement*)
        (assign*
         (member* (%member-prefix) (code:out-binding (.port o)))
         (function
          (statement
           (compound*
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
                 (map code:enum->enum-struct enums)))))


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
      (method
       (struct port)
       (type (string-append "delegate " type))
       (name signature-name)
       (formals (map cs:->formal formals))
       (statement #f))))
  (define (event->slot-member port event)
    (let* ((name (.name event))
           (signature-name (string-append "signature_" name)))
      (variable
       (type signature-name)
       (name name))))
  (define (event->check-binding event)
    (let ((event-name (code:event-name event)))
      (if* (equal* (member* event-name) "null")
           (statement*
            (format #f "throw new dzn.binding_error (this.meta, ~s)"
                    event-name)))))
  (let* ((public-enums (code:public-enum* o))
         (enums (append public-enums (code:enum* o)))
         (in-events (struct (name "in_events")))
         (out-events (struct (name "out_events")))
         (interface
          (struct
           (parents (list "dzn.Port"))
           (name (dzn:model-name o))
           (types
            `(,@(map code:enum->enum-struct enums)
              ,(struct
                (inherit in-events)
                (methods
                 (map (cute event->slot-method in-events <>) (ast:in-event* o)))
                (members
                 (map (cute event->slot-member in-events <>) (ast:in-event* o))))
              ,(struct
                (inherit out-events)
                (methods
                 (map (cute event->slot-method in-events <>) (ast:out-event* o)))
                (members
                 (map (cute event->slot-member out-events <>) (ast:out-event* o))))))
           (members
            (list
             (variable (type "in_events")
                       (name "in_port")
                       (expression (call (name (string-append "new " type)))))
             (variable (type "out_events")
                       (name "out_port")
                       (expression (call (name (string-append "new " type)))))))))
         (interface& (code:type-name o)))
    (let* ((interface
            (struct
             (inherit interface)
             (methods
              (list
               (constructor (struct interface)
                            )
               (destructor (struct interface)
                           (type "virtual")
                           (statement (compound*)))
               (method
                (struct interface)
                (type "static string")
                (name "to_string")
                (formals (list (formal (type "bool") (name "b"))))
                (statement
                 (compound*
                  (return*
                   (conditional* "b" "\"true\"" "\"false\"")))))
               (method
                (struct interface) (type "void") (name "dzn_check_bindings")
                (statement
                 (compound*
                  (append
                   (map event->check-binding (ast:in-event* o))
                   (map event->check-binding (ast:out-event* o))))))
               (method
                (struct interface) (type "static void") (name "connect")
                (formals (list (formal (type interface&) (name "provided"))
                               (formal (type interface&) (name "required"))))
                (statement
                 (compound*
                  (assign* "provided.out_port" "required.out_port")
                  (assign* "required.in_port" "provided.in_port")
                  (assign* "provided.meta.require" "required.meta.require")
                  (assign* "required.meta.provide" "provided.meta.provide"))))))))
           ;;(enum-to-string (map cs:enum->to-string public-enums))
           ;;(to-enum (map cs:enum->to-enum public-enums))
           )
      `(,@(code:->namespace o interface)
        ;;,@enum-to-string
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
      (variable
       (type (code:type-name interface))
       (name (.name port))
       (expression (call (name (string-append "new " type-name)))))))
  (define (requires->member port)
    (let* ((interface (.type port))
           (type-name (code:type-name interface)))
      (variable
       (type (code:type-name interface))
       (name (.name port))
       (expression (call (name (string-append "new " type-name)))))))
  (define (injected->member port)
    (let ((interface (.type port)))
      (variable
       (type (code:type-name interface))
       (name (.name port))
       (expression (member* (simple-format #f "dzn_locator.get< ~a> ()" type))))))
  (define (port->out-binding port)
    (variable
     (type "Action")
     (name (code:out-binding port))))
  (define (type->reply-variable o)
    (variable
     (type (code:type-name o))
     (name (code:reply-var o))))
  (define (port->injected-require-override port)
    (let* ((type (.type port))
           (type (code:type-name type)))
      (assign* (member* (simple-format #f "dzn_locator.get< ~a> ()" type))
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
                           (member* (code:reply-var (ast:type trigger)))))
           (call-slot (call-method
                       (name (code:event-slot-name trigger))
                       (arguments arguments)))
           (call-in/out
            (call
             (name (string-append "dzn_runtime.call_" (code:direction event)))
             (arguments
              `("this"
                ,(function
                  (statement
                   (compound*
                    `(,(ast->code out-bindings)
                      ,(cond ((and typed? (is-a? o <foreign>))
                              (assign* reply-var call-slot))
                             (else
                              call-slot))
                      ,@(if (ast:out? event) '()
                            `(,(call-method
                                (name "dzn_runtime.flush")
                                (arguments
                                 '("this"
                                   "dzn.pump.coroutine_id (this.dzn_locator)")))
                              ,@(if (is-a? o <foreign>) '()
                                    (list
                                     (if* (not-equal* this-out-binding "null")
                                          (call-method (name out-binding)))
                                     (assign* this-out-binding "null")))
                              ,(return (expression reply-var))))))))
                ,(simple-format #f "this.~a" port-name)
                ,(simple-format #f "~s" event-name))))))
      (assign*
       (member* (code:event-name trigger))
       (function
        (formals formals)
        (statement
         (compound*
          ;; FIXME: This is ridiculous
          `(,@(map cs:formal->temp out-formals)
            ,(cond ((not typed?)
                    call-in/out)
                   ((pair? out-formals)
                    (let ((type (code:type-name type)))
                      (variable (type type) (name "dzn_return")
                                (expression call-in/out))))
                   (else
                    (return* call-in/out)))
            ,@(map cs:temp->formal out-formals)
            ,@(if (or (not typed?) (null? out-formals)) '()
                  `(,(return* "dzn_return"))))))))))
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
      (method (struct component)
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
      (method (struct component)
              (type type)
              (name name)
              (formals formals)
              (statement statement))))
  (define (provides->assignments port)
    (let* ((name (.name port))
           (meta (string-append name ".meta.provide"))
           (name-string (simple-format #f "~s" name)))
      `(,(assign* (member* (string-append meta ".meta")) (member* "dzn_meta"))
        ,(assign* (member* (string-append meta ".name")) name-string)
        ,(assign* (member* (string-append meta ".component")) "this")
        ,(assign* (member* (string-append meta ".port")) (member* name)))))
  (define (requires->assignments port)
    (let* ((name (.name port))
           (meta (string-append name ".meta.require"))
           (name-string (simple-format #f "~s" name)))
      `(,(assign* (member* (string-append meta ".meta")) (member* "dzn_meta"))
        ,(assign* (member* (string-append meta ".name")) name-string)
        ,(assign* (member* (string-append meta ".component")) "this")
        ,(assign* (member* (string-append meta ".port")) (member* name)))))
  (define injected->assignments requires->assignments)
  (let* ((enums (filter (is? <enum>) (code:enum* o)))
         (check-bindings-list
          (map
           (compose
            (cute string-append "[this]{" <> ".dzn_check_bindings ();}")
            .name)
           (ast:port* o)))
         (component
          (struct
           (name (dzn:model-name o))
           (partial? (is-a? o <foreign>))
           (parents '("dzn.Component"))
           (inits (list (parent-init
                         (name "base")
                         (arguments '("locator" "name" "parent")))))
           (types (map code:enum->enum-struct enums))
           (members
            `(,@(map code:member->variable (ast:member* o))
              ,@(map type->reply-variable (code:reply-types o))
              ,@(map provides->member (ast:provides-port* o))
              ,@(map requires->member (ast:requires-no-injected-port* o))
              ,@(map injected->member (ast:injected-port* o))
              ,@(if (is-a? o <foreign>) '()
                    (map port->out-binding (ast:provides-port* o)))))))
         (component
          (struct
           (inherit component)
           (methods
            `(,(constructor
                (struct component)
                (formals (list (formal (type "dzn.Locator") (name "locator"))
                               (formal (type "String") (name "name"))
                               (formal (type "dzn.Meta") (name "parent")
                                       (default "null"))))
                (statement
                 (compound*
                  `(,@(append-map provides->assignments
                                  (ast:provides-port* o))
                    ,@(append-map requires->assignments
                                  (ast:requires-no-injected-port* o))
                    ,@(append-map injected->assignments
                                  (ast:injected-port* o))
                    ,@(cs:dzn-meta-assignments o)
                    ,@(if (is-a? o <foreign>) '()
                          `(,(assign* (member* "dzn_runtime.states[this].flushes")
                                      "true")))
                    ,@(map trigger->event-slot (ast:in-triggers o))))))
              ,@(if (not (is-a? o <foreign>)) '()
                    (list
                     (destructor (struct component)
                                 (type "virtual")
                                 (statement (compound*)))))
              ,(method
                (struct component) (type "void") (name "dzn_check_bindings")
                (statement
                 (compound*
                  (call (name "dzn.RuntimeHelper.check_bindings")
                        (arguments (list (member* "dzn_meta")))))))
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
        (variable
         (type (code:type-name (.type port)))
         (name (.name port))
         (expression (and (not injected?)
                          (port->expression port))))))
    (define (injected-instance? instance)
      (member instance injected-instances ast:eq?))
    (define (instance->expression instance)
      (let ((instance-name (.name instance))
            (type (code:type-name (.type instance))))
        (call (name (string-append "new " type))
              (arguments
               (list "locator"
                     (simple-format #f "~s" instance-name)
                     "this.dzn_meta")))))
    (define (instance->member instance)
      (let ((local? (and injected?
                         (not (injected-instance? instance))))
            (instance-name (.name instance)))
        (variable
         (type (code:type-name (.type instance)))
         (name instance-name)
         (expression (and (or (not injected?)
                              (member instance injected-instances ast:eq?))
                          (instance->expression instance))))))
    (define (instance->assignment instance)
      (let ((name (.name instance)))
        (assign* (member* name)
                 (instance->expression instance))))
    (define (port->assignment port)
      (let ((name (.name port)))
        (assign* (member* name)
                 (port->expression port))))
    (define (injected->assignment instance)
      (let* ((name (.name instance))
             (port-name (.port.name instance))
             (meta (string-append name ".dzn_meta."))
             (name-string (simple-format #f "~s" name))
             (meta (simple-format #f "~a.~a.meta." name port-name)))
        (assign* (string-append meta "require.name")
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
            (struct
             (name (dzn:model-name o))
             (parents '("dzn.SystemComponent"))
             ;; C&P from component
             (inits (list (parent-init
                           (name "base")
                           (arguments '("locator" "name" "parent")))))
             (members
              `(,@(map instance->member injected-instances)
                ,@(map instance->member instances)
                ,@(map port->member (ast:provides-port* o))
                ,@(map port->member (ast:requires-port* o))))))
           (system
            (struct
             (inherit system)
             (methods
              (list
               (constructor
                (struct system)
                ;; C&P from component
                (formals (list (formal (type "dzn.Locator") (name "locator"))
                               (formal (type "String") (name "name"))
                               (formal (type "dzn.Meta") (name "parent")
                                       (default "null"))))
                (statement
                 (compound*
                  `(,@(if (not injected?) '()
                          `(,(assign*
                              "locator"
                              (string-append
                               "locator.clone ()"
                               (string-join
                                (map binding->injected-initializer
                                     injected-bindings)
                                ".")))))
                    ,@(map injected->assignment injected-instances)
                    ,@(if (not injected?) '()
                          `(,@(map instance->assignment instances)
                            ,@(map port->assignment (ast:provides-port* o))
                            ,@(map port->assignment (ast:requires-port* o))))
                    ,@(cs:dzn-meta-assignments o)
                    ,@(map cs:binding->connect bindings)))))
               ;; C&P from component
               (method
                (struct system) (type "void") (name "dzn_check_bindings")
                (statement
                 (compound*
                  (call (name "dzn.RuntimeHelper.check_bindings")
                        (arguments (list (member* "dzn_meta"))))))))))))
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
        (call (name (string-append "new " type-name)))))
    (define (port->member port)
      (let ((other-end (ast:other-end-point port)))
        (variable
         (type (code:type-name (.type port)))
         (name (.name port))
         (expression (and (not injected?)
                          (port->expression port))))))
    (define (injected-instance? instance)
      (member instance injected-instances ast:eq?))
    (define (instance->expression instance)
      (let ((instance-name (.name instance))
            (type (code:type-name (.type instance))))
        (call (name (string-append "new " type))
              (arguments
               (list "locator"
                     (simple-format #f "~s" instance-name)
                     "this.dzn_meta")))))
    (define (instance->member instance)
      (let ((local? (and injected?
                         (not (injected-instance? instance))))
            (instance-name (.name instance)))
        (variable
         (type (code:type-name (.type instance)))
         (name instance-name)
         (expression (and (or (not injected?)
                              (member instance injected-instances ast:eq?))
                          (instance->expression instance))))))
    (define (instance->assignment instance)
      (let ((name (.name instance)))
        (assign* (member* name)
                 (instance->expression instance))))
    (define (provides->assignments port)
      (let* ((name (.name port))
             (meta (string-append name ".meta.provide"))
             (name-string (simple-format #f "~s" name)))
        `(,@(if (not injected?) '()
                `(,(assign* (member* name)
                            (port->expression port))))
          ,(assign* (member* (string-append meta ".meta")) (member* "dzn_meta"))
          ,(assign* (member* (string-append meta ".name")) name-string)
          ,(assign* (member* (string-append meta ".component")) "this")
          ,(assign* (member* (string-append meta ".port")) (member* name)))))
    (define (requires->assignments port)
      (let* ((name (.name port))
             (meta (string-append name ".meta.require"))
             (name-string (simple-format #f "~s" name)))
        `(,@(if (not injected?) '()
                `(,(assign* (member* name)
                            (port->expression port))))
          ,(assign* (member* (string-append meta ".meta")) (member* "dzn_meta"))
          ,(assign* (member* (string-append meta ".name")) name-string)
          ,(assign* (member* (string-append meta ".component")) "this")
          ,(assign* (member* (string-append meta ".port")) (member* name)))))
    (define (injected->assignment instance)
      (let* ((name (.name instance))
             (port-name (.port.name instance))
             (meta (string-append name ".dzn_meta."))
             (name-string (simple-format #f "~s" name))
             (meta (simple-format #f "~a.~a.meta." name port-name)))
        (assign* (string-append meta "require.name")
                 name-string)))
    (define (provides->init port)
      (let ((other-end (ast:other-end-point port)))
        (assign*
         (string-append (.instance.name other-end)
                        "." (.port.name other-end)
                        ".meta.require.name")
         (simple-format #f "~s" (.name port)))))
    (define (requires->init port)
      (let ((other-end (ast:other-end-point port)))
        (assign*
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
             (call-slot
              (call (name
                     (string-append ;;; XXX FIXME code:foo-name
                      (.instance.name other-end)
                      "."
                      (.port.name other-end)
                      "."
                      (code:event-name event)))
                    (arguments arguments)))
             (call-pump
              (call
               (name (if (ast:in? event) "this.dzn_pump.shell"
                         "this.dzn_pump.execute"))
               (arguments
                (list
                 (function
                  (statement
                   (compound*
                    (if (not typed?) call-slot
                        (return* call-slot))))))))))
        (assign*
         (code:event-name trigger)
         (function
          (formals formals)
          (statement
           (compound*
            ;; FIXME: This is ridiculous
            `(,@(map cs:formal->temp out-formals)
              ,(cond ((not typed?)
                      call-pump)
                     ((pair? out-formals)
                      (let ((type (code:type-name type)))
                        (variable (type type) (name "dzn_return")
                                  (expression call-pump))))
                     (else
                      (return* call-pump)))
              ,@(map cs:temp->formal out-formals)
              ,@(if (or (not typed?) (null? out-formals)) '()
                    `(,(return* "dzn_return"))))))))))
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
             (call (call (name (code:event-name trigger))
                         (arguments arguments))))
        (assign*
         (string-append ;;; XXX FIXME code:foo-name
          (.instance.name other-end)
          "."
          (.port.name other-end)
          "."
          (code:event-name event))
         (function
          (formals formals)
          (statement
           (if (and (not typed?) (null? out-formals)) call
               (compound*
                ;; FIXME: This is ridiculous
                `(,@(map cs:formal->temp out-formals)
                  ,(cond ((not typed?)
                          call)
                         ((pair? out-formals)
                          (let ((type (code:type-name type)))
                            (variable (type type) (name "dzn_return")
                                      (expression call))))
                         (else
                          (return* call)))
                  ,@(map cs:temp->formal out-formals)
                  ,@(if (or (not typed?) (null? out-formals)) '()
                        `(,(return* "dzn_return")))))))))))
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
            (struct
             (name (dzn:model-name o))
             (parents '("dzn.SystemComponent" "System.IDisposable"))
             ;; C&P from component
             (inits (list (parent-init
                           (name "base")
                           (arguments '("locator" "name" "parent")))))
             (members
              `(,@(map instance->member injected-instances)
                ,@(map instance->member instances)
                ,@(map port->member (ast:provides-port* o))
                ,@(map port->member (ast:requires-port* o))
                ,(variable
                  (type "dzn.pump")
                  (name "dzn_pump")
                  (expression (call (name "new dzn.pump"))))))))
           (shell
            (struct
             (inherit shell)
             (methods
              (list
               (constructor
                (struct shell)
                ;; C&P from component
                (formals (list (formal (type "dzn.Locator") (name "locator"))
                               (formal (type "String") (name "name"))
                               (formal (type "dzn.Meta") (name "parent")
                                       (default "null"))))
                (statement
                 (compound*
                  `(,(call (name "locator.set")
                           (arguments '("this.dzn_pump")))
                    ,@(if (not injected?) '()
                          `(,(assign*
                              "locator"
                              (string-append
                               "locator.clone ()"
                               (string-join
                                (map binding->injected-initializer
                                     injected-bindings)
                                ".")))))
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
               (method
                (struct shell) (type "virtual void") (name "Dispose")
                (formals (list (formal (type "bool") (name "gc"))))
                (statement
                 (compound*
                  (if* "gc"
                       (call (name "this.dzn_pump.Dispose"))))))
               (method
                (struct shell) (type "void") (name "Dispose")
                (statement
                 (compound*
                  (call (name "Dispose") (arguments '("true")))
                  (call (name "GC.SuppressFinalize") (arguments '("this"))))))
               ;; C&P from component
               (method
                (struct shell) (type "void") (name "dzn_check_bindings")
                (statement
                 (compound*
                  (call (name "dzn.RuntimeHelper.check_bindings")
                        (arguments (list (member* "dzn_meta"))))))))))))
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
           (call (name (string-append container
                                      "."
                                      "string_to_value<"
                                      type-name
                                      ">"))
                 (arguments (list "tmp"))))))
  (define (formal->assign-default formal)
    (let ((type (code:type-name formal)))
      (assign* (.name formal)
               (call (name "default")
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
            (function
             (formals formals)
             (statement
              (compound*
               `(,(call (name "dzn.Runtime.trace")
                        (arguments
                         (list meta
                               (simple-format #f "~s" event))))
                 ,(call (name "c.match")
                        (arguments
                         (list (simple-format #f "~s" port-event))))
                 ,(call (name "dzn.pump.port_block")
                        (arguments
                         (list "c.dzn_locator" "c.nullptr"
                               (simple-format #f "c.system.~a" port))))
                 ,(variable (type "string")
                            (name "tmp")
                            (expression
                             (call (name "c.trail_expect"))))
                 ,(assign (variable "tmp")
                          (expression "tmp.Split ('.')[1]"))
                 ,(call (name "dzn.Runtime.trace_out")
                        (arguments
                         (list meta "tmp")))
                 ,@(map formal->assign-default out-formals)
                 ,(return* (return-expression trigger))))))))
      (assign (variable (string-append "c.system." (code:event-name trigger)))
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
           (call-out
            (call
             (name "c.dzn_runtime.call_out")
             (arguments
              `("c"
                ,(function
                  (statement
                   (compound*
                    (if* "c.flush"
                         (call
                          (name "c.dzn_runtime.queue (c).Enqueue")
                          (arguments
                           (list
                            (function
                             (statement
                              (compound*
                               (if* (equal* "c.dzn_runtime.queue (c).Count" 0)
                                    (compound*
                                     (call (name "Console.Error.WriteLine")
                                           (arguments (list flush-string)))
                                     (call
                                      (name "c.match")
                                      (arguments
                                       (list flush-string)))))))))))))))
                ,system-port
                ,(simple-format #f "~s" event))))))
      (assign (variable (string-append "c.system." (code:event-name trigger)))
              (expression
               (function
                (formals formals)
                (statement
                 (compound*
                  (call (name "c.match")
                        (arguments
                         (list (simple-format #f "~s" port-event))))
                  (if (not (ast:typed? trigger)) call-out
                      (return* call-out)))))))))
  (function
   (type "static void")
   (name "connect_ports")
   (formals (list (formal (type container) (name "c"))))
   (statement
    (compound*
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
       (assign (variable (simple-format #f "~a.component" meta))
               (expression "c"))
       (assign (variable (simple-format #f "~a.meta" meta))
               (expression "c.dzn_meta"))
       (assign (variable (simple-format #f "~a.name" meta))
               (expression (simple-format #f "~s" port-name))))))
  (define (requires->init port)
    (let* ((port-name (.name port))
           (system-port (simple-format #f "c.system.~a" port-name))
           (meta (simple-format #f "~a.meta.provide" system-port)))
      (list
       (assign (variable (simple-format #f "~a.component" meta))
               (expression "c"))
       (assign (variable (simple-format #f "~a.meta" meta))
               (expression "c.dzn_meta"))
       (assign (variable (simple-format #f "~a.name" meta))
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
           (port-return-string (simple-format #f "~s" port-return)))
      (define (formal->variable formal)
        (variable (type "int")
                  (name (code:number-argument formal))
                  (expression (.name formal))))
      (call
       (name "lookup.Add")
       (arguments
        (list
         port-event-string
         (function
          (statement
           (compound*
            `(
              ,(call (name "c.match")
                     (arguments (list port-event-string)))
              ,@(map formal->variable out-formals)
              ,(call (name (string-append "c.system." (code:event-name trigger)))
                     (arguments arguments))
              ,(call (name "c.match")
                     (arguments (list port-return-string))))))))))))
  (define (typed-provides-in->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (type (ast:type trigger))
           (event-type (code:type-name type))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (port-return (simple-format #f "~a.return" port))
           (port-return-string (simple-format #f "~s" port-return))
           (port-prefix (simple-format #f "~a." port))
           (event-slot (string-append "c.system." (code:event-name trigger)))
           (formals (code:formal* trigger))
           (invoke (code->string (call (name event-slot)
                                       (arguments (iota (length formals)))))))
      (call
       (name "lookup.Add")
       (arguments
        (list
         port-event-string
         (function
          (statement
           (compound*
            (call (name "c.match")
                  (arguments (list port-event-string)))
            (variable (type "string")
                      (name "tmp")
                      (expression
                       (simple-format
                        #f
                        "~s + c.to_string<~a> (~a)" port-prefix event-type invoke)))
            (call (name "c.match")
                  (arguments (list "tmp")))))))))))
  (define (void-requires-in->init trigger)
    (let* ((port (.port.name trigger))
           (port-return (simple-format #f "~a.return" port))
           (port-return-string (simple-format #f "~s" port-return))
           (port-prefix (simple-format #f "~a." port))
           (system-port (simple-format #f "c.system.~a" port)))
      (call
       (name "lookup.Add")
       (arguments
        (list
         port-return-string
         (function
          (statement
           (compound*
            (call (name "dzn.pump.port_release")
                  (arguments
                   (list "c.dzn_locator"
                         "c.system"
                         system-port)))))))))))
  (define (typed-in->init port-pair) ;; FIXME: get rid of port-pair?
    (let* ((port (.port port-pair))
           (other (.other port-pair))
           (port-other (simple-format #f "~a.~a" port other)))
      (call
       (name "lookup.Add")
       (arguments
        (list
         (simple-format #f "~s" port-other)
         (function
          (statement
           (compound*
            (call (name "dzn.pump.port_release")
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
      (call
       (name "lookup.Add")
       (arguments
        (list
         port-event-string
         (function
          (statement
           (compound*
            (call (name "c.match")
                  (arguments (list port-event-string)))
            (call (name (string-append "c.system." (code:event-name trigger)))
                  (arguments (iota (length formals))))))))))))
  (define (flush->init port)
    (let* ((port (.name port))
           (flush (simple-format #f "~a.<flush>" port))
           (flush-string (simple-format #f "~s" flush)))
      (call
       (name "lookup.Add")
       (arguments
        (list
         flush-string
         (function
          (statement
           (compound*
            (call (name "c.match")
                  (arguments (list flush-string)))
            (call (name "System.Console.Error.WriteLine")
                  (arguments (list flush-string)))
            (call (name "c.dzn_runtime.flush")
                  (arguments (list "c")))))))))))
  (let ((map-type "Dictionary<String, Action>"))
    (function
     (type (string-append "static " map-type))
     (name "event_map")
     (formals (list (formal (type container) (name "c"))))
     (statement
      (compound*
       `(,@(append-map provides->init (ast:provides-port* o))
         ,@(append-map requires->init (ast:requires-port* o))
         ,(variable (type map-type) (name "lookup")
                    (expression (call (name (string-append "new " type)))))
         ,(call (name "lookup.Add")
                (arguments
                 (list "\"illegal\""
                       (function
                        (statement
                         (compound*
                          (call (name "Console.Error.WriteLine")
                                (arguments '("\"illegal\"")))
                          (call (name "Environment.Exit")
                                (arguments '(0)))))))))
         ,(call (name "lookup.Add")
                (arguments
                 (list "\"error\""
                       (function
                        (statement
                         (compound*
                          (call (name "Console.Error.WriteLine")
                                (arguments '("\"sut.error -> sut.error\"")))
                          (call (name "Environment.Exit")
                                (arguments '(0)))))))))
         ,@(map void-provides-in->init (ast:provides-in-void-triggers o))
         ,@(map typed-provides-in->init (ast:provides-in-typed-triggers o))
         ,@(map void-requires-in->init (code:requires-in-void-returns o))
         ,@(map typed-in->init (code:return-values o))
         ,@(map out->init (ast:requires-out-triggers o))
         ,@(map flush->init (ast:requires-port* o))
         ,(return* "lookup")))))))

(define-method (main-getopt)
  (function
   (type "static bool")
   (name "getopt")
   (formals (list (formal (type "String[]") (name "args"))
                  (formal (type "String") (name "option"))))
   (statement
    (compound*
     (return*
      (call (name "Array.Exists")
            (arguments (list "args"
                             (function (formals '("s"))
                                       (statement (equal* "s" "option")))))))))))

(define-method (main (o <component-model>) container)
  (function
   (type "static void")
   (name "Main")
   (formals (list (formal (type "String[]") (name "argv"))))
   (statement
    (compound*
     (let ((option (simple-format #f "~s" "--flush")))
       (variable (type "bool") (name "flush")
                 (expression (call (name "getopt")
                                   (arguments (list "argv" option))))))
     (let ((call-rdbuf (call (name "new TextWriterTraceListener")
                             (arguments '("Console.Error"))))
           (option (simple-format #f "~s" "--debug")))
       (if* (call (name "getopt") (arguments (list "argv" option)))
            (compound*
             (call (name "Debug.Listeners.Add")
                   (arguments (list call-rdbuf))
                   ;; (arguments (call (name "new TextWriterTraceListener")
                   ;; (arguments '("Console.Error"))))
                   )
             (assign* "Debug.AutoFlush" "true"))))
     (let ((type-name (code:type-name o)))
       (using
        (variables
         (list
          (variable
           (type container)
           (name "c")
           (expression
            (call (name (string-append "new " container))
                  (arguments
                   (list
                    (function
                     (formals '("locator" "name"))
                     (statement
                      (compound*
                       (return*
                        (call
                         (name (string-append "new " type-name))
                         (arguments formals))))))
                    "flush")))))))
        (statement
         (compound*
          (call (name "connect_ports") (arguments '("c")))
          (call (name "c.run") (arguments '("event_map (c)")))))))))))

(define-method (main-struct (o <component-model>))
  (let* ((type-name (code:type-name o))
         (container (string-append "dzn.container< " type-name ">"))
         (struct
          (struct (name "main")
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
         (scmcode (scmcode
                   (statements
                    `(,(code:generated-comment o)
                      ,@(if (not comment) '()
                            (list (comment* comment)))
                      ,(cpp-using* "System")
                      ,(cpp-using* "System.Collections.Generic")
                      ,@(root->statements o)
                      ,@(append-map interface->statements models)
                      ,(code:version-comment))))))
    ((@@ (scmackerel cs) set-record-printers!))
    (display scmcode)))

(define-method (print-main-ast (o <component-model>))
  (let ((scmcode (scmcode
                  (statements
                   `(,(code:generated-comment o)
                     ,(cpp-using* "System")
                     ,(cpp-using* "System.Collections.Generic")
                     ,(cpp-using* "System.Diagnostics")
                     ,(main-struct o)
                     ,(code:version-comment))))))
    ((@@ (scmackerel cs) set-record-printers!))
    (display scmcode)))
