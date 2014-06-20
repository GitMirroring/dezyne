;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 rdelim)
  :use-module (srfi srfi-1)

  :use-module (language asd ast)
  :use-module (language asd animate)
  :use-module (language asd misc)
  :export (asd-> 
           ))

(define *ast* '())

(define (asd-> ast)
  (set! *ast* ast)
  (module-define! (resolve-module '(language asd c++)) 'ast ast)  ;; FIXME
  (and-let* ((i (interface ast))
             (file-name (list (interface-name i) 'Interface.h)))
            (animate-file "templates/interface.hh.scm" file-name
                          (c++-module ast)))
  (and-let* ((comp (component ast))
             (name (component-name comp)))
            (animate-file 'templates/component.hh.scm (list name 'Component.h) (c++-module ast))
            (animate-file 'templates/component.cc.scm (list name 'Component.cpp)
                          (c++-module ast))
            (animate-file 'templates/c2.cc.scm (list name '-c2.cc)
                          (c++-module ast)))
  "")

(define (c++-module ast)
  (let ((module (make-module 31 (list 
                                 (resolve-module '(ice-9 match))
                                 (resolve-module '(language asd ast))
                                 (resolve-module '(language asd c++))
                                 (resolve-module '(language asd csp))))))
    (module-define! module 'ast ast)
    (and-let* ((int (interface ast)))
              (module-define! module '.interface (interface-name int))
              (module-define! module '.module (interface-name int)))
    (and-let* ((comp (component ast)))
              (module-define! module '.component (component-name comp))
              (module-define! module '.module (component-name comp)))
    module))

;;;; INTERFACE

(define (api port) (or (and (port-provides? port) 'API) 'CB))
(define (callback port) (or (and (port-provides? port) 'CB) 'API))

(define (ap port) (or (and (port-provides? port) 'api) 'cb))
(define (cb port) (or (and (port-provides? port) 'cb) 'api))

(define (->join lst infix) (string-join (map ->string lst) infix))
(define (comma-join lst) (string-join (map ->string lst) ","))
(define (comma-space-join lst) (->join lst ", "))
(define (comma-nl-join lst) (->join lst ",\n"))
(define (nl-comma-join lst) (->join lst "\n  , "))
(define (double-colon-join lst) (->join lst "::"))

(define (declare-enum enum)
  (->string (list "enum "  (enum-name enum) "\n  {\n  " (comma-nl-join (enum-elements enum)) ",\n  };\n")))

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
      ;;((? c++-template?) (parameterize ((statements.src src)) (apply c++-template->string src)))
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
       (if (member (list 'field (port-name port) (event-name event)) triggers)
           (statements->string statements)
           ""))
      (('field 'state name) (->string (list 'state " == " name)))
      (('field struct name) (->string (list struct "." name)))
      (('statements lst ...)
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
      (_ (stderr "NO MATCH: ~a\n" src) ""))))

(define (statement-last lst)
  (if (find (lambda (s) (and (pair? s) (or (eq? (car s) 'action)
                                           (eq? (car s) 'assign))))
            lst)
      (statements->string '(last arguments))
      ""))

(define (action-statement->string lst)
  (let* ((field (car lst))
         (int (field-type field))
         (trigger (field-entry field))
         (interface (component-port (component ast) int))
         (name (port-interface interface)))
    (statements->string (list "      context.Get" int name (callback interface) "()." trigger "();\n"))))
       
(define (statement-illegal)
  (let ((port (statements.port))
        (event (statements.event)))
    (statements->string (list  "    ASD_ILLEGAL(\"" (component-name (component ast)) "\", \"State\", \"" (port-interface port) (callback port) "\", \"" (event-name event) "\");\n"))))

(define (statement-last->string)
  (let ((port (statements.port))
        (event (statements.event))
        (arguments (arguments->string)))
    (statements->string (list 'context.Set (port-name port) (port-interface port) (api port) (event-type event) "(" arguments ");\n"))))

(define (arguments->string)
  (let ((port (statements.port)))
    (if (port-typed-event? port)
        (statements->string 
         (list (port-interface port) "::" (return-type-text port)))
        "")))

(define (expr->clause expr)
  (let* ((if-clause (list "    if (predicate." expr ")"))
         (else-if-clause (list "    else if (predicate." expr ")"))
         (else-clause "    else")
         (guards (behaviour-statements (component-behaviour (component ast))))
         (first? (equal? (statements.src) (car guards)))
         (top? (member (statements.src) guards)))
    (statements->string (if (eq? expr 'otherwise) else-clause (if (or first? (not top?)) if-clause else-if-clause)))))

(define (lhs->string lhs)
  (let* ((state-variables (behaviour-variables (component-behaviour (component ast))))
         (state? (find
                  (lambda (v) (eq? lhs (variable-name v)))
                  state-variables))
         (prefix (if state? "predicate." "")))
    (->string (list prefix (statements->string lhs)))))

(define (rhs->string rhs)
  (let* ((enum? (not (or (eq? rhs 'true) (eq? rhs 'false)))))
    (if enum?
        (enum->string rhs)
        (statements->string rhs))))

(define (c++-template? x) (parameterize ((templates c++-templates)) (template? x)))

(define (c++-template->string . x)
  (parameterize ((template-dir c++-template-dir) (templates c++-templates))
    (apply template->string x)))

(define c++-template-dir '(templates c++))
(define c++-templates
  `((action-illegal . (()))
    (assign . ((.lhs . ,lhs->string)
               (.rhs . ,rhs->string)))
    (guard . ((.clause . ,expr->clause)
              (.statement . ,(lambda (x) (statements->string (cdr x))))))
    (if . ((.expression . ,->string)
           (.statement . ,statements->string)
           (.else . ,statements->string)))
    (xxstatements . ((.s1 . ,(lambda (x) (statements->string x)))
                   (.s2 . ,(lambda (x) (statements->string x)))
                   (.s3 . ,(lambda (x) (statements->string  x)))
                   (.s4 . ,(lambda (x) (statements->string x)))))))

(define (enum->string e)
  (let ((comp-name (component-name (component *ast*))))
    (double-colon-join
     (list comp-name (field-type e) (field-entry e)))))

(define (return-type-text port)
  (or (and-let* ((event (null-is-#f (port-typed-event? port))))
                (event-type (car event)))
      'void))

(define (return-interface-type interface event)
  (or (and (event-typed? event)  (list interface "::" (event-type event)))
      'void))

(define (return-context-get interface event)
  (if (event-typed? event)
      (list interface "::" (event-type event)))
  "")

(define (variable-value->string module v)
  (case (variable-type v)
    ((bool) (->string (variable-initial-value v)))
    (;;(enum)
     else
     (double-colon-join (append (list module) 
                                (cdr (variable-initial-value v)))))))

(define (variable-state-type v)
  (case (variable-type v)
    ((bool) (->string (variable-type v)))
    (;;(enum)
     else (double-colon-join (list 'State (variable-type v))))))

(define (format-parameters port)
  (if (port-typed-event? port)
      (list (port-interface port) "::" (return-type-text port) " " 'value)
      ""))




;;;; MAPPERS
(define (string-if condition then . else)
  (animate-string (if condition then (if (pair? else) (car else)  "")) (current-module)))


(define (map-ports string ports)
  (map (lambda (port)
         (save-module-excursion
          (lambda ()
            (let ((module (c++-module ast)))
              (module-define! module 'port port)
              (module-define! module '.api (api port))
              (module-define! module '.callback (callback port))
              (module-define! module '.ap (ap port))
              (module-define! module '.cb (cb port))
              (module-define! module '.interface (port-interface port))
              (module-define! module '.name (port-name port))
              (module-define! module '.port (port-name port))
              (module-define! module '.behaviour (port-behaviour port))
              (module-define! module '.parameters (format-parameters port))
              (module-define! module '.type (return-type-text port))
              (module-define! module '.if-typed (if (port-typed-event? port) "" "#if 0"))
              (module-define! module '.else-typed(if (port-typed-event? port) "" "#else"))
              (module-define! module '.endif-typed (if (port-typed-event? port) "" "#endif"))

              (animate-string string module))))) ports))

(define (map-events string events)
  (map (lambda (event)
         (save-module-excursion
          (lambda ()
            (let ((module (current-module)))
              (module-define! module '.api (api '(provides)))
              (module-define! module '.callback (callback '(provides)))
              (module-define! module '.ap (ap '(provides)))
              (module-define! module '.cb (cb '(provides)))
              (module-define! module '.type (event-type event))
              (module-define! module '.event (event-name event))
              (animate-string string module))))) events))

(define (map-port-events string port events)
  (map (lambda (event)
         (save-module-excursion
          (lambda ()
            (let ((module (current-module)))
              ;;(module-define! module 'port port)
              (module-define! module 'event event)
              (module-define! module '.type (event-type event))
              (module-define! module '.name (event-name event))
              (module-define! module '.event (event-name event))
              (module-define! module '.statement
                              (parameterize ((statements.port port)
                                             (statements.event event))
                                (statements->string (behaviour-statements (component-behaviour (component ast))))))
              ;;(module-define! module '.statement "NOT NOW")
              (module-define! module '.return-interface-type (return-interface-type (port-interface port) event))
              (module-define! module '.return-context-get (return-context-get (port-interface port) event))
           (animate-string string module)))))
       events))

(define (map-variables string variables)
  (map (lambda (variable)
         (save-module-excursion
          (lambda ()
            (let ((module (current-module))
                  (behaviour (component-behaviour (component ast)))
                  (name (variable-name variable)))
              (module-define! module '.variable name)
              (module-define! module '.state-type (variable-state-type variable))
              (module-define! module '.value (variable-value->string (component-name (component ast)) variable))
              (animate-string string module))))) 
       variables))


(define (action port event) "enable")


         
