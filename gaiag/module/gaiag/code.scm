;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
;; Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  :use-module (gaiag list match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag annotate)  
  :use-module (gaiag gaiag)
  :use-module (gaiag indent)
  :use-module (gaiag misc)
  :use-module (gaiag norm-state)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
;;  :use-module (gaiag wfc)

  :use-module (gaiag ast)

  :export (ast:code
           code:om
           code:identifier?
           code:import
           code:->code
           code:extension
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
           enum-to-string
           string-to-enum
           include-component
           include-interface
           init-bind
           init-instance
           init-member
           init-port
           injected-binding
           injected-binding?
           injected-bindings
           injected-instance-interface
           injected-instance-name
           injected-instance-port
           injected-instance-type
           language
           injected-instances
           non-injected-instances
           join
           dump-indented
           expression->string
           indenter
           pipe
           return-type
           sep
           statements.event
           statements.port
           string-if
           *scope*
           ))

(define (ast:code ast)
  (let ((om ((om:register code:om) ast #t)))
    (map dump (filter (negate om:imported?) ((om:filter <model>) om)))
    (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
      (dump-header)))
  "")

(define (code:import name)
  (om:import name code:om))

(define (code:om ast)
  ((compose csp-norm-state
            ;;ast:wfc
            ast:resolve
            ast->om
            ) ast))

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define join (make-parameter (->join ", ")))
(define sep (make-parameter ","))
(define indenter (make-parameter indent))

(define (*scope* s)
 (if (eq? s '*global*) 'global s))

(define (dump-indented file-name thunk)
  (dump-output file-name
               (if (indenter)
                   (lambda () (pipe thunk (lambda () ((indenter)))))
                   thunk)))

(define (dump-header)
  (and-let* ((header (template-file `(header ,(code:extension (make <component>)))))
             (header (components->file-name header))
             ((file-exists? header)))
            (dump-file (basename header) (gulp-file header))))

(define (dump-global o)
  (and-let* (((null-is-#f (om:enums)))
             (template (template-file `(,(language) global ,(symbol-append (code:extension o) '.scm))))
             ((file-exists? (components->file-name template))))
            (dump-indented (list 'dezyne 'global (code:extension o))
                           (lambda ()
                             (code-file 'global (code:module o))))))

(define (dump o)
  (match o
    (($ <interface>) (dump-interface o))
    (($ <component>) (dump-component o))
    (($ <system>) (dump-system o))))

(define (dump-interface o)
  (mkdir-p "dezyne")
  (dump-global o)
  (let ((name (.name o)))
    (dump-indented (list 'dezyne name (code:extension o))
                   (lambda ()
                     (code-file 'interface (code:module o))))))

(define (dump-component o)
  (mkdir-p "dezyne")
  (dump-global o)
  (let ((name (.name o))
        (interfaces (map code:import (map .type ((compose .elements .ports) o)))))
    (when (.behaviour o)
      (map dump interfaces)
      (dump-indented (list 'dezyne name (code:extension o))
                   (lambda ()
                     (code-file 'component (code:module o)))))
    (dump-main o)))

(define (dump-main o)
  (and-let* ((name (.name o))
             (model (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                                string->symbol)))
             ((eq? model name))
             ;;(main (symbol-append 'main (code:extension o) '.scm))
             ;;((file-exists? main))
             )
            (dump-indented (symbol-append 'main (code:extension o))
                           (lambda ()
                             (code-file 'main (code:module o))))))

(define (dump-system o)
  (mkdir-p "dezyne")
  (let ((name (.name o))
        (model (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                           string->symbol)))
        (interfaces (map code:import (map .type ((compose .elements .ports) o)))))
    (dump-indented (list 'dezyne name (code:extension o))
                   (lambda ()
                     (code-file 'system (code:module o))))
    (dump-main o)))

(define (code-file file-name module)
  (let ((model (module-ref module 'model)))
   (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
     (animate-file (symbol-append file-name (code:extension model) '.scm) module))))

(define* (code:->code model src :optional (locals '()) (indent 1) (compound? #t))
  (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
    (->code model src locals indent compound?)))

(define statements.port (make-parameter #f))
(define statements.event (make-parameter #f))

(define (animate-snippet name pairs)
  (parameterize ((template-dir (append (template-dir) '(snippets))))
    (animate-template name pairs)))

(define snippet animate-snippet)

(define (language)
  (string->symbol (option-ref (parse-opts (command-line)) 'language 'c++)))

(define (code:extension o)
  (match o
    (($ <interface>)
     (assoc-ref `((c . .h)
                  (c++ . .hh)
                  (goops . .scm)
                  (java . .java)
                  (javascript . .js)
                  (cs . .cs)
                  (python . .py))
                (language)))
    ((or ($ <component>) ($ <system>))
     (assoc-ref '((c . .c)
                  (c++ . .cc)
                  (goops . .scm)
                  (java . .java)
                  (javascript . .js)
                  (cs . .cs)
                  (python . .py))
                (language)))))

(define (code:module o)
  (let ((module (make-module 31 (list
                                 (resolve-module (list 'gaiag (language)))
                                 (resolve-module '(gaiag misc))))))
    (module-define! module 'model o)
    (module-define! module '.model (.name o))
    (match o
      (($ <interface>)
       (module-define! module '.interface (.name o))
       (module-define! module '.INTERFACE (string-upcase (symbol->string (.name o)))))
      ((? (is? <model>))
       (module-define! module '.COMPONENT (string-upcase (symbol->string (.name o))))))
      module))

(define* (->code model src :optional (locals '()) (indent 1) (compound? #t))
  (let ((statement (->code- model src locals indent compound?)))
    (if (eq? statement '$empty-statement$)
        ""
        (->string statement))))

(define (unspecified? x) (eq? x *unspecified*))

(define* (->code- model src :optional (locals '()) (indent 1) (compound? #t))
  (define (enum? identifier) (om:enum model identifier))
  (define (extern? identifier) (om:extern model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (member? identifier) (and (not (local? identifier))
                                    (om:variable model identifier)))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
  (define (formal? identifier) (and=> (var? identifier) (is? <formal>)))
  (define (identifier-snippet identifier)
    (cond ((member? identifier)
           (snippet 'member `((identifier ,identifier))))
          ((formal? identifier)
           (snippet 'formal-identifier
                    `((identifier ,identifier)
                      (out? ,(om:out-or-inout? (formal? identifier)))
                      (argument . #f))))
          ((local? identifier)
           (snippet 'local `((identifier ,identifier) (argument #f))))
          (else identifier)))

  (let ((port (statements.port))
        (event (statements.event))
        (space (make-string (* indent (if (eq? (language) 'python) 4 2)) #\space)))
    (match src
      (() "")
      ('$empty-statement$ (snippet 'empty `((space ,space))))
      (($ <guard> expression (and ($ <guard>) statement))
       (let* ((statement (->code model (make <compound> :elements (list statement)) locals (1+ indent)))
              (statement (if (eq? statement '$empty-statement$)
                             (->code model statement locals (1+ indent))
                             statement)))
         (snippet 'guard
                  `((space ,space)
                    (clause ,(expr->clause model src expression))
                    (statement ,statement)))))
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
                   (identifier ,(identifier-snippet identifier))
                   (expression ,(expression->string model (action) locals)))))
      (($ <assign> identifier (and ($ <call>) (get! call)))
         (snippet 'assign
                  `((space ,space)
                    (identifier ,(identifier-snippet identifier))
                    (expression ,(expression->string model (call) locals)))))
      (($ <assign> identifier expression)
       (snippet 'assign
                `((space ,space)
                  (identifier ,(identifier-snippet identifier))
                  (expression ,(expression->string model expression locals)))))
      (($ <on> triggers statement)
       (or (and-let* ((trigger ((find-trigger port event) src)))
                     (let* ((aliases
                             (let loop ((formals ((compose .elements .formals .signature) event))
                                        (arguments (map (compose .name .value) ((compose .elements .arguments) trigger))))
                               (if (null? arguments)
                                   '()
                                   (let* ((formal (car formals))
                                          (type (->code model (.type formal) '(foo bar baz)))
                                          (out? (member (.direction formal) '(inout out)))
                                          (name (.name formal))
                                          (alias (car arguments))
                                          (rest (loop (cdr formals) (cdr arguments))))
                                     (if (eq? alias name)
                                         rest
                                         (begin
                                           (set! locals (acons alias (.name formal) locals))
                                           (cons (snippet 'alias `((type ,type) (name ,name) (out? ,out?) (alias ,alias) (space ,space)))
                                                 rest)))))))
                            (statement (->code model statement locals indent compound?))
                            (statement (if (pair? aliases)
                                           (snippet 'compound
                                                    `((space ,space)
                                                      (statements
                                                       ,(snippet 'context
                                                                 `((space ,space) (statement ,aliases) (continuation ,statement))))))
                                           statement)))
                       statement))
           '$empty-statement$))
      (($ <call> function ('arguments))
       (snippet 'call `((space ,space) (function ,function))))
      (($ <call> function ('arguments arguments ...))
       (let* ((formals ((compose .elements .formals .signature) (om:function model function)))
            (arguments ((join)
                        (map (lambda (e p)
                               (let ((out? (member (.direction p) '(inout out))))
                                 (snippet 'argument `((expression . ,(expression->string model e locals (if out? 'out 'in)))
                                                      (out? ,(member (.direction p) '(inout out)))))))
                             arguments formals))))
         (snippet 'call-arguments
                  `((space ,space) (function ,function) (arguments ,arguments)))))
      (('arguments arguments ...)
       ((join)
        (map (lambda (o) (expression->string model o locals)) arguments)))
      (('compound) (snippet 'compound-empty `((space ,space))))
      (('compound statements ...)
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
                    (let ((statement (->code model (car statements) locals indent))
                          (continuation (loop (cdr statements) locals)))
                      (if variable?
                          (list (snippet 'context `((space ,space)
                                                    (statement ,statement)
                                                    (continuation ,continuation))))
                          (cons statement continuation))))))))))
      (($ <illegal>) (snippet 'illegal `((space ,space))))
      (($ <action> ($ <trigger> port-name event-name ('arguments arguments ...)))
       (let* ((port (om:port model port-name))
              (name (.type port))
              (interface (om:import name))
              (event (om:event interface event-name))
              (direction (.direction event))
              (comma (if (pair? arguments) (sep) ""))
              (comma-space (if (pair? arguments) `(,(sep) " ") ""))
              (number (number->string (length arguments)))
              (formals ((compose .elements .formals .signature) event))
              (arguments ((join)
                          (map (lambda (e p)
                                 (let ((out? (member (.direction p) '(inout out))))
                                   (snippet 'argument `((expression . ,(expression->string model e locals (if out? 'out 'in)))
                                                        (out? ,(member (.direction p) '(inout out)))))))
                               arguments formals))))
         (snippet (symbol-append 'action- direction)
                  `((space ,space)
                    (port ,port-name)
                    (direction ,direction)
                    (event ,event-name)
                    (arguments ,arguments)
                    (number ,number)
                    (comma ,comma)
                    (comma-space ,comma-space)))))
      (($ <reply> (and ($ <expression> ($ <literal> scope type field)) (get! expression)))
       (snippet 'reply
                `((space ,space)
                  (scope ,scope)
                  (name ,type)
                  (expression ,(expression->string model (expression) locals)))))
      (($ <reply> (and ($ <expression> ($ <var> name)) (get! expression)))
       (let* ((decl (var? name))
              (type (.type decl)))
         (snippet 'reply
                  `((space ,space)
                    (scope ,(.scope type))
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
      ((and (? (is? <*type*>)) (? extern?))
       (let* ((extern (extern? src))
              (value (.value extern)))
         (snippet 'type-extern `((space ,space) (value ,value)))))
      (($ <type> name '*global*)
       (snippet 'type-global-enum `((space ,space) (scope global) (name ,name))))
      (($ <type> (and (? enum?) (get! name)) #f)
       (snippet 'type-local-enum `((space ,space) (scope ,(.name model)) (name ,(name)))))
      (($ <type> name #f)
       (snippet 'type-local `((space ,space) (scope ,(.name model)) (name ,name))))
      ((and ($ <type> name scope) (? enum?))
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
      (('formals formals ...)
       ((join) (map (lambda (x) (->code model x)) formals)))
      (($ <formal> name type direction)
       (snippet 'formal `((name ,name) (type ,(->code model type)) (out? ,(member direction '(inout out))))))
      (($ <data> value) value)
      ((? char?) (make-string 1 src))
      ((? string?) src)
      ('true (snippet 'true '()))
      ('false (snippet 'false '()))
      (#t (snippet 'true '()))
      (#f (snippet 'false '()))
      ((? symbol?) src)
      ((h t ...) (map (lambda (x) (->code model x locals indent)) src))
      ((? unspecified?) #f)
      (_ (throw 'match-error (format #f "~a:code:->code: no match: ~a\n" (current-source-location) src))))))

(define ((find-trigger port event) o)
  (match o
    (($ <on>)
     (find (lambda (t) (and (eq? (.port t) (.name port))
                            (eq? (.event t) (.name event))))
           ((compose .elements .triggers) o)))
    (($ <guard>) ((find-trigger port event) ( .statement o)))
    (('compound statements ...)
     (null-is-#f (filter identity (map (find-trigger port event) statements))))
    (_ #f)))

(define (expr->clause model guard expression)
  (if (is-a? expression <otherwise>)
      (snippet 'clause-else '())
      (let* ((c-expression (bool-expression->string model expression))
             (if-clause (snippet 'clause-if `((expression ,c-expression))))
             (else-if-clause (snippet 'clause-else-if `((expression ,c-expression)))))
        (->string (list (if (om:first-guard? model guard) if-clause else-if-clause))))))

(define (om:top-statements o)
  ((compose .elements .statement .behaviour) o))

(define (om:first-guard? model guard)
  (not
   (and-let* ((parent (om:parent model guard))
              (parent (cond ((is-a? parent <guard>) (.statement parent))
                            ((is-a? parent <on>) (om:parent model parent))
                            (else parent)))
              (guards
               ;;((om:statements-of-type 'guard) parent)
               (filter (is? <guard>) parent)
               )
              (guards (filter (find-trigger (statements.port) (statements.event)) guards))
              (guards (null-is-#f guards)))
             (not (eq? guard (car guards))))))

(define (om:top-guard? model guard)
  (member guard (om:top-statements model)))

(define (bool-expression->string model o)
  (match o
    (($ <field> identifier field)
     (snippet 'field `((identifier ,identifier) (field ,field))))
    (($ <literal> '*global* type field)
     (snippet 'literal-global `((scope . *global*) (type ,type) (field ,field))))
    (($ <literal> #f type field)
     (snippet 'literal-local `((scope . #f) (type ,type) (field ,field))))
    (($ <literal> scope type field)
     (snippet 'literal `((scope ,scope) (type ,type) (field ,field))))
    (_ (expression->string model o))))

(define* (expression->string model o :optional (locals '()) (argument #f))

  (define (enum? identifier) (om:enum model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (member? identifier) (and (not (local? identifier))
                                    (om:variable model identifier)))
  (define (var? identifier) (or (local? identifier) (member? identifier)))
  (define (formal? identifier) (and=> (var? identifier) (is? <formal>)))
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
    (($ <expression>) (expression->string model (.value o) locals argument))
    (($ <action> ($ <trigger> port-name event-name ('arguments arguments ...)))
     (let* ((port (om:port model port-name))
            (name (.type port))
            (interface (om:import name))
            (event (om:event interface event-name))
            (direction (.direction event))
            (comma (if (pair? arguments) (sep) ""))
            (comma-space (if (pair? arguments) `(,(sep) " ") ""))
            (number (number->string (length arguments)))
            (formals ((compose .elements .formals .signature) event))
            (arguments ((join)
                        (map (lambda (e p)
                               (let ((out? (member (.direction p) '(inout out))))
                                 (snippet 'argument `((expression . ,(expression->string model e locals (if out? 'out 'in)))
                                                      (out? ,(member (.direction p) '(inout out)))))))
                             arguments formals))))
       (snippet 'action-expression
                `((port ,port-name)
                  (direction ,direction)
                  (event ,event-name)
                  (arguments ,arguments)
                  (number ,number)
                  (comma ,comma)
                  (comma-space ,comma-space)))))
    (($ <var> (and (? member?) (get! identifier)))
     (snippet 'member `((identifier ,(identifier)) (argument ,argument))))
    (($ <var> (and (? formal?) (get! identifier)))
     (snippet 'formal-identifier
              `((identifier ,(identifier))
                (out? ,(om:out-or-inout? (formal? (identifier))))
                (argument ,argument))))
    (($ <var> (and (? local?) (get! identifier)))
     (snippet 'local `((identifier ,(identifier)) (argument ,argument))))
    (($ <var> identifier)
     identifier)
    (($ <field> (and (? member?) (get! identifier)) field)
     (snippet 'field-expression `((identifier ,(snippet 'member `((identifier ,(identifier)))))
                                  (expression ,(enum-type (identifier) field)))))
    (($ <field> (and (? local?) (get! identifier)) field)
     (snippet 'field-expression `((identifier ,(snippet 'local `((identifier ,(identifier)) (argument ,argument))))
                                  (expression ,(enum-type (identifier) field)))))
    (($ <field> identifier field)
     (snippet 'field-expression `((identifier ,identifier)
                                  (expression ,(enum-type identifier field)))))
    (($ <call> function ('arguments))
        (snippet 'call-expression `((function ,function))))
    (($ <call> function ('arguments arguments ...))
     (let* ((formals ((compose .elements .formals .signature) (om:function model function)))
            (arguments ((join)
                        (map (lambda (e p)
                               (let ((out? (member (.direction p) '(inout out))))
                                 (snippet 'argument `((expression . ,(expression->string model e locals (if out? 'out 'in)))
                                                      (out? ,(member (.direction p) '(inout out)))))))
                             arguments formals))))
       (snippet 'call-arguments-expression
                `((function ,function) (arguments ,arguments)))))
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
         (left-port (om:port model left))
         (right (.right bind))
         (right-port (om:port model right))
         (provided-required (if (om:provides? left-port)
                                (cons left right)
                                (cons right left)))
         (interface (.type left-port))
         (provided (binding-name model (car provided-required)))
         (required (binding-name model (cdr provided-required))))
    (animate snippet `((interface ,interface) (provided ,provided) (required ,required)))))

(define ((declare-enum model) enum)
  (let* ((scope (or (.scope enum) (.name model)))
         (fields ((compose .elements .fields) enum))
         (length (length fields)))
   (snippet 'declare-enum
            `((scope ,scope) (name ,(.name enum)) (fields ,fields) (length ,length)))))

(define ((enum-to-string o) enum)
  (let* ((fields ((compose .elements .fields) enum))
         (length (length fields))
         (scope (or (.scope enum) (.name o))))
    (snippet 'enum-to-string
             `((scope ,scope) (name ,(.name enum)) (fields ,fields) (length ,length)))))

(define ((string-to-enum o) enum)
  (let* ((fields ((compose .elements .fields) enum))
         (length (length fields))
         (scope (or (.scope enum) (.name o))))
   (snippet 'string-to-enum
            `((scope ,scope) (name ,(.name enum)) (fields ,fields) (length ,length)))))

(define (declare-integer integer)
  (snippet 'declare-integer `((name ,(.name integer)))))

(define ((declare-io model snippet) event)
  (let* ((name (.name event))
         (signature (.signature event))
         (type ((compose .name .type) signature))
         (return-type (return-type #f event))
         (formals (.formals signature))
         (formal-list (map (lambda (x) (code:->code model x)) (.elements formals)))
         (formal-objects (.elements formals))
         (formal-types (map (lambda (formal)
                                 (animate-snippet 'formal-type `((type ,(->code model (.type formal))) (out? ,(member (.direction formal) '(inout out))))))
                               ((compose .elements .formals) signature)))
         (comma (if (pair? (.elements formals)) (sep) ""))
         (comma-space (if (pair? (.elements formals)) `(,(sep) " ") ""))
         (formals (code:->code model formals)))
    (animate snippet `((name ,name) (comma ,comma) (comma-space ,comma-space) (formals ,formals) (formal-list ,formal-list) (formal-objects ,formal-objects) (formal-types ,formal-types) (return-type ,return-type)))))

(define ((define-function model snippet) function)
  (let* ((signature (.signature function))
         (return-type (code:->code model signature))
         (name (.name function))
         (formals (.formals signature))
         (comma (if (null? (.elements formals)) "" (sep)))
         (comma-space (if (null? (.elements formals)) "" `(,(sep) " ")))
         (statement (.statement function))
         (locals (map (lambda (x) (cons (.name x) x)) (.elements formals)))
         (formals (code:->code model formals))
         (statements (code:->code model statement locals 2 #f))
         (model (.name model)))
    (animate snippet `((name ,name) (model ,model) (return-type ,return-type)
                       (comma ,comma) (comma-space ,comma-space) (formals ,formals)
                       (statements ,statements)))))

(define ((om:statement-of-type type) statement)
  (and statement
   (eq? (ast-name statement) type)))

(define ((om:statements-of-type type) statement)
  (match statement
    ((? (om:statement-of-type type)) (list statement))
    (('compound s ...) (filter identity (apply append (map (om:statements-of-type type) s))))
    (($ <on> triggers statement) (filter identity ((om:statements-of-type type) statement)))
    ((? (is? <statement>)) '())
    (#f '())))

(define ((define-on model port snippet) event)
  (let* ((signature (.signature event))
         (type (.type signature))
         (enum (if (eq? (.name type) 'void) #f (om:enum model type)))
         (interface (.type port))
         (return-type (return-type port event))
         (formals (.formals signature))
         (argument-list (map .name (.elements formals)))
         (number (number->string (length argument-list)))
         (arguments (comma-join argument-list))
         (locals (let loop ((formals (.elements formals)) (locals '()))
                   (if (null? formals)
                       locals
                       (loop (cdr formals)
                             (acons (.name (car formals)) (car formals) locals)))))
         (comma (if (pair? (.elements formals)) (sep) ""))
         (comma-space (if (pair? (.elements formals)) (sep) ""))
         (formal-objects (.elements formals))
         (formal-list (map (lambda (x) (code:->code model x)) (.elements formals)))
         (formals (code:->code model formals))
         (formal-types (map (lambda (formal)
                                 (animate-snippet 'formal-type `((type ,(->code model (.type formal))) (out? ,(member (.direction formal) '(inout out))))))
                               ((compose .elements .formals) signature)))
         (reply-name (.name type))
         (reply-scope (or (and enum (.scope enum)) (.type port)))
         (statement
          (or (and-let*
               (((is-a? model <component>))
                (component model)
                (behaviour (.behaviour component))
                (statement (.statement behaviour))
                (guards
                 ;;((om:statements-of-type 'guard) statement)
                 (if (is-a? statement <guard>)
                     (list statement)
                     (filter (is? <guard>) statement))
                 )
                (ons
                 ((om:statements-of-type 'on) statement)
                 ;; (if (is-a? statement <on>)
                 ;;     (list statement)
                 ;;     (filter (is? <on>) statement))
                 )
                (guards (filter (find-trigger port event) guards))
                (ons (filter (find-trigger port event) ons)))
               (parameterize ((statements.port port)
                              (statements.event event))
                 (if (null? ons)
                     (code:->code model (make <compound> :elements guards) locals 2 #f)
                     (code:->code model ons locals 2 #f))))
              "")))
    (animate snippet `((port ,(.name port))
                       (event ,(.name event))
                       (argument-list ,argument-list)
                       (arguments ,arguments)
                       (direction ,(.direction event))
                       (comma ,comma)
                       (comma-space ,comma-space)
                       (enum ,enum)
                       (interface ,interface)
                       (number ,number)
                       (formals ,formals)
                       (formal-list ,formal-list)
                       (formal-objects ,formal-objects)
                       (formal-types ,formal-types)
                       (reply-name ,reply-name)
                       (reply-scope ,reply-scope)
                       (return-type ,return-type)
                       (statement ,statement)
                       (type ,(.name type))))))

(define ((init-bind model snippet) bind)
  (let* ((left (.left bind))
         (left-port (om:port model left))
         (right (.right bind))
         (right-port (om:port model right))
         (port (and (bind-port? bind)
                    (if (not (.instance left)) (.port left) (.port right))))
         (injected? (and (eq? port '*) port))
         (direction (or injected? (.direction (om:port model port))))
         (edir (or injected? (if (eq? direction 'provides) 'out 'in)))
         (interface (if injected? (if left-port (.type left-port) (.type right-port)) (.type (om:port model port))))
         (instance (and (bind-port? bind)
                        (if (not (.instance left))
                            (binding-name model right)
                            (binding-name model left)))))
    (animate snippet `((port ,port) (direction ,direction) (edir ,edir) (injected? ,injected?) (instance ,instance) (interface ,interface)))))

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
         (direction (.direction port))
         (interface (.type port))
         (injected? (.injected port)))
    (animate snippet `((name ,name) (direction ,direction) (injected? ,injected?) (interface ,interface)))))

(define (declare-replies o)
  (map (lambda (x) (snippet 'declare-reply
                            `((scope ,(or (.scope x) (.name o)))
                              (name ,(.name x)))))
       (om:reply-enums o)))

(define (return-type port event)
  (let* ((type ((compose .type .signature) event))
         (scope (or (.scope type) (and=> port .type)))
         (name (.name type)))
    (cond
      ((eq? name 'bool) (snippet 'bool '()))
      ((eq? name 'void) 'void)
      ((eq? (.scope type) '*global*)
       (snippet 'type-global-enum `((space "") (scope ,scope) (name ,name))))
      (scope (snippet 'type-enum `((space "") (scope ,scope) (name ,name))))
      (else
       (snippet 'type-local-enum `((space "") (scope ,scope) (name ,name)))))))

(define (binding-name model bind)
  (let ((instance (om:instance model bind))
        (port (om:port model bind)))
    (snippet 'binding
               `((instance . ,(match instance
                                (($ <instance>) (.name instance))
                                (($ <interface>) (.name instance))))
                 (port . ,(match port
                            (($ <port>) (.name port))
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

(define (injected-instance-port binding)
  (if (.instance (.left binding))
      (.port (.left binding))
      (.port (.right binding))))

(define (injected-instance-type model binding)
  (.component (om:instance model (if (.instance (.left binding))
                                      (.left binding)
                                      (.right binding)))))

(define (injected-instance-interface model binding)
  (.type (om:port (code:import (injected-instance-type model binding)))))

(define (injected-instances model)
  (let ((injected-instance-names (map injected-instance-name (injected-bindings model))))
    (filter (lambda (instance) (member (.name instance) injected-instance-names))
            ((compose .elements .instances) model))))

(define (non-injected-instances model)
  (let ((injected-instance-names (map injected-instance-name (injected-bindings model))))
    (filter (lambda (instance) (not (member (.name instance) injected-instance-names)))
            ((compose .elements .instances) model))))

(define-syntax string-if
  (syntax-rules ()
    ((_ condition then)
     (animate-string (if (null-is-#f condition) then "") (current-module)))
    ((_ condition then else)
     (animate-string (if (null-is-#f condition) then else) (current-module)))))

(define (code:identifier? name)
  (let* ((name (->string name))
         (first (car (string->list (->string name)))))
    (and (or (char-alphabetic? first)
             (eq? first #\_))
         (string-every (char-set-adjoin char-set:letter+digit #\_) name))))
