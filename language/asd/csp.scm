;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (language asd csp)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)
  :use-module (ice-9 receive)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (language asd animate)
  :use-module (language asd asserts)
  :use-module (language asd ast:)
  :use-module (language asd gaiag)
  :use-module (language asd misc)
  :use-module (language asd reader)
  :use-module (language asd normstate)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (language asd gom)

  :export (
           ast->
           csp->sugar
           csp-component
           csp-module
	   ast-transform
	   ast-transform*
	   ast-transform-function-call
	   ast-transform-return
	   ast-transform-return*
	   csp-expression->string
	   csp-transform
	   csp-transform*

           make-context
           context-extend
           statement-on-p/r
           provides?
           requires?
           ))

(define (ast-> ast)
  (let* ((norm (ast->gom*
                (normstate (if (member (ast:name (ast:component ast))
                                       '(mangle argument2))
                               (ast:mangle ast)
                               ast)))))
    (ast:register norm #t)
    (module-define! (resolve-module '(language asd csp)) 'ast norm)  ;; FIXME
    (and-let* ((comp (ast:component norm))
               (name (ast:name (ast:component ast))) ;; unmangled
               (module (csp-module norm))
               (fn (option-ref (parse-opts (command-line)) 'output (list name '.csp))))
              (dump-output fn
                           (lambda ()
                             (csp-component module)
                             (csp-asserts module)))))
  "")

(define (csp-component module)
  (animate-file 'templates/component.csp.scm module))

(define (csp-asserts module)
  (let* ((asserts-string (option-ref (parse-opts (command-line)) 'assert #f))
         (asserts (if asserts-string (with-input-from-string asserts-string read)
                      (assert-list (module-ref module 'ast)))))
    (for-each (csp-assert module) asserts)))

(define ((csp-assert module) assert)
  (let* ((class (car assert))
         (model (cadr assert))
         (check (caddr assert))
         (template (assoc-ref asserts-alist (list class check))))
    (module-define! module '.model model)
    (animate-string template module)))

(define asserts-alist
  `(
    ((component illegal) . "assert STOP [T= #.component _#.behaviour _Component(false) \\ diff(Events,{illegal})\n")
    ((component deterministic) . "assert #.component _#.behaviour(true,true) :[deterministic]\n")
    ((component deadlock)  . "assert #.component _#.behaviour _Component(false) :[deadlock free]\n")
    ((component compliance) . ,(gulp-file 'templates/asserts/component-compliance.csp.scm))
    ((component livelock)  .  "assert #.component _#.behaviour _Component(true) \\ diff(Events,{|illegal,#.port |}) :[livelock free]\n")
    ((interface deadlock) . ,(gulp-file 'templates/asserts/interface-deadlock.csp.scm))
    ((interface livelock) . ,(gulp-file 'templates/asserts/interface-livelock.csp.scm))))

(define (ast-norm model-name)
  (ast:ast model-name (compose normstate ast->gom*)))

(define (csp-module ast)
  (let ((module (make-module 31 (list
                                 (resolve-module '(ice-9 match))
                                 (resolve-module '(ice-9 curried-definitions))
                                 (resolve-module '(language asd ast:))
                                 (resolve-module '(language asd csp))))))
    (module-define! module 'ast ast)
    (and-let* ((comp (ast:component ast)))
              (module-define! module '.component (ast:name comp))
              (module-define! module 'component comp)
              (module-define! module '.interface (ast:name (ast:type (car (filter ast:provides? (ast:ports comp))))))
	      (module-define! module '.behaviour (ast:name (ast:behaviour comp)))
              (module-define! module '.interface-behaviour (ast:name (ast:behaviour (ast-norm (ast:type (ast:port (ast:component ast)))))))
	      (module-define! module '.port (ast:name (ast:port comp))))
    module))

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

(define* (map-interfaces string interfaces :optional (separator ""))
  ((->join separator)
   (map (lambda (interface)
          (with-output-to-string
            (lambda ()
              (save-module-excursion
               (lambda ()
                 (animate-string
                  string
                  (animate-module-populate
                   (csp-module ast)
                   interface
                   `((interface . ,(ast-norm interface))
                     (.name . ,ast:name)
                     (.interface . ,ast:name)))))))))
        interfaces)))

(define (map-guards string guards)
  (display
   ((->join "[]\n")
    (map (lambda (guard)
           (with-output-to-string
             (lambda ()
               (animate-string
                string
                (animate-module-populate
                 (current-module)
                 guard
                 `((guard . ,identity))))))) guards))))

(define (variable-prefix ast identfier)
  (and-let* ((variable (ast:variable ast identfier))
             (ast:variable? variable))
            (ast:type (ast:type (car variable)))))

(define (csp-expression->string ast src)
  (define (paren expression)
    (if (or (number? expression) (symbol? expression))
        expression
        (list "(" (csp-expression->string ast expression) ")")))

  (match src
    (('expression expression) (csp-expression->string ast expression))
    ((or (? number?) (? symbol?)) src)
    (('value type field)
     (let ((prefix (variable-prefix ast type)))
       (if prefix
           (list "(" type " == " prefix "_" field ")")
           (list type "_" field))))
    (('literal scope type value) (list type "_" value))

    (('group expression) (list "(" (csp-expression->string ast expression) ")"))
    (('! expression) (->string (list "(" "not " (paren expression) ")")))
    (((or 'and 'or '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (csp-expression->string ast lhs))
           (rhs (csp-expression->string ast rhs))
           (op (car src)))
       (list "(" lhs " " op " " rhs ")")))

    (_ (format #f "~a:no match: ~a" (current-source-location) src))))

(define (port-triggers port)
  (let* ((interface (ast-norm (ast:type port)))
         (events (map ast:name (ast:events interface)))
         (triggers (filter (lambda (x) (member x '(inevitable optional)))
                                      (map .event (gom:find-triggers interface)))))
    (sort (append events triggers) symbol<)))

(define (interface-triggers interface)
  (sort ((ast:find-events) interface) symbol<))

(define (typed-elements enum)
   (map (lambda (x) (symbol-append (ast:name enum) '_ x)) (ast:fields enum)))

(define (enum-values comp)
  (let ((comp-values (apply append (map typed-elements (ast:enums (ast:behaviour comp))))))
    (let loop ((ports (ast:ports comp)) (values comp-values))
      (if (null? ports)
          values
          (loop (cdr ports) (append values (apply append (map typed-elements (ast:enums (ast:behaviour (ast-norm (ast:type (car ports)))))))))))))

(define (return-value enum)
  (map (lambda (value) (symbol-append (ast:name enum) '_ value)) (ast:fields enum)))

(define (add-return-if-empty returns)
  (if (null? returns)
      '(return)
      (append (apply append returns) (list 'return)))) ;; FIXME: add only return when needed

(define (return-values-port port)
  (add-return-if-empty (map return-value (ast:enums (ast-norm (ast:type port))))))

(define (return-values-interface interface)
  (add-return-if-empty (map return-value (ast:enums interface))))


(define (return-values comp)
    (let loop ((ports (ast:ports comp)) (result '()))
      (if (null? ports)
          result
          (loop (cdr ports) (append result (return-values-port (car ports)))))))

(define ((statement-on-p/r predicate) on)
  (statement-on-p/r predicate on))

(define-generic statement-on-p/r)
(define-method (statement-on-p/r predicate (o <on>))
  (let* ((triggers (.elements (.triggers o)))
         (filtered-triggers (filter predicate triggers))
         (statement (.statement o)))
    (if (pair? filtered-triggers)
        (make <on> :triggers (make <triggers> :elements filtered-triggers)
              :statement statement)
        #f)))

(define (event->string event)
  (ast:event-name event))

(define (prefix-illegal? statement)
  (match statement
    (($ <compound>)
     (let loop ((statements (.elements statement)))
       (if (null? statements)
           #f
           (or (prefix-illegal? (car statements)) (loop (cdr statements))))))
    (('illegal) #t)
    (_ #f)))

(define (prefix-reply? statement)
  (match statement
    (($ <compound>)
     (let loop ((statements (.elements statement)))
       (if (null? statements)
           #f
           (or (prefix-reply? (car statements)) (loop (cdr statements))))))
    (('guard expr stat)
     (prefix-reply? stat))
    (($ <on>)
     (prefix-reply? stat))
    (('if expression then else)
     (or (prefix-reply? then) (prefix-reply? else)))
    (('reply value) #t)
    (_ #f)
    (_ (throw 'match-error (format #f "~a:prefix-reply?: no match: ~a\n" (current-source-location) statement)))))

(define-generic ast:event-name)
(define-method (ast:event-name (o <trigger>)) (.event o))
(define-generic ast:port-name)
(define-method (ast:port-name (o <trigger>)) (.port o))

(define (((provides-or-requires? direction) component) event)
  (if (ast:component? component)
      (pair?
       (filter
	(lambda (port)
          (and (equal? (ast:direction port) direction)
               (equal? (ast:port-name event) (ast:name port))))
	(ast:ports component)))
      #f))

(define ((provides? component) event)
  (((provides-or-requires? 'provides) component) event))

(define ((requires? component) event)
  (((provides-or-requires? 'requires) component) event))

(define ((provides-event? model) event)
  (and (ast:component? model)
       ((provides? model) event)))

(define ((requires-event? model) event)
  (and (ast:component? model)
       ((requires? model) event)))

(define (value ast)
  (match ast
    ((? ast:trigger?) (ast:event-name ast))
    ((? ast:value?) (symbol-append (ast:type ast) '_ (ast:field ast)))
    (_ ast)))

(define (optional-chaos port)
  (let ((interface (ast:type port)))
    (if (member 'optional (map .event (gom:find-triggers (ast-norm (ast:type port)))))
        (list "[|{" interface " .optional}|] " "CHAOS({" interface " .optional})")
        "")))

(define (->string src)
  (match src
    (('value type field) (->string (list type "." field)))
    (('trigger port event) (->string (list port "." event)))
;;    (_ (stderr "NO MATCH: ~a\n" src) (format #f "~a" src))
    (_ ((@ (language asd misc) ->string) src))))

(define (ast-transform ast src)
  (ast-transform- ast (ast-transform-return ast (ast-transform-function-call ast src))))

(define (ast-transform* ast src)
  (let ((ast* ((compose ast->gom* csp->sugar ast->sugar) ast))
        (src* ((compose ast->gom* csp->sugar ast->sugar) src)))
    (ast-transform- ast* (ast-transform-return ast* (ast-transform-function-call ast* src*)))))

(define (ast-transform-function-call ast src)
  (let ((model (or (ast:interface ast) (ast:component ast))))
    (match src
      (('action name)
       (if (member name (map ast:name (ast:functions (ast:behaviour model))))
           (list 'call name)
           src))
      ((h ...) (map (lambda (x) (ast-transform-function-call ast x)) src))
      (_ src))))

(define-method (ast-transform-return ast (o <top>)) ;; TODO: <ast>
  o)

(define-method (ast-transform-return ast (o <compound>))
  (let ((result
         (let loop ((statements (map (lambda (x) (ast-transform-return ast x)) (.elements o))))
           (if (null? statements)
               '()
               (cons (car statements) (loop (cdr statements)))))))
    (if (=1 (length result))
        (car result)
        (make <compound> :elements result))))

(define-class <csp-on> (<on>)
  (the-end :accessor .the-end :init-value #f :init-keyword :the-end))

(define (csp->sugar ast)
  (match ast
    (('on triggers statement the-end)
     (make <csp-on>
       :triggers (ast->gom* triggers)
       :statement (ast->gom* statement)
       :the-end the-end))
    (_ ast)))

(define-method (ast-transform-return ast (o <on>))
  (let* ((model (or (ast:interface ast) (ast:component ast)))
	 (members (ast:member-names model))
         (triggers (.triggers o)))
    (let ((result (ast-transform-return ast (.statement o))))
      (match result
        (($ <compound> '())
         (make <csp-on>
           :triggers triggers
           :statement (make <compound>
                        :elements (list (list 'eventreturn)))
           :the-end (list 'the-end members)))
        (('skip)
         (make <csp-on>
           :triggers triggers
           :statement (list 'eventreturn)
           :the-end (list 'the-end members)))
        ((? prefix-reply?)
         (make <csp-on>
           :triggers triggers
           :statement (make <compound> :elements (list result))
           :the-end (list 'the-end members)))
        (_
         (make <csp-on>
           :triggers triggers
           :statement (make <compound>
                        :elements (list result (list 'eventreturn)))
           :the-end (list 'the-end members)))))))

(define (ast-transform-return* ast src)
  (let ((ast* ((compose ast->gom* csp->sugar ast->sugar) ast))
        (src* ((compose ast->gom* csp->sugar ast->sugar) src)))
    (ast-transform-return ast* src*)))

(define ((valued-action? port?) src)
  (match src
    (('variable type var ($ <action>)) #t)
    (('variable type var ('value (? port?) action)) #t)
    (('assign var ($ <action>)) #t)
    (_ #f)))

(define (call? variable)
  (match variable
    (('variable type var ('call name arguments)) #t)
    (('variable type var ('call name)) #t)
    (_ #f)))

(define (make-context members locals)
  (list 'ctx (cons members locals)))

(define (frame-hide frame prefix extension)
  (let loop ((frame frame) (index 0))
    (if (null? frame)
        '()
        (let ((i (car frame)))
          (match i
            ((? symbol?)
             (cons
              (if (member i extension)
                  (string->symbol (format #f "~a~a'" prefix index))
                  i)
              (loop (cdr frame) (1+ index))))
            (('vector identifiers ..1)
             (cons (cons 'vector (loop identifiers index))
                   (loop (cdr frame) (+ index (length identifiers)))))
            (_ (throw 'match-error (format #f "~a:frame-hide: no match: ~a\n" (current-source-location) i))))))))

(define (context-extend context extension)
  (match context
    (('ctx (members locals ...))
     (match extension
       (('vector identifiers ..1)
        (make-context (frame-hide members 'hide_member identifiers)
                      (append (frame-hide locals 'hide_local identifiers)
                              (list extension))))
       ((? symbol?)
        (make-context (frame-hide members 'hide_member (list extension))
                      (append (frame-hide locals 'hide_local (list extension))
                                          (list extension))))
       ((h) (context-extend context h))
       ('() context)
       (_ (throw 'match-error (format #f "~a:context-extend: no match: ~a\n" (current-source-location) extension)))))
    (_ (throw 'match-error (format #f "~a:context-extend: no match: ~a\n" (current-source-location) context)))))

(define ((assign identifier expression) x)
  (match x
    (('vector expressions ...)
     (cons 'vector (map (assign identifier expression) expressions)))
    (_ (if (eq? x identifier) expression x))))

(define (context-assign context identifier expression)
  (match context
    (('ctx (members locals ...))
     (make-context (map (assign identifier expression) members)
                   (map (assign identifier expression) locals)))
    (_ (throw 'match-error (format #f "~a:context-assign: no match: ~a\n" (current-source-location) context)))))

(define (element->csp ast x)
  (match x
    (('vector expressions ...) (string-append "(" (comma-join (map (lambda (x) (csp-expression->string ast x)) expressions)) ")"))
    (_ (->string x))))

(define (context->csp ast context)
  (match context
    (('ctx context) (context->csp ast context))
    ((members locals ...)
     (let ((members (comma-join (map (lambda (x) (csp-expression->string ast x)) members)))
           (locals (reduce (lambda (x y) (string-append "(" (element->csp ast y) "," (element->csp ast x) ")")) #f (cons "stack'" locals))))
       (list "(" members "),(" locals ")")))
    (_ (throw 'match-error (format #f "~a:context->csp: no match: ~a\n" (current-source-location) context)))))

(define* (ast-transform- ast src :optional (return #t) (context #f))
  (let* ((model (or (ast:interface ast) (ast:component ast)))
         (context (or context (make-context (ast:member-names model) '())))
         (port? (lambda (port) (member port (map ast:name (ast:ports model)))))
         (valued-action? (valued-action? port?)))
    (match src
      (($ <compound>)
       (let loop ((statements (.elements src)) (context context))
	 (if (null? statements)
	     '()
             (let* ((statement (car statements))
                    (transformed (ast-transform- ast statement #f context))
                    (context (if (ast:variable? statement)
                                 (context-extend context (ast:name statement))
                                 context)))
               (if (>1 (length statements))
                   (if (equal? transformed '(illegal))
                       transformed
                       (list (if (ast:variable? statement)
                                 (if (or (valued-action? statement) (call? statement))
                                     'context-active
                                     'context)
                                 'semi)
                             transformed (loop (cdr statements) context)))
                   transformed)))))
      (('variable type var ('value (and (? port?) (get! port)) event))
       (list context var (list 'valued-action (make <trigger> :port (port) :event event))))
      (('variable type var ('call function))
       (list context var (list 'call function)))
      (('variable type var ('call function arguments))
       (list context var (list 'call function arguments)))
      (('variable type var expr)
       (list context var (list 'expression expr)))
      (('if pred then)
       (list 'if context (list 'expression (if (prefix-illegal? then)
                                               (list 'and 'IG pred)
                                               pred))
             (ast-transform- ast then return context) '()))
      (('if expr then else)
       (let* ((then-illegal? (prefix-illegal? then))
	      (else-illegal? (prefix-illegal? else))
	      (pred-then (if then-illegal? (list 'and 'IG expr) expr))
	      (pred (if else-illegal? (list 'and '(! IG) pred-then) pred-then)))
	 (list 'if context (list 'expression pred)
               (ast-transform- ast then return context)
               (ast-transform- ast else return context))))
      (('function name signature statement)
       (let* ((parameters (map ast:name (ast:parameters signature)))
              (context (context-extend context (if (>1 (length parameters))
                                                   (cons 'vector parameters)
                                                   parameters)))
              (transformed (ast-transform- ast statement return context)))
         (list 'function name signature transformed)))
      (('return expression)
       (list 'return context expression))
      (('call function)
       (list 'call context function))
      (('call function arguments)
       (list 'call context function arguments))
      (_ src))))

(define-generic ast-transform-)
(define-method (ast-transform- ast (o <ast>))
  (ast-transform- ast o #t #f))

(define-method (ast-transform- ast (o <assign>) return context)
  (let* ((model (or (ast:interface ast) (ast:component ast)))
         (context (or context (make-context (ast:member-names model) '())))
         (port? (lambda (port) (member port (map ast:name (ast:ports model)))))
         (expression (.value (.expression o))))
    (match expression
      (($ <action>)
       (list 'assign-active (list context 'r' expression)
             (context-assign context (.identifier o) 'r')))
      (('value (and (? port?) (get! port)) event) ;; FIXME: translate to <action>
       (list 'assign-active (list context 'r' (make <action>
                                                :trigger (make <trigger>
                                                           :port (port)
                                                           :event event)))
             (context-assign context (.identifier o) 'r')))
      (('call function)
       (list 'assign-active (list context 'r' (list 'call function))
             (context-assign context (.identifier o) 'r')))
      (('call function arguments)
       (list 'assign-active (list context 'r' (list 'call function arguments))
             (context-assign context (.identifier o) 'r')))
      (expression
       (make <assign>  ;; <csp-assign>?
         ;; hmm? :flavour 'assign
         :identifier context
           :expression
           (make <expression> :value
                 (context-assign context (.identifier o) expression)))))))

(define-method (ast-transform- ast (o <csp-on>) return context)
  (let ((triggers (.triggers o))
        (statement (.statement o))
        (the-end (.the-end o)))
    (let ((result (ast-transform- ast statement)))
      (if (prefix-illegal? statement)
          ;; (list 'on triggers 'IG result)
          (make <csp-on> :triggers triggers :statement 'IG :the-end result)
          ;; (list 'on triggers result the-end)
          (make <csp-on> :triggers triggers :statement result :the-end the-end)))))

(define (=>string ast src)
  (match src
    (('ctx context) (context->csp ast context))
    (('expression expression) (csp-expression->string ast expression))
    (('arguments arguments ..1) (comma-join (map (lambda (x) (=>string ast x)) (ast:body src))))
    ((h t ...) (->string (map (lambda (x) (=>string ast x)) src)))
    (_ (->string src))))

(define (csp-transform* ast src)
  (let ((ast* ((compose ast->gom* csp->sugar ast->sugar) ast))
        (src* ((compose ast->gom* csp->sugar ast->sugar) src)))
    (csp-transform ast* src*)))

(define* (csp-transform ast src :optional (inevitable-optional? #f) (channel #f) (provided-on? #t))
  (let* ((model (or (ast:interface ast) (ast:component ast)))
	 (model-name (ast:name model))
	 (behaviour (ast:name (ast:behaviour model)))
         (component? (ast:component? model)))
    (=>string ast
     (match src
       ;;('on ('triggers triggers ...) stat ...)
       (($ <csp-on>)
        (let* ((triggers (.elements (.triggers src)))
               (statement (.statement src))
               (the-end (.the-end src))
               (inevitable-optional? (or (member 'inevitable (map ast:event-name triggers))
                                         (member 'optional (map ast:event-name triggers))))
               (ig? (eq? statement 'IG))
               (channel (if (ast:interface? model) model-name (ast:port-name (car triggers))))
               (provided-on? (or (and (ast:interface? model) (not inevitable-optional?))
                                 (or (ast:interface? model) ((provides-event? model) (car triggers)))))
               (IG? (if ig? (if ((provides-event? model) (car triggers)) "IIG & "  "IG & ")))
               (event-names (comma-join (map ast:event-name triggers)))
               (transformed (if ig? #f (csp-transform ast statement inevitable-optional? channel provided-on?)))
               (transformed-end (csp-transform ast the-end inevitable-optional? channel provided-on?)))
          (list IG? channel "?x:{" event-names "}" " ->\n" transformed transformed-end)))
       (('reply expr) (let ((expr (csp-transform ast expr inevitable-optional? channel provided-on?)))
                        (list "(\\ P',V' @ " channel "." expr " -> P'(V'))")))
       (('return context expression)
        (let ((expression (csp-expression->string ast expression)))
          (list "returnvalue_(\\ (" context ") @ " expression ")")))
       (('return) "skip_") ;; FIXME
       (('eventreturn) (let ((channel-return (if (and (not inevitable-optional?) provided-on?)
                                            (list "(\\ P',V' @ " channel ".return -> P'(V'))")
                                            (list "(\\ P',V' @ P'(V'))"))))
                    (list channel-return)))
       (('the-end members)
        (let* ((transition-end (if component? "transition_end -> "))
               (context (make-context members '()))
               (end (if (not inevitable-optional?) (list transition-end))))
          (list "(\\ V' @ " end model-name "_" behaviour "_" "(V'),(" context "))")))
       (('illegal) "illegal -> STOP")
       (('function name ('signature type) statement)
        (let ((transformed (csp-transform ast statement inevitable-optional? channel provided-on?)))
          (list name " = \\ P',V' @ " transformed "(P',V')\n")))
       (('function name signature statement)
        (let ((body (csp-transform ast statement inevitable-optional? channel provided-on?)))
          (list name " = \\ P',V',F' @ context_(F',\n" body ")(P',V')\n")))
       (('call context function)
        (list "callvoid_(" function ")"))
       (('call context function arguments)
        (list "callvoid_(\\ P',V' @ " function " (P',V',\\ (" context ") @ (" arguments ")))"))
       (('assign context expressions)
        (list "assign_(\\ (" context ") @ (" expressions "))"))
       (('if context expression then else)
        (let ((expression (csp-expression->string ast expression))
              (then (csp-transform ast then inevitable-optional? channel provided-on?))
              (else (csp-transform ast else inevitable-optional? channel provided-on?)))
          (list "\\ P',(" context ") @ ifthenelse_(" expression ",\n" then ",\n" else "\n)(P',(" context "))")))
       (('value type field) (list type "_" field))
       (('literal scope type value) (list type "_" value))
;;       (('vector expressions ...) (cons 'vector (map (lambda (exp) (csp-transform ast exp)) expressions )))
       (('context-active (context var ('valued-action ($ <trigger> port event))) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on?)))
          (list "context_active_(sendrecv_("  port "," event "),\n" stat ")")))
       (('context-active (context var ('expression ($ <action> ($ <trigger> port event)))) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on?)))
          (list "context_active_(sendrecv_(" port "," event "),\n" stat ")")))
       (('context-active (context var ('call function)) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on?)))
          (list "context_active_(" function ",\n" stat ")")))
       (('context-active (context var ('call function arguments)) stat)
          (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on?)))
          (list "context_active_(\\ P',V' @ " function " (P',V',\\ (" context ") @ (" arguments ")),\n" stat ")")))
       (('assign-active (context var ($ <action> ($ <trigger> port event))) expressions)
        (let ((action (list "sendrecv_(" port "," event ")")))
          (list "assign_active_(" action ",\n\\ ((" context "))," var " @ (" expressions "))" )))
       (('assign-active (context var ('call function arguments)) expressions)
        (list "assign_active_(\\ P',V' @ " function " (P',V',\\ (" context ") @ (" arguments ")),\n\\ ((" context "))," var " @ (" expressions "))"))
       (('context (context var expression) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on?)))
          (list "context_(\\ (" context ") @ " expression ",\n" stat ")" )))
       (('semi stat1 stat2)
        (let ((first (csp-transform ast stat1 inevitable-optional? channel provided-on?))
              (second (csp-transform ast stat2 inevitable-optional? channel provided-on?)))
          (list "semi_(" first ",\n" second ")")))
       (('skip) "skip_")
       ('() "(\\ P',V' @ P'(V'))")
       ((? symbol?) src)
       ((? string?) src)
       (_ (throw 'match-error (format #f "~a:csp-transform: no match: ~a\n" (current-source-location) src)))))))

(define-generic csp-transform)
(define-method (csp-transform ast (o <action>) . rest)
  (let* ((model (or (ast:interface ast) (ast:component ast)))
	 (model-name (ast:name model)))
    (=>string
     ast
     (let* ((trigger (.trigger o))
            (channel (if (ast:interface? model) model-name (.port trigger)))
            (event-name (.event trigger))
            (channel-return (if ((requires-event? model) trigger) (list " -> " channel ".return"))))
       (list "(\\ P',V' @ " channel "!" event-name channel-return " -> P'(V'))")))))

(define-method (csp-transform ast (o <assign>) . rest)
  (=>string
   ast
   (list "assign_(\\ (" (.identifier o) ") @ (" (.value (.expression o)) "))")))
