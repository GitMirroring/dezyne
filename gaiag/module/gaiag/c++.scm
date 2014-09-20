;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(read-set! keywords 'prefix)

(define-module (gaiag c++)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 rdelim)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag indent)
  :use-module (gaiag mangle)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (ast->
           animate-template
           enum-type
           c++-module
           c++:gom
           c++:import
           string-if))

(define (ast-> ast)
  (let* ((gom ((gom:register c++:gom) ast #t)))
    (map dump ((gom:filter <model>) gom)))
  "")

(define (c++:import name)
  (gom:import name c++:gom))

(define (c++:gom ast)
  ((compose mangle ast:resolve ast->gom) ast))

(define (mangle o)
  (if #f
      o
      (parameterize ((mangle-prefix-alist '((port . po) (instance . is)))) (gom:mangle o))))

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define (dump-indented file-name thunk)
  (dump-output file-name (lambda () (pipe thunk (lambda () (indent))))))

(define-method (dump (o <interface>))
  (let ((name (.name o)))
    (dump-indented (symbol-append 'interface- name '-c3.hh)
                   (lambda ()
                     ((animate-template 'interface.c3.hh.scm) (c++-module o))))))

(define-method (dump (o <component>))
  (let ((name (.name o))
        (interfaces (map c++:import (map .type ((compose .elements .ports) o)))))
    (dump-indented (symbol-append 'component- name '-c3.hh)
                   (lambda ()
                     ((animate-template 'component.c3.hh.scm) (c++-module o))))
    (and (.behaviour o)
     (dump-indented (symbol-append 'component- name '-c3.cc)
                    (lambda ()
                      ((animate-template 'component.c3.cc.scm) (c++-module o)))))))

(define-method (dump (o <system>))
  (let ((name (.name o))
        (interfaces (map c++:import (map .type ((compose .elements .ports) o)))))
    (dump-indented (symbol-append 'component- name '-c3.hh)
                   (lambda ()
                     ((animate-template 'system.c3.hh.scm) (c++-module o))))
    (dump-indented (symbol-append 'component- name '-c3.cc)
                   (lambda ()
                     ((animate-template 'system.c3.cc.scm) (c++-module o))))))

(define ((animate-template file-name) module)
  (animate-file (append (prefix-dir) (list 'templates file-name)) module))

(define-method (c++-module)
  (make-module 31 (list
                   (resolve-module '(ice-9 match))
                   (resolve-module '(gaiag c++))
                   (resolve-module '(gaiag misc)))))

(define-method (c++-module (o <interface>))
  (let* ((module (c++-module)))
    (module-define! module 'model o)
    (module-define! module '.interface (.name o))
    (module-define! module '.INTERFACE (string-upcase (symbol->string (.name o))))
    (module-define! module '.model (.name o))
    module))

(define-method (c++-module (o <model>))
  (let ((module (c++-module)))
    (module-define! module 'model o)
    (module-define! module '.component (.name o))
    (module-define! module '.COMPONENT (string-upcase (symbol->string (.name o))))
    (module-define! module '.model (.name o))
    module))

(define-method (declare-replies (o <interface>))
  (map (lambda (x) (->string (list "interface::"  (.name o) "::" (.name x) "::type reply_" (.name o) "_" (.name x) ";\n"))) (gom:interface-enums o)))

(define (scope-type o)
  (match o
    (($ <expression> ($ <literal> scope type field)) (->string (list "interface::" scope)))))

(define (enum-type o)
  (match o
    (($ <expression> ($ <literal> scope type field)) (->string (list (scope-type o) "::" type)))))

(define (declare-enum enum)
  (->string (list "struct " (.name enum) "\n{\nenum type\n{\n" (comma-nl-join (.elements (.fields enum))) ",\n};\n};\n")))

(define (declare-integer integer)
  (->string (list "typedef int " (.name integer) ";\n")))

(define statements.src (make-parameter #f))
(define statements.port (make-parameter #f))
(define statements.event (make-parameter #f))

(define* (statements->string model src :optional (locals '()) (compound? #t))

  ;; FIXME: c&p (resolve-model-)
  (define (member? identifier)
    (find (lambda (m) (eq? (.name m) identifier)) (gom:variables model)))

  (define (local? identifier) (assoc-ref locals identifier))

  (define (var? identifier) (or (member? identifier) (local? identifier)))

  (define (enum-type o)
    (match o
      (($ <expression> ($ <literal> scope type field)) (->string (list scope "_" type)))
      (($ <expression> ($ <var> name))
       (or (and-let* ((decl (var? name))
                      (type (.type decl)))
                     (list (.scope type) "_" (.name type)))
           ""))))

  (define (enum? identifier)
    (member identifier (map .name (gom:enums model))))

  (let ((port (statements.port))
        (event (statements.event)))
    (->string
     (match src
       (() "")

       (($ <guard> expression statement)
        (list (parameterize ((statements.src src))
                (expr->clause model expression))
              "\n" (statements->string model statement locals)))
       (($ <if> expression then ($ <statement> '()))
        (list "if (" (expression->string model expression locals) ")\n" (statements->string model then locals)))
       (($ <if> expression then #f) ;; FIXME
        (list "if (" (expression->string model expression locals) ")\n" (statements->string model then locals)))
       (($ <if> expression then else)
        (list "if (" (expression->string model expression locals) ")\n" (statements->string model then locals) "else\n" (statements->string model else locals)))
       (($ <assign> name (and ($ <action>) (get! action)))
        (list name " = " (statements->string model (action) locals)))
       (($ <assign> identifier expression)
        (list (statements->string model identifier locals) " = " (expression->string model expression locals) ";\n"))
       (($ <on> triggers statement)
        (if (find (lambda (t) (and (eq? (.port t) (.name port))
                                   (eq? (.event t) (.name event))))
                  (.elements triggers))
            (statements->string model statement locals)
            ""))
       (($ <call> function ($ <arguments> '())) (list function "();\n"))
       (($ <call> function ($ <arguments> arguments))
        (let ((arguments ((->join ", ") (map (lambda (o) (expression->string model o locals)) arguments))))
          (list function  "(" arguments ");\n")))

       ;; c&p resolve/CSP/
       (($ <compound> statements)
        (list (if compound? "{\n")
              (let loop ((statements statements) (locals locals))
                (if (null? statements)
                    '()
                    (let* ((statement (car statements))
                           (locals (match statement
                                     (($ <variable> name type expression)
                                      (acons name statement locals))
                                     (_ locals))))
                      (let ((str (statements->string model (car statements) locals compound?)))
                        (cons str (loop (cdr statements) locals))))))
              (if compound? "\n}\n")))
       (($ <illegal>) "//illegal")
       (($ <action> trigger)
        (let* ((port-name (.port trigger))
               (event-name (.event trigger))
               (port (gom:port model port-name))
               (name (.type port))
               (interface (c++:import name))
               (event (gom:event interface event-name)))
          (list port-name '. (.direction event) '. event-name "();\n")))
       (($ <reply> expression)
        (let* ((type (enum-type expression)))
          (statements->string
           model
           (list "reply_" type " = " (expression->string model expression locals) ";\n")
           locals)))
       (($ <return> #f)
        "return;\n")
       (($ <return> expression)
        (list 'return " " (expression->string model expression locals) ";\n"))
       (($ <signature> type)
        (list (if (and (not (.scope type)) (enum? (.name type)))
                  (list (.name model) "::"))
              (statements->string model type locals)))
       (($ <type> name #f) (if (enum? name) (->string (list name "::type")) name))
       (($ <type> name scope) (list "interface::" scope "::" name "::type"))
       (($ <variable> name type (and ($ <action>) (get! action)))
        (statements->string model (list type " " name " = " (statements->string model (action))) locals))
       (($ <variable> name type expression)
        (statements->string model (list type " " name " = " (expression->string model expression locals) ";\n") locals))
       (($ <parameters> parameters)
        ((->join ", ") (map (lambda (x) (statements->string model x)) parameters)))
       (($ <gom:parameter> name type)
        (list (statements->string model type) " " name))
       ((? char?) (make-string 1 src))
       ((? string?) src)
       ((? symbol?) src)
       (#t 'true)
       (#f 'false)
       ((h t ...) (map (lambda (x) (statements->string model x locals)) src))
       (_ (throw 'match-error (format #f "~a:c++:statements->string: no match: ~a\n" (current-source-location) src)))))))

(define (expr->clause model expression)
    (let* ((c-expression (bool-expression->string model expression))
         (if-clause (list "    if (" c-expression ")"))
         (else-if-clause (list "    else if (" c-expression ")"))
         (else-clause "    else")
         (guards ((compose .elements .statement .behaviour) model))
         (first? (eq? (statements.src) (car guards)))
         (top? (find (lambda (guard) (eq? guard (statements.src))) guards)))
      (->string (list (if (is-a? expression <otherwise>) else-clause
                        (if (or first? (not top?)) if-clause else-if-clause))))))

(define (bool-expression->string model o)
  (match o
    (($ <field> identifier field)
     (list "(" identifier " == " field ")"))
    (($ <literal> scope type field) (->string (list type "." field)))
    (_ (expression->string model o))))

;; FIXME: c&p from csp.scm
(define* (expression->string model o :optional (locals '()))

  (define (paren expression)
    (list "(" (expression->string model expression locals) ")"))

  ;; FIXME: c&p (resolve-model-)
  (define (member? identifier)
    (find (lambda (m) (eq? (.name m) identifier)) (gom:variables model)))

  (define (local? identifier) (assoc-ref locals identifier))

  (define (var? identifier) (or (member? identifier) (local? identifier)))

  (define (enum-type o)
    (or (and-let* ((decl (var? o))
                   (type (.type decl))
                   (scope (if (.scope type) (list (.scope type) "::"))))
                  (list scope (.name type) "::"))
        ""))

  (match o
    (($ <expression>) (expression->string model (.value o) locals))
    (($ <var> identifier) identifier)
    (($ <field> identifier field)
     (list identifier " == " (enum-type identifier) field))

    (($ <call> function ($ <arguments> '())) (->string (list function "()")))
    (($ <call> function ($ <arguments> arguments))
     (let ((arguments ((->join ", ") (map (lambda (o) (expression->string model o locals)) arguments))))
       (->string (list function  "(" arguments ")"))))

    (($ <literal> #f type field) (list type "::" field))
    (($ <literal> scope type field)
     (->string (list "interface::" scope "::" type "::" field)))
    ((? number?) (number->string o))
    ((? string?) o)
    ((? symbol?) o)
    (('! expression)
     (->string (list "! " (paren expression))))

    (('group expression) (paren expression))

    (('or lhs rhs) (let ((lhs (expression->string model lhs locals))
                         (rhs (expression->string model rhs locals)))
                     (list "(" lhs " " 'or " " rhs ")")))

    (((or 'and '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (expression->string model lhs locals))
           (rhs (expression->string model rhs locals))
           (op (car o)))
       (list lhs " " op " " rhs )))

    (_ (format #f "~a:no match: ~a" (current-source-location) o))))

(define (return-type-text port)
  (or (and-let* ((event (null-is-#f (gom:typed? port))))
                (.type (.type (car event))))
      'void))

;;;; MAPPERS
(define-syntax string-if
  (syntax-rules ()
    ((_ condition then)
     (animate-string (if (null-is-#f condition) then "") (current-module)))
    ((_ condition then else)
     (animate-string (if (null-is-#f condition) then else) (current-module)))))

(define* (map-ports string ports :optional (separator ""))
  ((->join separator)
   (map (lambda (port)
          (with-output-to-string
            (lambda ()
              (let* ((model (module-ref (current-module) 'model))
                     (module (c++-module model)))
                (save-module-excursion
                 (lambda ()
                   (animate-string
                    string
                    (animate-module-populate
                     module
                     port
                     `((port . ,identity)
                       (.interface-name . ,.type)
                       (.port-name . ,.name)
                       (.type . ,return-type-text)
                       ))))))))) ;; FIXME-other

        ports)))


(define* (map-instances string instances :optional (separator ""))
  ((->join separator)
   (map (lambda (instance)
          (with-output-to-string
            (lambda ()
              (let* ((model (module-ref (current-module) 'model))
                     (module (c++-module model)))
                (save-module-excursion
                 (lambda ()
                   (animate-string
                    string
                    (animate-module-populate
                     module
                     instance
                     `((instance . ,identity)
                       (.component . ,.component)
                       (.name . ,.name))))))))))
          instances)))

(define (binding-name model bind)
  (let ((instance (gom:instance model bind))
        (port (gom:port model bind)))
    (list
     (match instance
       (($ <instance>) (.name instance))
       (($ <interface>) (.name instance))
       )
     "."
     (match port
       (($ <gom:port>) (.name port))
       (($ <interface>) (list "x" (.name port)))))))

(define (bind-port? bind)
  (or (not (.instance (.left bind))) (not (.instance (.right bind)))))

(define* (map-binds string binds :optional (separator ""))
  ((->join separator)
   (map (lambda (bind)
          (with-output-to-string
            (lambda ()
              (let* ((model (module-ref (current-module) 'model))
                     (module (c++-module model))
                     (left (.left bind))
                     (left-port (gom:port model left))
                     (right (.right bind))
                     (provided-required (if (gom:provides? left-port) (cons left right) (cons right left)))
                     (provided (binding-name model (car provided-required)))
                     (required (binding-name model (cdr provided-required))))
                (save-module-excursion
                 (lambda ()
                   (animate-string
                    string
                    (animate-module-populate
                     module
                     bind
                     `(
                       (.provided . ,provided)
                       (.required . ,required)
                       (.port-name . ,(and (bind-port? bind) (if (not (.instance left)) (.port left) (.port right))))
                       (.instance . ,(and (bind-port? bind) (if (not (.instance left)) (binding-name model right) (binding-name model left))))
                       )))))))))
        binds)))

(define (map-events string events)
  (map (lambda (event)
         (save-module-excursion
          (lambda ()
            (animate-string
             string
             (animate-module-populate
              (current-module)
              event
              `((.type . ,(compose .type .type))
                (.event-name . ,.name))))))) events))

(define (map-port-events string port events)
  (map (lambda (event)
         (save-module-excursion
          (lambda ()
            (let* ((model (module-ref (current-module) 'model))
                   (port (module-ref (current-module) 'port))
                   (type ((compose .type .type) event))
                   (reply-type (lambda (event) (->string (list (.type port) "_" (.name type)))))
                   (return-interface-type (lambda (event)
                                            (->string (if (not (eq? 'void (.name type)))
                                                          (list "interface" "::" (.type port) "::" (.name type) "::type")
                                                          'void)))))
              (animate-string
               string
               (animate-module-populate
                (current-module)
                event
                `((event . ,identity)
                  (.type- . ,(compose .type .type))
                  (.reply-type . ,reply-type)
                  (.event-name . ,.name)
                  (.statement- .
                              ,(or (and-let* (((is-a? model <component>))
                                              (component model)
                                              (behaviour (.behaviour component))
                                              (statement (.statement behaviour)))
                                             (lambda (event)
                                               (parameterize ((statements.port port)
                                                              (statements.event event))
                                                 (statements->string model statement '() #f))))
                                   ""))
                  (.return-interface-type . ,return-interface-type))))))))
         events))

(define (map-functions string functions)
  (map (lambda (function)
         (save-module-excursion
          (lambda ()
            (let* ((model (module-ref (current-module) 'model))
                   (signature (.signature function))
                   (parameters (.parameters signature))
                   (statement (.statement function))
                   (locals (map (lambda (x) (cons (.name x) x)) (.elements parameters))))
              (animate-string
               string
               (animate-module-populate
                (current-module)
                function
                `((.function . ,.name)
                  (.return-type . ,(statements->string model signature))
                  (.parameters- . ,(statements->string model parameters))
                  (.statements . ,(statements->string model statement locals)))))))))
       functions))

(define* (map-variables string variables :optional (separator ""))

  (define (enum? identifier)
    (let ((model (module-ref (current-module) 'model)))
      (member identifier (map .name (gom:enums model)))))

  ((->join separator)
   (map (lambda (variable)
          (with-output-to-string
            (lambda ()
              (save-module-excursion
               (lambda ()
                 (let ((model (module-ref (current-module) 'model))
                       (type (.type variable)))
                  (animate-string
                   string
                   (animate-module-populate
                    (current-module)
                    variable
                    `((.variable . ,.name)
                      (.type- . ,(if (enum? (.name type))
                                     (->string (list (.name type) "::type"))
                                     (.name type)))
                      (.scope- . ,(if (enum? (.name type)) (->string (list (.name type) "::"))))
                      (.value . ,(expression->string model (.expression variable))))))))))))
        variables)))

(define (action port event) "enable")
