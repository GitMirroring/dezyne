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

(define-module (gaiag code)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag gaiag)
  :use-module (gaiag indent)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
  :use-module (gaiag wfc)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (ast:code
           code:gom
           code:import
           code:->code
           enum-type
           ->code
           bind-port?
           binding-name
           code:module
           declare-enum
           declare-io
           declare-integer
           declare-replies
           include-interface
           init-member
           init-port
           dump-indented
           enum->identifier
           expression->string
           indenter
           pipe
           return-type
           statements.event
           statements.port))

(define (ast:code ast)
  (let ((gom ((gom:register code:gom) ast #t)))
    (map dump ((gom:filter <model>) gom)))
  "")

(define (code:import name)
  (gom:import name code:gom))

(define (code:gom ast)
  ((compose ast:wfc ast:resolve ast->gom) ast))

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define indenter (make-parameter indent))

(define (dump-indented file-name thunk)
  (dump-output file-name
               (if (indenter)
                   (lambda () (pipe thunk (lambda () ((indenter)))))
                   thunk)))

(define-method (dump (o <interface>))
  (mkdir-p "interface")
  (let ((name (.name o)))
    (dump-indented (list 'interface name (extension o))
                   (lambda ()
                     (code-file 'interface (code:module o))))))

(define-method (dump (o <component>))
  (mkdir-p "component")
  (let ((name (.name o))
        (interfaces (map code:import (map .type ((compose .elements .ports) o)))))
    (when (.behaviour o)
      (map dump interfaces)
      (dump-indented (list 'component name (extension o))
                   (lambda ()
                     (code-file 'component (code:module o)))))))

(define-method (dump (o <system>))
  (let ((name (.name o))
        (interfaces (map code:import (map .type ((compose .elements .ports) o)))))
    (dump-indented (list 'component name (extension o))
                   (lambda ()
                     (code-file 'system (code:module o))))))

(define (code-file file-name module)
  (let ((model (module-ref module 'model)))
   (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
     (animate-file (symbol-append file-name (extension model) '.scm) module))))

(define* (code:->code model src :optional (locals '()) (indent 1) (compound? #t))
  (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
    (->code model src locals indent compound?)))

(define statements.port (make-parameter #f))
(define statements.event (make-parameter #f))

(define (snippet name pairs)
  (parameterize ((template-dir (append (template-dir) '(snippets))))
    (animate-template name pairs)))

(define (language)
  (string->symbol (option-ref (parse-opts (command-line)) 'language 'c++)))

(define-method (extension (o <interface>))
  (assoc-ref '((c++ . .hh)
               (javascript . .js)
               (python . .py))
             (language)))

(define-method (extension (o <model>))
  (assoc-ref '((c++ . .cc)
               (javascript . .js)
               (python . .py))
             (language)))

(define-method (code:module)
  (make-module 31 (list
                   (resolve-module (list 'gaiag (language)))
                   (resolve-module '(gaiag misc)))))

(define-method (code:module (o <interface>))
  (let* ((module (code:module)))
    (module-define! module 'model o)
    (module-define! module '.interface (.name o))
    (module-define! module '.INTERFACE (string-upcase (symbol->string (.name o))))
    (module-define! module '.model (.name o))
    module))

(define-method (code:module (o <model>))
  (let ((module (code:module)))
    (module-define! module 'model o)
    (module-define! module '.COMPONENT (string-upcase (symbol->string (.name o))))
    (module-define! module '.model (.name o))
    module))

(define* (->code model src :optional (locals '()) (indent 1) (compound? #t))
  (define (enum? identifier) (gom:enum model identifier))

  (let ((port (statements.port))
        (event (statements.event))
        (space (make-string (* indent 4) #\space)))
    (->string
     (match src
       (() "")
       (($ <guard> expression statement)
        (snippet 'guard
                 `((space ,space)
                   (clause ,(expr->clause model src expression))
                   (statement ,(->code model statement locals (1+ indent))))))
       (($ <if> expression then #f)
        (snippet 'if-then
                 `((space ,space)
                   (expression ,(expression->string model expression locals))
                   (then ,(->code model then locals (1+ indent))))))
       (($ <if> expression then else)
        (snippet 'if-then-else
                 `((space ,space)
                   (expression ,(expression->string model expression locals))
                   (then ,(->code model then locals (1+ indent)))
                   (else ,(->code model else locals (1+ indent))))))
       (($ <assign> name (and ($ <action>) (get! action)))
        (snippet 'assign
                 `((space ,space)
                   (identifier ,name)
                   (expression ,(expression->string model (action) locals)))))
       (($ <assign> name (and ($ <call>) (get! call)))
        (snippet 'assign
                 `((space ,space)
                   (identifier ,name)
                   (expression ,(expression->string model (call) locals)))))
       (($ <assign> identifier expression)
        (snippet 'assign
                 `((space ,space)
                   (identifier ,(->code model identifier locals 0))
                   (expression ,(expression->string model expression locals)))))
       (($ <on> triggers statement)
        (if (find (lambda (t) (and (eq? (.port t) (.name port))
                                   (eq? (.event t) (.name event))))
                  (.elements triggers))
            (->code model statement locals indent)
            ""))
       (($ <call> function ($ <arguments> '()))
        (snippet 'call `((space ,space) (function ,function))))
       (($ <call> function arguments)
        (snippet 'call-arguments
                 `((space ,space)
                   (function ,function)
                   (arguments ,(->code model arguments locals indent)))))
       (($ <arguments> arguments)
        ((->join ", ")
         (map (lambda (o) (expression->string model o locals)) arguments)))
       (($ <compound> '()) (snippet 'compound-empty `((space ,space))))
       (($ <compound> statements)
        (snippet
         (if compound? 'compound 'statements)
         `((space ,space)
           (statements
            ,(let loop ((statements statements) (locals locals))
               (if (null? statements)
                   '()
                   (let* ((statement (car statements))
                          (locals (match statement
                                    (($ <variable> name type expression)
                                     (acons name statement locals))
                                    (_ locals))))
                     (let ((str (->code model (car statements) locals indent compound?)))
                       (cons str (loop (cdr statements) locals))))))
))))
       (($ <illegal>) (snippet 'illegal `((space ,space))))
       (($ <action> trigger)
        (let* ((port-name (.port trigger))
               (event-name (.event trigger))
               (port (gom:port model port-name))
               (name (.type port))
               (interface (gom:import name))
               (event (gom:event interface event-name)))
          (snippet 'action
                   `((space ,space)
                     (port ,port-name)
                     (direction ,(.direction event))
                     (event ,event-name)))))
       (($ <reply> expression)
          (snippet 'reply
                   `((space ,space)
                     (name ,(enum->identifier model expression locals))
                     (expression ,(expression->string model expression locals)))))
       (($ <return> #f) (snippet 'return-void `((space ,space))))
       (($ <return> expression)
        (snippet 'return
                 `((space ,space)
                   (expression ,(expression->string model expression locals)))))
       (($ <signature> type) (->code model type locals indent))
       (($ <type> 'bool #f) 'bool)
       (($ <type> 'void #f) 'void)
       (($ <type> (and (? enum?) (get! name)) #f)
        (snippet 'type-local-enum `((space ,space) (scope ,(.name model)) (name ,(name)))))
       (($ <type> name #f)
        (snippet 'type-local `((space ,space) (scope ,(.name model)) (name ,name))))
       (($ <type> name scope)
        (snippet 'type `((space ,space) (scope ,scope) (name ,name))))
       (($ <variable> name type (and ($ <action>) (get! action)))
        (snippet 'variable
                 `((space ,space)
                   (name ,name)
                   (type ,(->code model type))
                   (expression ,(expression->string model (action) locals)))))
       (($ <variable> name type (and ($ <call>) (get! call)))
        (snippet 'variable
                 `((space ,space)
                   (name ,name)
                   (type ,(->code model type))
                   (expression ,(expression->string model (call) locals)))))
       (($ <variable> name type expression)
        (snippet 'variable
                 `((space ,space)
                   (name ,name)
                   (type ,(->code model type))
                   (expression ,(expression->string model expression locals)))))
       (($ <parameters> parameters)
        ((->join ", ") (map (lambda (x) (->code model x)) parameters)))
       (($ <gom:parameter> name type)
        (snippet 'parameter `((name ,name) (type ,(->code model type)))))
       ((? char?) (make-string 1 src))
       ((? string?) src)
       ('true (snippet 'true '()))
       ('false (snippet 'false '()))
       (#t (snippet 'true '()))
       (#f (snippet 'false '()))
       ((? symbol?) src)
       ((h t ...) (map (lambda (x) (->code model x locals indent)) src))
       (_ (throw 'match-error (format #f "~a:code:->code: no match: ~a\n" (current-source-location) src)))))))

(define (expr->clause model src expression)
  (if (is-a? expression <otherwise>)
      (snippet 'clause-else '())
      (let* ((c-expression (bool-expression->string model expression))
             (if-clause (snippet 'clause-if `((expression ,c-expression))))
             (else-if-clause (snippet 'clause-else-if `((expression ,c-expression))))
             (guards ((compose .elements .statement .behaviour) model))
             (first? (eq? src (car guards)))
             (top? (find (lambda (guard) (eq? guard src)) guards)))
        (->string (list (if (or first? (not top?)) if-clause else-if-clause))))))

(define (bool-expression->string model o)
  (match o
    (($ <field> identifier field)
     (snippet 'field `((identifier ,identifier) (field ,field))))
    (($ <literal> #f type field)
     (snippet 'literal-local `((type ,type) (field ,field))))
    (($ <literal> scope type field)
     (snippet 'literal `((scope ,scope) (type ,type) (field ,field))))
    (_ (expression->string model o))))

(define* (expression->string model o :optional (locals '()))

  (define (paren expression)
    (list "(" (expression->string model expression locals) ")"))

  (define (enum? identifier) (gom:enum model identifier))
  (define (member? identifier) (gom:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))

  (define (enum-type o field)
    (or (and-let* ((decl (var? o))
                   (type (.type decl)))
                  (if (.scope type)
                      (snippet 'literal
                               `((scope ,(.scope type))
                                 (type ,(.name type))
                                         (field ,field)))
                      (snippet 'literal-local
                               `((type ,(.name type))
                                 (field ,field)))))
        ""))

  (match o
    (($ <expression>) (expression->string model (.value o) locals))
    (($ <action> trigger)
     (let* ((port-name (.port trigger))
            (event-name (.event trigger))
            (port (gom:port model port-name))
            (name (.type port))
            (interface (gom:import name))
            (event (gom:event interface event-name)))
       (snippet 'action-expression
                `((port ,port-name)
                  (direction ,(.direction event))
                  (event ,event-name)))))
    (($ <var> (and (? member?) (get! identifier)))
     (snippet 'member `((identifier ,(identifier)))))
    (($ <var> identifier) identifier)
    (($ <field> identifier field)
     (snippet 'field-expression `((identifier ,identifier)
                                  (expression ,(enum-type identifier field)))))
    (($ <call> function ($ <arguments> '()))
        (snippet 'call-expression `((function ,function))))
    (($ <call> function arguments)
        (snippet 'call-arguments-expression
                 `((function ,function)
                   (arguments ,(->code model arguments locals 0)))))
    (($ <literal>) (bool-expression->string model o))
    ((? number?) (number->string o))
    (('! expression) (->string (list "not " (paren expression))))
    (('group expression) (paren expression))
    (('or lhs rhs) (let ((lhs (expression->string model lhs locals))
                         (rhs (expression->string model rhs locals)))
                     (list "(" lhs " " 'or " " rhs ")")))
    (((or 'and '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (expression->string model lhs locals))
           (rhs (expression->string model rhs locals))
           (op (car o)))
       (list lhs " " op " " rhs )))
    (_ (->code model o locals 0))))

(define (declare-enum enum)
  (let* ((fields ((compose .elements .fields) enum))
         (length (length fields)))
   (snippet 'declare-enum
            `((name ,(.name enum)) (fields ,fields) (length ,length)))))

(define (declare-integer integer)
  (snippet 'declare-integer `((name ,(.name integer)))))

(define ((declare-io snippet) event)
  (let ((name (.name event))
         (type (.name (.type (.type event))))
         (return-type (return-type #f event)))
    (animate snippet `((name ,name) (return-type ,return-type)))))

(define ((include-interface snippet) port)
  (let ((interface (.type port)))
    (animate snippet `((interface ,interface)))))

(define ((init-member model snippet) variable)
  (let* ((name (.name variable))
         (type (.type variable))
         (enum? (gom:enum model type))
         (expression (expression->string model (.expression variable))))
    (animate snippet `((name ,name) (expression ,expression)))))

(define ((init-port snippet) port)
  (let* ((name (.name port))
         (interface (.type port)))
    (animate snippet `((name ,name) (interface ,interface)))))

(define-method (declare-replies (o <interface>))
  (map
   (lambda (x) (snippet 'declare-reply `((type ,(.name o)) (name ,(.name x)))))
   (gom:interface-enums o)))

(define-method (enum->identifier (model <model>) (o <expression>) locals)
  (define (member? identifier) (gom:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
  (match o
    (($ <expression> ($ <literal> scope type field))
     (->string (list scope "_" type)))
    (($ <expression> ($ <var> name))
     (or (and-let* ((decl (var? name))
                    (type (.type decl)))
                   (->string (list (.scope type) "_" (.name type))))
         ""))))

(define (return-type port event)
  (let ((type ((compose .type .type) event))
        (scope (and=> port .type)))
    (cond
      ((eq? (.name type) 'bool) 'bool)
      ((eq? (.name type) 'void) 'void)
      (scope
       (snippet 'type `((space "") (scope ,scope) (name ,(.name type)))))
      (else
       (snippet 'type-local-enum `((space "") (scope ,scope) (name ,(.name type))))))))

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
