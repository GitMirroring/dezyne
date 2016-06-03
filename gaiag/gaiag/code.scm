;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
;; Copyright © 2014, 2015, 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (gaiag om)

  :use-module (gaiag animate)
  :use-module (gaiag annotate)
  :use-module (gaiag gaiag)
  :use-module (gaiag indent)
  :use-module (gaiag misc)
;;  :use-module (gaiag norm-event)
  :use-module (gaiag norm-state)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
;;  :use-module (gaiag wfc)


  :export (ast:code
           code:om
           code-file
           code:identifier?
           code:import
           code:->code
           code:extension
           enum-type
           ->code
           binding-name
           code:module
           declare-enum
           declare-io
           declare-integer
           declare-replies
           define-function
           define-reply
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

           animate-pairs

           ))

(define (ast:code ast)
  (let ((om ((om:register code:om #t) ast)))
    (map dump (filter (negate om:imported?) ((om:filter <model>) om)))
    (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
      (dump-header)))
  "")

(define (code:import name)
  (om:import name code:om))

(define (code:om ast)
  ((compose
    ;;code-norm-event
    csp-norm-state
    ;;ast:wfc
    ast:resolve
    ast->om
    ) ast))

(define (om:data-member-names model)
  (map .name (filter (lambda (x) (is-a? ((om:type model) (.type x)) <extern>)) (om:variables model))))

(define (transform-formals-shadow-member model formals)
  (define (rename formal)
    (make <formal> :name (symbol-append 'dzn_ (.name formal)) :type (.type formal) :direction (.direction formal)))
  (let* ((members (om:data-member-names model))
         (transform (lambda (f) (if (member (.name f) members) (rename f)
                                    f))))
    (map transform formals)))

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define (wrap-compound statement) (make <compound> :elements (list statement)))
(define indenter (make-parameter indent))
(define join (make-parameter (->join ", ")))
(define sep (make-parameter ","))

(define (dump-indented file-name thunk)
  (dump-output file-name
               (if (indenter)
                   (lambda () (pipe thunk (lambda () ((indenter)))))
                   thunk)))

(define (dump-header)
  (and-let* ((header (template-file `(header ,(code:extension (make <component>)))))
             (header (components->file-name header))
             ((file-exists? header)))
            (dump-string (basename header) (gulp-file header))))

(define (dump-global o)
  (and-let* (((null-is-#f (om:enums)))
             (template (template-file `(,(language) global ,(symbol-append (code:extension o) '.scm))))
             ((file-exists? (components->file-name template))))
            (dump-indented (list 'dzn 'global (code:extension o))
                           (lambda ()
                             (code-file 'global (code:module o))))))

(define (dump o)
  (match o
    (($ <interface>) (dump-interface o))
    (($ <component>) (dump-component o))
    (($ <system>) (dump-system o))))

(define (dump-interface o)
  (dump-global o)
  (let ((name ((om:scope-name) o)))
    (dump-indented (list 'dzn name (code:extension o))
                   (lambda ()
                     (code-file 'interface (code:module o))))))

(define (dump-component o)
  (dump-global o)
  (let ((name ((om:scope-name) o))
        (interfaces (map code:import (map .type ((compose .elements .ports) o)))))
    (when (.behaviour o)
      (map dump interfaces)
      (dump-indented (list 'dzn name (code:extension o))
                   (lambda ()
                     (code-file 'component (code:module o)))))
    (dump-main o)))

(define (dump-main o)
  (and-let* ((name ((om:scope-name) o))
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
  (let ((name ((om:scope-name) o))
        (model (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                           string->symbol)))
        (interfaces (map code:import (map .type ((compose .elements .ports) o)))))
    (dump-indented (list 'dzn name (code:extension o))
                   (lambda ()
                     (code-file 'system (code:module o))))
    (dump-main o)))

(define (code-file file-name module)
  (let ((model (module-ref module 'model)))
   (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
     (animate-file (symbol-append file-name (code:extension model) '.scm) module))))

(define* (code:->code model src :optional (blocking? #f) (locals '()) (indent 1) (compound? #t))
  (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
    (->code model src blocking? locals indent compound?)))

(define statements.port (make-parameter #f))
(define statements.event (make-parameter #f))

(define (language)
  (string->symbol (option-ref (parse-opts (command-line)) 'language 'c++)))

(define (code:extension o)
  (match o
    (($ <interface>)
     (assoc-ref '((c . .h)
                  (c++ . .hh)
                  (c++03 . .hh)
                  (c++-msvc11 . .hh)
                  (dzn . .dzn)
                  (goops . .scm)
                  (java . .java)
                  (java7 . .java)
                  (javascript . .js)
                  (cs . .cs)
                  (python . .py))
                (language)))
    ((or ($ <component>) ($ <system>))
     (assoc-ref '((c . .c)
                  (c++ . .cc)
                  (c++03 . .cc)
                  (c++-msvc11 . .cc)
                  (dzn . .dzn)
                  (goops . .scm)
                  (java . .java)
                  (java7 . .java)
                  (javascript . .js)
                  (cs . .cs)
                  (python . .py))
                (language)))))

(define* (code:module o)
  (let ((module (make-module 31 (list
                                 (resolve-module (list 'gaiag (language)))
                                 (resolve-module '(gaiag misc))))))
    (module-define! module 'model o)
    (module-define! module '.model (om:name o))
    (module-define! module '.scope_model ((om:scope-name) o))
    (match o
      (($ <interface>)
       (module-define! module '.interface (om:name o))
       (module-define! module '.scope_interface ((om:scope-name) o))
       (module-define! module '.INTERFACE (string-upcase (symbol->string ((om:scope-name) o)))))
      ((? (is? <model>))
       (module-define! module '.COMPONENT (string-upcase (symbol->string ((om:scope-name) o))))))
      module))

(define* (->code model src :optional (blocking? #f) (locals '()) (indent 1) (compound? #t))
  (let ((statement (->code- model src blocking? locals indent compound?)))
    (if (eq? statement '$empty-statement$)
        ""
        (->string statement))))

(define (unspecified? x) (eq? x *unspecified*))

(define* (->code- model src :optional (blocking? #f) (locals '()) (indent 1) (compound? #t))
  (define (enum? identifier)
    (debug "ENUM?[~a] ==> ~a\n" identifier (om:enum model identifier))
    (om:enum model identifier))
  (define (extern? identifier) (om:extern model identifier))
  (define (int? identifier)
    (debug "INT?[~a] ==> ~a\n" identifier (om:integer model identifier))
    (om:integer model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (member? identifier) (and (not (local? identifier))
                                    (om:variable model identifier)))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
  (define (alias? identifier) (and=> (local? identifier) (lambda (x) (and (symbol? x) x))))
  (define (formal? identifier) (and=> (var? identifier) (is? <formal>)))
  (define (identifier-snippet identifier)
    (cond ((member? identifier)
            (snippet 'member `((identifier ,identifier))))
          ((formal? identifier)
           (snippet 'formal-identifier
                    `((identifier ,identifier)
                      (out? ,(om:out-or-inout? (formal? identifier)))
                      (argument #f))))
          ((local? identifier)
           (snippet 'local `((identifier ,identifier) (argument #f))))
          ((is-a? identifier <name>)
           (let* ((name (om:name identifier))
                  (alias (or (alias? name) name))
                  (formal (formal? alias))
                  (type-name ((compose om:name (om:type model)) formal)))
             (snippet 'formal-out-identifier `((type ,type-name)
                                               (name ,alias)))))
          (else identifier)))
  (define (expression-type o locals)
    (match o
      (($ <expression> expression) (expression-type expression locals))
      (($ <literal>) 'enum)
      (($ <var> name) (let* ((var (var? name))
                             (type (.type var)))
                        (ast-name ((om:type model) type))))
      ((? number?) 'int)
      ('false 'bool)
      ('true 'bool)
      (((or '+ '- '* '/) lhs rhs) 'int)
      (((or 'or 'and '== '!= '< '<= '> '>=) lhs rhs) 'bool)
      (('- _) 'int)
      (('! _) 'bool)
      ((? unspecified?) 'void)
      (_ 'bool)))

  (define (reply-port port)
    (or port
        (and=> (or (and (statements.port) (om:provides? (statements.port)) (statements.port))
                   (car (filter om:provides? (om:ports model))))
               .name)))

  (let ((port (statements.port))
        (event (statements.event))
        (space (make-string (* indent (if (eq? (language) 'python) 4 2)) #\space)))
    (match src
      (() "")
      ('$empty-statement$ (snippet 'empty `((space ,space))))
      (($ <guard> expression ('compound statements ...))
       (let* ((statement (.statement src))
              (statement (->code- model statement blocking? locals (1+ indent)))
              (statement (if (eq? statement '$empty-statement$)
                             (->code model statement blocking? locals (1+ indent))
                             statement)))
         (snippet 'guard
                  `((space ,space)
                    (clause ,(expr->clause model src expression))
                    (statement ,statement)))))
      (($ <guard> expression statement)
       (let* ((statement (wrap-compound statement))
              (statement (->code- model statement blocking? locals (1+ indent)))
              (statement (if (eq? statement '$empty-statement$)
                             (->code model statement blocking? locals (1+ indent))
                             statement)))
         (snippet 'guard
                  `((space ,space)
                    (clause ,(expr->clause model src expression))
                    (statement ,statement)))))
      (($ <if> expression then #f)
       (snippet 'if-then
                `((space ,space)
                  (expression ,(expression->string model expression locals))
                  (then ,(->code model then blocking? locals (1+ indent))))))
      (($ <if> expression (and ($ <if> e t) (get! then)) else)
       (->code- model (make <if> :expression expression :then (wrap-compound (then)) :else else) blocking? locals indent))
      (($ <if> expression then else)
       (snippet 'if-then-else
                `((space ,space)
                  (expression ,(expression->string model expression locals))
                  (then ,(->code model then blocking? locals (1+ indent)))
                  (else ,(->code model else blocking? locals (1+ indent))))))
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
      (($ <blocking> statement)
       (->code- model statement #t locals indent))
      (($ <on> triggers (and ($ <if> e t #f) (get! statement)))
       (->code- model (make <on> :triggers triggers :statement (wrap-compound (statement))) blocking? locals indent))
      (($ <on> triggers statement)
       (or (and-let* ((trigger ((find-trigger port event) src))
                      (formals ((compose .elements .formals .signature) event))
                      (formals (transform-formals-shadow-member model formals))
                      (arguments ((compose .elements .arguments) trigger))
                      (argument-names (map (compose (lambda (n) (match n (('name name) name) (_ n))) .name .value) arguments)))
                     (let* ((aliases
                             (let loop ((formals formals)
                                        (arguments argument-names))
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
                            (blocking? (pair? ((om:collect <blocking>) statement)))
                            (statement (->code model statement blocking? locals indent compound?))
                            (statement (if (pair? aliases)
                                           (snippet 'compound
                                                    `((space ,space)
                                                      (statements
                                                       ,(snippet 'context
                                                                 `((space ,space) (statement ,aliases) (continuation ,statement))))))
                                           statement))
                            (statement (if (or (not blocking?) (eq? (.direction port) 'requires)) statement
                                           `(,(out-bindings model port formals arguments)
                                             ,(snippet 'block
                                                       `((space ,space)
                                                         (statement ,statement)
                                                         (port ,(.port trigger))))))))
                       statement))
           '$empty-statement$))
      (($ <call> function ('arguments))
       (snippet 'call `((space ,space) (function ,function))))
      (($ <call> function ('arguments arguments ...))
       (let* ((formals ((compose .elements .formals .signature) (om:function model function)))
            (arguments ((join)
                        (map (lambda (e p)
                               (let ((out? (member (.direction p) '(inout out))))
                                 (snippet 'argument `((expression ,(expression->string model e locals (if out? 'out 'in)))
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
                    (let ((statement (->code model (car statements) blocking? locals indent))
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
                                   (snippet 'argument `((expression ,(expression->string model e locals (if out? 'out 'in)))
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
      (($ <reply> (and ($ <expression> ($ <literal> name field)) (get! expression)) port)
       (debug "reply0: ~a\n" (expression))
       (let ((port (reply-port port)))
         (->string
          (list (snippet 'reply
                         `((space ,space)
                           (scope ,(om:scope name))
                           (name ,(om:name name))
                           (expression ,(expression->string
                                         model (expression) locals))))
                (if (om:blocking? model)  (snippet 'release
                                                   `((space ,space)
                                                     (scope ,(om:scope name))
                                                     (name ,(om:name name))
                                                     (port ,port))))))))
      (($ <reply> (and ($ <expression> ($ <var> name)) (get! expression)) port)
       (debug "reply1: ~a\n" (expression))
       (let* ((var (var? name))
              (type (.type var))
              (port (reply-port port)))
         (debug "reply1: var=~a\n" var)
         (debug "reply1: type=~a\n" type)
         (debug "reply1: expression=~a\n" (expression->string model (expression) locals))
         (->string (list
                    (snippet 'reply
                             `((space ,space)
                               (scope ,(om:scope type))
                               (name ,(om:name type))
                               (expression ,(expression->string
                                             model (expression) locals))))
                    (if (om:blocking? model) (snippet 'release
                                                      `((space ,space)
                                                        (scope ,(om:scope type))
                                                        (name ,(om:name type))
                                                        (port ,port))))))))
      (($ <reply> (and ($ <expression> (? unspecified?)) (get! expression)) port)
       (debug "reply2: ~a\n" (expression))
       (let ((port (reply-port port)))
         (if (om:blocking? model) (snippet 'release
                                           `((space ,space)
                                             (port ,port))))))
      (($ <reply> (and ($ <expression>) (get! expression)) port) (=> failure)
       (debug "\nreply3: ~a\n" (expression))
       (if (eq? (expression) *unspecified*) (failure)
           (let* ((scope '())
                  (type (expression-type (expression) locals))
                  (port (reply-port port)))
             (debug "reply3: type=~a\n" type)
             (debug "reply3: expression=~a\n" (expression->string model (expression) locals))
             (->string (list (snippet 'reply
                                      `((space ,space)
                                        (scope ,scope)
                                        (name ,type)
                                        (expression ,(expression->string model (expression) locals))))
                             (if (om:blocking? model) (snippet 'release
                                                               `((space ,space)
                                                                 (scope ,scope)
                                                                 (name ,type)
                                                                 (port ,port)))))))))
      (($ <reply> expression port)
       (let ((port (reply-port port)))
         (if (om:blocking? model) (snippet 'release
                                           `((space ,space)
                                             (port ,port))))))
      (($ <return> #f) (snippet 'return-void `((space ,space))))
      (($ <return> expression)
       (snippet 'return
                `((space ,space)
                  (expression ,(expression->string model expression locals)))))
      (($ <signature> type) (->code model type blocking? locals indent))
      (($ <type> 'bool) (snippet 'bool '()))
      (($ <type> 'void) 'void)
      ((and (? (is? <*type*>)) (? extern?))
       (let* ((extern (extern? src))
              (value (.value extern)))
         (snippet 'type-extern `((space ,space) (value ,value)))))
      ((and ($ <type> name) (? enum?))
       (debug "\ntype: ~a\n" src)
       (debug "scope: ~a\n" (om:scope src))
       (debug "name: ~a\n" (om:name src))
       (debug "scope-name: ~a\n" (append (om:scope src) (list (om:name src))))
       (debug "we are here: ~a=> ~a\n" src        (snippet 'type-enum `((space ,space) (scope-name ,(append (om:scope src) (list (om:name src)))) (scope ,(om:scope src)) (name ,(om:name src)))))
       (snippet 'type-enum `((space ,space) (scope-name ,(append (om:scope src) (list (om:name src)))) (scope ,(om:scope src)) (name ,(om:name src)))))
      ((and ($ <type> name) (? int?))
       (snippet 'type-int `((space ,space) (scope-name ,(append (om:scope src) (list (om:name src)))) (scope ,(om:scope src)) (name ,(om:name src)))))
      (($ <type> name)
       (snippet 'type `((scope-name ,(cdr name)) (space ,space) (scope ,(om:scope src)) (name ,(om:name src)))))
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
      ((h t ...) (map (lambda (x) (->code model x blocking? locals indent)) src))
      ((? unspecified?) #f)
      (_ (throw 'match-error (format #f "~a:code:->code: no match: ~a\n" (current-source-location) src))))))

(define (out-bindings model port formals arguments)
  (let ((statements
         (filter-map
          (lambda (formal argument)
            (and (om:out-or-inout? formal)
                 (match argument (($ <expression> ('<- ('name alias) ($ <var> global)))
                                  (snippet 'out-binding `((alias ,alias) (formal ,(.name formal)) (global ,global) (port (.name port)))))
                   (_ #f)))) formals arguments)))
    (snippet 'out-bindings
             `((port ,(.name port))
               (statements ,statements)))))

(define ((find-trigger port event) o)
  (match o
    (($ <blocking>) ((find-trigger port event) (.statement o)))
    (($ <on>)
     (find (lambda (t) (and (eq? (.port t) (.name port))
                            (eq? (.event t) (.name event))))
           ((compose .elements .triggers) o)))
    (($ <guard>) ((find-trigger port event) (.statement o)))
    (('compound statements ...)
     (null-is-#f (filter identity (map (find-trigger port event) statements))))
    (_ #f)))

(define ((is-trigger? port event) o)
  (match o
    (($ <on> ('triggers ($ <trigger> p e)))
     (and (eq? p (.name port)) (eq? e (.name event)) o))
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

(define (norm-event-om:first-guard? model guard)
  (not
   (and-let* ((parent (om:parent model guard))
              (guards (null-is-#f (filter (is? <guard>) parent))))
             (not (eq? guard (car guards))))))

(define (om:first-guard? model guard)
  (not
   (and-let* ((parent (om:parent model guard))
              (parent (cond ((is-a? parent <guard>) (.statement parent))
                            ((is-a? parent <on>) (om:parent model parent))
                            (else parent)))
              (guards (filter (is? <guard>) parent))
              (guards (filter (find-trigger (statements.port) (statements.event)) guards))
              (guards (null-is-#f guards)))
             (not (eq? guard (car guards))))))

(define (bool-expression->string model o)
  (match o
    (($ <literal> name field)
     (debug "LIT!: ~a\n" o)
     (debug "scope: ~a\n" (om:scope o))
     (debug "name: ~a\n" (om:name o))
     (debug "==> ~a\n" (snippet 'literal `((scope-name ,(cdr name)) (scope ,(om:scope o)) (name ,(om:name o)) (field ,field))))
     (snippet 'literal `((scope-name ,(cdr name)) (scope ,(om:scope o)) (name ,(om:name o)) (field ,field))))
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
    (or (and-let* ((var (var? o))
                   (type (.type var))
                   (name (.name type))
                   (literal (make <literal> :name name :field field)))
                  (expression->string model literal locals))
        ""))

  (match o
    ((? unspecified?) *unspecified*)
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
                                 (snippet 'argument `((expression ,(expression->string model e locals (if out? 'out 'in)))
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
                                 (snippet 'argument `((expression ,(expression->string model e locals (if out? 'out 'in)))
                                                      (out? ,(member (.direction p) '(inout out)))))))
                             arguments formals))))
       (snippet 'call-arguments-expression
                `((function ,function) (arguments ,arguments)))))
    (($ <literal>)
     (debug "LIT: ~a\n"      (bool-expression->string model o))
     (bool-expression->string model o))
    ((? number?) (number->string o))
    (('! expression)
     (let ((expression (expression->string model expression locals)))
       (snippet 'not `((expression ,expression)))))
    (('group expression)
     (snippet 'group `((expression ,(expression->string model expression locals))) ")"))
    (((or 'and 'or '== '!=) lhs rhs)
     (let ((lhs (expression->string model lhs locals))
           (rhs (expression->string model rhs locals))
           (op (car o)))
       (snippet op `((op ,op) (lhs ,lhs) (rhs ,rhs)))))
    (((or '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (expression->string model lhs locals))
           (rhs (expression->string model rhs locals)))
       (snippet 'op `((op ,(car o)) (lhs ,lhs) (rhs ,rhs)))))
    (_ (->code model o #f locals 0))))

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
  (let* ((fields ((compose .elements .fields) enum))
         (length (length fields))
         (asd? #f))
   (snippet 'declare-enum
            `((scope+name ,(om:scope+name enum)) (scope ,(om:scope enum)) (name ,(om:name enum)) (fields ,fields) (length ,length) (asd? ,asd?)))))

(define ((enum-to-string o) enum)
  (let* ((fields ((compose .elements .fields) enum))
         (length (length fields)))
    (snippet 'enum-to-string
             `((scope+name ,(om:scope+name enum)) (scope ,(om:scope enum)) (name ,(om:name enum)) (fields ,fields) (length ,length)))))

(define ((string-to-enum o) enum)
  (let* ((fields ((compose .elements .fields) enum))
         (length (length fields)))
   (snippet 'string-to-enum
            `((scope ,(om:scope enum)) (name ,(om:name enum)) (fields ,fields) (length ,length)))))

(define (declare-integer integer)
  (snippet 'declare-integer `((name int))))

(define ((declare-io model string) event)
  (let* ((name (.name event))
         (signature (.signature event))
         (type ((compose .name .type) signature))
         (return-type (return-type model event))
         (formals (.formals signature))
         (formal-list (map (lambda (x) (code:->code model x)) (.elements formals)))
         (formal-objects (.elements formals))
         (formal-types (map (lambda (formal)
                              (snippet 'formal-type `((type ,(->code model (.type formal))) (out? ,(member (.direction formal) '(inout out))))))
                             ((compose .elements .formals) signature)))
         (comma (if (pair? (.elements formals)) (sep) ""))
         (comma-space (if (pair? (.elements formals)) `(,(sep) " ") ""))
         (formals (code:->code model formals)))
    (animate string `((name ,name) (comma ,comma) (comma-space ,comma-space) (formals ,formals) (formal-list ,formal-list) (formal-objects ,formal-objects) (formal-types ,formal-types) (return-type ,return-type)))))

(define ((define-function model string) function)
  (let* ((signature (.signature function))
         (return-type (code:->code model signature))
         (type (.type signature))
         (name (.name type))
         (scope-return-type (if (not (pair? name)) name
                                (snippet 'type-scope-enum `((scope-name ,(cdr name)) (scope ,(om:scope type)) (name ,(om:name type))))))
         (name (.name function))
         (formals (.formals signature))
         (comma (if (null? (.elements formals)) "" (sep)))
         (comma-space (if (null? (.elements formals)) "" `(,(sep) " ")))
         (statement (.statement function))
         (locals (map (lambda (x) (cons (.name x) x)) (.elements formals)))
         (formals (code:->code model formals))
         (statements (code:->code model statement #f locals 2 #f)))
    (animate string `((name ,name)
                       (return-type ,return-type)
                       (scope-return-type ,scope-return-type)
                       (comma ,comma)
                       (comma-space ,comma-space)
                       (formals ,formals)
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

(define ((define-on model port string) event)
  (let* ((signature (.signature event))
         (type (.type signature))
         (type-type ((om:type model) type))
         (interface (.type port))
         (return-type (return-type model event))
         (return-type-name (om:type-name type-type))
         (in-formals (filter om:in? ((compose .elements .formals) signature)))
         (in-formals (transform-formals-shadow-member model in-formals))
         (capture-list (comma-join (map .name in-formals)))
         (formals ((compose .elements .formals) signature))
         (formals (transform-formals-shadow-member model formals))
         (argument-list (map .name formals))
         (number (number->string (length argument-list)))
         (arguments (comma-join argument-list))
         (locals (let loop ((formals formals) (locals '()))
                   (if (null? formals)
                       locals
                       (loop (cdr formals)
                             (acons (.name (car formals)) (car formals) locals)))))
         (comma (if (pair? formals) (sep) ""))
         (comma-space (if (pair? formals) (sep) ""))
         (formal-types (map (lambda (formal)
                                 (snippet 'formal-type `((type ,(->code model (.type formal))) (out? ,(member (.direction formal) '(inout out))))))
                            formals))
         (formal-objects formals)
         (formal-list (map (lambda (x) (code:->code model x)) formals))
         (formals (code:->code model (make <formals> :elements formals)))
         (reply-type (ast-name ((om:type model) type)))
         (reply-name (if (eq? reply-type 'int) 'int (om:name type)))
         (reply-scope (om:scope type-type))
         (reply-scope-name (om:scope+name type-type))
         (system (is-a? model <system>))
         (bind (and system (om:port-bind system (.name port))))
         (instance-binding (and bind (om:instance-binding? bind)))
         (instance (and instance-binding (.instance instance-binding)))
         (instance-port (and instance-binding (.port instance-binding)))
         (blocking? #f)
         (statement
          (or (and-let*
               (((is-a? model <component>))
                ((.behaviour model))
                (component model)
                (behaviour (.behaviour component))
                (statement (.statement behaviour))
;;                (norm-event-ons ((compose .elements .statement .behaviour) component))
;;                (norm-event-ons (filter (is-trigger? port event) ons))
                (guards (if (is-a? statement <guard>) (list statement)
                            (filter (is? <guard>) statement)))
                (ons ((om:statements-of-type 'on) statement))
                (ons (filter (find-trigger port event) ons))
                (guards (filter (find-trigger port event) guards)))
               (parameterize ((statements.port port)
                              (statements.event event))
                 ;;(map (lambda (on) (code:->code model on blocking? locals 2 #f)) norm-event-ons)
                 (if (null? ons)
                     (code:->code model (make <compound> :elements guards) blocking? locals 2 #f)
                     (code:->code model ons blocking? locals 2 #f))))
              "")))
    (animate string `((port ,(.name port))
                       (event ,(.name event))
                       (argument-list ,argument-list)
                       (arguments ,arguments)
                       (direction ,(.direction event))
                       (capture-list ,capture-list)
                       (comma ,comma)
                       (comma-space ,comma-space)
                       (type-type ,type-type)
                       (interface ,interface)
                       (number ,number)
                       (formals ,formals)
                       (formal-list ,formal-list)
                       (formal-objects ,formal-objects)
                       (formal-types ,formal-types)
                       (reply-name ,reply-name)
                       (reply-type ,reply-type)
                       (reply-scope ,reply-scope)
                       (return-type ,return-type)
                       (return-type-name ,return-type-name)
                       (instance ,instance)
                       (instance-port ,instance-port)
                       (statement ,statement)
                       (type ,(.name type))))))

(define ((init-bind model string) bind)
  (let* ((left (.left bind))
         (left-port (om:port model left))
         (right (.right bind))
         (right-port (om:port model right))
         (port (and (om:port-bind? bind)
                    (if (not (.instance left)) (.port left) (.port right))))
         (injected? (and (eq? port '*) port))
         (direction (or injected? (.direction (om:port model port))))
         (edir (or injected? (if (eq? direction 'provides) 'out 'in)))
         (interface (if (not injected?) (om:port model port)
                        (if left-port left-port
                            right-port)))
         (interface (.type interface))
         (instance (and (om:port-bind? bind)
                        (if (not (.instance left))
                            (binding-name model right)
                            (binding-name model left)))))
    (animate string `((port ,port) (direction ,direction) (edir ,edir) (injected? ,injected?) (instance ,instance) (interface ,interface)))))

(define ((init-instance string) instance)
  (let ((component (.type instance))
        (name (.name instance)))
    (animate string `((component ,component) (name ,name)))))

(define ((include-component string) instance)
  (let ((component ((om:scope-name) instance)))
    (animate string `((component ,component)))))

(define ((include-interface string) port)
  (let ((interface ((om:scope-name) (.type port))))
    (animate string `((interface ,interface)))))

(define ((init-member model string) variable)
  (let* ((name (.name variable))
         (type (.type variable))
         (expression (expression->string model (.expression variable)))
         (expression (if (and (string? expression)
                              (not (string-null? expression))) expression))
         (type (code:->code model type)))
    (debug "TYPE FOR: ~a => ~a\n" variable type)
    (debug "EXPRESSION: ~a => ~a unspecified?=~a\n" variable expression (eq? expression *unspecified*))
    (animate string `((name ,name) (type ,type) (expression ,expression)))))

(define ((init-port string) port)
  (animate string `((scope ,om:scope)
                    (name ,.name)
                    (direction ,.direction)
                    (external? ,.external)
                    (injected? ,.injected)
                    (interface ,om:scope+name))
           port))

(define (declare-replies o)
  (debug "reply-types: ~a\n" (om:reply-types o))
  (map (lambda (x)
         (let ((s (match x
                    (($ <type> 'bool) 'declare-reply-bool)
                    (($ <enum>) 'declare-reply-enum)
                    (($ <int>) 'declare-reply-int))))
           (snippet s `((scope ,(om:scope x))
                        (scope-name ,(om:scope+name x))
                        (name ,(om:name x))))))
       (om:reply-types o)))

(define ((define-reply string) type)
  (animate string `((scope ,(om:scope type))
                    (scope-name ,(om:scope+name type))
                    (name ,(om:name type)))
           type))

(define (return-type model event)
  (let ((type ((compose .type .signature) event)))
    (->code- model type)))

(define (binding-name model bind)
  (let ((instance (om:instance model bind))
        (port (om:port model bind)))
    (snippet 'binding
               `((instance ,(match instance
                                (($ <instance>) (.name instance))
                                (($ <interface>) (.name instance))))
                 (port ,(match port
                            (($ <port>) (.name port))
                            (($ <interface>) (list "x" (.name port)))))))))

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
  (.type (om:instance model (if (.instance (.left binding))
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

(define (code:identifier? name)
  (let* ((name (->string name))
         (first (car (string->list (->string name)))))
    (and (or (char-alphabetic? first)
             (eq? first #\_))
         (string-every (char-set-adjoin char-set:letter+digit #\_) name))))

(define-syntax string-if
  (syntax-rules ()
    ((_ condition then)
     (animate-string (if (null-is-#f condition) then "") (current-module)))
    ((_ condition then else)
     (animate-string (if (null-is-#f condition) then else) (current-module)))))

(define* (pairs->module key-procedure-pairs :optional (parameter #f))
  (let ((module (code:module (and=> (module-variable (current-module) 'model)
                                    variable-ref))))
    (populate-module module key-procedure-pairs parameter)))

(define* ((animate-pairs pairs string) :optional parameter)
  (animate string (pairs->module pairs parameter)))

(define (debug . x) #t)
;;(define debug stderr)
