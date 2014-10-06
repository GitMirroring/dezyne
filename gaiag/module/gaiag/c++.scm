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
  :use-module (gaiag code)
  :use-module (gaiag indent)
  :use-module (gaiag mangle)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
  :use-module (gaiag wfc)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (ast->
           enum-type
           c++-module
           c++:gom
           c++:import))

(define (ast-> ast)
  (let ((gom ((gom:register c++:gom) ast #t)))
    (map dump ((gom:filter <model>) gom)))
  "")

(define (c++:import name)
  (gom:import name c++:gom))

(define (c++:gom ast)
  ((compose mangle ast:wfc ast:resolve ast->gom) ast))

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
                     (c++-file 'interface.hh.scm (c++-module o))))))

(define-method (dump (o <component>))
  (let ((name (.name o))
        (interfaces (map c++:import (map .type ((compose .elements .ports) o)))))
    (dump-indented (symbol-append 'component- name '-c3.hh)
                   (lambda ()
                     (c++-file 'component.hh.scm (c++-module o))))
    (if (.behaviour o)
        (dump-indented (symbol-append 'component- name '-c3.cc)
                       (lambda ()
                         (c++-file 'component.cc.scm (c++-module o))))
        (dump-indented (symbol-append 'glue-component- name '-c3.cc)
                       (lambda ()
                         (c++-file 'glue-bottom-component.cc.scm (c++-module o)))))))

(define-method (dump (o <system>))
  (let ((name (.name o))
        (interfaces (map c++:import (map .type ((compose .elements .ports) o)))))
    (dump-indented (symbol-append 'component- name '-c3.hh)
                   (lambda ()
                     (c++-file 'system.hh.scm (c++-module o))))
    (dump-indented (symbol-append 'component- name '-c3.cc)
                   (lambda ()
                     (c++-file 'system.cc.scm (c++-module o))))
    (dump-indented (symbol-append name 'Interface.h)
                   (lambda ()
                     (c++-file 'glue-top-system-interface.hh.scm (c++-module o))))
    (dump-indented (symbol-append name 'Component.h)
                   (lambda ()
                     (c++-file 'glue-top-system.hh.scm (c++-module o))))
    (dump-indented (symbol-append name 'Component.cpp)
                   (lambda ()
                     (c++-file 'glue-top-system.cc.scm (c++-module o))))))

(define (c++-file file-name module)
  (parameterize ((template-dir '(templates c++-03)))
    (animate-file file-name module)))

(define-method (c++-module)
  (make-module 31 (list
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
    (module-define! module '.COMPONENT (string-upcase (symbol->string (.name o))))
    (module-define! module '.model (.name o))
    module))

(define (declare-enum enum)
  (->string (list "struct " (.name enum) "\n{\nenum type\n{\n" (comma-nl-join (.elements (.fields enum))) ",\n};\n};\n")))

(define (declare-integer integer)
  (->string (list "typedef int " (.name integer) ";\n")))

(define statements.src (make-parameter #f))
(define statements.port (make-parameter #f))
(define statements.event (make-parameter #f))

(define (enum->type) "todo")

(define* (statements->string model src :optional (locals '()) (compound? #t))
  (define (enum? identifier) (gom:enum model identifier))

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
       (($ <illegal>) "assert(false);")
       (($ <action> trigger)
        (let* ((port-name (.port trigger))
               (event-name (.event trigger))
               (port (gom:port model port-name))
               (name (.type port))
               (interface (c++:import name))
               (event (gom:event interface event-name)))
          (list port-name '. (.direction event) '. event-name "();\n")))
       (($ <reply> expression)
        (let* ((name (enum->identifier model expression locals)))
          (statements->string
           model
           (list "reply_" name " = " (expression->string model expression locals) ";\n")
           locals)))
       (($ <return> #f)
        "return;\n")
       (($ <return> expression)
        (list 'return " " (expression->string model expression locals) ";\n"))
       (($ <signature> type) (statements->string model type locals))
       (($ <type> name #f) (if (enum? name) (->string (list (.name model) "::" name "::type")) name))
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
  (define (enum? identifier) (gom:enum model identifier))
  (define (member? identifier) (gom:variable model identifier))
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

(define (return-type port event)
  (let ((type ((compose .type .type) event)))
    (->string (if (not (eq? 'void (.name type)))
                  (list "interface" "::" (.type port) "::" (.name type) "::type")
                  'void))))
