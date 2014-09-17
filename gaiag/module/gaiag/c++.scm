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

(define *ast* '())

(define (ast-> ast)
  (let* ((gom ((gom:register c++:gom) ast #t)))
    (set! *ast* gom)
    (and=> (gom:interface gom) dump)
    (and=> (gom:component gom) dump)
    (and=> (gom:system gom) dump))
  "")

(define (c++:import name)
  (gom:import name c++:gom))

(define (c++:gom ast)
  ((compose mangle ast:resolve ast->gom) ast))

(define (mangle o)
  (if #f
      o
      (parameterize ((mangle-prefix-alist '((port . po)))) (gom:mangle o))))

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
    (dump-indented (symbol-append 'component- name '-c3.cc)
                   (lambda ()
                     ((animate-template 'component.c3.cc.scm) (c++-module o))))))

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
    (module-define! module '.interface (.type (gom:port o)))
    (module-define! module '.model (.name o))
    module))

(define-method (declare-replies (o <interface>))
  (map (lambda (x) (->string (list "interface::"  (.name o) "::" (.name x) " reply_" (.name x) ";\n"))) (gom:interface-enums o)))

(define (scope-type o)
  (match o
    (($ <expression> ($ <literal> scope type field)) (->string (list "interface::" scope)))))

(define (enum-type o)
  (match o
    (($ <expression> ($ <literal> scope type field)) (->string (list (scope-type o) "::" type)))))

(define (declare-enum enum)
  (->string (list "enum "  (.name enum) "\n  {\n  " (comma-nl-join (.elements (.fields enum))) ",\n  };\n")))

(define (declare-reply enum)
  (->string (list (enum-type enum) " reply_" (.name enum))))

(define (declare-integer integer)
  (->string (list "typedef int " (.name integer) ";\n")))

(define statements.src (make-parameter *ast*))
(define statements.port (make-parameter #f))
(define statements.event (make-parameter #f))

(define* (statements->string src :optional (compound? #t))

  (define (enum-type o)
    (match o
      (($ <expression> ($ <literal> scope type field)) (->string type))))

  (define (scope-type o)
    (match o
      (($ <expression> ($ <literal> scope type field)) (->string (list "interface::" scope)))))

  ;; (stderr "statements->string: ~a\n" src)
  (let ((port (statements.port))
        (event (statements.event)))
    (match src
      (() "")

      (($ <guard> expression statement)
       (->string (list
                            (parameterize ((statements.src src))
                              (expr->clause expression))
                            "\n" (statements->string statement))))
      (($ <if> expression statement ($ <statement> '()))
       (->string (list "if (" (expression->string expression) ")\n" (statements->string statement))))
      (($ <if> expression statement #f) ;; FIXME
       (->string (list "if (" (expression->string expression) ")\n" (statements->string statement))))
      (($ <if> expression statement else)
       (->string (list "if (" (expression->string expression) ")\n" (statements->string statement) "else\n" (statements->string else))))
      (($ <assign> identifier expression)
       (->string (list (statements->string identifier) " = " (expression->string expression) ";\n")))
      (($ <on> triggers statement)
       (if (find (lambda (t) (and (eq? (.port t) (.name port))
                                  (eq? (.event t) (.name event))))
                 (.elements triggers))
           (statements->string statement)
           ""))
      (($ <call> function ($ <arguments> '())) (->string (list function "();\n")))
      (($ <call> function ($ <arguments> arguments))
       (let ((arguments ((->join ", ") (map expression->string arguments))))
         (->string (list function  "(" arguments ");\n"))))

      (($ <compound> elements)
       (let ((statements (map statements->string elements)))
        (if compound?
            (->string (list "{\n" statements "\n}\n"))
            (->string statements))))
      (($ <illegal>) "//illegal")
      (($ <action> trigger)
       (let* ((port-name (.port trigger))
              (event-name (.event trigger))
              (port (gom:port (gom:component *ast*) port-name))
              (name (.type port))
              (interface (c++:import name))
              (event (gom:event interface event-name)))
         (->string (list port-name '. (.direction event) '. event-name "();\n"))))
      (($ <reply> expression)
       (let ((type (enum-type expression))
             (scope (scope-type expression)))
         (->string (list "reply_" type " = "  scope "::" (expression->string expression) ";\n"))))
      (($ <return> #f)
       "return;\n")
      (($ <return> expression)
       (->string (list 'return " " (expression->string expression) ";\n")))
      (($ <variable> name type expression)
       (->string (list (gom:name type) " " name " = " (expression->string expression) ";\n")))
      ((? char?) (make-string 1 src))
      ((? string?) src)
      ((? symbol?) (symbol->string src))
      (#t 'true)
      (#f 'false)
      (_ (stderr "~a: NO MATCH: ~a\n" (current-source-location) src) ""))))

(define (expr->clause expression)
    (let* ((c-expression (bool-expression->string expression))
         (if-clause (list "    if (" c-expression ")"))
         (else-if-clause (list "    else if (" c-expression ")"))
         (else-clause "    else")
         (guards ((compose .elements .statement .behaviour gom:component) *ast*))
         (first? (eq? (statements.src) (car guards)))
         (top? (find (lambda (guard) (eq? guard (statements.src))) guards)))
      (->string (list (if (is-a? expression <otherwise>) else-clause
                        (if (or first? (not top?)) if-clause else-if-clause))))))

(define (bool-expression->string ast)
  (match ast
    (($ <field> identifier field)
     (list "(" identifier " == " field ")"))
    (($ <literal> scope type field) (->string (list type "." field)))
    (_ (expression->string ast))))

;; FIXME: c&p from csp.scm
(define (expression->string ast)

  (define (paren expression)
    (list "(" (expression->string expression) ")"))

  (match ast
    (($ <expression>) (expression->string (.value ast)))
    (($ <var> identifier) identifier)
    (($ <field> identifier field)
     (list identifier " == " field))

    (($ <call> function ($ <arguments> '())) (->string (list function "()")))
    (($ <call> function ($ <arguments> arguments))
     (let ((arguments ((->join ", ") (map expression->string arguments))))
       (->string (list function  "(" arguments ")"))))

    (($ <literal> scope type field) field)
    ((? number?) (number->string ast))
    ((? string?) ast)
    ((? symbol?) ast)
    (('! expression)
     (->string (list "! " (paren expression))))

    (('group expression) (paren expression))

    (('or lhs rhs) (let ((lhs (expression->string lhs))
                         (rhs (expression->string rhs)))
                     (list "(" lhs " " 'or " " rhs ")")))

    (((or 'and '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (expression->string lhs))
           (rhs (expression->string rhs))
           (op (car ast)))
       (list lhs " " op " " rhs )))

    (_ (format #f "~a:no match: ~a" (current-source-location) ast))))

(define (parameter->string parameter)
  (->string (list (gom:name (.type parameter)) " " (.name parameter))))

(define (value->string value)
  (let ((comp-name (.name (gom:component *ast*))))
    (double-colon-join
     (list comp-name (.type value) (.field value)))))

(define (return-type-text port)
  (or (and-let* ((event (null-is-#f (gom:typed? port))))
                (.type (.type (car event))))
      'void))

(define (return-interface-type interface event)
  (or (and (gom:typed? event) (list "interface::" interface "::" (cadr (.type (.type event)))))
      'void))

(define (variable-value->string model v) ;; FIXME: expression
  (let* ((enums (map .name (gom:enums model)))
         (booleans (map .name (gom:booleans model)))
         (integers (map .name (gom:integers model)))
         (type (.type (.type v))))
    (cond
     ((member type enums)
      (double-colon-join (append (list (.name model))
                                 (cdr (.expression v)))))
     (else
      (->string (.expression v))))))

(define (gom:state-type v)
  (case (gom:name (.type v))
    ((bool) (->string (gom:name (.type v))))
    (;;(enum)
     else (double-colon-join (list (.name (gom:component *ast*))
                                   (gom:name (.type v)))))))


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
            (let ((port (module-ref (current-module) 'port)))
              (animate-string
               string
               (animate-module-populate
                (current-module)
                event
                `((event . ,identity)
                  (.type . ,(compose .type .type))
                  (.event-name . ,.name)
                  (.statement .
                              ,(or (and-let* ((component (gom:component *ast*))
                                              (behaviour (.behaviour component))
                                              (statement (.statement behaviour)))
                                             (lambda (event)
                                               (parameterize ((statements.port port)
                                                              (statements.event event))
                                                 (statements->string statement #f))))
                                   ""))
                  (.return-interface-type . ,(lambda (event) (return-interface-type (.type port) event)))
                  )))))))
       events))

(define (map-functions string functions)
  (map (lambda (function)
         (save-module-excursion
          (lambda ()
            (animate-string
             string
             (animate-module-populate
              (current-module)
              function
              `((.function . ,.name)
                (.return-type . ,(compose gom:name .type .signature))
                (.comma . ,(lambda (x) (if (null-is-#f ((compose .elements .parameters .signature) x)) ", " "")))
                (.parameters . ,(lambda (x) ((->join ", ") (map parameter->string ((compose .elements .parameters .signature) x)))))
                (.statements . ,(lambda (x) (statements->string (.statement x))))))))))
       functions))

(define* (map-variables string variables :optional (separator ""))
  ((->join separator)
   (map (lambda (variable)
          (with-output-to-string
            (lambda ()
              (save-module-excursion
               (lambda ()
                 (animate-string
                  string
                  (animate-module-populate
                   (current-module)
                   variable
                   `((.variable . ,.name)
                     (.state-type . ,gom:state-type)
                     (.value . ,(expression->string (.expression variable)))))))))))
        variables)))

(define (action port event) "enable")
