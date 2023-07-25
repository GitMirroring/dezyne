;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2023 Rutger van Beusekom <rutger@dezyne.org>
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
             (type "std::string")
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
         (formals (code:formal* (.event o)))
         (event-name (.event.name o))
         (action-name (code:event-name o))
         (arguments (code:argument* o))
         (arguments (map c++:ast->expression arguments)))
    (sm:call (name (simple-format #f "dzn::call_~a" (.direction event)))
             (arguments
              `("this"
                ,(.port.name o)
                ,(simple-format #f "~s" event-name)
                ,(sm:function
                  (captures '("&"))
                  (statement
                   (sm:compound*
                    (sm:return*
                     (sm:call (name action-name)
                              (arguments arguments)))))))))))

(define-method (ast->code (o <assign>))
  (let* ((variable (.variable o))
         (var (c++:ast->expression variable))
         (expression (.expression o))
         (action? (is-a? expression <action>)))
    (if (not action?) (sm:assign* var (c++:ast->expression expression))
        (sm:assign* var (ast->code expression)))))

(define-method (ast->code (o <defer>))
  (define (variable->defer-variable o)
    (sm:variable
     (type (code:type-name (ast:type o)))
     (name (code:capture-name o))
     (expression (code:member-name o))))
  (define (variable->equality o)
    (sm:equal* (c++:ast->expression o)
               (code:capture-name o)))
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
                                (cons* "this"
                                       (map code:capture-name variables)))
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
             (out-binding (string-append (%member-prefix)
                                         (code:out-binding (.port o)))))
        (sm:statements*
         `(,@(if (is-a? type <void>) '()
                 `(,(sm:assign* (sm:member* (%member-prefix) (code:reply-var type))
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
         (sm:member* (%member-prefix) (code:out-binding (.port o)))
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
          (formals (code:formal* event)))
      (sm:variable
       (type (string-append "std::function< "
                            (sm:code->string
                             (sm:call (name type)
                                      (arguments (map c++:->formal formals))))
                            ">"))
       (name (.name event)))))
  (define (event->check-binding event)
    (let ((event-name (code:event-name event)))
      (sm:if* (sm:not* (sm:member* event-name))
              (sm:statement*
               (format #f "throw dzn::binding_error (this->dzn_meta, ~s)"
                       event-name)))))
  (let* ((public-enums (code:public-enum* o))
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
               ,(sm:variable (type "std::vector<char const*>") (name "dzn_prefix") (expression ""))
               ,(sm:variable (type "int") (name "dzn_state") (expression ""))
               ,(sm:variable (type (string-append name "*")) (name "dzn_peer") (expression ""))
               ,(sm:variable (type "bool") (name "dzn_busy") (expression ""))
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
      (simple-format #f "~s" (.value value)))

    (define (dzn:hash s h)
      (let ((overflow 4294967296)
            (b 47)
            (p 79))
        (car
         (fold
          (lambda (s h.pow)
            (string-fold
             (lambda (c h.pow)
               (let* ((c (- (char->integer c) b))
                      (h (car h.pow))
                      (pow (cdr h.pow))
                      (h (modulo
                          (+ h (modulo (* c pow) overflow))
                          overflow))
                      (pow (modulo (* pow p) overflow)))
                 (cons h pow)))
             h.pow s))
          (cons (* h p) 1) s))))

    (define (event->sm:switch-case transition interface-shared)
      (let* ((prefix (.prefix transition))
             (prefix (ast:statement* prefix))
             (initializer-list (sm:code->string
                                (sm:generalized-initializer-list*
                                 (map value->init prefix))))
             (state (simple-format #f "~a" (.to transition)))
             (assignments (and=>
                           (find
                            (compose (cute eq? (.to transition) <>)
                                     .state)
                            interface-shared)
                           (compose ast:statement* .assign)))
             (assignments (map ast->assign (or assignments '()))))
        (sm:switch-case
         (expression (string-append
                      (number->string
                       (dzn:hash (map .value prefix)
                                 (.from transition)))
                      "u"))
         (statement
          (sm:statements*
           (cons (sm:comment* (string-append
                               "//" (number->string (.from transition))
                               ":" (string-join (map .value prefix) ",")))
                 (if (.skip transition) `(,(sm:return*))
                     `(,(sm:assign* "dzn_state" state)
                       ,@assignments
                       ,(sm:break)))))))))

    (define (synchronize->member variable)
      (sm:assign*
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

    (let* ((interface
            (sm:struct
              (inherit interface)
              (methods
               `(,(sm:constructor (struct interface)
                                  (formals (list (sm:formal (type "dzn::port::meta const&")
                                                            (name "m"))))
                                  (statement
                                   (sm:compound*
                                    (if (= (dzn:debugity) 0) '()
                                        (sm:call (name "debug")
                                                 (arguments (list "\"ctor\"")))))))
                 ,(sm:destructor (struct interface)
                                 (type "virtual")
                                 (statement "= default;"))
                 ,@(if (= (dzn:debugity) 0) '()
                       `(,(sm:method
                           (struct interface) (type "void") (name "debug")
                           (formals (list (sm:formal (type "std::string&&") (name "label"))))
                           (statement
                            (sm:compound*
                             (sm:variable (type "std::string")
                                          (name "tmp")
                                          (expression
                                           (sm:conditional*
                                            "this->dzn_meta.provide.component"
                                            (sm:call (name "dzn::path")
                                                     (arguments '("this->dzn_meta.provide.meta")))
                                            (sm:call (name "dzn::path")
                                                     (arguments '("this->dzn_meta.require.meta"))))))
                             (sm:statement* "std::cout << tmp << \".\";")
                             (sm:assign* "tmp"
                                         (sm:conditional*
                                          (sm:call (name "this->dzn_meta.provide.name.size")
                                                   (arguments '()))
                                          "this->dzn_meta.provide.name"
                                          "this->dzn_meta.require.name"))
                             (sm:statement* "std::cout << tmp << \" \" << label << \": \" << dzn_state << \" prefix: \"")
                             (sm:call (name "std::copy")
                                      (arguments
                                       (list
                                        (sm:call (name "dzn_prefix.begin")
                                                 (arguments '()))
                                        (sm:call (name "dzn_prefix.end")
                                                 (arguments '()))
                                        (sm:call (name "std::ostream_iterator<std::string>")
                                                 (arguments '("std::cout" "\",\""))))))
                             (sm:statement* "std::cout << std::endl"))))))
                 ,@(if (%no-constraint?)
                       `(,(sm:method
                           (struct interface) (type "void") (name "dzn_event")
                           (formals (list (sm:formal (type "char const*") (name "event"))))
                           (statement
                            (sm:compound*)))
                         ,(sm:method
                           (struct interface) (type "void") (name "dzn_update_state")
                           (formals (list (sm:formal (type "dzn::locator const&")
                                                     (name "locator"))))
                           (statement
                            (sm:compound*))))
                       (let* ((shared (code:shared-state o))
                              (events (ast:event* o))
                              (transitions (append-map event->transitions events))
                              (transitions (delete-duplicates transitions ast:equal?))
                              (interface-shared (reverse (code:shared-state o))))
                         `(,(sm:method
                             (struct interface) (type "void") (name "dzn_event")
                             (formals (list (sm:formal (type "char const*") (name "event"))))
                             (statement
                              (sm:compound*
                               `(,(sm:if* (sm:not* "dzn_share_p") (sm:return*))
                                 ,(sm:call (name "dzn_prefix.push_back")
                                           (arguments '("event")))
                                 ,(sm:call (name "dzn_sync"))
                                 ,@(if (= (dzn:debugity) 0) '()
                                       `(,(sm:call (name "debug") (arguments '("\"dzn_event\"")))))))))
                           ,(sm:method
                             (struct interface) (type "void") (name "dzn_update_state")
                             (formals (list (sm:formal (type "dzn::locator const&")
                                                       (name "locator"))))
                             (statement
                              (sm:compound*
                               `(,(sm:if* (sm:not* "dzn_share_p") (sm:return*))
                                 ,@(if (= (dzn:debugity) 0) '()
                                       `(,(sm:call (name "debug") (arguments '("\"update_state\"")))))
                                 ,(sm:switch
                                   (expression
                                    (sm:call
                                     (name "dzn::hash")
                                     (arguments `("dzn_prefix" "dzn_state"))))
                                   (cases
                                    `(,@(map (cute event->sm:switch-case <>
                                                   interface-shared)
                                             transitions)
                                      ,(sm:switch-case
                                        (label "default")
                                        (statement
                                         (sm:statement* "locator.get<dzn::illegal_handler> ().handle (LOCATION)"))))))
                                 ,(sm:call (name "dzn_prefix.clear"))
                                 ,(sm:call (name "dzn_sync")))))))))
                 ,(sm:method
                   (struct interface) (type "void") (name "dzn_sync")
                   (statement
                    (sm:compound*
                     (sm:if* (sm:and* (sm:not-equal* "this->dzn_peer" "nullptr")
                                      (sm:not-equal* "this->dzn_peer" "this"))
                             (sm:compound*
                              `(,@(if (= (dzn:debugity) 0) '()
                                      `(,(sm:call (name "debug") (arguments '("\"sync\"")))))
                                ,(sm:assign* "dzn_peer->dzn_prefix" "this->dzn_prefix")
                                ,(sm:assign* "dzn_peer->dzn_state" "this->dzn_state")
                                ,(sm:assign* "dzn_peer->dzn_busy" "this->dzn_busy")
                                ,@(map (compose synchronize->member) (ast:member* o))))))))
                 ,(sm:method
                   (struct interface) (type "void") (name "dzn_check_bindings")
                   (statement
                    (sm:compound*
                     (append
                      (map event->check-binding (ast:in-event* o))
                      (map event->check-binding (ast:out-event* o))))))))))
           (connect
            (sm:function
             (name "connect")
             (type "void")
             (formals (list (sm:formal (type interface&) (name "provided"))
                            (sm:formal (type interface&) (name "required"))))
             (statement
              (sm:compound*
               (sm:assign* "provided.out" "required.out")
               (sm:assign* "required.in" "provided.in")
               (sm:assign* "provided.dzn_meta.require" "required.dzn_meta.require")
               (sm:assign* "required.dzn_meta.provide" "provided.dzn_meta.provide")
               (sm:assign* "provided.dzn_peer" "&required")
               (sm:assign* "required.dzn_peer" "&provided")
               (sm:assign* "provided.dzn_share_p" "required.dzn_share_p = provided.dzn_share_p && required.dzn_share_p")))))
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
                  #f "{{~s,&~a,this,&dzn_meta},{\"\",0,0,0}}" name name))))
  (define (requires->member port)
    (sm:variable
     (type (code:type-name (.type port)))
     (name (.name port))
     (expression (simple-format
                  #f
                  "{{\"\",0,0,0},{~s,&~a,this,&dzn_meta}}" name name))))
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
  (define (port->out-binding port)
    (sm:variable
     (type "std::function<void ()>")
     (name (code:out-binding port))))
  (define (type->reply-variable o)
    (sm:variable
     (type (code:type-name o))
     (name (code:reply-var o))))
  (define (port->injected-require-override port)
    (let* ((type (.type port))
           (type (code:type-name type)))
      (sm:assign* (sm:member* (%member-prefix)
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
                           (sm:member* (code:reply-var (ast:type trigger)))))
           (sm:call-slot (sm:call-method
                          (name (code:event-slot-name trigger))
                          (arguments arguments)))
           (sm:call-in/out
            (sm:call
             (name (string-append "dzn::wrap_" (code:direction event)))
             (arguments
              `("this"
                ,(sm:member* port-name)
                ,(sm:function
                  (captures (cons* "&" "this" in-arguments))
                  (statement
                   (sm:compound*
                    `(,@(map port->injected-require-override
                             (ast:injected-port* o))
                      ,(if (or (not typed?) (not (is-a? o <foreign>))) sm:call-slot
                           (sm:assign* reply-var sm:call-slot))
                      ,@(if
                         (ast:out? event) '()
                         `(,@(if
                              (is-a? o <foreign>) '()
                              `(,(sm:call
                                  (name "this->dzn_runtime.flush")
                                  (arguments
                                   (list
                                    "this"
                                    (sm:call (name "dzn::coroutine_id")
                                             (arguments '("this->dzn_locator"))))))
                                ,(sm:if* out-binding (sm:call (name out-binding)))
                                ,(sm:assign* out-binding "nullptr")))
                           ,(sm:return (expression reply-var))))))))
                ,event-name-string)))))
      (sm:assign*
       (code:event-name trigger)
       (sm:function
        (captures '("this"))
        (formals formals)
        (statement
         (sm:compound*
          (sm:return* sm:call-in/out)))))))
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
      (sm:method (struct component)
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
                                 ""
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
               ,@(if (is-a? o <foreign>) '()
                     (map port->out-binding (ast:provides-port* o)))
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
                   `(,@(map requires->external (filter ast:external? (ast:requires-port* o)))
                     ,@(if (is-a? o <foreign>) '()
                           `(,(requires->assignment (ast:requires-port* o))
                             ,@(append-map injected->assignments
                                           (ast:injected-port* o))
                             ,(sm:assign* (sm:member* "dzn_runtime.performs_flush (this)")
                                          "true")))
                     ,@(map trigger->event-slot (ast:in-triggers o))))))
               ,@(if (not (is-a? o <foreign>)) '()
                     (list
                      (sm:destructor (struct component)
                                     (type "virtual")
                                     (statement (sm:compound*)))))
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
       ,@(component-model->statements o)))))

(define-method (model->statements (o <component>))
  (component-model->statements o))


;;;
;;; Foreign.
;;;
(define-method (model->foreign (o <foreign>))
  (component-model->statements o))

(define-method (model->header-statements (o <foreign>))
  (let* ((interface-includes (code:interface-include* o))
         (statements `(,(sm:cpp-system-include* "dzn/locator.hh")
                       ,(sm:cpp-system-include* "dzn/runtime.hh")
                       ,@(map c++:file-name->include interface-includes)
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
      (let* ((other-end (ast:other-end-point port)))
        (sm:assign*
         (string-append (.instance.name other-end)
                        "."
                        (.port.name other-end)
                        (if (ast:provides? port) ".dzn_meta.require.name"
                            ".dzn_meta.provide.name"))
         (simple-format #f "~s" (.name port)))))
    (define (provides->member port)
      (let* ((other-end (ast:other-end-point port)))
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
          ,(sm:assign* (string-append meta "name") name-string)
          ,@(if (not (injected-instance? instance)) '()
                (let ((meta (simple-format #f "~a.~a.dzn_meta." name port-name)))
                  (list
                   (sm:assign* (string-append meta "require.name")
                               name-string)))))))
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
             (sm:call-action (sm:call (name
                                       (string-append
                                        (code:event-name trigger)))
                                      (arguments arguments)))
             (type (ast:type event))
             (type (code:type-name type))
             (typed? (ast:typed? event)))
        (sm:assign*
         (string-append
          (.instance.name other-end)
          "."
          (.port.name other-end)
          "."
          (code:event-name event))
         (sm:call (name "std::ref")
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
                                   ""
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
                                      "locator.clone ()"
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
                     ,@(append-map instance->assignments instances)
                     ,@(map code:binding->connect bindings)
                     ,@(map trigger->event-slot (ast:provides-out-triggers o))
                     ,@(map trigger->event-slot (ast:requires-in-triggers o)))))))))))
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
    (define (port->external port)
      (sm:assign*
       (simple-format
        #f "~a.dzn_share_p" (.name port))
       "false"))
    (define (provides->member port)
      (let* ((other-end (ast:other-end-point port)))
        (sm:variable
         (type (string-join (cons "" (ast:full-name (.type port))) "::"))
         (name (.name port))
         (expression (sm:member*
                      (string-append (.instance.name other-end)
                                     "."
                                     (.port.name other-end)))))))
    (define (requires->member port)
      (let ((other-end (ast:other-end-point port)))
        (sm:variable
         (type (string-join (cons "" (ast:full-name (.type port))) "::"))
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
             (formals (code:formal* trigger))
             (arguments (map .name formals))
             ;; (out-formals (filter (negate ast:in?) formals))
             ;; (out-arguments (map .name out-formals))
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
             (formals- (code:formal* trigger))
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
                                   ""
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
                                      "locator.clone ()"
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
           (formals (code:formal* trigger))
           (formals (map (cute clone <> #:name #f) formals))
           (formals (map c++:->formal formals))
           (system-port (string-append "c.system." port))
           (meta (string-append system-port ".dzn_meta"))
           (port-event (string-append port "." event))
           (function
            (sm:function
             (captures '("&"))
             (formals formals)
             (statement
              (sm:compound*
               (sm:call (name "c.match")
                        (arguments
                         (list (simple-format #f "~s" port-event))))
               (sm:call (name "dzn::port_block")
                        (arguments
                         (list "c.dzn_locator" "nullptr"
                               (simple-format #f "&c.system.~a" port))))
               (sm:variable (type "std::string")
                            (name "tmp")
                            (expression
                             (sm:call (name "c.trail_expect"))))
               (sm:variable (type "size_t")
                            (name "pos")
                            (expression "tmp.rfind ('.')+1"))
               (sm:assign (variable "tmp")
                          (expression "tmp.substr (pos)"))
               (sm:return* (return-expression trigger)))))))
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
           (formals (map (cute clone <> #:name #f) formals))
           (formals (map c++:->formal formals))
           (port (.port trigger)))
      (sm:assign (variable (string-append "c.system." (code:event-name trigger)))
                 (expression
                  (sm:function
                   (captures '("&"))
                   (formals formals)
                   (statement
                    (sm:compound*
                     (sm:call (name "c.match")
                              (arguments
                               (list (simple-format #f "~s" port-event)))))))))))
  (sm:function
   (type "static void")
   (name "connect_ports")
   (formals (list (sm:formal (type (string-append container "&"))
                             (name "c"))))
   (statement
    (sm:compound*
     (cons*
      (sm:statement* "dzn::debug.rdbuf () && dzn::debug << c.dzn_meta.name << std::endl")
      (append
       (map trigger-in-event->assign (ast:out-triggers-in-events o))
       (map trigger-out-event->assign (ast:out-triggers-out-events o))))))))

(define-method (main-event-map (o <component-model>) container)
  (define (provides->init port)
    (let* ((port-name (.name port))
           (system-port (simple-format #f "c.system.~a" port-name))
           (meta (simple-format #f "~a.dzn_meta.require" system-port)))
      (list
       (sm:assign (variable (simple-format #f "~a.component" meta))
                  (expression "&c"))
       (sm:assign (variable (simple-format #f "~a.meta" meta))
                  (expression "&c.dzn_meta"))
       (sm:assign (variable (simple-format #f "~a.name" meta))
                  (expression (simple-format #f "~s" port-name))))))
  (define (requires->init port)
    (let* ((port-name (.name port))
           (system-port (simple-format #f "c.system.~a" port-name))
           (meta (simple-format #f "~a.dzn_meta.provide" system-port)))
      (list
       (sm:assign (variable (simple-format #f "~a.component" meta))
                  (expression "&c"))
       (sm:assign (variable (simple-format #f "~a.meta" meta))
                  (expression "&c.dzn_meta"))
       (sm:assign (variable (simple-format #f "~a.name" meta))
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
           (port-sm:return-string (simple-format #f "~s" port-return)))
      (define (formal->variable formal)
        (sm:variable (type "int")
                     (name (code:number-argument formal))
                     (expression (.name formal))))
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
            ,(sm:call (name "c.match")
                      (arguments (list port-sm:return-string))))))))))
  (define (typed-provides-in->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (port-return (simple-format #f "~a.return" port))
           (port-sm:return-string (simple-format #f "~s" port-return))
           (port-prefix (simple-format #f "~a." port))
           (event-slot (string-append "c.system." (code:event-name trigger)))
           (formals (code:formal* trigger))
           (invoke (sm:code->string (sm:call (name event-slot)
                                             (arguments (iota (length formals)))))))
      (sm:generalized-initializer-list*
       port-event-string
       (sm:function
        (captures '("&"))
        (statement
         (sm:compound*
          (sm:call (name "c.match")
                   (arguments (list port-event-string)))
          (sm:variable (type "std::string")
                       (name "tmp")
                       (expression
                        (simple-format #f
                                       "~s + dzn::to_string (~a)" port-prefix invoke)))
          (sm:call (name "c.match")
                   (arguments (list "tmp")))))))))
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
                          "&c.system"
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
                          "&c.system"
                          (simple-format #f "&c.system.~a" (.port port-pair)))))))))))
  (define (out->init trigger)
    (let* ((port (.port.name trigger))
           (event (.event.name trigger))
           (port-event (simple-format #f "~a.~a" port event))
           (port-event-string (simple-format #f "~s" port-event))
           (formals (code:formal* trigger)))
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
          (sm:call (name "c.dzn_runtime.flush")
                   (arguments (list "&c")))))))))
  (sm:function
   (type "static std::map<std::string, std::function<void ()> >")
   (name "event_map")
   (formals (list (sm:formal (type (string-append container "&"))
                             (name "c"))))
   (statement
    (sm:compound*
     (append
      (append-map provides->init (ast:provides-port* o))
      (append-map requires->init (ast:requires-port* o))
      (list
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
            (map void-requires-in->init (code:requires-in-void-returns o))
            (map typed-in->init (code:return-values o))
            (map out->init (ast:requires-out-triggers o))
            (map flush->init (ast:requires-port* o))
            (map flush->init (ast:provides-port* o)))))))))))))

(define-method (main-getopt)
  (sm:function
   (type "static bool")
   (name "getopt")
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
                    (expression (sm:call (name "getopt")
                                         (arguments (list "argc" "argv" option))))))
     (let ((call-rdbuf (sm:call (name "std::clog.rdbuf")))
           (option (simple-format #f "~s" "--debug")))
       (sm:if* (sm:call (name "getopt") (arguments (list "argc" "argv" option)))

               (sm:call (name "dzn::debug.rdbuf")
                        (arguments (list call-rdbuf))
                        ;; (arguments (list (sm:call (name "std::clog.rdbuf"))))
                        )))
     (sm:call (name (simple-format #f "~a c" container))
              (arguments '("flush")))
     (sm:call (name "connect_ports") (arguments '("c")))
     (sm:call (name "c") (arguments '("event_map (c)")))))))


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
                      ,(sm:cpp-system-include* "dzn/meta.hh")
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
