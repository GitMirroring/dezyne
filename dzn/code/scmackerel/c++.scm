;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021, 2022, 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2023, 2024, 2025 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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

  #:use-module (dzn ast ast)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code goops)
  #:use-module (dzn code scmackerel code)
  #:use-module (dzn code language dzn)
  #:use-module (dzn code language c++)
  #:use-module (dzn command-line)
  #:use-module (dzn lts)
  #:use-module (dzn misc)
  #:export (c++:call-check-bindings
            c++:event-method
            c++:event-return-method
            c++:port-update-method
            c++:statement*
            print-code-ast
            print-header-ast
            print-main-ast)
  #:re-export (sm:code->string))

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
    `(,(sm:cpp-ifndef* guard)
      ,(sm:cpp-define* guard)
      ,@(match code
          ((code ...) code)
          (code (list code)))
      ,(sm:cpp-endif* guard))))

(define-method (c++:enum->to-string (o <enum>))
  (let ((enum-type (code:type-name o)))
    (define (field->sm:switch-case field)
      (let ((str (simple-format #f "~a:~a" (ast:name o) field)))
        (sm:switch-case
         (expression (simple-format #f "~a::~a" enum-type field))
         (statement (sm:return* (simple-format #f "~s" str))))))
    (let ((string-conversion
           (list
            (sm:function
             (name "to_cstr")
             (type "char const*")
             (formals (list (sm:formal (type enum-type)
                                       (name "v"))))
             (statement
              (sm:compound*
               (sm:switch (expression "v")
                          (cases (map field->sm:switch-case (ast:field* o))))
               (sm:return* (simple-format #f "~s" "")))))
            (sm:function
             (name "to_string")
             (type "template <>
std::string")
             (formals (list (sm:formal (type enum-type)
                                       (name "v"))))
             (statement
              (sm:compound*
               (sm:return* (sm:call (name "to_cstr") (arguments '("v")))))))))
          (ostream-operator
           (sm:function
            (name "operator <<")
            (inline? #t)
            (type "template <typename Char, typename Traits>
std::basic_ostream<Char, Traits> &")
            (formals (list (sm:formal (type "std::basic_ostream<Char, Traits>&")
                                      (name "os"))
                           (sm:formal (type enum-type)
                                      (name "v"))))
            (statement
             (sm:compound*
              (sm:return* (sm:statement* "os << dzn::to_cstr (v)")))))))
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
            (sm:function
             (name (simple-format #f "to_~a" enum-name))
             (formals (list (sm:formal (type "std::string")
                                       (name "s"))))
             (type enum-type)
             (statement
              (sm:compound*
               (sm:variable (type
                             (simple-format #f "static std::map<std::string, ~a>"
                                            enum-type))
                            (name "m")
                            (expression (string-append
                                         "{\n"
                                         (string-join map-elements ",\n")
                                         "}")))
               (sm:return* "m.at (s)"))))))
      (code:->namespace '("dzn") to-enum))))

(define-method (c++:enum->statements (o <enum>))
  `(,@(c++:enum->to-string o)
    ,@(c++:enum->to-enum o)))

(define-method (c++:enum->header-statements (o <enum>))
  (let* ((struct (code:enum->sm:enum-struct o))
         (statements
          `(,@(code:->namespace o struct)
            ,@(c++:enum->statements o))))
    (c++:include-guard o statements)))

(define-method (c++:->formal (o <formal>))
  (let* ((type (code:type-name o))
         (type (if (ast:in? o) type
                   (string-append type "&"))))
    (sm:formal (type type)
               (name (.name o)))))

(define-method (c++:file-name->include (o <string>))
  (sm:cpp-include* (string-append o ".hh")))

(define-method (c++:file-name->include (o <file-name>))
  (c++:file-name->include (.name o)))

(define-method (c++:file-name->include (o <import>))
  (c++:file-name->include (code:file-name o)))

;;; XXX FIXME template system renmants
(define-method (c++:file-name->include (o <instance>))
  (sm:cpp-include* (string-append (code:file-name->string o) ".hh")))

(define-method (c++:statement* (o <compound>))
  (ast:statement* o))

;; XXX FIXME: introduce <block> statement instead of
;; <blocking-compound>, like VM?
(define-method (c++:statement* (o <blocking-compound>))
  (let* ((port-name (.port.name o))
         (block (sm:call (name "port_block")
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
  (sm:function
   (captures '("this"))
   (statement
    (sm:compound*
     (sm:call (name (string-append port ".dzn_check_bindings"))
              (arguments '()))))))

(define-method (c++:event-method o (event <string>)) ; (o <trigger> or <action>)
  (let ((event-string (simple-format #f "~s" event)))
    (sm:call-method
     (name (code:shared-dzn-event-method o))
     (arguments (list event-string)))))

(define-method (c++:event-method o event) ; (o <trigger> or <action>) RECORD
  (sm:call-method
   (name (code:shared-dzn-event-method o))
   (arguments (list event))))

(define-method (c++:event-method o)     ; (o <trigger> or <action>)
  (c++:event-method o (.event.name o)))

(define-method (c++:event-return-method o variable)
  (let ((typed? (ast:typed? o))
        (sm:return-name "return"))
    (c++:event-method o (if (not typed?) sm:return-name
                            (sm:call (name "dzn::to_string")
                                     (arguments (list variable)))))))

(define-method (c++:event-return-method (o <trigger>))
  (if (ast:typed? o) (c++:event-return-method o "dzn_value")
      (c++:event-return-method o "return")))

(define-method (c++:port-update-method o); (o <trigger> or <action>)
  (sm:call-method
   (name (code:shared-update-method o))))

(define (c++:binding->connect binding)
  (code:binding->connect binding #:name "dzn::connect"))


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
          (sm:statements* (map ast->code statements))))
       ((is-a? statement <compound>)
        (sm:statement*))
       (else
        (ast->code statement))))
     (else
      (sm:if* (c++:ast->expression expression)
              (ast->code statement))))))

;;; imperative
(define-method (ast->code (o <blocking-compound>))
  (let ((statements (c++:statement* o)))
    (sm:compound* (map ast->code statements)))) ;;; XXX new sm:compound*

(define-method (ast->code (o <action>))
  (let* ((event (.event o))
         (formals (ast:formal* (.event o)))
         (event-name (.event.name o))
         (action-name (code:event-name o))
         (arguments (ast:argument* o))
         (arguments (map c++:ast->expression arguments)))
    (sm:call (name (string-append (%member-prefix) action-name))
             (arguments arguments))))

(define-method (ast->code (o <assign>))
  (let* ((variable (.variable o))
         (var (c++:ast->expression variable))
         (expression (.expression o))
         (action? (is-a? expression <action>)))
    (if (not action?) (sm:assign* var (c++:ast->expression expression))
        (sm:assign* var (ast->code expression)))))

(define-method (ast->code (o <defer>))
  (define (variable->defer-variable v)
    (sm:variable
     (type (code:type-name (ast:type v)))
     (name (c++:capture-name v o))
     (expression (code:member-name v))))
  (define (variable->equality v)
    (sm:equal* (c++:ast->expression v)
               (c++:capture-name v o)))
  (let* ((variables (ast:defer-variable* o))
         (locals (code:capture-local o))
         (equality (code:defer-equality* o))
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
             ,(sm:call (name "dzn::defer")
                       (arguments
                        (list "this"
                              (sm:function
                               (captures
                                `("this"
                                  ,@(map (cute c++:capture-name <> o)
                                         variables)))
                               (statement
                                (sm:compound*
                                 (sm:return* condition))))
                              (sm:function
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
             (out-binding (string-append "(*" (%member-prefix)
                                         (code:out-binding (.port o)) ")")))
        (sm:statements*
         `(,@(if (is-a? type <void>) '()
                 `(,(sm:assign*
                     (sm:member* (string-append "*" (%member-prefix))
                                 (code:reply-var type))
                     (c++:ast->expression (.expression o)))))
           ,(sm:if* out-binding (sm:call (name out-binding)))
           ,(sm:assign* out-binding "nullptr")
           ,@(if (not (code:port-release? o)) '()
                 `(,(sm:call (name "dzn::port_release")
                             (arguments
                              (list "dzn_locator"
                                    "this"
                                    (string-append
                                     "&"
                                     (%member-prefix)
                                     (.port.name o))))))))))))))

(define %illegal "locator.get<dzn::illegal_handler> ().handle (LOCATION)")

(define-method (ast->code (o <illegal>))
  (sm:statement* (string-append "this->dzn_" %illegal)))

(define-method (ast->code (o <out-bindings>))
  (define (formal->assign formal)
    (sm:assign* (.name formal)
                (sm:member* (%member-prefix) (.variable.name formal))))
  (let ((formals (ast:formal* o)))
    (if (null? formals) (sm:statement*)
        (sm:assign*
         (sm:member* (string-append "*" (%member-prefix))
                     (code:out-binding (.port o)))
         (sm:function
          (captures '("&"))
          (statement
           (sm:compound*
            (map formal->assign formals))))))))


;;;
;;; c++:ast->expression
;;;

(define-method (c++:ast->expression (o <top>))
  (ast->expression o))

(define-method (c++:ast->expression (o <not>))
  (sm:not* (c++:ast->expression (.expression o))))

(define-method (c++:ast->expression (o <binary>))
  (sm:expression
   (operator (operator->string o))
   (operands (list (c++:ast->expression (.left o))
                   (c++:ast->expression (.right o))))))

(define-method (c++:ast->expression (o <group>))
  (sm:group* (c++:ast->expression (.expression o))))

(define-method (c++:ast->expression (o <shared-var>))
  (let ((lst (ast:full-name o)))
    (string-join lst (%name-infix))))

(define-method (c++:ast->expression (o <shared-variable>))
  (let* ((name (ast:full-name o))
         (name (string-join name (%name-infix))))
    (if (ast:member? o) (sm:member* (%member-prefix) name)
        name)))

(define-method (c++:ast->expression (o <shared-field-test>))
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
    (c++:ast->expression expression)))


;;;
;;; Root.
;;;
(define-method (root->header-statements (o <root>))
  (let ((imports (ast:unique-import* o))
        (enums (code:enum* o)))
    (append
     (map c++:file-name->include imports)
     (map (compose (cute string-append <> "\n") .value) (ast:data* o))
     (append-map c++:enum->header-statements enums))))

(define-method (root->statements (o <root>))
  (let ((enums (code:enum* o)))
    (append-map c++:enum->statements enums)))


;;;
;;; Interface.
;;;
(define-method (interface->sm:statements-unmemoized (o <interface>))
  (define (event->slot event)
    (let ((type (code:type-name (ast:type event)))
          (formals (ast:formal* event)))
      (sm:variable
       (type (simple-format #f "dzn::~a::event<~a>"
                            (code:direction event)
                            (sm:code->string
                             (sm:call (name type)
                                      (arguments (map c++:->formal formals))))))
       (name (.name event)))))
  (define (event->check-binding event)
    (let ((event-name (code:event-name event)))
      (sm:if* (sm:not* (sm:member* event-name))
              (sm:statement*
               (format #f "throw dzn::binding_error (this->dzn_meta, ~s)"
                       event-name)))))
  (let* ((shared initial (code:shared-state o))
         (public-enums (code:public-enum* o))
         (enums (append public-enums (code:enum* o)))
         (interface
          (sm:struct
            (name (dzn:model-name o))
            (types (map code:enum->sm:enum-struct enums))
            (members
             `(,(sm:variable (type "dzn::port::meta") (name "dzn_meta")
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
                             (name "out"))
               ,(sm:variable (type "bool") (name "dzn_share_p") (expression "true"))
               ,(sm:variable (type "char const*") (name "dzn_label") (expression "\"\""))
               ,(sm:variable (type "int") (name "dzn_state") (expression initial))
               ,@(map code:member->variable (ast:member* o))))))
         (interface& (string-append
                      (string-join (cons "" (ast:full-name o)) "::")
                      "&")))

    (define (ast->assign ast)
      (let* ((expression (.expression ast))
             (value (code:shared-value expression)))
        (sm:assign* (.variable.name ast) value)))
    (define (state->if shared else)
      (let* ((expression (sm:equal* "dzn_state" (.state shared)))
             (assignments (ast:statement* (.assign shared)))
             (assignments (map ast->assign assignments)))
        (sm:if* expression
                (match assignments
                  ((assign) assign)
                  ((assigns ...) (sm:compound* assigns)))
                else)))

    (define (value->init value)
      (simple-format #f "~s" value))

    (define (dzn:hash r h)
      (let ((overflow 4294967296)
            (b 47)
            (p 79)
            (h.pow (cons 0 1))
            (r (cons (number->string h) r)))
        (car
         (fold
          (lambda (s h.pow)
            (string-fold
             (lambda (c h.pow)
               (let* ((c (- (char->integer c) b))
                      (h (car h.pow))
                      (pow (cdr h.pow))
                      (pow (modulo (* pow p) overflow))
                      (h (modulo
                          (+ h (modulo (* c pow) overflow))
                          overflow)))
                 (cons h pow)))
             h.pow s))
          h.pow r))))


    (define (event->sm:switch-case transition interface-shared)
      (let* ((prefix (edge-label transition))
             (initializer-list (sm:code->string
                                (sm:generalized-initializer-list*
                                 `(,(value->init prefix)))))
             (state (simple-format #f "~a" (edge-to transition)))
             (assignments (and=>
                           (find
                            (compose (cute eq? (edge-to transition) <>)
                                     .state)
                            interface-shared)
                           (compose ast:statement* .assign)))
             (assignments (map ast->assign (or assignments '()))))
        (sm:switch-case
         (expression (string-append
                      (number->string
                       (dzn:hash `(,prefix)
                                 (edge-from transition)))
                      "u"))
         (statement
          (sm:statements*
           (cons (sm:comment* (string-append
                               "//" (number->string (edge-from transition))
                               ":" prefix))
                 `(,(sm:assign* "dzn_state" state)
                   ,@assignments
                   ,(sm:break))))))))

    (define (event->transitions event)
      (let* ((transitions (code:shared event)))
        transitions))

    (define (transition< a b)
      (or (< (edge-from a) (edge-from b))
          (and (= (edge-from a) (edge-from b))
               (string<? (edge-label a)
                         (edge-label b)))))

    (define (transition= a b)
      (and
       (= (edge-from a) (edge-from b))
       (string=? (edge-label a) (edge-label b))))

    (let* ((type (string-join (cons "" (ast:full-name o)) "::"))
           (type& (string-append type "&"))
           (connect
            (sm:namespace*
             "dzn"
             (sm:function
              (name "connect")
              (inline? #t)
              (type "inline void")
              (formals (list (sm:formal (type type&)
                                        (name "provide"))
                             (sm:formal (type type&)
                                        (name "require"))))
              (statement
               (sm:compound*
                `(,@(append-map
                     (lambda (o)
                       (let ((provide (string-append "provide.out." (.name o)))
                             (require (string-append "require.out." (.name o))))
                         `(,(sm:assign*
                             (string-append provide ".other_port_update")
                             (string-append require ".port_update"))
                           ,(sm:assign*
                             (string-append require ".other_port_update")
                             (string-append provide ".port_update"))
                           ,(sm:assign* provide require))))
                     (ast:out-event* o))
                  ,@(map (lambda (o)
                           (sm:assign*
                            (string-append "require.in." (.name o))
                            (string-append "provide.in." (.name o))))
                         (ast:in-event* o))
                  ,(sm:assign* "provide.dzn_meta.require"
                               "require.dzn_meta.require")
                  ,(sm:assign* "require.dzn_meta.provide"
                               "provide.dzn_meta.provide")
                  ,(sm:assign* "provide.dzn_share_p"
                               "require.dzn_share_p = provide.dzn_share_p && require.dzn_share_p")))))))
           (interface
            (sm:struct
              (inherit interface)
              (methods
               `(,(sm:constructor
                   (struct interface)
                   (formals (list (sm:formal (type "dzn::port::meta const&")
                                             (name "m"))))
                   (statement
                    (sm:compound*
                     (if (= (dzn:debugity) 0) '()
                         (sm:call (name "debug")
                                  (arguments (list "\"ctor\"")))))))
                 ,(sm:constructor
                   (inline? #t)
                   (type "template <typename Component>\n")
                   (struct interface)
                   (formals (list (sm:formal (type "dzn::port::meta const&")
                                             (name "m"))
                                  (sm:formal (type "Component*")
                                             (name "that"))))
                   (statement
                    (sm:compound*
                     (map
                      (lambda (event)
                        (let* ((direction (code:direction event))
                               (event-name (.name event))
                               (event-name-string (simple-format #f "~s"
                                                                 event-name)))
                          (sm:call (name (string-append direction "."
                                                        event-name ".set"))
                                   (arguments `("that", "this",
                                                event-name-string)))))
                      (ast:event* o)))))
                 ,(sm:destructor (struct interface)
                                 (type "virtual")
                                 (statement "= default;"))
                 ,@(if (= (dzn:debugity) 0) '()
                       `(,(sm:method
                           (struct interface) (type "void") (name "debug")
                           (statement
                            (sm:compound*
                             (sm:statement*
                              "std::cout << \" => \" << dzn_state << std::endl"))))))
                 ,@(if (= (dzn:debugity) 0) '()
                       `(,(sm:method
                           (struct interface) (type "void") (name "debug")
                           (formals (list (sm:formal (type "std::string&&")
                                                     (name "label"))))
                           (statement
                            (sm:compound*
                             (sm:variable
                              (type "std::string")
                              (name "tmp")
                              (expression
                               (sm:conditional*
                                "this->dzn_meta.provide.component"
                                (sm:call
                                 (name "dzn::path")
                                 (arguments '("this->dzn_meta.provide.meta")))
                                (sm:call
                                 (name "dzn::path")
                                 (arguments
                                  '("this->dzn_meta.require.meta"))))))
                             (sm:statement* "std::cout << tmp << \".\";")
                             (sm:assign*
                              "tmp"
                              (sm:conditional*
                               (sm:call (name "this->dzn_meta.provide.name.size")
                                        (arguments '()))
                               "this->dzn_meta.provide.name"
                               "this->dzn_meta.require.name"))
                             (sm:statement*
                              "std::cout << tmp << \" \" << label << \": \" << dzn_state << \" prefix: \" << dzn_label << std::endl"))))))
                 ,@(if (%no-constraint?)
                       `(,(sm:method
                           (struct interface) (type "void") (name "dzn_event")
                           (formals (list (sm:formal (type "char const*")
                                                     (name "event"))))
                           (statement
                            (sm:compound*)))
                         ,(sm:method
                           (struct interface) (type "void")
                           (name "dzn_update_state")
                           (formals (list (sm:formal
                                           (type "dzn::locator const&")
                                           (name "locator"))))
                           (statement
                            (sm:compound*))))
                       (let* ((events (ast:event* o))
                              (transitions (append-map event->transitions
                                                       events))
                              (transitions (sort transitions transition<))
                              (transitions (delete-adjacent-duplicates
                                            transitions
                                            transition=)))
                         `(,(sm:method
                             (struct interface) (type "void")
                             (name "dzn_event")
                             (formals (list (sm:formal (type "char const*")
                                                       (name "event"))))
                             (statement
                              (sm:compound*
                               `(,(sm:if* (sm:not* "dzn_share_p") (sm:return*))
                                 ,(sm:assign* "dzn_label" "event")
                                 ,@(if (= (dzn:debugity) 0) '()
                                       `(,(sm:call
                                           (name "debug")
                                           (arguments '("\"dzn_event\"")))))))))
                           ,(sm:method
                             (struct interface) (type "void")
                             (name "dzn_update_state")
                             (formals (list
                                       (sm:formal (type "dzn::locator const&")
                                                  (name "locator"))))
                             (statement
                              (sm:compound*
                               `(,(sm:if* (sm:or* (sm:not* "dzn_share_p")
                                                  (sm:not* "dzn_label"))
                                          (sm:return*))
                                 ,@(if (= (dzn:debugity) 0) '()
                                       `(,(sm:call (name "debug")
                                                   (arguments
                                                    '("\"update_state\"")))))
                                 ,(sm:switch
                                   (expression
                                    (sm:call
                                     (name "dzn::hash")
                                     (arguments `("dzn_label" "dzn_state"))))
                                   (cases
                                    `(,@(map (cute event->sm:switch-case <>
                                                   shared)
                                             transitions)
                                      ,(sm:switch-case
                                        (label "default")
                                        (statement
                                         (sm:statement*
                                          "locator.get<dzn::illegal_handler> ().handle (LOCATION)"))))))
                                 ,@(if (= (dzn:debugity) 0) '()
                                       `(,(sm:call (name "debug")))))))))))
                 ,(sm:method
                   (struct interface) (type "void") (name "dzn_check_bindings")
                   (statement
                    (sm:compound*
                     (append
                      (map event->check-binding (ast:in-event* o))
                      (map event->check-binding (ast:out-event* o))))))))))
           (sm:enum-to-string (append-map c++:enum->to-string public-enums))
           (to-enum (append-map c++:enum->to-enum public-enums)))
      `(,@(code:->namespace o interface)
        ,connect
        ,@sm:enum-to-string
        ,@to-enum))))

(define-method (interface->statements (o <interface>))
  ((ast:perfect-funcq interface->sm:statements-unmemoized) o))

(define-method (model->header-statements (o <interface>))
  (c++:include-guard o (interface->statements o)))

(define-method (model->statements (o <interface>))
  (interface->statements o))


;;;
;;; Component.
;;;
(define-method (component-model->sm:statements-unmemoized (o <component-model>))
  (define (provides->member port)
    (sm:variable
     (type (code:type-name (.type port)))
     (name (.name port))
     (expression (simple-format
                  #f "{{~s,&~a,this,&dzn_meta},{~s,&~a,0,0}},this" name name name name))))
  (define (requires->member port)
    (sm:variable
     (type (code:type-name (.type port)))
     (name (.name port))
     (expression (simple-format
                  #f
                  "{{~s,&~a,0,0},{~s,&~a,this,&dzn_meta}},this" name name name name))))
  (define (requires->external port)
    (sm:assign*
     (simple-format
      #f "~a.dzn_share_p" (.name port))
     "false"))
  (define (injected->member port)
    (sm:variable
     (type (code:type-name (.type port)))
     (name (.name port))
     (expression (sm:member* (simple-format #f "dzn_locator.get< ~a> ()" type)))))
  (define (type->reply-variable o)
    (sm:variable
     (type (string-append (code:type-name o) "*"))
     (name (code:reply-var o))))
  (define (port->out-binding port)
    (sm:variable
     (type "std::function<void ()>*")
     (name (code:out-binding port))))
  (define (port->injected-require-override port)
    (let* ((type (.type port))
           (type (code:type-name type)))
      (sm:assign* (sm:member*
                   (%member-prefix)
                   (string-append "dzn_locator.get< " type "> ().dzn_meta"))
                  (string-append (.name port) ".dzn_meta"))))
  (define (port->update port)
    (sm:call (name (string-append (%member-prefix)
                                  (.name port)
                                  ".dzn_update_state"))
             (arguments `(,(string-append (%member-prefix)
                                          "dzn_locator")))))
  (define (trigger->event-slot trigger)
    (let* ((port (.port trigger))
           (port-name (.name port))
           (event (.event trigger))
           (direction (code:direction event))
           (event-name (.name event))
           (event-name-string (simple-format #f "~s" event-name))
           (formals (ast:formal* trigger))
           (arguments (map .name formals))
           (in-formals (filter ast:in? formals))
           (in-arguments (map .name in-formals))
           (formals (map c++:->formal formals))
           (out-binding (code:out-binding port))
           (return-type (ast:type trigger))
           (type (code:type-name return-type))
           (typed? (ast:typed? trigger))
           (call-slot (sm:call-method
                       (name (code:event-slot-name trigger))
                       (arguments arguments))))
      (sm:assign*
       (sm:member* (%member-prefix) (code:event-name trigger))
       (sm:function
        (captures '("this"))
        (formals formals)
        (statement
         (sm:compound*
          `(,@(map port->injected-require-override
                   (ast:injected-port* o))
            ,@(if (not (ast:provides? port)) '()
                  `(,(sm:assign*
                      (sm:member* (%member-prefix) (code:out-binding port))
                      (sm:member* (string-append "&" (%member-prefix))
                                  (string-append (code:event-name trigger)
                                                 ".dzn_out_binding")))))
            ,@(if (not typed?) `(,call-slot)
                  `(,(sm:assign*
                      (sm:member* (%member-prefix) (code:reply-var return-type))
                      (sm:member* (string-append "&"(%member-prefix))
                                  (simple-format #f "~a.in.~a.reply"
                                                 port-name event-name)))
                    ,@(if (is-a? o <foreign>) `(,(sm:return* call-slot))
                          `(,call-slot
                            ,(sm:return*
                              (sm:member*
                               (%member-prefix)
                               (simple-format #f "~a.in.~a.reply"
                                              port-name event-name))))))))))))))
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
           (formals (ast:formal* trigger))
           (return-type (ast:type trigger)))
      (sm:method (struct component)
                 (type (if (not (is-a? o <foreign>)) "void"
                           (string-append "virtual "
                                          (code:type-name return-type))))
                 (name (code:event-slot-name trigger))
                 (formals (map c++:->formal formals))
                 (statement statement))))
  (define (function->method component function)
    (let* ((type (code:type-name (ast:type function)))
           (name (.name function))
           (formals (ast:formal* function))
           (statement (.statement function))
           (statement (ast->code statement)))
      (sm:method (struct component)
                 (type type)
                 (name name)
                 (formals (map c++:->formal formals))
                 (statement statement))))
  (define (injected->assignments port)
    (let* ((name (.name port))
           (meta (string-append name ".dzn_meta.require"))
           (name-string (simple-format #f "~s" name)))
      `(,(sm:assign* (sm:member* (string-append meta ".meta")) "&dzn_meta")
        ,(sm:assign* (sm:member* (string-append meta ".name")) name-string)
        ,(sm:assign* (sm:member* (string-append meta ".component")) "this"))))
  (define (requires->assignment ports)
    (sm:assign* (sm:member* "dzn_meta.require")
                (sm:generalized-initializer-list*
                 (map (compose
                       (cute string-append "&" <> ".dzn_meta")
                       .name)
                      ports))))
  (define (out->method component trigger)
    (let* ((arguments (map c++:ast->expression
                           (ast:formal* trigger)))
           (lambda (sm:function
                    (captures `("this" ,@arguments))
                    (statement
                     (sm:compound*
                      (sm:call
                       (name (string-append
                              (%member-prefix)
                              (code:event-name trigger)))
                       (arguments arguments)))))))
      (sm:method (struct component)
                 (type "void")
                 (name (code:event-slot-name trigger))
                 (formals (map c++:->formal (ast:formal* trigger)))
                 (statement
                  (sm:compound*
                   (sm:call
                    (name (string-append
                           (%member-prefix)
                           (code:event-name trigger)))
                    (arguments arguments)))))))
  (let* ((enums (filter (is? <enum>) (code:enum* o)))
         (ports (ast:port* o))
         (check-bindings-list
          (map (compose sm:code->string c++:call-check-bindings .name) ports))
         (component
          (sm:struct
            (name (dzn:model-name o))
            (parents '("public dzn::component"))
            (types (map code:enum->sm:enum-struct enums))
            (members
             `(,(sm:variable
                 (type "dzn::meta")
                 (expression
                  (simple-format #f
                                 "{~s,~s,0,{},{},{~a}}"
                                 name
                                 name
                                 (string-join check-bindings-list ", ")))
                 (name "dzn_meta"))
               ,(sm:variable
                 (type "dzn::runtime&")
                 (name "dzn_runtime")
                 (expression "locator.get<dzn::runtime> ()"))
               ,(sm:variable
                 (type "dzn::locator const&")
                 (name "dzn_locator")
                 (expression "locator"))
               ,@(map code:member->variable (ast:member* o))
               ,@(map type->reply-variable (code:reply-types o))
               ,@(map port->out-binding (ast:provides-port* o))
               ,@(map provides->member (ast:provides-port* o))
               ,@(map requires->member (ast:requires-no-injected-port* o))
               ,@(map injected->member (ast:injected-port* o))))))
         (component
          (sm:struct
            (inherit component)
            (methods
             `(,(sm:constructor
                 (struct component)
                 (formals (list (sm:formal (type "dzn::locator const&")
                                           (name "locator"))))
                 (statement
                  (sm:compound*
                   `(,@(map requires->external (filter ast:external?
                                                       (ast:requires-port* o)))
                     ,@(if (is-a? o <foreign>) '()
                           `(,(sm:assign* "dzn_runtime.native (this)"
                                          "true")
                             ,(requires->assignment (ast:requires-port* o))
                             ,@(append-map injected->assignments
                                           (ast:injected-port* o))))
                     ,@(map trigger->event-slot (ast:in-triggers o))))))
               ,@(if (not (is-a? o <foreign>)) '()
                     `(,(sm:destructor (struct component)
                                       (type "virtual")
                                       (statement (sm:compound*)))
                       ,(sm:protection* "protected")
                       ,@(map (cute out->method component <>)
                              (ast:provides-out-triggers o))))
               ,(sm:protection* "private")
               ,@(map (cute trigger->method component <>) (ast:in-triggers o))
               ,@(map (cute function->method component <>) (ast:function* o))))))
         (component (if (not (is-a? o <foreign>)) component
                        (sm:namespace
                         (name "skel")
                         (statements (list component))))))
    (code:->namespace o component)))

(define-method (component-model->statements (o <component-model>))
  ((ast:perfect-funcq component-model->sm:statements-unmemoized) o))

(define-method (model->header-statements (o <component>))
  (let ((interface-includes (code:interface-include* o)))
    (c++:include-guard
     o
     `(,@(map c++:file-name->include interface-includes)
       ,@(component-model->statements o)
       ,@(append-map c++:enum->statements (code:enum* o))))))

(define-method (model->statements (o <component>))
  `(,@(component-model->statements o)
    ,@(append-map c++:enum->statements (code:enum* o))))


;;;
;;; Foreign.
;;;
(define-method (model->foreign (o <foreign>))
  (component-model->statements o))

(define-method (model->header-statements (o <foreign>))
  (let* ((interface-includes (code:interface-include* o))
         (statements `(,@(map c++:file-name->include interface-includes)
                       ,@(model->foreign o))))
    (c++:include-guard o statements)))

(define-method (model->statements (o <foreign>))
  (model->foreign o))


;;;
;;; System.
;;;
(define-method (system->sm:statements-unmemoized (o <system>))
  (let* ((injected-instances (code:injected-instance* o))
         (injected? (pair? injected-instances)))
    (define (port->pairing port)
      (let ((other-end (ast:other-end-point port)))
        (sm:assign*
         (string-append (.instance.name other-end)
                        "."
                        (.port.name other-end)
                        (if (ast:provides? port) ".dzn_meta.require.name"
                            ".dzn_meta.provide.name"))
         (simple-format #f "~s" (.name port)))))
    (define (provides->member port)
      (let ((other-end (ast:other-end-point port)))
        (sm:variable
         (type (string-append (code:type-name (.type port)) "&"))
         (name (.name port))
         (expression (sm:member*
                      (string-append (.instance.name other-end)
                                     "."
                                     (.port.name other-end)))))))
    (define (requires->member port)
      (let ((other-end (ast:other-end-point port)))
        (sm:variable
         (type (string-append (code:type-name (.type port)) "&"))
         (name (.name port))
         (expression (sm:member*
                      (string-append (.instance.name other-end)
                                     "."
                                     (.port.name other-end)))))))
    (define (injected-instance? instance)
      (member instance injected-instances ast:eq?))
    (define (instance->member instance)
      (let ((local? (and injected?
                         (not (injected-instance? instance)))))
        (sm:variable
         (type (string-append (code:type-name (.type instance))))
         (name (.name instance))
         (expression (if local? "dzn_local_locator"
                         "dzn_locator")))))
    (define (instance->assignments instance)
      (let* ((name (.name instance))
             (port-name (.port.name instance))
             (meta (string-append name ".dzn_meta."))
             (name-string (simple-format #f "~s" name)))
        `(,(sm:assign* (string-append meta "parent") "&dzn_meta")
          ,(sm:assign* (string-append meta "name") name-string))))
    (define (requires->assignment ports)
      (sm:assign* "dzn_meta.require"
                  (sm:generalized-initializer-list*
                   (map (compose
                         (cute string-append "&" <> ".dzn_meta")
                         .name)
                        ports))))
    (define (children->assignment instances)
      (sm:assign* "dzn_meta.children"
                  (sm:generalized-initializer-list*
                   (map (compose
                         (cute string-append "&" <> ".dzn_meta")
                         .name)
                        instances))))
    (define (binding->injected-initializer binding)
      (let ((end-point (code:instance-end-point binding)))
        (string-append ".set ("
                       (code:end-point->string end-point)
                       ")")))
    (let* ((instances (code:instance* o))
           (port-instances (filter (compose ast:provides-port .type) instances))
           (bindings (code:component-binding* o))
           (injected-bindings (code:injected-binding* o))
           (ports (ast:port* o))
           (check-bindings-list
            (map (compose sm:code->string c++:call-check-bindings .name) ports))
           (system
            (sm:struct
              (name (dzn:model-name o))
              (parents '("public dzn::component"))
              (members
               `(,(sm:variable
                   (type "dzn::meta")
                   (expression
                    (simple-format #f
                                   "{~s,~s,0,{},{},{~a}}"
                                   name
                                   name
                                   (string-join check-bindings-list ", ")))
                   (name "dzn_meta"))
                 ,(sm:variable
                   (type "dzn::runtime&")
                   (name "dzn_runtime")
                   (expression "locator.get<dzn::runtime> ()"))
                 ,(sm:variable
                   (type "dzn::locator const&")
                   (name "dzn_locator")
                   (expression "locator"))
                 ,@(map instance->member injected-instances)
                 ,@(if (not injected?) '()
                       (list
                        (sm:variable
                         (type "dzn::locator")
                         (name "dzn_local_locator")
                         (expression
                          (sm:call (name "std::move")
                                   (arguments
                                    (list
                                     (string-append
                                      "dzn_locator.clone ()"
                                      (string-join
                                       (map binding->injected-initializer
                                            injected-bindings)
                                       "")))))))))
                 ,@(map instance->member instances)
                 ,@(map provides->member (ast:provides-port* o))
                 ,@(map requires->member (ast:requires-port* o))))))
           (system
            (sm:struct
              (inherit system)
              (methods
               (list
                (sm:constructor
                 (struct system)
                 (formals (list (sm:formal (type "dzn::locator const&")
                                           (name "locator"))))
                 (statement
                  (sm:compound*
                   `(,@(map port->pairing (ast:provides-port* o))
                     ,@(map port->pairing (ast:requires-port* o))
                     ,(requires->assignment (ast:requires-port* o))
                     ,(children->assignment (ast:instance* o))
                     ,@(append-map instance->assignments injected-instances)
                     ,@(append-map instance->assignments port-instances)
                     ,@(map c++:binding->connect bindings))))))))))
      (code:->namespace o system))))

(define-method (system->statements (o <system>))
  ((ast:perfect-funcq system->sm:statements-unmemoized) o))

(define-method (model->header-statements (o <system>))
  (let* ((component-includes (code:component-include* o))
         (injected? (pair? (code:injected-instance* o)))
         (statements `(,@(if (not injected?) '()
                             (list (sm:cpp-system-include* "dzn/locator.hh")))
                       ,@(map c++:file-name->include component-includes)
                       ,@(system->statements o))))
    (c++:include-guard o statements)))

(define-method (model->statements (o <system>))
  (system->statements o))


;;;
;;; Shell.
;;;
(define-method (shell-system->sm:statements-unmemoized (o <shell-system>))
  (let* ((injected-instances (code:injected-instance* o))
         (injected? (pair? injected-instances)))
    (define (provides->member port)
      (let ((other-end (ast:other-end-point port)))
        (sm:variable
         (type (string-join (cons "" (ast:full-name (.type port))) "::"))
         (name (.name port))
         (expression
          (simple-format
           #f "{{~s,&~a,this,&dzn_meta},{~s,0,0,0}}" name name name)))))
    (define (requires->member port)
      (let ((other-end (ast:other-end-point port)))
        (sm:variable
         (type (string-join (cons "" (ast:full-name (.type port))) "::"))
         (name (.name port))
         (expression
          (simple-format
           #f "{{~s,0,0,0},{~s,&~a,this,&dzn_meta}}" name name name)))))
    (define (injected-instance? instance)
      (member instance injected-instances ast:eq?))
    (define (instance->member instance)
      (let ((local? (and injected?
                         (not (injected-instance? instance)))))
        (sm:variable
         (type (string-join (cons "" (ast:full-name (.type instance))) "::"))
         (name (.name instance))
         (expression (if local? "dzn_local_locator"
                         "dzn_locator")))))
    (define (instance->assignments instance)
      (let* ((name (.name instance))
             (port-name (.port.name instance))
             (meta (string-append name ".dzn_meta."))
             (name-string (simple-format #f "~s" name)))
        `(,(sm:assign* (string-append meta "parent") "&dzn_meta")
          ,(sm:assign* (string-append meta "name") name-string)
          ,@(if (not (injected-instance? instance)) '()
                (let ((meta (simple-format #f "~a.~a.dzn_meta." name port-name)))
                  (list
                   (sm:assign* (string-append meta "require.name")
                               name-string)))))))
    (define (provides->init port)
      (let ((other-end (ast:other-end-point port)))
        (sm:assign*
         (string-append (.instance.name other-end)
                        "." (.port.name other-end)
                        ".dzn_meta.require.name")
         (simple-format #f "~s" (.name port)))))
    (define (requires->init port)
      (let ((other-end (ast:other-end-point port)))
        (sm:assign*
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
             (formals (ast:formal* trigger))
             (arguments (map .name formals))
             (in-formals (filter ast:in? formals))
             (in-arguments (map .name in-formals))
             (formals (map c++:->formal formals)))
        (sm:assign*
         (code:event-name trigger)
         (sm:function
          (captures '("&"))
          (formals formals)
          (statement
           (sm:compound*
            (sm:return*
             (sm:call
              (name (if (ast:in? event) "dzn::shell"
                        "dzn_pump"))
              (arguments
               `(,@(if (ast:out? event) '()
                       '("dzn_pump"))
                 ,(sm:function
                   (captures (cons* "&" in-arguments))
                   (statement
                    (sm:compound*
                     (sm:return*
                      (sm:call (name
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
             (formals- (ast:formal* trigger))
             (arguments (map .name formals-)))
        (sm:assign*
         (string-append ;;; XXX FIXME code:foo-name
          (.instance.name other-end)
          "."
          (.port.name other-end)
          "."
          (code:event-name event))
         (sm:call (name "std::ref")
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
            (map (compose sm:code->string c++:call-check-bindings .name) ports))
           (shell
            (sm:struct
              (name (dzn:model-name o))
              (parents '("public dzn::component"))
              (members
               `(,(sm:variable
                   (type "dzn::meta")
                   (expression
                    (simple-format #f
                                   "{~s,~s,0,{},{},{~a}}"
                                   name
                                   name
                                   (string-join check-bindings-list ", ")))
                   (name "dzn_meta"))
                 ,(sm:variable
                   (type "dzn::runtime")
                   (name "dzn_runtime")
                   (expression ""))
                 ,(sm:variable
                   (type "dzn::locator")
                   (name "dzn_locator")
                   (expression
                    "std::move (locator.clone ().set (dzn_runtime).set (dzn_pump))"))
                 ,@(map instance->member injected-instances)
                 ,@(if (not injected?) '()
                       (list
                        (sm:variable
                         (type "dzn::locator")
                         (name "dzn_local_locator")
                         (expression
                          (sm:call (name "std::move")
                                   (arguments
                                    (list
                                     (string-append
                                      "dzn_locator.clone ()"
                                      (string-join
                                       (map binding->injected-initializer
                                            injected-bindings)
                                       "")))))))))
                 ,@(map instance->member instances)
                 ,@(map provides->member (ast:provides-port* o))
                 ,@(map requires->member (ast:requires-port* o))
                 ,(sm:variable
                   (type "dzn::pump")
                   (name "dzn_pump")
                   (expression ""))))))
           (shell
            (sm:struct
              (inherit shell)
              (methods
               (list
                (sm:constructor
                 (struct shell)
                 (formals (list (sm:formal (type "dzn::locator const&")
                                           (name "locator"))))
                 (statement
                  (sm:compound*
                   `(,@(map provides->init (ast:provides-port* o))
                     ,@(map requires->init (ast:requires-port* o))
                     ,@(map trigger->event-slot (ast:provides-in-triggers o))
                     ,@(map trigger->event-slot (ast:requires-out-triggers o))
                     ,@(map trigger->out-event-slot (ast:provides-out-triggers o))
                     ,@(map trigger->out-event-slot (ast:requires-in-triggers o))
                     ,@(append-map instance->assignments injected-instances)
                     ,@(append-map instance->assignments instances)
                     ,@(map c++:binding->connect bindings))))))))))
      (code:->namespace o shell))))

(define-method (shell-system->statements (o <system>))
  ((ast:perfect-funcq shell-system->sm:statements-unmemoized) o))

(define-method (model->header-statements (o <shell-system>))
  (let* ((component-includes (code:component-include* o))
         (injected? (pair? (code:injected-instance* o)))
         (statements `(,(sm:cpp-system-include* "dzn/locator.hh")
                       ,(sm:cpp-system-include* "dzn/runtime.hh")
                       ,(sm:cpp-system-include* "dzn/pump.hh")
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
      (sm:call (name (string-append "dzn::to_" type-name))
               (arguments (list "tmp")))))
  (define (trigger-in-event->assign trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (direction (ast:direction trigger))
           (formals (ast:formal* trigger))
           (formals (map (cute clone <> #:name #f) formals))
           (formals (map c++:->formal formals))
           (system-port (string-append "c.system." port))
           (meta (string-append system-port ".dzn_meta"))
           (port-event (string-append port "." event))
           (blocking? (.blocking? (.port trigger)))
           (function
            (sm:function
             (captures '("&"))
             (formals formals)
             (statement
              (sm:compound*
               (sm:call (name "c.perform"))
               (sm:call (name "c.match")
                        (arguments
                         (list (simple-format #f "~s" port-event))))
               (if (not blocking?) (sm:call (name "c.sync_trigger"))
                   (sm:call (name "dzn::port_block")
                            (arguments
                             (list "c.dzn_locator" "nullptr"
                                   (simple-format #f "&c.system.~a" port)))))
               (sm:variable (type "std::string")
                            (name "tmp")
                            (expression
                             (sm:call (name "c.trail.front"))))
               (sm:call (name "c.trail.pop"))
               (sm:variable (type "size_t")
                            (name "pos")
                            (expression "tmp.rfind ('.')+1"))
               (sm:assign (variable "tmp")
                          (expression "tmp.substr (pos)"))
               (sm:return* (return-expression trigger)))))))
      (sm:assign
       (variable (string-append "c.system." (code:event-name trigger)))
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
           (formals (ast:formal* trigger))
           (formals (map (cute clone <> #:name #f) formals))
           (formals (map c++:->formal formals))
           (port (.port trigger)))
      `(,(sm:assign
          (variable (string-append "c.system." (code:event-name trigger)))
          (expression
           (sm:function
            (captures '("&"))
            (formals formals)
            (statement
             (sm:compound*
              (sm:call (name "c.perform"))
              (sm:call (name "c.match")
                       (arguments
                        (list (simple-format #f "~s" port-event))))))))))))
  (sm:function
   (type "static void")
   (name "connect_ports")
   (formals (list (sm:formal (type (string-append container "&"))
                             (name "c"))))
   (statement
    (sm:compound*
     (cons*
      (sm:statement*
       "dzn::debug.rdbuf () && dzn::debug << c.dzn_meta.name << std::endl")
      (append
       (map trigger-in-event->assign (ast:out-triggers-in-events o))
       (append-map trigger-out-event->assign
                   (ast:out-triggers-out-events o))))))))

(define-method (main-event-map (o <component-model>) container)
  (define (provides->init port)
    (let* ((port-name (.name port))
           (system-port (simple-format #f "c.system.~a" port-name))
           (meta (simple-format #f "~a.dzn_meta.require" system-port)))
      (list
       (sm:assign (variable (simple-format #f "~a.component" meta))
                  (expression "nullptr"))
       (sm:assign (variable (simple-format #f "~a.meta" meta))
                  (expression "&c.dzn_meta"))
       (sm:assign (variable (simple-format #f "~a.name" meta))
                  (expression (simple-format #f "~s" port-name))))))
  (define (requires->init port)
    (let* ((port-name (.name port))
           (system-port (simple-format #f "c.system.~a" port-name))
           (meta (simple-format #f "~a.dzn_meta.provide" system-port))
           (requires (simple-format #f "~a.dzn_meta.require.component"
                                    system-port)))
      (list
       (sm:assign (variable (simple-format #f "~a.component" meta))
                  (expression "nullptr"))
       (sm:assign (variable (simple-format #f "~a.meta" meta))
                  (expression "&c.dzn_meta"))
       (sm:assign (variable (simple-format #f "~a.name" meta))
                  (expression (simple-format #f "~s" port-name)))
       (sm:assign (variable
                   (sm:call (name "c.dzn_runtime.performs_flush")
                            (arguments (list requires))))
                  (expression "flush")))))
  (define (formal->variable formal)
    (sm:variable (type (code:type-name formal))
                 (name (code:number-argument formal))
                 (expression (.name formal))))
  (define (void-provides-in->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (formals (ast:formal* trigger))
           (formals (code:number-formals formals))
           (arguments (map code:number-argument formals))
           (out-formals (filter (negate ast:in?) formals))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (port-return (simple-format #f "~a.return" port))
           (port-sm:return-string (simple-format #f "~s" port-return)))
      (sm:generalized-initializer-list*
       port-event-string
       (sm:function
        (captures '("&"))
        (statement
         (sm:compound*
          `(,(sm:call (name "c.match")
                      (arguments (list port-event-string)))
            ,@(map formal->variable out-formals)
            ,(sm:call (name (string-append "c.system." (code:event-name trigger)))
                      (arguments arguments))
            ,(sm:call (name "c.perform"))
            ,(sm:call (name "c.match")
                      (arguments (list port-sm:return-string))))))))))
  (define (typed-provides-in->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (formals (ast:formal* trigger))
           (formals (code:number-formals formals))
           (arguments (map code:number-argument formals))
           (out-formals (filter (negate ast:in?) formals))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (port-return (simple-format #f "~a.return" port))
           (port-sm:return-string (simple-format #f "~s" port-return))
           (port-prefix (simple-format #f "~a." port))
           (event-slot (string-append "c.system." (code:event-name trigger)))
           (invoke (sm:code->string (sm:call (name event-slot)
                                             (arguments arguments)))))
      (sm:generalized-initializer-list*
       port-event-string
       (sm:function
        (captures '("&"))
        (statement
         (sm:compound*
          `(,(sm:call (name "c.match")
                      (arguments (list port-event-string)))
            ,@(map formal->variable out-formals)
            ,(sm:variable (type "std::string")
                          (name "tmp")
                          (expression
                           (simple-format #f
                                          "~s + dzn::to_string (~a)" port-prefix invoke)))
            ,(sm:call (name "c.perform"))
            ,(sm:call (name "c.match")
                      (arguments (list "tmp"))))))))))
  (define (void-requires-in->init trigger)
    (let* ((port (.port.name trigger))
           (port-return (simple-format #f "~a.return" port))
           (port-sm:return-string (simple-format #f "~s" port-return))
           (port-prefix (simple-format #f "~a." port))
           (system-port (simple-format #f "c.system.~a" port)))
      (sm:generalized-initializer-list*
       port-sm:return-string
       (sm:function
        (captures '("&"))
        (statement
         (sm:compound*
          (sm:call (name "dzn::port_release")
                   (arguments
                    (list "c.dzn_locator"
                          "nullptr"
                          (string-append "&" system-port))))))))))
  (define (typed-in->init port-pair) ;; FIXME: get rid of port-pair?
    (let* ((port (.port port-pair))
           (other (.other port-pair))
           (port-other (simple-format #f "~a.~a" port other)))
      (sm:generalized-initializer-list*
       (simple-format #f "~s" port-other)
       (sm:function
        (captures '("&"))
        (statement
         (sm:compound*
          (sm:call (name "dzn::port_release")
                   (arguments
                    (list "c.dzn_locator"
                          "nullptr"
                          (simple-format #f "&c.system.~a" port))))))))))
  (define (out->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (formals (ast:formal* trigger)))
      (sm:generalized-initializer-list*
       port-event-string
       (sm:function
        (captures '("&"))
        (statement
         (sm:compound*
          (sm:call (name "c.match")
                   (arguments (list port-event-string)))
          (sm:call (name (string-append "c.system." (code:event-name trigger)))
                   (arguments (iota (length formals))))))))))
  (define (flush->init port)
    (let* ((port (.name port))
           (flush (simple-format #f "~a.<flush>" port))
           (flush-string (simple-format #f "~s" flush)))
      (sm:generalized-initializer-list*
       flush-string
       (sm:function
        (captures '("&"))
        (statement
         (sm:compound*
          (sm:call (name "c.match")
                   (arguments (list flush-string)))
          (sm:statement*
           (simple-format #f "std::clog << ~s << std::endl" flush))
          (sm:call
           (name "c.dzn_runtime.flush")
           (arguments
            (list
             (simple-format #f "c.system.~a.dzn_meta.require.component" port)
             (sm:call (name "dzn::coroutine_id")
                      (arguments (list "c.system.dzn_locator")))
             "false")))))))))
  (sm:function
   (type "static std::map<std::string, std::function<void ()> >")
   (name "event_map")
   (formals (list (sm:formal (type (string-append container "&"))
                             (name "c"))
                  (sm:formal (type "bool")
                             (name "flush"))))
   (statement
    (sm:compound*
     (append
      (append-map provides->init (ast:provides-port* o))
      (append-map requires->init (ast:requires-port* o))
      (list
       (sm:assign (variable (sm:call (name "c.dzn_runtime.performs_flush")
                                     (arguments (list "nullptr"))))
                  (expression "flush"))
       (sm:return*
        (sm:generalized-initializer-list
         (newline? #t)
         (initializers
          (cons*
           "{\"illegal\", []{std::clog << \"illegal\" << std::endl;}}"
           "{\"error\", []{std::clog << \"sut.error -> sut.error\" << std::endl; std::exit (0);}}"
           (append
            (map void-provides-in->init (ast:provides-in-void-triggers o))
            (map typed-provides-in->init (ast:provides-in-typed-triggers o))
            (map void-requires-in->init (code:blocking-requires-in-void-returns o))
            (map typed-in->init (code:blocking-return-values o))
            (map out->init (ast:requires-out-triggers o))
            (map flush->init (ast:requires-port* o))
            (map flush->init (ast:provides-port* o)))))))))))))

(define-method (main-getopt)
  (sm:function
   (type "static bool")
   (name "dzn_getopt")
   (formals (list (sm:formal (type "int") (name "argc"))
                  (sm:formal (type "char const*") (name "argv[]"))
                  (sm:formal (type "std::string") (name "option"))))
   (statement
    (sm:compound*
     (sm:return*
      (sm:not-equal*
       (sm:plus* "argv" "argc")
       (sm:call (name "std::find_if")
                (arguments
                 (list
                  (sm:plus* "argv" 1)
                  (sm:plus* "argv" "argc")
                  (sm:function (formals (list (sm:formal (type "char const*") (name "s"))))
                               (captures '("&option"))
                               (statement
                                (sm:compound* (sm:return* (sm:equal* "s" "option"))))))))))))))

(define-method (main (o <component-model>) container)
  (sm:function
   (name "main")
   (formals (list (sm:formal (type "int") (name "argc"))
                  (sm:formal (type "char const*") (name "argv[]"))))
   (statement
    (sm:compound*
     (let ((option (simple-format #f "~s" "--flush")))
       (sm:variable (type "bool") (name "flush")
                    (expression (sm:call (name "dzn_getopt")
                                         (arguments (list "argc" "argv" option))))))
     (let ((call-rdbuf (sm:call (name "std::clog.rdbuf")))
           (option (simple-format #f "~s" "--debug")))
       (sm:if* (sm:call (name "dzn_getopt") (arguments (list "argc" "argv" option)))

               (sm:call (name "dzn::debug.rdbuf")
                        (arguments (list call-rdbuf))
                        ;; (arguments (list (sm:call (name "std::clog.rdbuf"))))
                        )))
     (sm:statement* (simple-format #f "~a c" container))
     (sm:call (name "connect_ports") (arguments '("c")))
     (sm:call (name "dzn::check_bindings") (arguments '("c.system")))
     (sm:call (name "c") (arguments '("event_map (c, flush)")))))))


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
                      ,(sm:cpp-system-include* "dzn/runtime.hh")
                      ,(sm:namespace* "dzn"
                                      (sm:statement* "struct locator")
                                      (sm:statement* "struct runtime"))
                      ;; XXX DATA
                      ,(sm:cpp-system-include* "iostream")
                      ,(sm:cpp-system-include* "vector")
                      ,(sm:cpp-system-include* "map")
                      ,@(root->header-statements o)
                      ,@(append-map model->header-statements models)
                      ,(code:version-comment))))))
    (display header)))

(define-method (print-code-ast (o <root>))
  (let* ((models (code:model* o))
         (comment (dzn:comment o))
         (header (string-append (code:file-name o) ".hh"))
         (code (sm:code
                 (statements
                  `(,(code:generated-comment o)
                    ,@(if (not comment) '()
                          (list (sm:comment* comment)))
                    ,(sm:cpp-include* header)
                    ,(sm:cpp-system-include* "dzn/locator.hh")
                    ,(sm:cpp-system-include* "dzn/runtime.hh")
                    ,(sm:cpp-system-include* "iterator")
                    ,(sm:cpp-define* "STRINGIZING(x) #x")
                    ,(sm:cpp-define* "STR(x) STRINGIZING (x)")
                    ,(sm:cpp-define* "LOCATION __FILE__ \":\" STR (__LINE__)")
                    ,@(if (not (code:pump? o)) '()
                          (list (sm:cpp-system-include* "dzn/pump.hh")))
                    ,@(root->statements o)
                    ,@(append-map model->statements models)
                    ,(code:version-comment))))))
    (display code)))

(define-method (print-main-ast (o <component-model>))
  (let* ((header (string-append (code:file-name o) ".hh"))
         (container (simple-format
                     #f "dzn::container< ~a, std::function<void ()>>"
                     (code:type-name o)))
         (code (sm:code
                 (statements
                  `(,(code:generated-comment o)
                    ,(sm:cpp-include* header)
                    ,(sm:cpp-system-include* "dzn/container.hh")
                    ,(sm:cpp-system-include* "algorithm")
                    ,(sm:cpp-system-include* "cstring")

                    ,(main-connect-ports o container)
                    ,(main-event-map o container)
                    ,(main-getopt)
                    ,(main o container)
                    ,(code:version-comment))))))
    (display code)))
