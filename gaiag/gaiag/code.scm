;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
;; Copyright © 2014, 2015, 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag code)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 pretty-print)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (gaiag lexicals)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag ast2om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag util)

  #:use-module (gaiag animate)
  #:use-module (gaiag annotate)
  #:use-module (gaiag gaiag)
  #:use-module (gaiag indent)
  #:use-module (gaiag misc)
  #:use-module (gaiag norm-event)
  #:use-module (gaiag reader)
  #:use-module (gaiag resolve)
  #:use-module (gaiag wfc)


  #:export (ast:code
           code:om
           code-file
           code:identifier?
           code:import
           code:->code
           code:extension
           code:signature-equal?
           code:signature-types-equal?
           enum-type
           ->code
           binding-name
           code:module
           declare-enum
           declare-io
           declare-interface-event
           declare-integer
           declare-replies
           define-function
           define-helper
           define-reply
           define-on
           define-on+
           connect-ports
           enum-to-string
           string-to-enum
           include-component
           include-interface
           init-bind
           init-instance
           init-member
           init-async-port
           init-port
           injected-binding
           injected-binding?
           injected-bindings
           injected-instance-interface
           injected-instance-name
           injected-instance-port
           injected-instance-type
           language
           locals
           local-lexicals
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

           code:animate-file
           ))

(define (ast:code ast)
  (let ((om ((om:register code:om #t) ast)))
    (map dump (filter (negate om:imported?) ((om:filter:p <model>) om)))
    (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
      (dump-header)))
  "")

(define (code:import name)
  (om:import name code:om))

(define (code:om ast)
  ((compose
    code-norm-event
    ;;ast:wfc
    ast:resolve
    ast->om
    ) ast))

(define (om:data-member-names model)
  (map .name (filter (lambda (x) (as ((om:type model) (.type x)) <extern>)) (om:variables model))))

(define (transform-formals-shadow-member model formals)
  (define (rename formal)
    (make <formal> #:name (symbol-append 'dzn_ (.name formal)) #:type (.type formal) #:direction (.direction formal)))
  (let* ((members (om:data-member-names model))
         (transform (lambda (f) (if (member (.name f) members) (rename f)
                                    f))))
    (map transform formals)))

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define (wrap-compound statement) (make <compound> #:elements (list statement)))
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
    (dump-indented `(,@(code:dir o) ,name ,(code:extension o))
                   (lambda ()
                     (code-file 'interface (code:module o))))))

(define (dump-component o)
  (dump-global o)
  (let ((name ((om:scope-name) o))
        (interfaces (map code:import (map .type ((compose .elements .ports) o)))))
    (when (.behaviour o)
      (map dump interfaces)
      (dump-indented `(,@(code:dir o) ,name ,(code:extension o))
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
  (let* ((name ((om:scope-name) o))
         (model (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                            string->symbol)))
         (interfaces (map code:import (map .type ((compose .elements .ports) o))))
         (shell (option-ref (parse-opts (command-line)) 'shell #f))
         (template (if (and shell (eq? name (string->symbol shell))) 'shell 'system)))
    (dump-indented `(,@(code:dir o) ,name ,(code:extension o))
                   (lambda ()
                     (code-file template (code:module o))))
    (dump-main o)))

(define (code-file file-name module)
  (let ((model (module-ref module 'model)))
   (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
     (code:animate-file (symbol-append file-name (code:extension model) '.scm) module))))

(define* (code:->code model src #:optional (blocking? #f) (locals '()) (indent 1) (compound? #t))
  (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
    (->code model src blocking? locals indent compound?)))

(define statements.port (make-parameter #f))
(define statements.event (make-parameter #f))

(define (language)
  (string->symbol (option-ref (parse-opts (command-line)) 'language "c++")))

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

(define (code:dir o)
  (if (eq? (language) 'cs) '()
      '(dzn)))

(define* (code:module o)
  (let ((module (make-module 31 (list
                                 (resolve-module (list 'gaiag (language)))
                                 (resolve-module '(gaiag lexicals))
                                 (resolve-module '(gaiag misc))
                                 (resolve-module '(oop goops))
                                 (resolve-module '(gaiag goops))))))
    (module-define! module 'model o)
    (module-define! module '.model (om:name o))
    (module-define! module '.scope_model ((om:scope-name) o))
    (match o
      (($ <interface>)
       (module-define! module '.interface (om:name o))
       (let ((events (.events o)))
         (module-define! module 'events events)
         (module-define! module 'in-events (filter om:in? (.elements events)))
         (module-define! module 'out-events (filter om:out? (.elements events))))
       (module-define! module '.scope_interface ((om:scope-name) o))
       (module-define! module '.INTERFACE (string-upcase (symbol->string ((om:scope-name) o)))))
      ((? (is? <model>))
       (module-define! module '.COMPONENT (string-upcase (symbol->string ((om:scope-name) o))))))
      module))

(define* (->code model src #:optional (blocking? #f) (locals '()) (indent 1) (compound? #t))
  (let ((statement (->code- model src blocking? locals indent compound?)))
    (if (eq? statement '$empty-statement$)
        ""
        (->string statement))))

(define (unspecified? x) (eq? x *unspecified*))

(define* (->code- model src #:optional (blocking? #f) (locals '()) (indent 1) (compound? #t))
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
      (($ <guard> expression ($ <compound> (statements ...)))
       (let* ((statement (.statement src))
              (statement (->code- model statement blocking? locals (1+ indent)))
              (statement (if (eq? statement '$empty-statement$)
                             (->code model statement blocking? locals (1+ indent))
                             statement)))
         (string-append
          (snippet 'guard
                   `((space ,space)
                     (clause ,(expr->clause model src expression))
                     (statement ,statement)))
          (if (not (om:last-guard? model src)) ""
              (snippet 'else-illegal `((space ,space)
                                       (illegal ,(snippet 'illegal `((space ,space))))))))))
      (($ <guard> expression statement)
       (let* ((statement (wrap-compound statement))
              (statement (->code- model statement blocking? locals (1+ indent)))
              (statement (if (eq? statement '$empty-statement$)
                             (->code model statement blocking? locals (1+ indent))
                             statement)))
         (string-append
          (snippet 'guard
                   `((space ,space)
                     (clause ,(expr->clause model src expression))
                     (statement ,statement)))
          (if (not (om:last-guard? model src)) ""
              (snippet 'else-illegal `((space ,space)
                                       (illegal ,(snippet 'illegal `((space ,space))))))))))
      (($ <if> expression then #f)
       (snippet 'if-then
                `((space ,space)
                  (expression ,(expression->string model expression locals))
                  (then ,(->code model then blocking? locals (1+ indent))))))
      (($ <if> expression (and ($ <if> e t) (get! then)) else)
       (->code- model (make <if> #:expression expression #:then (wrap-compound (then)) #:else else) blocking? locals indent))
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
       (->code- model (make <on> #:triggers triggers #:statement (wrap-compound (statement))) blocking? locals indent))
      (($ <on> triggers statement)
       (or (and-let* ((signature (transform-signature (.signature event) src))
                      (trigger (car (.elements triggers))))
             (let* ((blocking? (pair? ((om:collect <blocking>) statement)))
                    (statement (->code model statement blocking? locals indent compound?))
                    (statement (if (or (not blocking?) (and port (eq? (.direction port) 'requires))) statement
                                   `(,(snippet 'block
                                               `((space ,space)
                                                 (statement ,statement)
                                                 (port ,(.port.name trigger))))))))
               statement))
           '$empty-statement$))
      (($ <call> function ($ <arguments> ()))
       (snippet 'call `((space ,space) (function ,function))))
      (($ <call> function ($ <arguments> (arguments ...)))
       (let* ((formals ((compose .elements .formals .signature) (om:function model function)))
              (formals (if (calling-context)
                           (cons (make <formal> #:name 'cc__ #:type (calling-context)) formals)
                           formals))
              (arguments (if (calling-context)
                             (cons 'cc__ arguments)
                             arguments))
              (arguments ((join)
                          (map (lambda (e p)
                                 (let ((out? (member (.direction p) '(inout out))))
                                   (snippet 'argument `((expression ,(expression->string model e locals (if out? 'out 'in)))
                                                        (out? ,(member (.direction p) '(inout out)))))))
                               arguments formals))))
         (snippet 'call-arguments
                  `((space ,space) (function ,function) (arguments ,arguments)))))
      (($ <arguments> (arguments ...))
       ((join)
        (map (lambda (o) (expression->string model o locals)) arguments)))
      (($ <compound> ())
       (snippet 'compound-empty `((space ,space))))
      (($ <compound> (statements ...))
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
                         (variable? (as statement <variable>))
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
      (($ <action> (and ($ <trigger>) (= .port port) (= .event event) (= .arguments ($ <arguments> (arguments ...)))))
       (let* ((name (.type port))
              (port-name (.name port))
              (event-name (.name event))
              (interface (om:import name))
              (direction (.direction event))
              (comma (if (pair? arguments) (sep) ""))
              (comma-space (if (pair? arguments) `(,(sep) " ") ""))
              (number (number->string (length arguments)))
              (formals ((compose .elements .formals .signature) event))
              (formals (if (calling-context) (cons (make <formal> #:name 'cc__ #:type (calling-context)) formals)
                           formals))
              (arguments (if (calling-context)
                           (cons 'cc__ arguments)
                           arguments))
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
      (($ <scope.name>) (om:scope+name src))

      (($ <bool>) (snippet 'bool '()))
      (($ <extern>)
       (let ((value (.value src)))
         (snippet 'type-extern `((space ,space) (value ,value)))))
      (($ <enum>)
       (snippet 'type-enum `((space ,space) (scope-name ,(append (om:scope src) (list (om:name src)))) (scope ,(om:scope src)) (name ,(om:name src)))))
      (($ <int>)
       (snippet 'type-int `((space ,space) (scope-name ,(append (om:scope src) (list (om:name src)))) (scope ,(om:scope src)) (name ,(om:name src)))))
      (($ <void>) 'void)

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
      (($ <formals> (formals ...))
       ((join) (map (lambda (x) (->code model x)) formals)))
      (($ <formal> name type direction)
       (snippet 'formal `((name ,name) (type ,(->code model type)) (out? ,(member direction '(inout out))))))
      (($ <data> value) value)
      (($ <var> name) name)
      (($ <out-bindings>)
       (let ((statements (map (lambda (x) (->code model x)) (.elements src)))
             (assignments (map (lambda (assignment) (cons (.name (cadr assignment)) (.name (caddr assignment)))) (map .value (.elements src)))))
         (snippet 'out-bindings
                  `((port ,(.name port))
                    (statements ,statements)
                    (assignments ,assignments)))))
      ((and ($ <expression>) (= .value ('<- ($ <var> formal) ($ <var> global))))
       (let* ((var (var? global))
              (type (->code model (.type var))))
         (snippet 'out-binding `((formal ,formal) (global ,global) (type ,type)))))
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

(define ((find-trigger port event) o)
  (match o
    (($ <blocking>) ((find-trigger port event) (.statement o)))
    (($ <on>)
     (find (lambda (t) (and (eq? (.port.name t) (.name port))
                            (eq? (.event.name t) (.name event))))
           ((compose .elements .triggers) o)))
    (($ <guard>) ((find-trigger port event) (.statement o)))
    (($ <compound> (statements ...))
     (null-is-#f (filter identity (map (find-trigger port event) statements))))
    (_ #f)))

(define ((is-trigger? port event) o)
  (match o
    (($ <on>)
     (let ((trigger ((compose car .elements .triggers) o)))
       (and (eq? (.port.name trigger) (.name port))
            (eq? (.event.name trigger) (.name event)) o)))
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
              ((not (is-a? parent <on>)))
              ((is-a? parent <compound>))
              (guards (null-is-#f (om:filter (is? <guard>) parent))))
     (not (eq? guard (car guards))))))

(define (om:last-guard? model guard)
  (not
   (and-let* ((parent (om:parent model guard))
              ((not (is-a? parent <on>)))
              ((is-a? parent <compound>))
              (guards (null-is-#f (om:filter (is? <guard>) parent))))
             (not (eq? guard (last guards))))))

(define (bool-expression->string model o)
  (match o
    (($ <literal> name field)
     (snippet 'literal `((scope-name ,(om:scope+name name)) (scope ,(.scope name)) (name ,(.name name)) (field ,field))))
    (_ (expression->string model o))))

(define* (expression->string model o #:optional (locals '()) (argument #f))

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
                   (literal (make <literal> #:name name #:field field)))
                  (expression->string model literal locals))
        ""))

  (match o
    ((? unspecified?) *unspecified*)
    (($ <expression> (? unspecified?)) *unspecified*)
    (($ <expression>) (expression->string model (.value o) locals argument))
    (($ <action> (and ($ <trigger>) (= .port port) (= .event event) (= .arguments ($ <arguments> (arguments ...)))))
     (let* ((port-name (.name port))
            (name (.type port))
            (event-name (.name event))
            (interface (om:import name))
            (direction (.direction event))
            (comma (if (pair? arguments) (sep) ""))
            (comma-space (if (pair? arguments) `(,(sep) " ") ""))
            (number (number->string (length arguments)))
            (formals ((compose .elements .formals .signature) event))
            (formals (if (calling-context) (cons (make <formal> #:name 'cc__ #:type (calling-context)) formals)
                         formals))
            (arguments (if (calling-context)
                           (cons 'cc__ arguments)
                           arguments))
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
    (($ <call> function ($ <arguments> ()))
     (snippet 'call-expression `((function ,function))))
    (($ <call> function ($ <arguments> (arguments ...)))
     (let* ((formals ((compose .elements .formals .signature) (om:function model function)))
            (arguments (if (calling-context)
                           (cons 'cc__ arguments)
                           arguments))
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

(define (pair->list o) (list (car o) (cdr o)))
(define (ast-cdr? o) ((compose (is? <ast>) cdr) o))

(define ((declare-io model string) event)
  (parameterize ((any->string (cut ->code model <>)))
    (let* ((signature (.signature event))
           (formals (.formals signature))
           (formals (if (calling-context) (make <formals> #:elements (cons (make <formal> #:name 'cc__ #:type (calling-context)) (.elements formals)))
                        formals))
           (signature
            (if (calling-context)
                (make <signature> #:type (.type signature) #:formals formals)
                signature))
           (type (.type signature)))
      (animate string (cons `(name ,(.name event))
                            (map pair->list (filter ast-cdr? (lexicals))))))))

(define ((declare-interface-event model) event)
  ((declare-io model (gulp-snippet 'declare-interface-event)) event))

(define ((define-function model string) function)
  (let* ((signature (.signature function))
         (return-type (code:->code model signature))
         (type (.type signature))
         (scope-return-type (if (not (pair? (om:scope type))) (om:name type)
                                (snippet 'type-scope-enum `((scope-name ,(om:scope+name type)) (scope ,(om:scope type)) (name ,(om:name type))))))
         (name (.name function))
         (formals (.formals signature))
         (formals (if (calling-context) (make <formals> #:elements (cons (make <formal> #:name 'cc__ #:type (calling-context)) (.elements formals)))
                        formals))
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
    (($ <compound> (s ...)) (filter identity (apply append (map (om:statements-of-type type) s))))
    (($ <on> triggers statement) (filter identity ((om:statements-of-type type) statement)))
    ((? (is? <statement>)) '())
    (#f '())))

(define (code:formals->name model signature)
  (let ((formals ((compose .elements .formals) signature)))
    ((->join "_")
     (cons*
      ((compose om:type-name (om:type model) .type) signature)
      (if (null? formals) '(void)
          (map
           (lambda (formal)
             (let ((name ((compose om:type-name (om:type model) .type) formal)))
               (if (om:out-or-inout? formal) (symbol-append name 'p)
                   name)))
           formals))))))

(define (x-formal formal)
  (make <formal> #:type (.type formal) #:name (.name formal) #:direction (if (om:out-or-inout? formal) 'out 'in)))

(define ((code:signature-equal? model) a b)
  (and (equal? (->code- model (.type a)) (->code- model (.type b)))
       (equal? (map x-formal ((compose .elements .formals) a))
               (map x-formal ((compose .elements .formals) b)))))

(define* ((type-equal? model) a b)
  (or (equal? a b)
      (and (om:enum model a) (om:enum model b))))

(define ((code:signature-types-equal? model) a b)
  (and ((type-equal? model) (.type a) (.type b))
       (equal? (map om:out-or-inout? ((compose .elements .formals) a))
               (map om:out-or-inout? ((compose .elements .formals) b)))
       (every (type-equal? model)
              (map .type ((compose .elements .formals) a))
              (map .type ((compose .elements .formals) b)))))

(define ((define-helper model port string) signature)
  (let* ((formals ((compose .elements .formals) signature))
         (formal-list (map (lambda (x) (code:->code model x)) formals))
         (formal-types (map (lambda (formal)
                              (snippet 'formal-type `((type ,(->code model (.type formal))) (out? ,(member (.direction formal) '(inout out))))))
                            formals))
         (formal-numbered-list (map (lambda (type number) (list type " _" number)) formal-types (iota (length formal-types))))
         (return-type (->code- model (.type signature))))
    (animate string `((argument-list ,(map .name formals))
                      (comma ,(if (pair? formals) (sep) ""))
                      (formal-list ,formal-list)
                      (formal-numbered-list ,formal-numbered-list)
                      (formal-types ,formal-types)
                      (port ,(and=> port .name))
                      (signature-name ,(code:formals->name model signature))
                      (return-type ,return-type))
             signature)))

(define (transform-signature signature on)
  (define (rename-formal formal name)
    (make <formal> #:name name #:type (.type formal) #:direction (.direction formal)))
  (define (argument->name o)
    (match o
      (($ <expression> ($ <var> name)) name)
      (($ <expression> ('<- ($ <var> name) x)) name)))
  (if (not on)
      signature
      (let* ((formals (map argument->name ((compose .elements .arguments car .elements .triggers) on)))
             (formals (map rename-formal ((compose .elements .formals) signature) formals)))
        (make <signature> #:type (.type signature) #:formals (make <formals> #:elements formals)))))

(define ((define-on+ model port string) event)
  (let* ((behaviour (and=> (as model <component>) .behaviour))
         (ons (if (not behaviour) '()
                  ((compose .elements .statement) behaviour)))
         (ons (filter (is-trigger? port event) ons))
         (on (and (pair? ons) (car ons)))
         (signature (.signature event))
         (signature (transform-signature signature on))
         (signature-name (code:formals->name model signature))
         (formals (.formals signature))
         (formal-objects (.elements formals))
         (formal-objects (if (calling-context)
                              (cons (make <formal> #:name 'cc__ #:type (calling-context)) formal-objects)
                              formal-objects))
         (formals (make <formals> #:elements formal-objects))
         (signature
          (if (calling-context)
              (make <signature> #:type (.type signature) #:formals formals)
              signature))
         (type (.type signature))
         (type-type ((om:type model) type))
         (interface (.type port))
         (interface-name (.name interface))
         (return-type (return-type model event))
         (return-type-name (om:type-name type-type))
         (in-formals (filter om:in? ((compose .elements .formals) signature)))
         (capture-list (comma-join (append (list "&") (map .name in-formals))))
         (formals ((compose .elements .formals) signature))
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
         (formal-list (map (lambda (x) (code:->code model x)) formals))
         (formals (code:->code model (make <formals> #:elements formals)))
         (reply-type (ast-name ((om:type model) type)))
         (reply-name (if (is-a? type-type <int>) 'int (om:name type)))
         (reply-scope (om:scope type-type))
         (reply-scope-name (om:scope+name type-type))
         (system (as model <system>))
         (bind (and system (om:port-bind system (.name port))))
         (instance-binding (and bind (om:instance-binding? bind)))
         (instance (and instance-binding (.instance instance-binding)))
         (instance-port (and instance-binding (.port instance-binding)))
         (blocking? #f)
         (space "    ")
         (statement
          (cond
           ((and behaviour (is-a? model <component>))
            (parameterize ((statements.port port)
                           (statements.event event))
              (if on
                  (code:->code model on blocking? locals 2 #f)
                  (snippet 'illegal `((space ,space))))))
           (else ""))))
    (animate string `((port ,(.name port))
                       (event ,(.name event))
                       (argument-list ,argument-list)
                       (arguments ,arguments)
                       (direction ,(.direction event))
                       (capture-list ,capture-list)
                       (comma ,comma)
                       (comma-space ,comma-space)
                       (type-type ,type-type)
                       (signature-name ,signature-name)
                       (interface ,interface)
                       (interface-name ,interface-name)
                       (number ,number)
                       (formals ,formals)
                       (formal-list ,formal-list)
                       (formal-objects ,formal-objects)
                       (formal-types ,formal-types)
                       (reply-name ,reply-name)
                       (reply-type ,reply-type)
                       (reply-scope ,reply-scope)
                       (reply-scope-name ,reply-scope-name)
                       (return-type ,return-type)
                       (return-type-name ,return-type-name)
                       (instance ,instance)
                       (instance-port ,instance-port)
                       (statement ,statement)
                       (type ,(.name type))))))

(define ((define-on model port string) event)
  (let* ((behaviour (and=> (as model <component>) .behaviour))
         (ons (if (not behaviour) '()
                  ((compose .elements .statement) behaviour)))
         (ons (filter (is-trigger? port event) ons))
         (on (and (pair? ons) (car ons)))
         (signature (.signature event))
         (signature (transform-signature signature on))
         (signature-name (code:formals->name model signature))
         (formals (.formals signature))
         (formal-objects (.elements formals))
         (formal-objects (if (calling-context)
                              (cons (make <formal> #:name 'cc__ #:type (calling-context)) formal-objects)
                              formal-objects))
         (formals (make <formals> #:elements formal-objects))
         (signature
          (if (calling-context)
              (make <signature> #:type (.type signature) #:formals formals)
              signature))
         (type (.type signature))
         (type-type ((om:type model) type))
         (interface (.type port))
         (return-type (return-type model event))
         (return-type-name (om:type-name type-type))
         (in-formals (filter om:in? ((compose .elements .formals) signature)))
         (capture-list (comma-join (append (list "&") (map .name in-formals))))
         (formals ((compose .elements .formals) signature))
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
         (formal-list (map (lambda (x) (code:->code model x)) formals))
         (formals (code:->code model (make <formals> #:elements formals)))
         (reply-type (ast-name ((om:type model) type)))
         (reply-name (if (eq? reply-type 'int) 'int (om:name type)))
         (reply-scope (om:scope type-type))
         (reply-scope-name (om:scope+name type-type))
         (system (as model <system>))
         (bind (and system (om:port-bind system (.name port))))
         (instance-binding (and bind (om:instance-binding? bind)))
         (instance (and instance-binding (.instance instance-binding)))
         (instance-port (and instance-binding (.port instance-binding)))
         (blocking? #f)
         (space "    "))
    (animate string `((port ,(.name port))
                       (event ,(.name event))
                       (argument-list ,argument-list)
                       (arguments ,arguments)
                       (direction ,(.direction event))
                       (capture-list ,capture-list)
                       (comma ,comma)
                       (comma-space ,comma-space)
                       (type-type ,type-type)
                       (signature-name ,signature-name)
                       (interface ,interface)
                       (number ,number)
                       (formals ,formals)
                       (formal-list ,formal-list)
                       (formal-objects ,formal-objects)
                       (formal-types ,formal-types)
                       (reply-name ,reply-name)
                       (reply-type ,reply-type)
                       (reply-scope ,reply-scope)
                       (reply-scope-name ,reply-scope-name)
                       (return-type ,return-type)
                       (return-type-name ,return-type-name)
                       (instance ,instance)
                       (instance-port ,instance-port)
                       (type ,(.name type))))))

(define ((init-bind model string) bind)
  (let* ((left (.left bind))
         (left-port (om:port model left))
         (right (.right bind))
         (right-port (om:port model right))
         (port (and (om:port-bind? bind)
                    (if (not (.instance left)) (.port left) (.port right))))
         (instance-port (and (om:port-bind? bind)
                             (if (not (.instance left)) (.port right) (.port left))))
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
    (animate string `((port ,port) (direction ,direction) (edir ,edir) (injected? ,injected?) (instance ,instance) (instance-port ,instance-port) (interface ,interface)))))

(define ((init-instance model string) instance)
  (let* ((component (.type instance))
         (name (.name instance))
         (bindings (injected-bindings model))
         (injected-instance-names (map injected-instance-name bindings))
         (injected? (member (.name instance) injected-instance-names))
         (injected-ports (if injected? (map injected-instance-port bindings) '())))
    (animate string `((component ,component)
                      (injected? ,injected?)
                      (injected-ports ,injected-ports)
                      (name ,name)))))

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
                    (interface ,om:scope+name)
                    (port ,port))
           port))

(define ((init-async-port model string) port)
  (let* ((signature (.signature (car (om:events port))))
         (type (->code model (.type signature)))
         (formals ((compose .elements .formals) signature))
         (formal-types (map (lambda (formal)
                              (snippet 'formal-type `((type ,(->code model (.type formal))) (out? ,(member (.direction formal) '(inout out))))))
                            formals)))
   (animate string `((scope ,om:scope)
                     (name ,.name)
                     (direction ,.direction)
                     (external? ,.external)
                     (injected? ,.injected)
                     (interface ,om:scope+name)
                     (port ,port)
                     (signature ,signature)
                     (formal-types ,formal-types)
                     (type ,type))
            port)))

(define (declare-replies o)
  (map (lambda (x)
         (let ((s (match x
                    (($ <bool>) 'declare-reply-bool)
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

(define* (pairs->module key-procedure-pairs #:optional (parameter #f))
  (let ((module (code:module (and=> (module-variable (current-module) 'model)
                                    variable-ref))))
    (populate-module module key-procedure-pairs parameter)))

(define* ((animate-pairs pairs string) #:optional parameter)
  (animate string (pairs->module pairs parameter)))

(define (debug . x) #t)
;;(define debug stderr)

(define (calling-context)
  (let ((type (option-ref (parse-opts (command-line)) 'calling-context #f)))
    (if type (make <type> #:name (make <scope.name> #:scope '() #:name (string->symbol type))) #f)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; helper functions/macros to identify bottlenecks ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-syntax *match*
  (syntax-rules ... ()
    ((_ obj (pat exp ...) ...)
     (match obj (pat (begin (map display (list "match " 'pat ":")) (newline)
                            (measure-perf- '(exp ...) (lambda () exp ...)))) ...))))

(define (measure-perf- label thunk)
  (let ((t1 (get-internal-run-time))
        (result (thunk))
        (t2 (get-internal-run-time)))
    (stderr "~a: ~a\n" (- t2 t1) label)
    result))

(define-syntax measure-perf
  (syntax-rules ()
    ((_ label exp)
     (let ((t1 (get-internal-run-time))
           (result ((lambda () exp)))
           (t2 (get-internal-run-time)))
       (stderr "~a: ~a\n" (- t2 t1) label)
       result))))

(define-syntax *let*
  (syntax-rules ()
    ((_ ((var val) ...) exp exp* ...)
     (let* ((var (measure-perf 'var val)) ...)
       (measure-perf '*let* exp exp* ...)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    template procedures: map procedure name to template and                 ;;
;;                         pass the appropriate ast type                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; requirements:
;; - trivially define a new template function by name
;; - trivially define which part of the passed ast is to be available in the template
;; - trivially map such a template function over a list of ast or parts of ast
;; - allow template functions to recurse (and therefore do not self reference ;-)

;; TODO:
;; - robust template approach => resolve dependency between mapped and primitive naming, x:* prefix
;; - proper mapped, mapped-prefix, mapped-infix naming conventions
;; - remove need for ->code (MORTAL SIN)
;; - fix return in statement
;; - animate: disallow all scheme from template, i.e. only allow strings and procedures

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(define-syntax define-template
  (syntax-rules ()
    ((_ name f)
     (define-public (name module ast)
       (let* ((filename (string-drop (symbol->string 'name) 2))
              (o (f ast)))
         (cond ((symbol? o) (display o))
               ((string? o) (display o))
               ((char? o) (display o))
               ((list? o) (map (lambda (ast) (animate-file filename module ast)) o))
               (#t (animate-file filename module o))))
       ""))))

(define (infix lst separator)
  (let loop ((lst lst))
    (if (null? (cdr lst))
        lst
        (cons (car lst) (cons separator (loop (cdr lst)))))))

(define-syntax x:map
  (syntax-rules ()
    ((_ template lst)
     (map template lst))))

(define-syntax x:map-infix
  (syntax-rules ()
    ((_ template lst separator)
     (if (pair? lst)
         (let loop ((a lst))
           (template (car a))
           (when (pair? (cdr a))
             (display separator)
             (loop (cdr a))))))))

(define-syntax define-mapped
  (syntax-rules ()
    ((_ name f)
     (define-public (name module ast)
       (x:map (cut (module-ref module
                               (string->symbol (string-drop (symbol->string 'name) 4))) module <>)
              (f ast)) ""))))

(define-syntax define-mapped-prefix
  (syntax-rules ()
    ((_ name f separator)
     (define-public (name module ast)
       (x:map (cut (module-ref module
                               (string->symbol (string-drop (symbol->string 'name) 4))) module <>)
              (append-map (lambda (o) (list separator o)) (f ast))) ""))))

(define-syntax define-mapped-infix
  (syntax-rules ()
    ((_ name f  separator)
     (define-public (name module ast)
       (x:map-infix (cut (module-ref module
                                        (string->symbol (string-drop (symbol->string 'name) 4))) module <>)
                       (f ast) separator) ""))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(define-template x:code-formal-type (lambda (o)
                                      (let ((code (code:->code ((ast:model) o) o)))
                                        (string-append (code:->code ((ast:model) o) (.type o)) (if (not (eq? 'in (.direction o))) "&" ""))))) ;; MORTAL SIN HERE!!?

(define-template x:on identity)

(define-mapped map:x:on ast:on)

(define-template x:return ast:return-type)

(define-template x:reply (lambda (o)
                           (if (is-a? o <void>)
                               ""
                               (let ((type (ast-name ((om:type ((ast:model) o)) o))))
                                (string-append " this->reply_" (->string ((om:scope-join #f) (om:scope o))) "_" (->string (if (is-a? o <int>) type (om:name o)))))))) ;; MORTAL SIN HERE!!?

(define-template x:return-type ast:return-type)

(define-template x:model-name (compose om:name (ast:model)))

(define-template x:port-type ast:port-type)

(define-template x:port-name ast:port-name)

(define-template x:event-name ast:event-name)

(define-template x:argument_n identity)

(define-mapped-prefix map:x:argument_n ast:formal-to-argument_n #\,)

(define-template x:argument identity)

(define-mapped-infix map:x:argument ast:formal-to-argument #\,)

(define-template x:out-argument identity)

(define-mapped-prefix map:x:out-argument ast:out-formal-to-argument #\,)

(define-template x:formal-type identity)

(define-mapped-prefix cmx:x:formal-type ast:formal #\,)

(define-mapped-infix mcx:x:formal-type ast:formal #\,)

(define-template x:formal (lambda (o) (code:->code ((ast:model) o) o))) ;; MORTAL SIN HERE!!?

(define-mapped-infix map:x:formal ast:formal #\,)

(define-template x:statement ast:statement)

(define-template x:type (lambda (o) (code:->code ((ast:model) o) o))) ;; MORTAL SIN HERE!!?

(define-template x:call identity)

(define-template x:rcall identity)

(define-template x:req identity)

(define-template x:clr identity)

(define-mapped map:x:call (lambda (o) (filter (lambda (t) (is-a? (ast:return-type t) <void>)) (ast:in-trigger o))))

(define-mapped map:x:rcall (lambda (o) (filter (lambda (t) (not (is-a? (ast:return-type t) <void>))) (ast:in-trigger o))))

(define-mapped map:x:req ast:req-events)

(define-mapped map:x:clr ast:clr-events)

(define-template x:direction ast:direction)

(define-template x:event-decl identity)

(define-mapped map:x:event-decl ast:in-trigger)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   ast accessors; must return an ast type or a: string, number or symbol   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-method (ast:req-events (o <component>))
  (append-map (lambda (port)
                (map (lambda (event) (make <trigger> #:port port #:event event))
                     (filter (conjoin om:in? (compose (cut eq? 'req <>) .name)) (om:events port))))
              (om:ports (.behaviour o))))

(define-method (ast:clr-events (o <component>))
  (append-map (lambda (port)
                (map (lambda (event) (make <trigger> #:port port #:event event))
                     (filter (conjoin om:in? (compose (cut eq? 'clr <>) .name)) (om:events port))))
              (om:ports (.behaviour o))))

(define ast:decl (make-parameter (lambda (o) #f)))
(define ast:model (make-parameter (lambda (o) #f)))

(define-method (ast:statement (o <on>)) ;; MORTAL SIN HERE!!?
  (with-throw-handler #t
    (lambda ()
      (let ((port (ast:port o))
            (event (ast:event o))
            (blocking? #f)
            (locals '()))
        (parameterize ((statements.port port)
                       (statements.event event))
          (code:->code ((ast:model) o) o blocking? locals 2 #f))))
    (lambda (key . args)
      (display-backtrace (make-stack #t) (current-error-port))
      (stderr "key: ~a; args: ~a\n" key args)
      (exit 1))))

(define-method (ast:statement (o <boolean>))
  (snippet 'illegal `((space ,space))))

(define-method (ast:on (o <component>))
  (let ((behaviour (.behaviour o)))
    (if (not behaviour) '()
        ((compose .elements .statement) behaviour))))

(define-method (ast:formal-to-argument_n (o <trigger>)) ;; MORTAL SIN HERE!!?
  (map (compose (cut string-append "_" <>) number->string) (iota (length (ast:formal o)) 1 1)))

(define-method (ast:formal-to-argument (o <trigger>)) ;; MORTAL SIN HERE!!?
  (map .name (ast:formal o)))

(define-method (ast:out-formal-to-argument (o <trigger>)) ;; MORTAL SIN HERE!!?
  (map (lambda (formal) (string-append "&" (symbol->string (.name formal)))) (filter om:out-or-inout? (ast:formal o))))

(define-method (ast:formal (o <trigger>))
  ((compose .elements .formals .signature .event) o))

(define-method (ast:formal (o <on>))
  (let* ((trigger ((compose car .elements .triggers) o))
         (event (.event trigger)))
    (map (lambda (name formal)
           (clone formal #:name name))
         (map (compose .name .value) ((compose .elements .arguments) trigger))
         ((compose .elements .formals .signature) event))))

(define-method (ast:port (o <on>))
  ((compose .port car .elements .triggers) o))

(define-method (ast:event (o <on>))
  (ast:event (car ((compose .elements .triggers) o))))

(define-method (ast:port-type (o <trigger>))
  ((->join "::") (om:scope+name ((compose .type .port) o)))) ;; MORTAL SIN HERE!!?

(define-method (ast:port-name (o <trigger>))
  (ast:port-name (.port o)))

(define-method (ast:port-name (o <on>))
  ((compose .name .port car .elements .triggers) o))

(define-method (ast:port-name (o <port>))
  (.name o))


(define-method (ast:event-name (o <trigger>))
  (ast:event-name (.event o)))

(define-method (ast:event-name (o <on>))
  ((compose .name .event car .elements .triggers) o))

(define-method (ast:event-name (o <event>))
  (.name o))

(define-method (ast:event-name (o <on>))
  ((compose .name .event car .elements .triggers) o))


(define-method (ast:model-decl model (o <trigger>))
  (.event o)) ;;FIXME

(define-method (ast:return-type (o <trigger>))
  (ast:return-type (.event o)))

(define-method (ast:return-type (o <event>))
  ((compose .type .signature) o))

(define-method (ast:return-type (o <on>))
  (ast:return-type (car ((compose .elements .triggers) o))))

(define-method (ast:return-type (o <trigger>))
  (ast:return-type (ast:event o)))




(define-method (ast:event (o <trigger>))
  (.event o))

(define (code:animate-file file-name module)
  (parameterize ((ast:decl (lambda (p) (ast:model-decl (module-ref module 'model) p)))
                 (ast:model (lambda (_) (module-ref module 'model))))
    (animate-file file-name module)))
