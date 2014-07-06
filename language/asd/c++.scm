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
  :use-module (language asd misc)
  :use-module (language asd reader)
  :export (ast->
           c++-module
           november
           traditional-interface
           traditional-component-header
           traditional-component
           ))

(define *ast* '())

(define (ast-> ast)
  (set! *ast* ast)
  (module-define! (resolve-module '(language asd c++)) 'ast ast)  ;; FIXME
  (and=> (ast:interface ast) dump-interface)
  (and=> (ast:component ast) dump-component)
  (and=> (ast:system ast) dump-component)
  "")


(define (dump-interface model)
  (let ((file-name (list (ast:name model) 'Interface.h)))
    (dump-output file-name 
                 (lambda ()
                   ((animate-template 'interface.hh.scm) (c++-module ast))))))

(define (dump-component model)
  (let ((name (ast:name model)))
    (dump-output (list name 'Component.h)
                 (lambda ()
                   ((animate-template 'component.hh.scm) (c++-module ast))))
    (dump-output (list name 'Component.cpp)
                 (lambda ()
                   ((animate-template 'component.cc.scm) (c++-module ast))))
    (dump-output (list name '-c2.cc)
                 (lambda ()
                   ((animate-template 'c2.cc.scm) (c++-module ast))))))

(define ((animate-template file-name) module)
  (animate-file (symbol-append 'templates/ file-name) module))

(define (c++-module ast)
  (let ((module (make-module 31 (list 
                                 (resolve-module '(ice-9 match))
                                 (resolve-module '(language asd ast:))
                                 (resolve-module '(language asd c++))
                                 (resolve-module '(language asd misc))))))
    (module-define! module 'ast ast)
    (and-let* ((int (ast:interface ast)))
              (module-define! module 'model int)
              (module-define! module '.interface (ast:name int))
              (module-define! module '.model (ast:name int)))
    (and-let* ((comp (ast:component ast)))
              (module-define! module 'model comp)
              (module-define! module '.component (ast:name comp))
              (module-define! module '.interface (ast:type (ast:port comp)))
              (module-define! module '.model (ast:name comp)))
    (and-let* ((comp (ast:system ast)))
              (module-define! module 'model comp)
              (module-define! module '.component (ast:name comp))
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

;;;; COMPONENT

(define .api (api '(provides)))
(define .callback (callback '(provides)))
(define .ap (ap '(provides)))
(define .cb (cb '(provides)))
(define .parameters "/*parameters*/")
(define .no-dpc "/*noDpc*/")



;;;; STRINGERS

(define statements.src (make-parameter *ast*))
(define statements.port (make-parameter #f))
(define statements.event (make-parameter #f))

(define (statements->string src)
  ;;(stderr "statements->string matching: ~a\n" src)
  (let ((port (statements.port))
        (event (statements.event)))
    (match src
      (() "")

      ;; Comment-out to use pattern matching and in-line C++ code,
      ;; enable to use list of c++-templates.
      ((? c++-template?) (parameterize ((statements.src src)) (apply c++-template->string src)))

      (('guard expr statements ...)
       (statements->string (list 
                            (parameterize ((statements.src src))
                              (expr->clause expr))
                            "\n" (statements->string statements))))
      (('if expression statement) (->string (list "if (" (statements->string expression) ")\n{\n" (statements->string statement) "}\n")))
      (('if expression statement else) (->string (list "if (" (statements->string expression) ")\n{\n" (statements->string statement) "else\n{\n"  (statements->string else) "}\n")))
      (('assign lhs rhs ...)
       (->string (list (lhs->string lhs) " = " (rhs->string (car rhs)) ";\n")))
      (('on triggers statements ...)
       (if (member (list 'trigger (ast:name port) (ast:name event)) triggers)
           (statements->string statements)
           ""))
      (('value 'state field) (->string (list 'state " == " field))) ;; FIXME name resolution
      (('value struct name) (->string (list struct "." name)))
      (('compound lst ...)
       (statements->string (list "{\n" lst (statement-last lst) "\n}\n")))
      (('last 'arguments)
       (statement-last->string))
      (('action 'illegal)
       (statements->string (list 'action-illegal)))
      (('action-illegal) (statements->string (statement-illegal)))
      (('action lst ...) (action-statement->string lst))
      ((? char?) (make-string 1 src))
      ((? string?) src)
      ((? symbol?) (symbol->string src))
      ((h ... t) (apply string-append (map (lambda (x) (statements->string x)) src)))
      (_ (stderr "~a: NO MATCH: ~a\n" (current-source-location) src) ""))))

(define (statement-last lst)
  (if (find (lambda (s) (and (pair? s) (or (eq? (car s) 'action)
                                           (eq? (car s) 'assign))))
            lst)
      (statements->string '(last arguments))
      ""))

(define (action-statement->string lst)
  (let* ((trigger (car lst))
         (port-name (ast:port-name trigger))
         (event-name (ast:event-name trigger))
         (interface (ast:port (ast:component ast) port-name))
         (name (ast:type interface)))
    (statements->string (list "      context.Get" port-name name (callback interface) "()." event-name "();\n"))))
       
(define (statement-illegal)
  (let ((port (statements.port))
        (event (statements.event)))
    (statements->string (list  "    ASD_ILLEGAL(\"" (ast:name (ast:component ast)) "\", \"State\", \"" (ast:type port) (callback port) "\", \"" (ast:name event) "\");\n"))))

(define (statement-last->string)
  (let ((port (statements.port))
        (event (statements.event))
        (arguments (arguments->string)))
    (statements->string (list 'context.Set (ast:name port) (ast:type port) (api port) (ast:type (ast:return-type event)) "(" arguments ");\n"))))

(define (arguments->string)
  (let ((port (statements.port)))
    (if (ast:typed? port)
        (statements->string 
         (list (ast:type port) "::" (return-type-text port)))
        "")))

(define (expr->clause expr)
  (let* ((if-clause (list "    if (predicate." expr ")"))
         (else-if-clause (list "    else if (predicate." expr ")"))
         (else-clause "    else")
         (guards ((compose ast:body ast:statement ast:behaviour ast:component) ast))
         (first? (equal? (statements.src) (car guards)))
         (top? (member (statements.src) guards)))
    (statements->string (if (eq? expr 'otherwise) else-clause (if (or first? (not top?)) if-clause else-if-clause)))))

(define (lhs->string lhs)
  (let* ((state-variables ((compose ast:variables ast:behaviour ast:component) ast))
         (state? (find
                  (lambda (v) (eq? lhs (ast:name v)))
                  state-variables))
         (prefix (if state? "predicate." "")))
    (->string (list prefix (statements->string lhs)))))

(define (rhs->string rhs)
  (let* ((enum? (not (or (eq? rhs 'true) (eq? rhs 'false)))))
    (if enum?
        (value->string rhs)
        (statements->string rhs))))

(define (c++-template? x) (parameterize ((templates c++-templates)) (template? x)))

(define (c++-template->string . x)
  (parameterize ((template-dir c++-template-dir) (templates c++-templates))
    (apply template->string x)))

(define c++-template-dir '(templates c++))
;; for the pretty printer, small templates work just fine
;; for c++, using pattern matching is better?
(define c++-templates
  `((action-illegal . (()))
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

(define (variable-value->string model v)
  (case (ast:type (ast:type v))
    ((bool) (->string (ast:expression v)))
    (;;(enum)
     else
     (double-colon-join (append (list model) 
                                (cdr (ast:expression v)))))))

(define (ast:state-type v)
  (case (ast:type (ast:type v))
    ((bool) (->string (ast:type (ast:type v))))
    (;;(enum)
     else (double-colon-join (list 'State (ast:type (ast:type v)))))))

(define (format-parameters port)
  (if (ast:typed? port)
      (list (ast:type port) "::" (return-type-text port) " " 'value)
      ""))




;;;; MAPPERS
(define (string-if condition then . else)
  (animate-string (if (null-is-#f condition) then (if (pair? else) (car else)  "")) (current-module)))

(define (map-ports string ports)
  (map (lambda (port)
         (save-module-excursion
          (lambda ()
            (animate-string 
             string 
             (animate-module-populate
              (c++-module ast) 
              port
              `((port . ,identity)
                (.api . ,api)
                (.callback . ,callback)
                (.ap . ,ap)
                (.cb . ,cb)
                (.interface . ,ast:type) ;; FIXME
                (.name . ,ast:name) ;; JUNKME
                (.port . ,ast:name)
                (.behaviour . ,(compose ast:name ast:behaviour))
                (.parameters . ,format-parameters)
                (.type . ,return-type-text)
                (.if-typed . ,(lambda (port) (if (ast:typed? port) "" "#if 0")))
                (.else-typed . ,(lambda (port) (if (ast:typed? port) "" "#else")))
                (.endif-typed . ,(lambda (port) (if (ast:typed? port) "" "#endif")))))))))
       ports))

(define (map-instances string instances)
  (map (lambda (instance)
         (save-module-excursion
          (lambda ()
            (animate-string 
             string 
             (animate-module-populate
              (c++-module ast) 
              instance
              `((instance . ,identity)
                (.instance . ,ast:name)
                (.Class . ,(compose ast:Class ast:ast ast:type))
                (.type . ,ast:type)))))))
       instances))

(define (map-binds string binds)
  (map (lambda (bind)
         (save-module-excursion
          (lambda ()
            (animate-string 
             string 
             (animate-module-populate
              (c++-module ast) 
              bind
              `((.left . left)
                (.left-api . left-api)
                (.left-callback . left-callback)
                (.left-interface . left-interface)
                (.left-postfix . left-postfix)

                (.right . right)
                (.right-postfix . right-postfix)))))))
       binds))

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
                              ,(if (ast:component ast) 
                                   (lambda (event)
                                     (parameterize ((statements.port port) 
                                                    (statements.event event))
                                       (statements->string
                                        ((compose ast:body ast:statement ast:behaviour ast:component) ast))))
                                   ""))
                  (.return-interface-type . ,(lambda (event) (return-interface-type (ast:type port) event)))
                  (.return-context-get . ,(lambda (event) (return-context-get (ast:type port) event))))))))))
       events))

(define (map-variables string variables)
  (map (lambda (variable)
         (save-module-excursion
          (lambda ()
              (animate-string
               string
               (animate-module-populate
                (current-module)
                variable
                `((.variable . ,ast:name)
                  (.state-type . ,ast:state-type)
                  (.value . ,(lambda (variable) (variable-value->string (ast:name (ast:component ast)) variable)))))))))
       variables))

(define (action port event) "enable")
