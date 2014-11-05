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
           define-function
           define-on
           connect-ports
           include-component
           include-interface
           init-bind
           init-instance
           init-member
           init-port
           injected-binding
           injected-binding?
           injected-bindings
           injected-instance-name
           non-injected-instances
           join
           dump-indented
           expression->string
           indenter
           pipe
           return-type
           statements.event
           statements.port))

(define (ast:code ast)
  (let ((gom ((gom:register code:gom) ast #t)))
    (map dump ((gom:filter <model>) gom))
    (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
      (dump-header)))
  "")

(define (code:import name)
  (gom:import name code:gom))

(define (code:gom ast)
  ((compose ast:wfc ast:resolve ast->gom) ast))

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define join (make-parameter (->join ", ")))
(define indenter (make-parameter indent))

(define (dump-indented file-name thunk)
  (dump-output file-name
               (if (indenter)
                   (lambda () (pipe thunk (lambda () ((indenter)))))
                   thunk)))

(define (dump-header)
  (and-let* ((header (template-file `(header ,(extension (make <component>)))))
             (header (components->file-name header))
             ((file-exists? header)))
            (dump-file (basename header) (gulp-file header))))

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
  (mkdir-p "component")
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

(define (animate-snippet name pairs)
  ;;(stderr "snippet: ~a\n" name)
  (parameterize ((template-dir (append (template-dir) '(snippets))))
    (animate-template name pairs)))

(define snippet animate-snippet)

(define (language)
  (string->symbol (option-ref (parse-opts (command-line)) 'language 'c++)))

(define-method (extension (o <interface>))
  (assoc-ref `((c++ . .hh)
               (goops . .scm)
               (java . .java)
               (javascript . .js)
               (python . .py))
             (language)))

(define-method (extension (o <model>))
  (assoc-ref '((c++ . .cc)
               (goops . .scm)
               (java . .java)
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
  (let ((statement (->code- model src locals indent compound?)))
    (if (eq? statement '$empty-statement$)
        ""
        (->string statement))))

(define* (->code- model src :optional (locals '()) (indent 1) (compound? #t))
  (define (enum? identifier) (gom:enum model identifier))
  (define (extern? identifier) (gom:extern model identifier))
  (define (member? identifier) (gom:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))

  (let ((port (statements.port))
        (event (statements.event))
        (space (make-string (* indent (if (eq? (language) 'python) 4 2)) #\space)))
    (match src
      (() "")
      ('$empty-statement$ (snippet 'empty `((space ,space))))
      (($ <guard> expression statement)
       (let* ((statement (->code- model statement locals (1+ indent)))
              (statement (if (eq? statement '$empty-statement$)
                             (->code model statement locals (1+ indent))
                             statement)))
         (snippet 'guard
                  `((space ,space)
                    (clause ,(expr->clause model src expression))
                    (statement ,statement)))))
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
      (($ <assign> identifier (and ($ <action>) (get! action)))
       (snippet 'assign
                `((space ,space)
                  (identifier ,identifier)
                  (member? ,(member? identifier))
                  (expression ,(expression->string model (action) locals)))))
      (($ <assign> identifier (and ($ <call>) (get! call)))
       (snippet 'assign
                `((space ,space)
                  (identifier ,identifier)
                  (member? ,(member? identifier))
                  (expression ,(expression->string model (call) locals)))))
      (($ <assign> identifier expression)
       (snippet 'assign
                `((space ,space)
                  ;; FIXME?(identifier ,(->code model identifier locals 0))
                  (identifier ,identifier)
                  (member? ,(member? identifier))
                  (expression ,(expression->string model expression locals)))))
      (($ <on> triggers statement)
       (or (and-let* ((trigger (find (lambda (t) (and (eq? (.port t) (.name port))
                                                      (eq? (.event t) (.name event))))
                                     (.elements triggers))))
                     (let* ((aliases
                             (let loop ((parameters ((compose .elements .parameters .signature) event))
                                        (arguments (map (compose .name .value) ((compose .elements .arguments) trigger))))
                               (if (null? arguments)
                                   '()
                                   (let* ((parameter (car parameters))
                                          (type (->code model (.type parameter)))
                                          (out? (member (.direction parameter) '(inout out)))
                                          (name (.name parameter))
                                          (alias (car arguments))
                                          (rest (loop (cdr parameters) (cdr arguments))))
                                     (if (eq? alias name)
                                         rest
                                         (cons (snippet 'alias `((type ,type) (name ,name) (out? ,out?) (alias ,alias)))
                                               rest))))))
                            (indent (if (pair? aliases) (1+ indent) indent))
                            (statement (->code model statement locals indent))
                            (statement (if (pair? aliases)
                                           (snippet 'compound `((space space)
                                                                (statements ,(string-join (append aliases (list statement))))))
                                           statement)))
                       statement))
           '$empty-statement$))
      (($ <call> function ($ <arguments> '()))
       (snippet 'call `((space ,space) (function ,function))))
      (($ <call> function arguments)
       (snippet 'call-arguments
                `((space ,space)
                  (function ,function)
                  (arguments ,(->code model arguments locals indent)))))
      (($ <arguments> arguments)
       ((join)
        (map (lambda (o) (expression->string model o locals)) arguments)))
      (($ <compound> '()) (snippet 'compound-empty `((space ,space))))
      (($ <compound> statements)
       (snippet
        (symbol-append
         (if compound? 'compound 'statements)
         (if (is-a? (car statements) <guard>) '-guarded (string->symbol "")))
        `((space ,space)
          (statements
           ,(let loop ((statements statements) (locals locals))
              (if (null? statements)
                  '()
                  (let* ((statement (car statements))
                         (variable? (is-a? statement <variable>))
                         (locals (if variable? (acons (.name statement) statement locals)
                                     locals)))
                    (let ((statement (->code model (car statements) locals indent compound?))
                          (continuation (loop (cdr statements) locals)))
                      (if variable?
                          (list (snippet 'context `((space ,space)
                                                    (statement ,statement)
                                                    (continuation ,continuation))))
                          (cons statement continuation))))))))))
      (($ <illegal>) (snippet 'illegal `((space ,space))))
      (($ <action> ($ <trigger> port-name event-name arguments))
       (let* ((port (gom:port model port-name))
              (name (.type port))
              (interface (gom:import name))
              (event (gom:event interface event-name))
              (arguments (->code model arguments)))
         (snippet 'action
                  `((space ,space)
                    (port ,port-name)
                    (direction ,(.direction event))
                    (event ,event-name)
                    (arguments ,arguments)))))
      (($ <reply> (and ($ <expression> ($ <literal> scope type field)) (get! expression)))
       (snippet 'reply
                `((space ,space)
                  (type ,scope)
                  (name ,type)
                  (expression ,(expression->string model (expression) locals)))))
      (($ <reply> (and ($ <expression> ($ <var> name)) (get! expression)))
       (let* ((decl (var? name))
              (type (.type decl)))
         (snippet 'reply
                  `((space ,space)
                    (type ,(.scope type))
                    (name ,(.name type))
                    (expression ,(expression->string model (expression) locals))))))
      (($ <return> #f) (snippet 'return-void `((space ,space))))
      (($ <return> expression)
       (snippet 'return
                `((space ,space)
                  (expression ,(expression->string model expression locals)))))
      (($ <signature> type) (->code model type locals indent))
      (($ <type> 'bool #f) (snippet 'bool '()))
      (($ <type> 'void #f) 'void)
      ((and (? (is? <type>)) (? extern?))
       (let* ((extern (extern? src))
              (value (.value extern)))
         (snippet 'type-extern `((space ,space) (value ,value)))))
      (($ <type> (and (? enum?) (get! name)) #f)
       (snippet 'type-local-enum `((space ,space) (scope ,(.name model)) (name ,(name)))))
      (($ <type> name #f)
       (snippet 'type-local `((space ,space) (scope ,(.name model)) (name ,name))))
      ((and (? enum?) ($ <type> name scope))
       (snippet 'type-enum `((space ,space) (scope ,scope) (name ,name))))
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
       ((join) (map (lambda (x) (->code model x)) parameters)))
      (($ <gom:parameter> name type direction)
       (snippet 'parameter `((name ,name) (type ,(->code model type)) (out? ,(member direction '(inout out))))))
      (($ <data> value) value)
      ((? char?) (make-string 1 src))
      ((? string?) src)
      ('true (snippet 'true '()))
      ('false (snippet 'false '()))
      (#t (snippet 'true '()))
      (#f (snippet 'false '()))
      ((? symbol?) src)
      ((h t ...) (map (lambda (x) (->code model x locals indent)) src))
      (_ (throw 'match-error (format #f "~a:code:->code: no match: ~a\n" (current-source-location) src))))))

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

  (define (enum? identifier) (gom:enum model identifier))
  (define (member? identifier) (gom:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
  (define (unspecified? x) (eq? x *unspecified*))

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
    (($ <expression> (? unspecified?)) *unspecified*)
    (($ <expression>) (expression->string model (.value o) locals))
    (($ <action> ($ <trigger> port-name event-name arguments))
     (let* ((port (gom:port model port-name))
            (name (.type port))
            (interface (gom:import name))
            (event (gom:event interface event-name))
            (arguments (->code model arguments)))
       (snippet 'action-expression
                `((port ,port-name)
                  (direction ,(.direction event))
                  (event ,event-name)
                  (arguments ,arguments)))))
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
    (('! expression)
     (let ((expression (expression->string model expression locals)))
       (snippet 'not `((expression ,expression)))))
    (('group expression)
     (list "(" (expression->string model expression locals) ")"))
    (((or 'and 'or '== '!=) lhs rhs)
     (let ((lhs (expression->string model lhs locals))
           (rhs (expression->string model rhs locals))
           (op (car o)))
       (snippet op `((op ,op) (lhs ,lhs) (rhs ,rhs)))))
    (((or '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (expression->string model lhs locals))
           (rhs (expression->string model rhs locals)))
       (snippet 'op `((op ,(car o)) (lhs ,lhs) (rhs ,rhs)))))
    (_ (->code model o locals 0))))

(define ((connect-ports model snippet) bind)
  (let* ((left (.left bind))
         (left-port (gom:port model left))
         (right (.right bind))
         (right-port (gom:port model right))
         (provided-required (if (gom:provides? left-port)
                                (cons left right)
                                (cons right left)))
         (provided (binding-name model (car provided-required)))
         (required (binding-name model (cdr provided-required))))
    (animate snippet `((provided ,provided) (required ,required)))))

(define (declare-enum enum)
  (let* ((fields ((compose .elements .fields) enum))
         (length (length fields)))
   (snippet 'declare-enum
            `((name ,(.name enum)) (fields ,fields) (length ,length)))))

(define (declare-integer integer)
  (snippet 'declare-integer `((name ,(.name integer)))))

(define ((declare-io model snippet) event)
  (let* ((name (.name event))
         (signature (.signature event))
         (type ((compose .name .type) signature))
         (return-type (return-type #f event))
         (parameters (code:->code model (.parameters signature))))
    (animate snippet `((name ,name) (parameters ,parameters) (return-type ,return-type)))))

(define ((define-function model snippet) function)
  (let* ((signature (.signature function))
         (return-type (code:->code model signature))
         (name (.name function))
         (parameters (.parameters signature))
         (comma (if (null? (.elements parameters)) "" ", "))
         (statement (.statement function))
         (locals (map (lambda (x) (cons (.name x) x)) (.elements parameters)))
         (parameters (code:->code model parameters))
         (statements (code:->code model statement locals 2 #f))
         (model (.name model)))
    (animate snippet `((name ,name) (model ,model) (return-type ,return-type)
                       (comma ,comma) (parameters ,parameters)
                       (statements ,statements)))))

(define ((define-on model port snippet) event)
  (let* ((signature (.signature event))
         (type (.type signature))
         (return-type (return-type port event))
         (parameters (code:->code model (.parameters signature)))
         (parameter-types (map (lambda (parameter)
                                 (animate-snippet 'parameter-type `((type ,(->code model (.type parameter))) (out? ,(member (.direction parameter) '(inout out))))))
                               ((compose .elements .parameters) signature)))
         (reply-name (.name type))
         (reply-type (.type port))
         (statement
          (or (and-let*
               (((is-a? model <component>))
                (component model)
                (behaviour (.behaviour component))
                (statement (.statement behaviour)))
               (parameterize ((statements.port port)
                              (statements.event event))
                 (code:->code model statement '() 2 #f)))
              "")))
    (animate snippet `((port ,(.name port))
                       (event ,(.name event))
                       (direction ,(.direction event))
                       (model ,(.name model))
                       (parameters ,parameters)
                       (parameter-types ,parameter-types)
                       (reply-name ,reply-name)
                       (reply-type ,reply-type)
                       (return-type ,return-type)
                       (statement ,statement)
                       (type ,(.name type))))))

(define ((init-bind model snippet) bind)
  (let* ((left (.left bind))
         (left-port (gom:port model left))
         (right (.right bind))
         (port (and (bind-port? bind)
                    (if (not (.instance left)) (.port left) (.port right))))
         (instance (and (bind-port? bind)
                        (if (not (.instance left))
                            (binding-name model right)
                            (binding-name model left)))))
    (animate snippet `((port ,port) (instance ,instance)))))

(define ((init-instance snippet) instance)
  (let ((component (.component instance))
        (name (.name instance)))
    (animate snippet `((component ,component) (name ,name)))))

(define ((include-component snippet) instance)
  (let ((component (.component instance)))
    (animate snippet `((component ,component)))))

(define ((include-interface snippet) port)
  (let ((interface (.type port)))
    (animate snippet `((interface ,interface)))))

(define ((init-member model snippet) variable)
  (let* ((name (.name variable))
         (type (.type variable))
         (expression (expression->string model (.expression variable)))
         (type (code:->code model type)))
    (animate snippet `((name ,name) (type ,type) (expression ,expression)))))

(define ((init-port snippet) port)
  (let* ((name (.name port))
         (interface (.type port))
         (injected? (.injected port)))
    (animate snippet `((name ,name) (interface ,interface)))))

(define-method (declare-replies (o <interface>))
  (map
   (lambda (x) (snippet 'declare-reply `((type ,(.name o)) (name ,(.name x)))))
   (gom:interface-enums o)))

(define-method (return-type port (event <event>))
  (let ((type ((compose .type .signature) event))
        (scope (and=> port .type)))
    (cond
      ((eq? (.name type) 'bool) (snippet 'bool '()))
      ((eq? (.name type) 'void) 'void)
      (scope
       (snippet 'type-enum `((space "") (scope ,scope) (name ,(.name type)))))
      (else
       (snippet 'type-local-enum `((space "") (scope ,scope) (name ,(.name type))))))))

(define (binding-name model bind)
  (let ((instance (gom:instance model bind))
        (port (gom:port model bind)))
    (snippet 'binding
             `((instance . ,(match instance
                              (($ <instance>) (.name instance))
                              (($ <interface>) (.name instance))))
               (port . ,(match port
                          (($ <gom:port>) (.name port))
                          (($ <interface>) (list "x" (.name port)))))))))

(define (bind-port? binding)
  (or (not (.instance (.left binding))) (not (.instance (.right binding)))))

(define (injected-binding? binding)
  (or (eq? '* (.port (.left binding)))
      (eq? '* (.port (.right binding)))))

(define (injected-binding binding)
  (cond ((eq? '* (.port (.left binding))) (.right binding))
        ((eq? '* (.port (.right binding))) (.left binding))
        (else #f)))

(define (injected-bindings model)
  (filter injected-binding? ((compose .elements .bindings) model)))

(define (injected-instance-name binding)
  (or (.instance (.left binding)) (.instance (.right binding))))

(define (non-injected-instances model)
(let ((injected-instance-names (map injected-instance-name (injected-bindings model))))
  (filter (lambda (instance) (not (member (.name instance) injected-instance-names)))
          ((compose .elements .instances) model))))
