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

(define-module (language asd c++)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 rdelim)
  :use-module (srfi srfi-1)

  :use-module (language asd ast:)
  :use-module (language asd animate)
  :use-module (language asd indent)
  :use-module (language asd misc)
  :use-module (language asd reader)
  :use-module (language asd resolve)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (language asd gom)

  :export (ast->
           animate-template
           c++-module
           string-if))

(define *ast* '())

(define (ast-> ast)
  (let ((gom (c++:gom ast)))
    (gom:register gom #t)
    (set! *ast* gom)
    (and=> (gom:interface gom) dump-interface)
    (and=> (gom:component gom) dump-component)
    ;;  (and=> (gom:system ast) dump-system)
)
  "")

(define (c++:import name)
  (gom:import name c++:gom))

(define (c++:gom ast)
  ((compose ast->gom ast:resolve) ast))


(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define (dump-indented file-name thunk)
  (dump-output file-name (lambda () (pipe thunk (lambda () (indent))))))

(define (dump-interface model)
  (let ((name (.name model)))
    (dump-indented (list 'interface- name '-c3.hh)
                   (lambda ()
                     ((animate-template 'interface.c3.hh.scm) (c++-module *ast*))))))

(define (dump-component model)
  (let ((name (.name model)))
    (dump-indented (list 'component- name '-c3.hh)
                   (lambda ()
                     ((animate-template 'component.c3.hh.scm) (c++-module *ast*))))
    (dump-indented (list 'component- name '-c3.cc)
                   (lambda ()
                     ((animate-template 'component.c3.cc.scm) (c++-module *ast*))))))

(define (dump-system model)
  (let ((name (.name model)))
    (dump-indented (list 'component- name '-c3.hh)
                   (lambda ()
                     ((animate-template 'system.c3.hh.scm) (c++-module *ast*))))
    (dump-indented (list 'component- name '-c3.cc)
                   (lambda ()
                     ((animate-template 'system.c3.cc.scm) (c++-module *ast*))))))

(use-modules (ice-9 pretty-print))


(define ((animate-template file-name) module)
  (animate-file (symbol-append 'templates/ file-name) module))

(define (c++-module ast)
  (let ((module (make-module 31 (list
                                 (resolve-module '(ice-9 match))
                                 (resolve-module '(language asd ast:))
                                 (resolve-module '(language asd c++))
                                 (resolve-module '(language asd misc))))))
    (module-define! module 'ast ast)
    (and-let* ((int (gom:interface ast)))
              (module-define! module 'model int)
              (module-define! module '.interface (.name int))
              (module-define! module '.INTERFACE (string-upcase (symbol->string (.name int))))
              (module-define! module '.model (.name int)))
    (and-let* ((comp (gom:component ast)))
              (module-define! module 'model comp)
              (module-define! module '.component (.name comp))
              (module-define! module '.COMPONENT (string-upcase (symbol->string (.name comp))))
              (module-define! module '.interface (.type (gom:port comp)))
              (module-define! module '.model (.name comp)))
    (and-let* ((comp (gom:system ast)))
              (module-define! module 'model comp)
              (module-define! module '.component (.name comp))
              (module-define! module '.interface (.type (.port comp)))
              (module-define! module '.model (.name comp)))
    module))

(define (declare-enum enum)
  (->string (list "enum "  (.name enum) "\n  {\n  " (comma-nl-join (.elements (.fields enum))) ",\n  };\n")))

(define (declare-integer integer)
  (->string (list "typedef int " (.name integer) ";\n")))

(define statements.src (make-parameter *ast*))
(define statements.port (make-parameter #f))
(define statements.event (make-parameter #f))

(define (statements->string src)
  ;; (stderr "statements->string: ~a\n" src)
  (let ((port (statements.port))
        (event (statements.event)))
    (match src
      (() "")

      (('guard expr statement)
       (statements->string (list
                            (parameterize ((statements.src src))
                              (expr->clause expr))
                            "\n" (statements->string statement))))
      (('if expression statement) (->string (list "if (" (expression->string expression) ")\n" (statements->string statement))))
      (('if expression statement else) (->string (list "if (" (expression->string expression) ")\n" (statements->string statement) "else\n"  (statements->string else))))
      (('assign lhs rhs ...)
       (->string (list (lhs->string lhs) " = " (expression->string (car rhs)) ";\n")))
      (('on triggers statement)
       (if (member (list 'trigger (.name port) (.name event)) triggers)
           (statements->string statement)
           ""))
      (('compound lst ...)
       (statements->string (list "{\n" lst (statement-last lst) "\n}\n")))
      (('last 'arguments)
       (statement-last->string))
      (('illegal) (statements->string (statement-illegal)))
      (('action trigger) (action-statement->string trigger))
      (('return) (->string (list 'return ";\n")))
      (('return expression) (->string (list 'return " " (expression->string expression) ";\n")))
      (('variable type identifier expression)
       (statements->string (list (.name type) " " identifier " = " (expression->string expression) ";\n")))
      ((? char?) (make-string 1 src))
      ((? string?) src)
      ((? symbol?) (symbol->string src))
      ((h ... t)
       (apply string-append (map (lambda (x) (statements->string x)) src)))
      (_ "STATEMENTS")
      (_ (stderr "~a: NO MATCH: ~a\n" (current-source-location) src) ""))))

(define (statement-last lst)
  (if (find (lambda (s) (and (pair? s) (or (eq? (car s) 'action)
                                           (eq? (car s) 'assign))))
            lst)
      (statements->string '(last arguments))
      ""))

(define (action-statement->string trigger)
  (let* ((port-name (.port trigger))
         (event-name (.event trigger))
         (port (.port (gom:component *ast*) port-name))
         (name (.type port))
         (interface (c++:import name))
         (event (gom:event interface event-name)))
    (statements->string (list "      " port-name '. (.direction event) '. event-name "();\n"))))

(define (statement-illegal)
  (let ((port (statements.port))
        (event (statements.event)))
    (statements->string "//illegal")))

(define (statement-last->string)
  (or (and-let* ((port (statements.port))
                 (event (statements.event))
                 (arguments (if (gom:typed? port)
                                (statements->string
                                 (list (.type port) "::" (return-type-text port)))
                                "")))
                (statements->string ""))
      ""))

(define (expr->clause expression)
  (let* ((c-expression (bool-expression->string expression))
         (if-clause (list "    if (" c-expression ")"))
         (else-if-clause (list "    else if (" c-expression ")"))
         (else-clause "    else")
         (guards ((compose .elements .statement .behaviour gom:component) *ast*))
         (first? (equal? (statements.src) (car guards)))
         (top? (member (statements.src) guards)))
    (statements->string (if (eq? expression 'otherwise) else-clause (if (or first? (not top?)) if-clause else-if-clause)))))

(define (lhs->string lhs)
  (let* ((state-variables ((compose .variables .behaviour gom:component) *ast*))
         (state? (find
                  (lambda (v) (eq? lhs (.name v)))
                  state-variables))
         (prefix (if state? "" "")))
    (->string (list prefix (statements->string lhs)))))

(define (rhs->string rhs)
  (expression->string rhs))

(define (is-member? identifier)
  (member identifier (gom:member-names (gom:component *ast*))))

(define (bool-expression->string ast)
  (match ast
    (('value (and (? is-member?) (get! identifier)) field)
     (->string (bool-expression->string (identifier))  " == " field))
    (('value struct field) (->string (list struct "." field)))
    (_ (expression->string ast))))

;; FIXME: c&p from csp.scm
(define (expression->string ast)

  (define (paren expression)
    (list "(" (expression->string expression) ")"))

  (match ast
    (($ <expression>) (expression->string (.value ast)))
    (('action function) (->string (list function "()")))
    (('call function) (->string (list function "()")))
    (('call function ('arguments arguments ...))
     (let ((arguments ((->join ", ") (map expression->string (cons 'context arguments)))))
       (->string (list function  "(" arguments ")"))))

    (('value type field) field)
    (($ <literal> scope type field) field)
    ((? number?) (number->string ast))
    ((? string?) ast)
    ((? symbol?)
     (let ((prefix (if (is-member? ast)
                       "" "")))
       (->string (list prefix ast))))
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
  (->string (list (.name (.type parameter)) " " (.name parameter))))

(define (value->string value)
  (let ((comp-name (.name (gom:component *ast*))))
    (double-colon-join
     (list comp-name (.type value) (.field value)))))

(define (return-type-text port)
  (or (and-let* ((event (null-is-#f (gom:typed? port))))
                (.type (.type (car event))))
      'void))

(define (return-interface-type interface event)
  (or (and (gom:typed? event) (list interface "::" (.type (.type event))))
      'void))

;; (define (return-context-get interface event)
;;   (if (gom:typed? event)
;;       (c++-template->string 'return-context-get)
;;       ""))

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
  (case (ast:type (.type v))
    ((bool) (->string (ast:type (.type v))))
    (;;(enum)
     else (double-colon-join (list (.name (gom:component *ast*))
                                   (ast:type (.type v)))))))

(define (format-parameters port)
  (if (gom:typed? port)
      (list (.type port) "::" (return-type-text port) " " 'value)
      ""))




;;;; MAPPERS
(define-syntax string-if
  (syntax-rules ()
    ((_ condition then)
     (animate-string (if (null-is-#f condition) then "") (current-module)))
    ((_ condition then else)
     (animate-string (if (null-is-#f condition) then else) (current-module)))))

(define (find-bind model port)
  (find (lambda (bind)
          ;; (stderr "find: ~a in ~a?\n" port bind) ;; FIXME
          (or (equal? port (.port model (.left bind)))
              (equal? port (.port model (.right bind)))))
        (gom:binds model)))

(define (bind-other model port)
  (and-let* ((bind (find-bind model port))
             (other (if (equal? port (.port model (.left bind)))
                        (.right bind)
                        (.left bind))))
            ;; (stderr "other: ~a --> ~a ===>>> ~a?\n" other other (.port model other)) ;; FIXME
            (.port model other)))

(define* (map-ports string ports :optional (separator ""))
  ((->join separator)
   (map (lambda (port)
          (with-output-to-string
            (lambda ()
              (let* ((module (c++-module *ast*))
                     (model (module-ref module 'model))
                     (other (bind-other model port))
                     (.FIXME-other (.name (or other port)))
                     (.other (if (eq? .FIXME-other 'console) 'alarm .FIXME-other)))
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
;;                       (.behaviour . ,(compose .name .behaviour))
                       (.parameters . ,format-parameters)
                       (.type . ,return-type-text)
                       (.if-typed . ,(lambda (port) (if (gom:typed? port) "" "#if 0")))
                       (.else-typed . ,(lambda (port) (if (gom:typed? port) "" "#else")))
                       (.endif-typed . ,(lambda (port) (if (gom:typed? port) "" "#endif")))
                       (other . ,other)
                       (.other . ,.other)
                       (.other-postfix . ,(if (and (not (eq? other 'alarm)) (gom:bottom? (c++:import (.type (or other port)))))
                                              "" .FIXME-other))))))))))) ;; FIXME-other

        ports)))


(define* (map-instances string instances :optional (separator ""))
  ((->join separator)
   (map (lambda (instance)
          (with-output-to-string
            (lambda ()
              (save-module-excursion
               (lambda ()
                 (animate-string
                  string
                  (animate-module-populate
                   (c++-module *ast*)
                   instance
                   `((instance . ,identity)
                     (.instance . ,.name)
                     (.Class . ,(compose symbol-capitalize ast-name c++:import .type))
                     (.type . ,.type)))))))))
        instances)))

(define (binding-name model bind)
  (list (.name (.instance model bind)) '. (.name (.port model bind))))

(define (bind-port? bind)
  (or (symbol? (.left bind)) (symbol? (.right bind))))

(define* (map-binds string binds :optional (separator ""))
  ((->join separator)
   (map (lambda (bind)
          (with-output-to-string
            (lambda ()
              (let* ((module (c++-module *ast*))
                     (model (module-ref module 'model))
                     (left (.left bind))
                     (left-instance (.instance model left))
                     (left-name (.name left-instance))
                     (left-port (.port model left))
                     (left-interface (.type left-port))
                     (left-postfix (if (gom:bottom? (c++:import left-interface))
                                       "" (.name left-port)))

                     (right (.right bind))
                     (right-instance (.instance model right))
                     (right-name (.name right-instance))
                     (right-port (.port model right))
                     (right-interface (.type right-port))
                     (right-postfix (if (or #t (gom:bottom? (c++:import right-interface)))
                                        "" (.name right-port)))
                     ;;(right 3)

                     (provided-required (if (gom:provides? left-port) (cons left right) (cons right left)))
                     (provided (binding-name model (car provided-required)))
                     (required (binding-name model (cdr provided-required)))
                     )
                (save-module-excursion
                 (lambda ()
                   (animate-string
                    string
                    (animate-module-populate
                     module
                     bind
                     `((left . ,left)
                       (.left . ,left-name)
                       (.left-port . ,(.name left-port))
                       (.left-interface . ,left-interface)
                       (.left-postfix . ,left-postfix)

                       (right . ,right)
                       (.right . ,right-name)
                       (.right-port . ,(.name right-port))
                       (.right-interface . ,right-interface)
                       (.right-postfix . ,right-postfix)
                       (.provided . ,provided)
                       (.required . ,required)

                       (.port . ,(and (bind-port? bind) (if (symbol? left) left right)))
                       (.instance . ,(and (bind-port? bind) (if (symbol? left) (binding-name model right) (binding-name model left)))))))))))))
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
                              ,(if (gom:component *ast*)
                                   (lambda (event)
                                     (parameterize ((statements.port port)
                                                    (statements.event event))
                                       (statements->string
                                        ((compose .elements .statement .behaviour gom:component) *ast*))))
                                   ""))
                  (.return-interface-type . ,(lambda (event) (return-interface-type (.type port) event)))
;;                  (.return-context-get . ,(lambda (event) (return-context-get (.type port) event)))
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
                (.return-type . ,(compose .name .type))
                (.comma . ,(lambda (x) (if (null-is-#f (.elements (.parameters x))) ", " "")))
                (.parameters . ,(lambda (x) ((->join ", ") (map parameter->string (.elements (.parameters x))))))
                (.statements . ,(lambda (x) (statements->string (.elements (.statement x)))))))))))
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
