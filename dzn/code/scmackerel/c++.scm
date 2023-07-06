;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn code scmackerel c++)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)
  #:use-module (scmackerel code)
  #:use-module (scmackerel header)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code goops)
  #:use-module (dzn code scmackerel code)
  #:use-module (dzn code language dzn)
  #:use-module (dzn code language c++)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:export (c++:call-check-bindings
            c++:event-method
            c++:event-return-method
            c++:port-update-method
            c++:statement*
            print-code-ast
            print-header-ast
            print-main-ast)
  #:re-export (code->string))

;;;
;;; Helpers.
;;;
(define-method (c++:include-guard (o <ast>) code)
  (let* ((name (ast:full-name o))
         (name (if (not (is-a? o <foreign>)) name
                   (cons "SKEL" name)))
         (name (if (is-a? o <enum>) (cons "ENUM" name)
                   (append name '("hh"))))
         (name (map string-upcase name))
         (guard (string-join name "_")))
    `(,(cpp-ifndef* guard)
      ,(cpp-define* guard)
      ,@(match code
          ((code ...) code)
          (code (list code)))
      ,(cpp-endif* guard))))

(define-method (c++:enum->to-string (o <enum>))
  (let ((enum-type (code:type-name o)))
    (define (field->switch-case field)
      (let ((str (simple-format #f "~a:~a" (ast:name o) field)))
        (switch-case
         (expression (simple-format #f "~a::~a" enum-type field))
         (statement (return* (simple-format #f "~s" str))))))
    (let ((string-conversion
           (list
            (function
             (name "to_cstr")
             (type "char const*")
             (formals (list (formal (type enum-type)
                                    (name "v"))))
             (statement
              (compound*
               (switch (expression "v")
                       (cases (map field->switch-case (ast:field* o))))
               (return* (simple-format #f "~s" "")))))
            (function
             (name "to_string")
             (type "std::string")
             (formals (list (formal (type enum-type)
                                    (name "v"))))
             (statement
              (compound*
               (return* (call (name "to_cstr") (arguments '("v")))))))))
          (ostream-operator
           (function
            (name "operator <<")
            (inline? #t)
            (type "template <typename Char, typename Traits>
std::basic_ostream<Char, Traits> &")
            (formals (list (formal (type "std::basic_ostream<Char, Traits>&")
                                   (name "os"))
                           (formal (type enum-type)
                                   (name "v"))))
            (statement
             (compound*
              (return* (statement* "os << dzn::to_cstr (v)")))))))
      `(,@(code:->namespace '("dzn") string-conversion)
        ,@(code:->namespace o ostream-operator)))))

(define-method (c++:enum->to-enum (o <enum>))
  (let ((enum-name (string-join (ast:full-name o) "_"))
        (enum-type (code:type-name o))
        (short-name (ast:name o)))
    (define (field->map-element field)
      (let ((str (simple-format #f "~a:~a" short-name field)))
        (simple-format #f "{~s, ~a::~a}" str enum-type field)))
    (let* ((map-elements (map field->map-element (ast:field* o)))
           (to-enum
            (function
             (name (simple-format #f "to_~a" enum-name))
             (formals (list (formal (type "std::string")
                                    (name "s"))))
             (type enum-type)
             (statement
              (compound*
               (variable (type
                          (simple-format #f "static std::map<std::string, ~a>"
                                         enum-type))
                         (name "m")
                         (expression (string-append
                                      "{\n"
                                      (string-join map-elements ",\n")
                                      "}")))
               (return* "m.at (s)"))))))
      (code:->namespace '("dzn") to-enum))))

(define-method (c++:enum->statements (o <enum>))
  `(,@(c++:enum->to-string o)
    ,@(c++:enum->to-enum o)))

(define-method (c++:enum->header-statements (o <enum>))
  (let* ((struct (code:enum->enum-struct o))
         (statements
          `(,@(code:->namespace o struct)
            ,@(c++:enum->statements o))))
    (c++:include-guard o statements)))

(define-method (c++:->formal (o <formal>))
  (let* ((type (code:type-name o))
         (type (if (ast:in? o) type
                   (string-append type "&"))))
    (formal (type type)
            (name (.name o)))))

(define-method (c++:file-name->include (o <string>))
  (cpp-include* (string-append o ".hh")))

(define-method (c++:file-name->include (o <file-name>))
  (c++:file-name->include (.name o)))

(define-method (c++:file-name->include (o <import>))
  (c++:file-name->include (code:file-name o)))

;;; XXX FIXME template system renmants
(define-method (c++:file-name->include (o <instance>))
  (cpp-include* (string-append (code:file-name->string o) ".hh")))

(define-method (c++:statement* (o <compound>))
  (ast:statement* o))

;; XXX FIXME: introduce <block> statement instead of
;; <blocking-compound>, like VM?
(define-method (c++:statement* (o <blocking-compound>))
  (let* ((port-name (.port.name o))
         (block (call (name "port_block")
                      (arguments
                       (list "dzn_locator"
                             "this"
                             (string-append
                              "&"
                              (%member-prefix)
                              port-name))))))
    `(,@(ast:statement* o)
      ,block)))

(define (c++:call-check-bindings port)
  (function
   (captures '("this"))
   (statement
    (compound*
     (call (name (string-append port ".dzn_check_bindings"))
           (arguments '()))))))

(define-method (c++:event-method o (event <string>)) ; (o <trigger> or <action>)
  (let ((event-string (simple-format #f "~s" event)))
    (call-method
     (name (code:shared-dzn-event-method o))
     (arguments (list event-string)))))

(define-method (c++:event-method o event) ; (o <trigger> or <action>) RECORD
  (call-method
   (name (code:shared-dzn-event-method o))
   (arguments (list event))))

(define-method (c++:event-method o)     ; (o <trigger> or <action>)
  (c++:event-method o (.event.name o)))

(define-method (c++:event-return-method o variable)
  (let ((typed? (ast:typed? o))
        (return-name "return"))
    (c++:event-method o (if (not typed?) return-name
                            (call (name "dzn::to_string")
                                  (arguments (list variable)))))))

(define-method (c++:event-return-method (o <trigger>))
  (if (ast:typed? o) (c++:event-return-method o "dzn_value")
      (c++:event-return-method o "return")))

(define-method (c++:port-update-method o); (o <trigger> or <action>)
  (call-method
   (name (code:shared-update-method o))))


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
             (as (c++:statement* statement) <pair>))
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
  (let ((statements (c++:statement* o)))
    (compound* (map ast->code statements)))) ;;; XXX new compound*

(define-method (ast->code (o <action>))
  (let* ((event (.event o))
         (formals (code:formal* (.event o)))
         (event-name (.event.name o))
         (action-name (code:event-name o))
         (arguments (code:argument* o))
         (arguments (map ast->expression arguments)))
    (call (name (simple-format #f "dzn::call_~a" (.direction event)))
          (arguments
           `("this"
             ,(.port.name o)
             ,(simple-format #f "~s" event-name)
             ,(function
               (captures '("&"))
               (statement
                (compound*
                 (return*
                  (call (name action-name)
                        (arguments arguments)))))))))))

(define-method (ast->code (o <assign>))
  (let* ((variable (.variable o))
         (var (ast->expression variable))
         (expression (.expression o))
         (action? (is-a? expression <action>)))
    (if (not action?) (assign* var (ast->expression expression))
        (assign* var (ast->code expression)))))

(define-method (ast->code (o <defer>))
  (define (variable->defer-variable o)
    (variable
     (type (code:type-name (ast:type o)))
     (name (code:capture-name o))
     (expression (code:member-name o))))
  (define (variable->equality o)
    (equal* (ast->expression o)
            (code:capture-name o)))
  (let* ((variables (ast:defer-variable* o))
         (locals (code:capture-local o))
         (equality (code:defer-equality* o))
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
             ,(call (name "dzn::defer")
                    (arguments
                     (list "this"
                           (function
                            (captures
                             (cons* "this"
                                    (map code:capture-name variables)))
                            (statement
                             (compound*
                              (return* condition))))
                           (function
                            (captures
                             (cons* "&" (map .name locals)))
                            (statement statement)))))))))
    statement))

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
           ,(if* out-binding (call (name out-binding)))
           ,(assign* out-binding "nullptr")
           ,@(if (not (code:port-release? o)) '()
                 `(,(call (name "dzn::port_release")
                          (arguments
                           (list "dzn_locator"
                                 "this"
                                 (string-append
                                  "&"
                                  (%member-prefix)
                                  (.port.name o))))))))))))))

(define %illegal "locator.get<dzn::illegal_handler> ().handle (LOCATION)")

(define-method (ast->code (o <illegal>))
  (statement* (string-append "this->dzn_" %illegal)))

(define-method (ast->code (o <out-bindings>))
  (define (formal->assign formal)
    (assign* (.name formal)
             (member* (%member-prefix) (.variable.name formal))))
  (let ((formals (ast:formal* o)))
    (if (null? formals) (statement*)
        (assign*
         (member* (%member-prefix) (code:out-binding (.port o)))
         (function
          (captures '("&"))
          (statement
           (compound*
            (map formal->assign formals))))))))

;; FIXME: C&P from code.scm, to override makreel.scm override
(define-method (ast->expression (o <shared-field-test>))
  (let* ((variable (.variable o))
         (type (.type variable))
         (type-name (make <scope.name> #:ids (ast:full-name type)))
         (enum-literal (make <enum-literal>
                         #:type.name type-name
                         #:field (.field o)))
         (enum-literal (clone enum-literal #:parent o))
         (name (.name variable))
         (port-name (.port.name o))
         (var (make <shared-var> #:name name #:port.name port-name))
         (expression (make <equal>
                       #:left var
                       #:right enum-literal)))
    (ast->expression expression)))

(define-method (ast->expression (o <shared-var>))
  (let ((lst (ast:full-name o)))
    (string-join lst (%name-infix))))

(define-method (ast->expression (o <shared-variable>))
  (let* ((name (ast:full-name o))
         (name (string-join name (%name-infix))))
    (if (ast:member? o) (member* (%member-prefix) name)
        name)))
;; END FIXME


;;;
;;; Root.
;;;
(define-method (root->header-statements (o <root>))
  (let ((imports (ast:unique-import* o))
        (enums (code:enum* o)))
    (append
     (map c++:file-name->include imports)
     (map .value (ast:data* o))
     (append-map c++:enum->header-statements enums))))

(define-method (root->statements (o <root>))
  (let ((enums (code:enum* o)))
    (append-map c++:enum->statements enums)))


;;;
;;; Interface.
;;;
(define-method (interface->statements-unmemoized (o <interface>))
  (define (event->slot event)
    (let ((type (code:type-name (ast:type event)))
          (formals (code:formal* event)))
      (variable
       (type (string-append "std::function< "
                            (code->string
                             (call (name type)
                                   (arguments (map c++:->formal formals))))
                            ">"))
       (name (.name event)))))
  (define (event->check-binding event)
    (let ((event-name (code:event-name event)))
      (if* (not* (member* event-name))
           (statement*
            (format #f "throw dzn::binding_error (this->dzn_meta, ~s)"
                    event-name)))))
  (let* ((public-enums (code:public-enum* o))
         (enums (append public-enums (code:enum* o)))
         (interface
          (struct
           (name (dzn:model-name o))
           (types (map code:enum->enum-struct enums))
           (members
            `(,(variable (type "dzn::port::meta") (name "dzn_meta")
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
                         (name "out"))
              ,(variable (type "bool") (name "dzn_external") (expression "false"))
              ,(variable (type "std::vector<char const*>") (name "dzn_prefix") (expression ""))
              ,(variable (type "int") (name "dzn_state") (expression ""))
              ,(variable (type (string-append name "*")) (name "dzn_peer") (expression ""))
              ,(variable (type "bool") (name "dzn_busy") (expression ""))
              ,@(map code:member->variable (ast:member* o))))))
         (interface& (string-append
                      (string-join (cons "" (ast:full-name o)) "::")
                      "&")))

    (define (ast->assign ast)
      (let* ((expression (.expression ast))
             (value (code:shared-value expression)))
        (assign* (.variable.name ast) value)))
    (define (state->if shared else)
      (let* ((expression (equal* "dzn_state" (.state shared)))
             (assignments (ast:statement* (.assign shared)))
             (assignments (map ast->assign assignments)))
        (if* expression
             (match assignments
               ((assign) assign)
               ((assigns ...) (compound* assigns)))
             else)))

    (define (value->init value)
      (simple-format #f "~s" (.value value)))

    (define (event->switch-case transition interface-shared)
      (let* ((prefix (.prefix transition))
             (prefix (ast:statement* prefix))
             (initializer-list (code->string
                                (generalized-initializer-list*
                                 (map value->init prefix))))
             (state (simple-format #f "~a" (.to transition)))
             (assignments (and=>
                           (find
                            (compose (cute eq? (.to transition) <>)
                                     .state)
                            interface-shared)
                           (compose ast:statement* .assign)))
             (assignments (map ast->assign (or assignments '()))))
        (switch-case
         (expression
          (call (name "dzn::hash")
                (arguments
                 `(,initializer-list
                   ,(.from transition)))))
         (statement
          (statements*
           (if (.skip transition) `(,(return*))
               `(,(assign* "dzn_state" state)
                 ,@assignments
                 ,(break*))))))))

    (define (synchronize->member variable)
      (assign*
       (string-append "this->dzn_peer->" (.name variable))
       (string-append "this->" (.name variable))))

    (define (remove-non-matching-node transition event-name)
      (let ((prefix (reverse (ast:statement* (.prefix transition)))))
        (let loop ((prefix prefix) (result '()))
          (cond ((null? prefix)
                 result)
                ((equal? (.value (car prefix)) event-name)
                 (loop (cdr prefix) (cons (reverse prefix) result)))
                (else
                 (loop (cdr prefix) result))))))

    (define (event->transitions event)
      (let ((transitions (code:shared event)))
        (cond ((ast:in? event)
               (append
                (append-map
                 (lambda (transition)
                   (let loop ((prefix ((compose reverse ast:statement* .prefix) transition)))
                     (if (= 2 (length prefix)) '()
                         (cons (clone transition
                                      #:prefix (make <compound>
                                                 #:elements (reverse (cdr prefix)))
                                      #:skip #t)
                               (loop (cdr prefix))))))
                 (filter (lambda (transition)
                           (let ((prefix ((compose reverse ast:statement* .prefix) transition)))
                             (< 2 (length prefix))))
                         transitions))
                transitions))
              (else
               (let* ((event-name (.name event))
                      (mismatch (filter (compose not (cute equal? event-name <>)
                                                 .value last ast:statement* .prefix)
                                        transitions))
                      (skip (append-map (cute remove-non-matching-node <> event-name) mismatch))
                      (skip (map (lambda (mismatch skip)
                                   (clone mismatch
                                          #:prefix (make <compound> #:elements skip)
                                          #:skip #t))
                                 mismatch skip))
                      (skip (delete-duplicates
                             skip
                             (lambda (a b)
                               (and (equal? (.from a) (.from b))
                                    (ast:equal? (.prefix a) (.prefix b)))))))
                 (append skip transitions))))))

    (let* ((shared (code:shared-state o))
           (events (ast:event* o))
           (transitions (append-map event->transitions events))
           (transitions (delete-duplicates transitions ast:equal?))
           (interface-shared (reverse (code:shared-state o)))
           (interface
            (struct
             (inherit interface)
             (methods
              `(,(constructor (struct interface)
                              (formals (list (formal (type "dzn::port::meta const&")
                                                     (name "m"))))
                              (statement
                               (compound*
                                (if (= (dzn:debugity) 0) '()
                                    (call (name "debug")
                                          (arguments (list "\"ctor\"")))))))
                ,(destructor (struct interface)
                             (type "virtual")
                             (statement "= default;"))
                ,@(if (= (dzn:debugity) 0) '()
                      `(,(method
                          (struct interface) (type "void") (name "debug")
                          (formals (list (formal (type "std::string&&") (name "label"))))
                          (statement
                           (compound*
                            (variable (type "std::string")
                                      (name "tmp")
                                      (expression
                                       (conditional*
                                        "this->dzn_meta.provide.component"
                                        (call (name "dzn::path")
                                              (arguments '("this->dzn_meta.provide.meta")))
                                        (call (name "dzn::path")
                                              (arguments '("this->dzn_meta.require.meta"))))))
                            (statement* "std::cout << tmp << \".\";")
                            (assign* "tmp"
                                     (conditional*
                                      (call (name "this->dzn_meta.provide.name.size")
                                            (arguments '()))
                                      "this->dzn_meta.provide.name"
                                      "this->dzn_meta.require.name"))
                            (statement* "std::cout << tmp << \" \" << label << \": \" << dzn_state << \" prefix: \"")
                            (call (name "std::copy")
                                  (arguments
                                   (list
                                    (call (name "dzn_prefix.begin")
                                          (arguments '()))
                                    (call (name "dzn_prefix.end")
                                          (arguments '()))
                                    (call (name "std::ostream_iterator<std::string>")
                                          (arguments '("std::cout" "\",\""))))))
                            (statement* "std::cout << std::endl"))))))
                ,(method
                  (struct interface) (type "void") (name "dzn_event")
                  (formals (list (formal (type "char const*") (name "event"))))
                  (statement
                   (compound*
                    `(,(if* "dzn_external" (return*))
                      ,(call (name "dzn_prefix.push_back")
                             (arguments '("event")))
                      ,(call (name "dzn_sync"))
                      ,@(if (= (dzn:debugity) 0) '()
                            `(,(call (name "debug") (arguments '("\"dzn_event\"")))))))))
                ,(method
                  (struct interface) (type "void") (name "dzn_update_state")
                  (formals (list (formal (type "dzn::locator const&")
                                         (name "locator"))))
                  (statement
                   (compound*
                    `(,(if* "dzn_external" (return*))
                      ,@(if (= (dzn:debugity) 0) '()
                            `(,(call (name "debug") (arguments '("\"update_state\"")))))
                      ,(switch
                        (expression
                         (call
                          (name "dzn::hash")
                          (arguments `("dzn_prefix" "dzn_state"))))
                        (cases
                         `(,@(map (cute event->switch-case <>
                                        interface-shared)
                                  transitions)
                           ,(switch-case
                             (label "default")
                             (statement
                              (statement* "locator.get<dzn::illegal_handler> ().handle (LOCATION)"))))))
                      ,(call (name "dzn_prefix.clear"))
                      ,(call (name "dzn_sync"))))))
                ,(method
                  (struct interface) (type "void") (name "dzn_sync")
                  (statement
                   (compound*
                    (if* (and* (not-equal* "this->dzn_peer" "nullptr")
                               (not-equal* "this->dzn_peer" "this"))
                         (compound*
                          `(,@(if (= (dzn:debugity) 0) '()
                                  `(,(call (name "debug") (arguments '("\"sync\"")))))
                            ,(assign* "dzn_peer->dzn_prefix" "this->dzn_prefix")
                            ,(assign* "dzn_peer->dzn_state" "this->dzn_state")
                            ,(assign* "dzn_peer->dzn_busy" "this->dzn_busy")
                            ,@(map (compose synchronize->member) (ast:member* o))))))))
                ,(method
                  (struct interface) (type "void") (name "dzn_check_bindings")
                  (statement
                   (compound*
                    (append
                     (map event->check-binding (ast:in-event* o))
                     (map event->check-binding (ast:out-event* o))))))))))
           (connect
            (function
             (name "connect")
             (type "void")
             (formals (list (formal (type interface&) (name "provided"))
                            (formal (type interface&) (name "required"))))
             (statement
              (compound*
               (assign* "provided.out" "required.out")
               (assign* "required.in" "provided.in")
               (assign* "provided.dzn_meta.require" "required.dzn_meta.require")
               (assign* "required.dzn_meta.provide" "provided.dzn_meta.provide")
               (assign* "provided.dzn_peer" "&required")
               (assign* "required.dzn_peer" "&provided")))))
           (enum-to-string (append-map c++:enum->to-string public-enums))
           (to-enum (append-map c++:enum->to-enum public-enums)))
      `(,@(code:->namespace o interface)
        ,connect
        ,@enum-to-string
        ,@to-enum))))

(define-method (interface->statements (o <interface>))
  ((ast:perfect-funcq interface->statements-unmemoized) o))

(define-method (model->header-statements (o <interface>))
  (c++:include-guard o (interface->statements o)))

(define-method (model->statements (o <interface>))
  (interface->statements o))


;;;
;;; Component.
;;;
(define-method (component-model->statements-unmemoized (o <component-model>))
  (define (provides->member port)
    (variable
     (type (code:type-name (.type port)))
     (name (.name port))
     (expression (simple-format
                  #f "{{~s,&~a,this,&dzn_meta},{\"\",0,0,0}}" name name))))
  (define (requires->member port)
    (variable
     (type (code:type-name (.type port)))
     (name (.name port))
     (expression (simple-format
                  #f
                  "{{\"\",0,0,0},{~s,&~a,this,&dzn_meta}}" name name))))
  (define (requires->external port)
    (assign*
     (simple-format
      #f "~a.dzn_external" (.name port))
     "true"))
  (define (injected->member port)
    (variable
     (type (code:type-name (.type port)))
     (name (.name port))
     (expression (member* (simple-format #f "dzn_locator.get< ~a> ()" type)))))
  (define (port->out-binding port)
    (variable
     (type "std::function<void ()>")
     (name (code:out-binding port))))
  (define (type->reply-variable o)
    (variable
     (type (code:type-name o))
     (name (code:reply-var o))))
  (define (port->injected-require-override port)
    (let* ((type (.type port))
           (type (code:type-name type)))
      (assign* (member* (%member-prefix)
                        (string-append "dzn_locator.get< " type "> ()"))
               (.name port))))
  (define (trigger->event-slot trigger)
    (let* ((port (.port trigger))
           (port-name (.name port))
           (event (.event trigger))
           (event-name (.name event))
           (event-name-string (simple-format #f "~s" event-name))
           (formals (code:formal* trigger))
           (arguments (map .name formals))
           (in-formals (filter ast:in? formals))
           (in-arguments (map .name in-formals))
           (formals (map c++:->formal formals))
           (out-binding (code:out-binding port))
           (this-out-binding (code:member out-binding))
           (type (ast:type trigger))
           (type (code:type-name type))
           (typed? (ast:typed? trigger))
           (reply-var (and typed?
                           (member* (code:reply-var (ast:type trigger)))))
           (call-slot (call-method
                       (name (code:event-slot-name trigger))
                       (arguments arguments)))
           (call-in/out
            (call
             (name (string-append "dzn::wrap_" (code:direction event)))
             (arguments
              `("this"
                ,(member* port-name)
                ,(function
                  (captures (cons* "&" "this" in-arguments))
                  (statement
                   (compound*
                    `(,@(map port->injected-require-override
                             (ast:injected-port* o))
                      ,(if (or (not typed?) (not (is-a? o <foreign>))) call-slot
                           (assign* reply-var call-slot))
                      ,@(if
                         (ast:out? event) '()
                         `(,@(if
                              (is-a? o <foreign>) '()
                              `(,(call
                                  (name "this->dzn_runtime.flush")
                                  (arguments
                                   (list
                                    "this"
                                    (call (name "dzn::coroutine_id")
                                          (arguments '("this->dzn_locator"))))))
                                ,(if* out-binding (call (name out-binding)))
                                ,(assign* out-binding "nullptr")))
                           ,(return (expression reply-var))))))))
                ,event-name-string)))))
      (assign*
       (code:event-name trigger)
       (function
        (captures '("this"))
        (formals formals)
        (statement
         (compound*
          (return* call-in/out)))))))
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
           (type (ast:type trigger)))
      (method (struct component)
              (type (if (not (is-a? o <foreign>)) "void"
                        (string-append "virtual " (code:type-name type))))
              (name (code:event-slot-name trigger))
              (formals (map c++:->formal formals))
              (statement statement))))
  (define (function->method component function)
    (let* ((type (code:type-name (ast:type function)))
           (name (.name function))
           (formals (code:formal* function))
           (statement (.statement function))
           (statement (ast->code statement)))
      (method (struct component)
              (type type)
              (name name)
              (formals (map c++:->formal formals))
              (statement statement))))
  (define (injected->assignments port)
    (let* ((name (.name port))
           (meta (string-append name ".dzn_meta.require"))
           (name-string (simple-format #f "~s" name)))
      `(,(assign* (member* (string-append meta ".meta")) "&dzn_meta")
        ,(assign* (member* (string-append meta ".name")) name-string)
        ,(assign* (member* (string-append meta ".component")) "this"))))
  (define (requires->assignment ports)
    (assign* (member* "dzn_meta.require")
             (generalized-initializer-list*
              (map (compose
                    (cute string-append "&" <> ".dzn_meta")
                    .name)
                   ports))))
  (let* ((enums (filter (is? <enum>) (code:enum* o)))
         (ports (ast:port* o))
         (check-bindings-list
          (map (compose code->string c++:call-check-bindings .name) ports))
         (component
          (struct
           (name (dzn:model-name o))
           (parents '("public dzn::component"))
           (types (map code:enum->enum-struct enums))
           (members
            `(,(variable
                (type "dzn::meta")
                (expression
                 (simple-format #f
                                "{~s,~s,0,{},{},{~a}}"
                                ""
                                name
                                (string-join check-bindings-list ", ")))
                (name "dzn_meta"))
              ,(variable
                (type "dzn::runtime&")
                (name "dzn_runtime")
                (expression "locator.get<dzn::runtime> ()"))
              ,(variable
                (type "dzn::locator const&")
                (name "dzn_locator")
                (expression "locator"))
              ,@(map code:member->variable (ast:member* o))
              ,@(map type->reply-variable (code:reply-types o))
              ,@(if (is-a? o <foreign>) '()
                    (map port->out-binding (ast:provides-port* o)))
              ,@(map provides->member (ast:provides-port* o))
              ,@(map requires->member (ast:requires-no-injected-port* o))
              ,@(map injected->member (ast:injected-port* o))))))
         (component
          (struct
           (inherit component)
           (methods
            `(,(constructor
                (struct component)
                (formals (list (formal (type "dzn::locator const&")
                                       (name "locator"))))
                (statement
                 (compound*
                  `(,@(map requires->external (filter ast:external? (ast:requires-port* o)))
                    ,@(if (is-a? o <foreign>) '()
                          `(,(requires->assignment (ast:requires-port* o))
                            ,@(append-map injected->assignments
                                          (ast:injected-port* o))
                            ,(assign* (member* "dzn_runtime.performs_flush (this)")
                                      "true")))
                    ,@(map trigger->event-slot (ast:in-triggers o))))))
              ,@(if (not (is-a? o <foreign>)) '()
                    (list
                     (destructor (struct component)
                                 (type "virtual")
                                 (statement (compound*)))))
              ,(protection* "private")
              ,@(map (cute trigger->method component <>) (ast:in-triggers o))
              ,@(map (cute function->method component <>) (ast:function* o)))))))
    (code:->namespace o component)))

(define-method (component-model->statements (o <component-model>))
  ((ast:perfect-funcq component-model->statements-unmemoized) o))

(define-method (model->header-statements (o <component>))
  (let ((interface-includes (code:interface-include* o)))
    (c++:include-guard
     o
     `(,@(map c++:file-name->include interface-includes)
       ,@(component-model->statements o)))))

(define-method (model->statements (o <component>))
  (component-model->statements o))


;;;
;;; Foreign.
;;;
(define-method (model->foreign (o <foreign>))
  (let ((foreign (component-model->statements o)))
    (namespace
     (name "skel")
     (statements foreign))))

(define-method (model->header-statements (o <foreign>))
  (let* ((interface-includes (code:interface-include* o))
         (statements `(,(cpp-system-include* "dzn/locator.hh")
                       ,(cpp-system-include* "dzn/runtime.hh")
                       ,@(map c++:file-name->include interface-includes)
                       ,(model->foreign o))))
    (c++:include-guard o statements)))

(define-method (model->statements (o <foreign>))
  (list (model->foreign o)))


;;;
;;; System.
;;;
(define-method (system->statements-unmemoized (o <system>))
  (let* ((injected-instances (code:injected-instance* o))
         (injected? (pair? injected-instances)))
    (define (port->pairing port)
      (let* ((other-end (ast:other-end-point port)))
        (assign*
         (string-append (.instance.name other-end)
                        "."
                        (.port.name other-end)
                        (if (ast:provides? port) ".dzn_meta.require.name"
                            ".dzn_meta.provide.name"))
         (simple-format #f "~s" (.name port)))))
    (define (provides->member port)
      (let* ((other-end (ast:other-end-point port)))
        (variable
         (type (string-append (code:type-name (.type port)) "&"))
         (name (.name port))
         (expression (member*
                      (string-append (.instance.name other-end)
                                     "."
                                     (.port.name other-end)))))))
    (define (requires->member port)
      (let ((other-end (ast:other-end-point port)))
        (variable
         (type (string-append (code:type-name (.type port)) "&"))
         (name (.name port))
         (expression (member*
                      (string-append (.instance.name other-end)
                                     "."
                                     (.port.name other-end)))))))
    (define (injected-instance? instance)
      (member instance injected-instances ast:eq?))
    (define (instance->member instance)
      (let ((local? (and injected?
                         (not (injected-instance? instance)))))
        (variable
         (type (string-append (code:type-name (.type instance))))
         (name (.name instance))
         (expression (if local? "dzn_local_locator"
                         "dzn_locator")))))
    (define (instance->assignments instance)
      (let* ((name (.name instance))
             (port-name (.port.name instance))
             (meta (string-append name ".dzn_meta."))
             (name-string (simple-format #f "~s" name)))
        `(,(assign* (string-append meta "parent") "&dzn_meta")
          ,(assign* (string-append meta "name") name-string)
          ,@(if (not (injected-instance? instance)) '()
                (let ((meta (simple-format #f "~a.~a.dzn_meta." name port-name)))
                  (list
                   (assign* (string-append meta "require.name")
                            name-string)))))))
    (define (requires->assignment ports)
      (assign* "dzn_meta.require"
               (generalized-initializer-list*
                (map (compose
                      (cute string-append "&" <> ".dzn_meta")
                      .name)
                     ports))))
    (define (children->assignment instances)
      (assign* "dzn_meta.children"
               (generalized-initializer-list*
                (map (compose
                      (cute string-append "&" <> ".dzn_meta")
                      .name)
                     instances))))
    (define (trigger->event-slot trigger)
      (let* ((port (.port trigger))
             (other-end (ast:other-end-point port))
             (port-name (.name port))
             (event (.event trigger))
             (direction (symbol->string (.direction event)))
             (event-name (.name event))
             (formals (code:formal* trigger))
             (arguments (map .name formals))
             (in-formals (filter ast:in? formals))
             (in-arguments (map .name in-formals))
             (formals (map c++:->formal formals))
             (call-action (call (name
                                 (string-append
                                  (code:event-name trigger)))
                                (arguments arguments)))
             (type (ast:type event))
             (type (code:type-name type))
             (typed? (ast:typed? event)))
        (assign*
         (string-append
          (.instance.name other-end)
          "."
          (.port.name other-end)
          "."
          (code:event-name event))
         (call (name "std::ref")
               (arguments
                `(,(string-append
                    "this->" port-name
                    "." direction
                    "." event-name)))))))
    (define (binding->injected-initializer binding)
      (let ((end-point (code:instance-end-point binding)))
        (string-append ".set ("
                       (code:end-point->string end-point)
                       ")")))
    (let* ((instances (code:instance* o))
           (bindings (code:component-binding* o))
           (injected-bindings (code:injected-binding* o))
           (ports (ast:port* o))
           (check-bindings-list
            (map (compose code->string c++:call-check-bindings .name) ports))
           (system
            (struct
             (name (dzn:model-name o))
             (parents '("public dzn::component"))
             (members
              `(,(variable
                  (type "dzn::meta")
                  (expression
                   (simple-format #f
                                  "{~s,~s,0,{},{},{~a}}"
                                  ""
                                  name
                                  (string-join check-bindings-list ", ")))
                  (name "dzn_meta"))
                ,(variable
                  (type "dzn::runtime&")
                  (name "dzn_runtime")
                  (expression "locator.get<dzn::runtime> ()"))
                ,(variable
                  (type "dzn::locator const&")
                  (name "dzn_locator")
                  (expression "locator"))
                ,@(map instance->member injected-instances)
                ,@(if (not injected?) '()
                      (list
                       (variable
                        (type "dzn::locator")
                        (name "dzn_local_locator")
                        (expression
                         (call (name "std::move")
                               (arguments
                                (list
                                 (string-append
                                  "locator.clone ()"
                                  (string-join
                                   (map binding->injected-initializer
                                        injected-bindings)
                                   ".")))))))))
                ,@(map instance->member instances)
                ,@(map provides->member (ast:provides-port* o))
                ,@(map requires->member (ast:requires-port* o))))))
           (system
            (struct
             (inherit system)
             (methods
              (list
               (constructor
                (struct system)
                (formals (list (formal (type "dzn::locator const&")
                                       (name "locator"))))
                (statement
                 (compound*
                  `(,@(map port->pairing (ast:provides-port* o))
                    ,@(map port->pairing (ast:requires-port* o))
                    ,(requires->assignment (ast:requires-port* o))
                    ,(children->assignment (ast:instance* o))
                    ,@(append-map instance->assignments injected-instances)
                    ,@(append-map instance->assignments instances)
                    ,@(map code:binding->connect bindings)
                    ,@(map trigger->event-slot (ast:provides-out-triggers o))
                    ,@(map trigger->event-slot (ast:requires-in-triggers o)))))))))))
      (code:->namespace o system))))

(define-method (system->statements (o <system>))
  ((ast:perfect-funcq system->statements-unmemoized) o))

(define-method (model->header-statements (o <system>))
  (let* ((component-includes (code:component-include* o))
         (injected? (pair? (code:injected-instance* o)))
         (statements `(,@(if (not injected?) '()
                             (list (cpp-system-include* "dzn/locator.hh")))
                       ,@(map c++:file-name->include component-includes)
                       ,@(system->statements o))))
    (c++:include-guard o statements)))

(define-method (model->statements (o <system>))
  (system->statements o))


;;;
;;; Shell.
;;;
(define-method (shell-system->statements-unmemoized (o <shell-system>))
  (let* ((injected-instances (code:injected-instance* o))
         (injected? (pair? injected-instances)))
    (define (port->external port)
      (assign*
       (simple-format
        #f "~a.dzn_external" (.name port))
       "true"))
    (define (provides->member port)
      (let* ((other-end (ast:other-end-point port)))
        (variable
         (type (string-join (cons "" (ast:full-name (.type port))) "::"))
         (name (.name port))
         (expression (member*
                      (string-append (.instance.name other-end)
                                     "."
                                     (.port.name other-end)))))))
    (define (requires->member port)
      (let ((other-end (ast:other-end-point port)))
        (variable
         (type (string-join (cons "" (ast:full-name (.type port))) "::"))
         (name (.name port))
         (expression (member*
                      (string-append (.instance.name other-end)
                                     "."
                                     (.port.name other-end)))))))
    (define (injected-instance? instance)
      (member instance injected-instances ast:eq?))
    (define (instance->member instance)
      (let ((local? (and injected?
                         (not (injected-instance? instance)))))
        (variable
         (type (string-join (cons "" (ast:full-name (.type instance))) "::"))
         (name (.name instance))
         (expression (if local? "dzn_local_locator"
                         "dzn_locator")))))
    (define (instance->assignments instance)
      (let* ((name (.name instance))
             (port-name (.port.name instance))
             (meta (string-append name ".dzn_meta."))
             (name-string (simple-format #f "~s" name)))
        `(,(assign* (string-append meta "parent") "&dzn_meta")
          ,(assign* (string-append meta "name") name-string)
          ,@(if (not (injected-instance? instance)) '()
                (let ((meta (simple-format #f "~a.~a.dzn_meta." name port-name)))
                  (list
                   (assign* (string-append meta "require.name")
                            name-string)))))))
    (define (provides->init port)
      (let ((other-end (ast:other-end-point port)))
        (assign*
         (string-append (.instance.name other-end)
                        "." (.port.name other-end)
                        ".dzn_meta.require.name")
         (simple-format #f "~s" (.name port)))))
    (define (requires->init port)
      (let ((other-end (ast:other-end-point port)))
        (assign*
         (string-append (.instance.name other-end)
                        "." (.port.name other-end)
                        ".dzn_meta.provide.name")
         (simple-format #f "~s" (.name port)))))
    (define (trigger->event-slot trigger)
      (let* ((port (.port trigger))
             (other-end (ast:other-end-point port))
             (port-name (.name port))
             (event (.event trigger))
             (event-name (.name event))
             (formals (code:formal* trigger))
             (arguments (map .name formals))
             ;; (out-formals (filter (negate ast:in?) formals))
             ;; (out-arguments (map .name out-formals))
             (in-formals (filter ast:in? formals))
             (in-arguments (map .name in-formals))
             (formals (map c++:->formal formals)))
        (assign*
         (code:event-name trigger)
         (function
          (captures '("&"))
          (formals formals)
          (statement
           (compound*
            (return*
             (call
              (name (if (ast:in? event) "dzn::shell"
                        "dzn_pump"))
              (arguments
               `(,@(if (ast:out? event) '()
                       '("dzn_pump"))
                 ,(function
                   (captures (cons* "&" in-arguments))
                   (statement
                    (compound*
                     (return*
                      (call (name
                             (string-append ;;; XXX FIXME code:foo-name
                              (.instance.name other-end)
                              "."
                              (.port.name other-end)
                              "."
                              (code:event-name event)))
                            (arguments arguments))))))))))))))))
    (define (trigger->out-event-slot trigger)
      (let* ((port (.port trigger))
             (port-name (.port.name trigger))
             (other-end (ast:other-end-point port))
             (event (.event trigger))
             (event-name (.name event))
             (direction (symbol->string (.direction event)))
             (formals- (code:formal* trigger))
             (arguments (map .name formals-)))
        (assign*
         (string-append ;;; XXX FIXME code:foo-name
          (.instance.name other-end)
          "."
          (.port.name other-end)
          "."
          (code:event-name event))
         (call (name "std::ref")
               (arguments `(,(string-append
                              port-name
                              "."
                              (code:event-name event))))))))
    (define (binding->injected-initializer binding)
      (let ((end-point (code:instance-end-point binding)))
        (string-append ".set ("
                       (code:end-point->string end-point)
                       ")")))
    (let* ((instances (code:instance* o))
           (bindings (code:component-binding* o))
           (injected-bindings (code:injected-binding* o))
           (ports (ast:port* o))
           (check-bindings-list
            (map (compose code->string c++:call-check-bindings .name) ports))
           (shell
            (struct
             (name (dzn:model-name o))
             (parents '("public dzn::component"))
             (members
              `(,(variable
                  (type "dzn::meta")
                  (expression
                   (simple-format #f
                                  "{~s,~s,0,{},{},{~a}}"
                                  ""
                                  name
                                  (string-join check-bindings-list ", ")))
                  (name "dzn_meta"))
                ,(variable
                  (type "dzn::runtime")
                  (name "dzn_runtime")
                  (expression ""))
                ,(variable
                  (type "dzn::locator")
                  (name "dzn_locator")
                  (expression
                   "std::move (locator.clone ().set (dzn_runtime).set (dzn_pump))"))
                ,@(map instance->member injected-instances)
                ,@(if (not injected?) '()
                      (list
                       (variable
                        (type "dzn::locator")
                        (name "dzn_local_locator")
                        (expression
                         (call (name "std::move")
                               (arguments
                                (list
                                 (string-append
                                  "locator.clone ()"
                                  (string-join
                                   (map binding->injected-initializer
                                        injected-bindings)
                                   ".")))))))))
                ,@(map instance->member instances)
                ,@(map provides->member (ast:provides-port* o))
                ,@(map requires->member (ast:requires-port* o))
                ,(variable
                  (type "dzn::pump")
                  (name "dzn_pump")
                  (expression ""))))))
           (shell
            (struct
             (inherit shell)
             (methods
              (list
               (constructor
                (struct shell)
                (formals (list (formal (type "dzn::locator const&")
                                       (name "locator"))))
                (statement
                 (compound*
                  `(,@(map port->external (ast:provides-port* o))
                    ,@(map port->external (ast:requires-port* o))
                    ,@(map provides->init (ast:provides-port* o))
                    ,@(map requires->init (ast:requires-port* o))
                    ,@(map trigger->event-slot (ast:provides-in-triggers o))
                    ,@(map trigger->event-slot (ast:requires-out-triggers o))
                    ,@(map trigger->out-event-slot (ast:provides-out-triggers o))
                    ,@(map trigger->out-event-slot (ast:requires-in-triggers o))
                    ,@(append-map instance->assignments injected-instances)
                    ,@(append-map instance->assignments instances)
                    ,@(map code:binding->connect bindings))))))))))
      (code:->namespace o shell))))

(define-method (shell-system->statements (o <system>))
  ((ast:perfect-funcq shell-system->statements-unmemoized) o))

(define-method (model->header-statements (o <shell-system>))
  (let* ((component-includes (code:component-include* o))
         (injected? (pair? (code:injected-instance* o)))
         (statements `(,(cpp-system-include* "dzn/locator.hh")
                       ,(cpp-system-include* "dzn/runtime.hh")
                       ,(cpp-system-include* "dzn/pump.hh")
                       ,@(map c++:file-name->include component-includes)
                       ,@(shell-system->statements o))))
    (c++:include-guard o statements)))

(define-method (model->statements (o <shell-system>))
  (shell-system->statements o))


;;;
;;; Main.
;;;
(define-method (main-connect-ports (o <component-model>) container)
  (define (return-expression trigger)
    (let* ((type (ast:type trigger))
           (type-name (code:type->string type)))
      (call (name (string-append "dzn::to_" type-name))
            (arguments (list "tmp")))))
  (define (trigger-in-event->assign trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (direction (ast:direction trigger))
           (formals (code:formal* trigger))
           (formals (map (cute clone <> #:name #f) formals))
           (formals (map c++:->formal formals))
           (system-port (string-append "c.system." port))
           (meta (string-append system-port ".dzn_meta"))
           (port-event (string-append port "." event))
           (function
            (function
             (captures '("&"))
             (formals formals)
             (statement
              (compound*
               (call (name "c.match")
                     (arguments
                      (list (simple-format #f "~s" port-event))))
               (call (name "dzn::port_block")
                     (arguments
                      (list "c.dzn_locator" "nullptr"
                            (simple-format #f "&c.system.~a" port))))
               (variable (type "std::string")
                         (name "tmp")
                         (expression
                          (call (name "c.trail_expect"))))
               (variable (type "size_t")
                         (name "pos")
                         (expression "tmp.rfind ('.')+1"))
               (assign (variable "tmp")
                       (expression "tmp.substr (pos)"))
               (return* (return-expression trigger)))))))
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
           (formals (map (cute clone <> #:name #f) formals))
           (formals (map c++:->formal formals))
           (port (.port trigger)))
      (assign (variable (string-append "c.system." (code:event-name trigger)))
              (expression
               (function
                (captures '("&"))
                (formals formals)
                (statement
                 (compound*
                  (call (name "c.match")
                        (arguments
                         (list (simple-format #f "~s" port-event)))))))))))
  (function
   (type "static void")
   (name "connect_ports")
   (formals (list (formal (type (string-append container "&"))
                          (name "c"))))
   (statement
    (compound*
     (cons*
      (statement* "dzn::debug.rdbuf () && dzn::debug << c.dzn_meta.name << std::endl")
      (append
       (map trigger-in-event->assign (ast:out-triggers-in-events o))
       (map trigger-out-event->assign (ast:out-triggers-out-events o))))))))

(define-method (main-event-map (o <component-model>) container)
  (define (provides->init port)
    (let* ((port-name (.name port))
           (system-port (simple-format #f "c.system.~a" port-name))
           (meta (simple-format #f "~a.dzn_meta.require" system-port)))
      (list
       (assign (variable (simple-format #f "~a.component" meta))
               (expression "&c"))
       (assign (variable (simple-format #f "~a.meta" meta))
               (expression "&c.dzn_meta"))
       (assign (variable (simple-format #f "~a.name" meta))
               (expression (simple-format #f "~s" port-name))))))
  (define (requires->init port)
    (let* ((port-name (.name port))
           (system-port (simple-format #f "c.system.~a" port-name))
           (meta (simple-format #f "~a.dzn_meta.provide" system-port)))
      (list
       (assign (variable (simple-format #f "~a.component" meta))
               (expression "&c"))
       (assign (variable (simple-format #f "~a.meta" meta))
               (expression "&c.dzn_meta"))
       (assign (variable (simple-format #f "~a.name" meta))
               (expression (simple-format #f "~s" port-name))))))
  (define (void-provides-in->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (formals (code:formal* trigger))
           (formals (code:number-formals formals))
           (arguments (map code:number-argument formals))
           (out-formals (filter (negate ast:in?) formals))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (port-return (simple-format #f "~a.return" port))
           (port-return-string (simple-format #f "~s" port-return)))
      (define (formal->variable formal)
        (variable (type "int")
                  (name (code:number-argument formal))
                  (expression (.name formal))))
      (generalized-initializer-list*
       port-event-string
       (function
        (captures '("&"))
        (statement
         (compound*
          `(,(call (name "c.match")
                   (arguments (list port-event-string)))
            ,@(map formal->variable out-formals)
            ,(call (name (string-append "c.system." (code:event-name trigger)))
                   (arguments arguments))
            ,(call (name "c.match")
                   (arguments (list port-return-string))))))))))
  (define (typed-provides-in->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (port-return (simple-format #f "~a.return" port))
           (port-return-string (simple-format #f "~s" port-return))
           (port-prefix (simple-format #f "~a." port))
           (event-slot (string-append "c.system." (code:event-name trigger)))
           (formals (code:formal* trigger))
           (invoke (code->string (call (name event-slot)
                                       (arguments (iota (length formals)))))))
      (generalized-initializer-list*
       port-event-string
       (function
        (captures '("&"))
        (statement
         (compound*
          (call (name "c.match")
                (arguments (list port-event-string)))
          (variable (type "std::string")
                    (name "tmp")
                    (expression
                     (simple-format #f
                                    "~s + dzn::to_string (~a)" port-prefix invoke)))
          (call (name "c.match")
                (arguments (list "tmp")))))))))
  (define (void-requires-in->init trigger)
    (let* ((port (.port.name trigger))
           (port-return (simple-format #f "~a.return" port))
           (port-return-string (simple-format #f "~s" port-return))
           (port-prefix (simple-format #f "~a." port))
           (system-port (simple-format #f "c.system.~a" port)))
      (generalized-initializer-list*
       port-return-string
       (function
        (captures '("&"))
        (statement
         (compound*
          (call (name "dzn::port_release")
                (arguments
                 (list "c.dzn_locator"
                       "&c.system"
                       (string-append "&" system-port))))))))))
  (define (typed-in->init port-pair) ;; FIXME: get rid of port-pair?
    (let* ((port (.port port-pair))
           (other (.other port-pair))
           (port-other (simple-format #f "~a.~a" port other)))
      (generalized-initializer-list*
       (simple-format #f "~s" port-other)
       (function
        (captures '("&"))
        (statement
         (compound*
          (call (name "dzn::port_release")
                (arguments
                 (list "c.dzn_locator"
                       "&c.system"
                       (simple-format #f "&c.system.~a" (.port port-pair)))))))))))
  (define (out->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (formals (code:formal* trigger)))
      (generalized-initializer-list*
       port-event-string
       (function
        (captures '("&"))
        (statement
         (compound*
          (call (name "c.match")
                (arguments (list port-event-string)))
          (call (name (string-append "c.system." (code:event-name trigger)))
                (arguments (iota (length formals))))))))))
  (define (flush->init port)
    (let* ((port (.name port))
           (flush (simple-format #f "~a.<flush>" port))
           (flush-string (simple-format #f "~s" flush)))
      (generalized-initializer-list*
       flush-string
       (function
        (captures '("&"))
        (statement
         (compound*
          (call (name "c.match")
                (arguments (list flush-string)))
          (statement*
           (simple-format #f "std::clog << ~s << std::endl" flush))
          (call (name "c.dzn_runtime.flush")
                (arguments (list "&c")))))))))
  (function
   (type "static std::map<std::string, std::function<void ()> >")
   (name "event_map")
   (formals (list (formal (type (string-append container "&"))
                          (name "c"))))
   (statement
    (compound*
     (append
      (append-map provides->init (ast:provides-port* o))
      (append-map requires->init (ast:requires-port* o))
      (list
       (return*
        (generalized-initializer-list
         (newline? #t)
         (initializers
          (cons*
           "{\"illegal\", []{std::clog << \"illegal\" << std::endl;}}"
           "{\"error\", []{std::clog << \"sut.error -> sut.error\" << std::endl; std::exit (0);}}"
           (append
            (map void-provides-in->init (ast:provides-in-void-triggers o))
            (map typed-provides-in->init (ast:provides-in-typed-triggers o))
            (map void-requires-in->init (code:requires-in-void-returns o))
            (map typed-in->init (code:return-values o))
            (map out->init (ast:requires-out-triggers o))
            (map flush->init (ast:requires-port* o))
            (map flush->init (ast:provides-port* o)))))))))))))

(define-method (main-getopt)
  (function
   (type "static bool")
   (name "getopt")
   (formals (list (formal (type "int") (name "argc"))
                  (formal (type "char const*") (name "argv[]"))
                  (formal (type "std::string") (name "option"))))
   (statement
    (compound*
     (return*
      (not-equal*
       (plus* "argv" "argc")
       (call (name "std::find_if")
             (arguments
              (list
               (plus* "argv" 1)
               (plus* "argv" "argc")
               (function (formals (list (formal (type "char const*") (name "s"))))
                         (captures '("&option"))
                         (statement
                          (compound* (return* (equal* "s" "option"))))))))))))))

(define-method (main (o <component-model>) container)
  (function
   (name "main")
   (formals (list (formal (type "int") (name "argc"))
                  (formal (type "char const*") (name "argv[]"))))
   (statement
    (compound*
     (let ((option (simple-format #f "~s" "--flush")))
       (variable (type "bool") (name "flush")
                 (expression (call (name "getopt")
                                   (arguments (list "argc" "argv" option))))))
     (let ((call-rdbuf (call (name "std::clog.rdbuf")))
           (option (simple-format #f "~s" "--debug")))
       (if* (call (name "getopt") (arguments (list "argc" "argv" option)))

            (call (name "dzn::debug.rdbuf")
                  (arguments (list call-rdbuf))
                  ;; (arguments (list (call (name "std::clog.rdbuf"))))
                  )))
     (call (name (simple-format #f "~a c" container))
           (arguments '("flush")))
     (call (name "connect_ports") (arguments '("c")))
     (call (name "c") (arguments '("event_map (c)")))))))


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
                        ,(cpp-system-include* "dzn/meta.hh")
                        ,(namespace* "dzn"
                                     (statement* "struct locator")
                                     (statement* "struct runtime"))
                        ;; XXX DATA
                        ,(cpp-system-include* "iostream")
                        ,(cpp-system-include* "vector")
                        ,(cpp-system-include* "map")
                        ,@(root->header-statements o)
                        ,@(append-map model->header-statements models)
                        ,(code:version-comment))))))
    (display scmheader)))

(define-method (print-code-ast (o <root>))
  (let* ((models (code:model* o))
         (comment (dzn:comment o))
         (header (string-append (code:file-name o) ".hh"))
         (scmcode (scmcode
                   (statements
                    `(,(code:generated-comment o)
                      ,@(if (not comment) '()
                            (list (comment* comment)))
                      ,(cpp-include* header)
                      ,(cpp-system-include* "dzn/locator.hh")
                      ,(cpp-system-include* "dzn/runtime.hh")
                      ,(cpp-system-include* "iterator")
                      ,(cpp-define* "STRINGIZING(x) #x")
                      ,(cpp-define* "STR(x) STRINGIZING (x)")
                      ,(cpp-define* "LOCATION __FILE__ \":\" STR (__LINE__)")
                      ,@(if (not (code:pump? o)) '()
                            (list (cpp-system-include* "dzn/pump.hh")))
                      ,@(root->statements o)
                      ,@(append-map model->statements models)
                      ,(code:version-comment))))))
    (display scmcode)))

(define-method (print-main-ast (o <component-model>))
  (let* ((header (string-append (code:file-name o) ".hh"))
         (container (simple-format
                     #f "dzn::container< ~a, std::function<void ()>>"
                     (code:type-name o)))
         (scmcode (scmcode
                   (statements
                    `(,(code:generated-comment o)
                      ,(cpp-include* header)
                      ,(cpp-system-include* "dzn/container.hh")
                      ,(cpp-system-include* "algorithm")
                      ,(cpp-system-include* "cstring")

                      ,(main-connect-ports o container)
                      ,(main-event-map o container)
                      ,(main-getopt)
                      ,(main o container)
                      ,(code:version-comment))))))
    (display scmcode)))
