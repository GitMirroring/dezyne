;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (g c++)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 rdelim)
  :use-module (srfi srfi-1)

  :use-module (g ast-colon)
  :use-module (g animate)
  :use-module (g indent)
  :use-module (g misc)
  :use-module (g reader)
  :export (ast->
           animate-template
           c++-module
           november
           traditional-interface
           traditional-component-header
           traditional-component))

(define *ast* '())

(define (ast-> ast)
  (set! *ast* ast)
  (and=> (ast:interface ast) dump-interface)
  (and=> (ast:component ast) dump-component)
  (and=> (ast:system ast) dump-system)
  "")

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define (dump-indented file-name thunk)
  (dump-output file-name (lambda () (pipe thunk (lambda () (indent))))))

(define (dump-interface model)
  (let ((name (ast:name model)))
    (dump-indented (list 'interface- name '-c3.hh)
                   (lambda ()
                     ((animate-template 'interface.c3.hh.scm) (c++-module *ast*))))))

(define (dump-component model)
  (let ((name (ast:name model)))
    (dump-indented (list 'component- name '-c3.hh)
                   (lambda ()
                     ((animate-template 'component.c3.hh.scm) (c++-module *ast*))))
    (dump-indented (list 'component- name '-c3.cc)
                   (lambda ()
                     ((animate-template 'component.c3.cc.scm) (c++-module *ast*))))))

(define (dump-system model)
  (let ((name (ast:name model)))
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
                                 (resolve-module '(g ast-colon))
                                 (resolve-module '(g c++))
                                 (resolve-module '(g misc))))))
    (module-define! module 'ast ast)
    (and-let* ((int (ast:interface ast)))
              (module-define! module 'model int)
              (module-define! module '.interface (ast:name int))
              (module-define! module '.INTERFACE (string-upcase (symbol->string (ast:name int))))
              (module-define! module '.model (ast:name int)))
    (and-let* ((comp (ast:component ast)))
              (module-define! module 'model comp)
              (module-define! module '.component (ast:name comp))
              (module-define! module '.COMPONENT (string-upcase (symbol->string (ast:name comp))))
              (module-define! module '.no-dpc (no-dpc comp))
              (module-define! module '.interface (ast:type (ast:port comp)))
              (module-define! module '.model (ast:name comp)))
    (and-let* ((comp (ast:system ast)))
              (module-define! module 'model comp)
              (module-define! module '.component (ast:name comp))
              (module-define! module '.no-dpc (no-dpc comp))
              (module-define! module '.interface (ast:type (ast:port comp)))
              (module-define! module '.model (ast:name comp)))
    module))

;;;; INTERFACE

(define (api port) (or (and (ast:provides? port) 'API) 'CB))
(define (callback port) (or (and (ast:provides? port) 'CB) 'API))

(define (ap port) (or (and (ast:provides? port) 'api) 'cb))
(define (cb port) (or (and (ast:provides? port) 'cb) 'api))

(define (declare-enum enum)
  (->string (list "enum "  (ast:name enum) "\n  {\n  " (comma-nl-join (ast:elements enum)) ",\n  };\n")))

(define (declare-integer integer)
  (->string (list "typedef int " (ast:name integer) ";\n")))

;;;; COMPONENT

(define .api (api '(provides)))
(define .callback (callback '(provides)))
(define .ap (ap '(provides)))
(define .cb (cb '(provides)))
(define .parameters "/*parameters*/")
(define (no-dpc component)
  (if (null-is-#f (filter ast:requires? (ast:ports component)))
      "" "/*NoDpc*/"))

;;;; STRINGERS

(define statements.src (make-parameter *ast*))
(define statements.port (make-parameter #f))
(define statements.event (make-parameter #f))

(define (statements->string src)
  ;; (stderr "statements->string: ~a\n" src)
  (let ((port (statements.port))
        (event (statements.event)))
    (match src
      (() "")

      ;; Comment-out to use pattern matching and in-line C++ code,
      ;; enable to use list of c++-template snippets.
      ;;((? c++-template?) (parameterize ((statements.src src)) (apply c++-template->string src)))

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
       (if (member (list 'trigger (ast:name port) (ast:name event)) triggers)
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
       (statements->string (list (ast:name type) " " identifier " = " (expression->string expression) ";\n")))
      ((? char?) (make-string 1 src))
      ((? string?) src)
      ((? symbol?) (symbol->string src))
      ((h ... t)
       (apply string-append (map (lambda (x) (statements->string x)) src)))
      (_ (stderr "~a: NO MATCH: ~a\n" (current-source-location) src) ""))))

(define (statement-last lst)
  (if (find (lambda (s) (and (pair? s) (or (eq? (car s) 'action)
                                           (eq? (car s) 'assign))))
            lst)
      (statements->string '(last arguments))
      ""))

(define (action-statement->string trigger)
  (let* ((port-name (ast:port-name trigger))
         (event-name (ast:event-name trigger))
         (port (ast:port (ast:component *ast*) port-name))
         (name (ast:type port))
         (interface (ast:ast name))
         (event (ast:event interface event-name)))
    (statements->string (list "      " port-name '. (ast:direction event) '. event-name "();\n"))))

(define (statement-illegal)
  (let ((port (statements.port))
        (event (statements.event)))
    (statements->string "//illegal")))

(define (statement-last->string)
  (or (and-let* ((port (statements.port))
                 (event (statements.event))
                 (arguments (if (ast:typed? port)
                                (statements->string
                                 (list (ast:type port) "::" (return-type-text port)))
                                "")))
                (statements->string ""))
      ""))

(define (expr->clause expression)
  (let* ((c-expression (bool-expression->string expression))
         (if-clause (list "    if (" c-expression ")"))
         (else-if-clause (list "    else if (" c-expression ")"))
         (else-clause "    else")
         (guards ((compose ast:body ast:statement ast:behaviour ast:component) *ast*))
         (first? (equal? (statements.src) (car guards)))
         (top? (member (statements.src) guards)))
    (statements->string (if (eq? expression 'otherwise) else-clause (if (or first? (not top?)) if-clause else-if-clause)))))

(define (lhs->string lhs)
  (let* ((state-variables ((compose ast:variables ast:behaviour ast:component) *ast*))
         (state? (find
                  (lambda (v) (eq? lhs (ast:name v)))
                  state-variables))
         (prefix (if state? "" "")))
    (->string (list prefix (statements->string lhs)))))

(define (rhs->string rhs)
  (expression->string rhs))

(define (is-member? identifier)
  (member identifier (ast:member-names (ast:component *ast*))))

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
    (('action function) (->string (list function "()")))
    (('call function) (->string (list function "()")))
    (('call function ('arguments arguments ...))
     (let ((arguments ((->join ", ") (map expression->string (cons 'context arguments)))))
       (->string (list function  "(" arguments ")"))))

    (('value type field) field)
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
  (->string (list (ast:name (ast:type parameter)) " " (ast:name parameter))))

(define (c++-template? x) (parameterize ((templates c++-templates)) (template? x)))

(define (c++-template->string . x)
  (parameterize ((template-dir c++-template-dir) (templates c++-templates))
    (apply template->string x)))

(define c++-template-dir '(templates c++))
;; for the pretty printer, small templates work just fine
;; for c++, using pattern matching is better?
(define c++-templates
  `((illegal . (()))
    (assign . ((.lhs . ,lhs->string)
               (.rhs . ,rhs->string)))
    (guard . ((.clause . ,expr->clause)
              (.statement . ,(lambda (x) (statements->string (list (cdr x) (statement-last (cdr x))))))))
    (if . ((.expression . ,->string)
           (.statement . ,statements->string)
           (.else . ,statements->string)))))

(define (value->string value)
  (let ((comp-name (ast:name (ast:component *ast*))))
    (double-colon-join
     (list comp-name (ast:type value) (ast:field value)))))

(define (return-type-text port)
  (or (and-let* ((event (null-is-#f (ast:typed? port))))
                (ast:type (ast:return-type (car event))))
      'void))

(define (return-interface-type interface event)
  (or (and (ast:typed? event) (list interface "::" (ast:type (ast:return-type event))))
      'void))

(define (return-context-get interface event)
  (if (ast:typed? event)
      (c++-template->string 'return-context-get)
      ""))

(define (variable-value->string model v) ;; FIXME: expression
  (let* ((enums (map ast:name (ast:enums model)))
         (booleans (map ast:name (ast:booleans model)))
         (integers (map ast:name (ast:integers model)))
         (type (ast:type (ast:type v))))
    (cond
     ((member type enums)
      (double-colon-join (append (list (ast:name model))
                                 (cdr (ast:expression v)))))
     (else
      (->string (ast:expression v))))))

(define (ast:state-type v)
  (case (ast:type (ast:type v))
    ((bool) (->string (ast:type (ast:type v))))
    (;;(enum)
     else (double-colon-join (list (ast:name (ast:component *ast*))
                                   (ast:type (ast:type v)))))))

(define (format-parameters port)
  (if (ast:typed? port)
      (list (ast:type port) "::" (return-type-text port) " " 'value)
      ""))




;;;; MAPPERS
(define (find-bind model port)
  (find (lambda (bind)
          ;; (stderr "find: ~a in ~a?\n" port bind) ;; FIXME
          (or (equal? port (ast:port model (ast:left bind)))
              (equal? port (ast:port model (ast:right bind)))))
        (ast:binds model)))

(define (bind-other model port)
  (and-let* ((bind (find-bind model port))
             (other (if (equal? port (ast:port model (ast:left bind)))
                        (ast:right bind)
                        (ast:left bind))))
            ;; (stderr "other: ~a --> ~a ===>>> ~a?\n" other other (ast:port model other)) ;; FIXME
            (ast:port model other)))

(define* (map-ports string ports :optional (separator ""))
  ((->join separator)
   (map (lambda (port)
          (with-output-to-string
            (lambda ()
              (save-module-excursion
               (lambda ()
                 (animate-string
                  string
                  (animate-module-populate
                   (csp-module ast)
                   port
                   `((port . ,identity)
                     (interface . ,(ast-norm (ast:type port)))
                     (.optional-chaos . ,optional-chaos)
                     (.interface . ,ast:type) ;; FIXME
                     (.name . ,ast:name)
                     (.port . ,ast:name)
                     (.behaviour . ,(compose ast:name ast:behaviour))))))))))
        ports)))

(define* (map-ports string ports :optional (separator ""))
  ((->join separator)
   (map (lambda (port)
          (with-output-to-string
            (lambda ()
              (let* ((module (c++-module *ast*))
                     (model (module-ref module 'model))
                     (other (bind-other model port))
                     (.FIXME-other (ast:name (or other port)))
                     (.other (if (eq? .FIXME-other 'console) 'alarm .FIXME-other)))
                (save-module-excursion
                 (lambda ()
                   (animate-string
                    string
                    (animate-module-populate
                     module
                     port
                     `((port . ,identity)
                       (.api . ,api)
                       (.callback . ,callback)
                       (.ap . ,ap)
                       (.cb . ,cb)
                       (.interface . ,ast:type)
                       (.name . ,ast:name) ;; JUNKME
                       (.port . ,ast:name)
                       (.behaviour . ,(compose ast:name ast:behaviour))
                       (.parameters . ,format-parameters)
                       (.type . ,return-type-text)
                       (.if-typed . ,(lambda (port) (if (ast:typed? port) "" "#if 0")))
                       (.else-typed . ,(lambda (port) (if (ast:typed? port) "" "#else")))
                       (.endif-typed . ,(lambda (port) (if (ast:typed? port) "" "#endif")))
                       (other . ,other)
                       (.other . ,.other)
                       (.other-api . ,(api (or other port)))
                       (.other-callback . ,(callback (or other port)))
                       (.other-postfix . ,(if (and (not (eq? other 'alarm)) (ast:bottom? (ast:ast (ast:type (or other port)))))
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
                     (.instance . ,ast:name)
                     (.Class . ,(compose ast:Class ast:ast ast:type))
                     (.type . ,ast:type)))))))))
        instances)))

(define (binding-name model bind)
  (list (ast:name (ast:instance model bind)) '. (ast:name (ast:port model bind))))

(define (bind-port? bind)
  (or (symbol? (ast:left bind)) (symbol? (ast:right bind))))

(define* (map-binds string binds :optional (separator ""))
  ((->join separator)
   (map (lambda (bind)
          (with-output-to-string
            (lambda ()
              (let* ((module (c++-module *ast*))
                     (model (module-ref module 'model))
                     (left (ast:left bind))
                     (left-instance (ast:instance model left))
                     (left-name (ast:name left-instance))
                     (left-port (ast:port model left))
                     (left-api (api left-port))
                     (left-callback (callback left-port))
                     (left-interface (ast:type left-port))
                     (left-postfix (if (ast:bottom? (ast:ast left-interface))
                                       "" (ast:name left-port)))

                     (right (ast:right bind))
                     (right-instance (ast:instance model right))
                     (right-name (ast:name right-instance))
                     (right-port (ast:port model right))
                     (right-interface (ast:type right-port))
                     (right-postfix (if (or #t (ast:bottom? (ast:ast right-interface)))
                                        "" (ast:name right-port)))
                     ;;(right 3)

                     (provided-required (if (ast:provides? left-port) (cons left right) (cons right left)))
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
                       (.left-port . ,(ast:name left-port))
                       (.left-api . ,left-api)
                       (.left-callback . ,left-callback)
                       (.left-interface . ,left-interface)
                       (.left-postfix . ,left-postfix)

                       (right . ,right)
                       (.right . ,right-name)
                       (.right-port . ,(ast:name right-port))
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
              `((.api . ,(api '(provides)))
                (.callback . ,(callback '(provides)))
                (.ap . ,(ap '(provides)))
                (.cb . ,(cb '(provides)))
                (.type . ,(compose ast:type ast:return-type))
                (.event . ,ast:name))))))) events))

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
                  (.type . ,(compose ast:type ast:return-type))
                  (.name . ,ast:name)
                  (.event . ,ast:name)
                  (.statement .
                              ,(if (ast:component *ast*)
                                   (lambda (event)
                                     (parameterize ((statements.port port)
                                                    (statements.event event))
                                       (statements->string
                                        ((compose ast:body ast:statement ast:behaviour ast:component) *ast*))))
                                   ""))
                  (.return-interface-type . ,(lambda (event) (return-interface-type (ast:type port) event)))
                  (.return-context-get . ,(lambda (event) (return-context-get (ast:type port) event))))))))))
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
              `((.function . ,ast:name)
                (.return-type . ,(compose ast:name ast:return-type))
                (.comma . ,(lambda (x) (if (null-is-#f (ast:parameters x)) ", " "")))
                (.parameters . ,(lambda (x) ((->join ", ") (map parameter->string (ast:parameters x)))))
                (.statements . ,(lambda (x) (statements->string (ast:body (ast:statement x)))))))))))
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
                   `((.variable . ,ast:name)
                     (.state-type . ,ast:state-type)
                     (.value . ,(expression->string (ast:expression variable)))))))))))
        variables)))

(define (action port event) "enable")
