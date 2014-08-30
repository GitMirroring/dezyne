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
  :use-module (language asd normstate)
  :use-module (language asd reader)
  :use-module (language asd resolve)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (language asd gom)

  :export (
           ast->
           behaviour->csp
           csp:import
           csp->sugar
           csp->gom
           csp-component
           csp-module
	   ast-transform
	   ast-transform*
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
           enum-type
           ))

(define (ast-> ast)
  (let* ((norm ((gom:register csp:norm) ast #t)))
    (module-define! (resolve-module '(language asd csp)) 'ast norm)  ;; FIXME
    (and-let* ((comp (gom:component norm))
               (name (ast:name (ast:component ast))) ;; unmangled
               (module (csp-module norm))
               (fn (option-ref (parse-opts (command-line)) 'output (list name '.csp))))
              (dump-output fn
                           (lambda ()
                             (csp-component module)
                             (csp-asserts module)))))
  "")

(define (csp:import name)
  (gom:import name csp:norm))

(define (csp:norm ast)
  ((compose ast->gom ast:resolve normstate mangle) ast))

(define (mangle ast)
  "experimental mangling"
  (if (member (ast:name (ast:component ast))
              '(mangle argument2))
      (ast:mangle ast)
      ast))

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
    ((component illegal) . "assert STOP [T= #.component _#.behaviour.name _Component(false) \\ diff(Events,{illegal})\n")
    ((component deterministic) . "assert #.component _#.behaviour.name(true,true) :[deterministic]\n")
    ((component deadlock)  . "assert #.component _#.behaviour.name _Component(false) :[deadlock free]\n")
    ((component compliance) . ,(gulp-file 'templates/asserts/component-compliance.csp.scm))
    ((component livelock)  .  "assert #.component _#.behaviour.name _Component(true) \\ diff(Events,{|illegal,#.port.name |}) :[livelock free]\n")
    ((interface deadlock) . ,(gulp-file 'templates/asserts/interface-deadlock.csp.scm))
    ((interface livelock) . ,(gulp-file 'templates/asserts/interface-livelock.csp.scm))))

(define (csp-module ast)
  (let ((module (make-module 31 (list
                                 (resolve-module '(ice-9 match))
                                 (resolve-module '(ice-9 curried-definitions))
                                 (resolve-module '(language asd ast:))
                                 (resolve-module '(language asd csp))))))
    (module-define! module 'ast ast)
    (and-let* ((comp (gom:component ast)))
              (module-define! module '.component (.name comp))
              (module-define! module 'component comp)
              (module-define! module '.interface.name (.type (car (filter gom:provides? (.elements (.ports comp))))))
	      (module-define! module '.behaviour.name (.name (.behaviour comp)))
              (module-define! module '.interface-behaviour (.name (.behaviour (csp:import (.type (gom:port (gom:component ast)))))))
	      (module-define! module '.port.name (.name (gom:port comp))))
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
                     (interface . ,(csp:import (.type port)))
                     (.optional-chaos . ,optional-chaos)
                     (.interface.name . ,.type)
                     (.port.name . ,.name)
                     (.behaviour.name . ,(compose .name .behaviour csp:import .type))
                     ))))))))
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
                   `((interface . ,(csp:import interface))
                     (.interface.name . ,interface)))))))))
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

(define (behaviour->csp model default)
  (or (string-null-is-#f
       ((->join "\n[]\n")
        (append
         (map
          (lambda (guard)
            (let ((expression (csp-expression->string model (.expression guard)))
                  (ons ((gom:statements-of-type 'on) (.statement guard))))
              (list
               "(" expression ") & (\n"
               ((->join "\n []\n  ")
                (map (lambda (on)
                       (csp-transform model (ast-transform model on)))
                     (if (is-a? model <interface>)
                         ons
                         (append
                          (filter identity (map (statement-on-p/r (provides? model)) ons))
                          (filter identity (map (statement-on-p/r (requires? model)) ons))))))
               ")")))
          ((gom:statements-of-type 'guard) (gom:statement (.behaviour model))))
         (map (lambda (on) (csp-transform model (ast-transform model on)))
              ((gom:statements-of-type 'on) (gom:statement (.behaviour model)))))))
      default))

(define (enum-type ast identifier)
  (and-let* ((variable (gom:variable ast identifier))
             ((is-a? variable <variable>))
             (type (.type variable)))
            (ast:type type)))

(define (csp-expression->string ast src) ;; FIXME: no test
  (define (paren expression)
    (if (or (number? expression) (symbol? expression))
        expression
        (list "(" (csp-expression->string ast expression) ")")))

  (match src
    (($ <expression>) (csp-expression->string ast (.value src)))
    ((or (? number?) (? symbol?)) src)
    (($ <field> identifier field)
     (let ((enum (enum-type ast identifier)))
       (list "(" identifier " == " enum "_" field ")")))
    (($ <literal> scope type field) (list type "_" field))

    (('group expression) (list "(" (csp-expression->string ast expression) ")"))
    (('! expression) (->string (list "(" "not " (paren expression) ")")))
    (((or 'and 'or '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (csp-expression->string ast lhs))
           (rhs (csp-expression->string ast rhs))
           (op (car src)))
       (list "(" lhs " " op " " rhs ")")))

    (_ (format #f "~a:no match: ~a" (current-source-location) src))))

(define (port-events port) ;; FIXME: no test
  (let ((interface (csp:import (.type port))))
    (interface-events interface)))

(define (modeling-event? event)
  (member (.event event) '(optional inevitable)))

(define (modeling-events interface)
  (filter modeling-event? (gom:find-events interface)))

(define (interface-events interface)
  (let* ((events (map .name (.elements (.events interface))))
         (modeling (map .event (modeling-events interface))))
    (sort (append events modeling) symbol<)))

(define-method (typed-elements (o <enum>))
   (map (lambda (x) (symbol-append (.name o) '_ x)) ((compose .elements .fields) o)))

(define (enum-values comp)
  (let ((comp-values (apply append (map typed-elements (gom:enums (.behaviour comp))))))
    (let loop ((ports ((compose .elements .ports) comp)) (values comp-values))
      (if (null? ports)
          values
          (loop (cdr ports) (append values (apply append (map typed-elements (gom:enums (.behaviour (csp:import (.type (car ports)))))))))))))

(define-method (return-value (o <enum>))
  (map (lambda (value) (symbol-append (.name o) '_ value)) ((compose .elements .fields) o)))

(define (add-return-if-empty returns)
  (if (null? returns)
      '(return)
      (append (apply append returns) (list 'return)))) ;; FIXME: add only return when needed

(define (return-values-port port) ;; FIMXE: no test
  (add-return-if-empty (map return-value (gom:enums (csp:import (.type port))))))

(define (return-values-interface interface)
  (add-return-if-empty (map return-value (gom:enums interface))))


(define (return-values comp)
    (let loop ((ports ((compose .elements .ports) comp)) (result '()))
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

(define (prefix-illegal? statement)
  (match statement
    (($ <compound>)
     (let loop ((statements (.elements statement)))
       (if (null? statements)
           #f
           (or (prefix-illegal? (car statements)) (loop (cdr statements))))))
    (($ <illegal>) #t)
    (_ #f)))

(define (prefix-reply? statement)
  (match statement
    (($ <compound>)
     (let loop ((statements (.elements statement)))
       (if (null? statements)
           #f
           (or (prefix-reply? (car statements)) (loop (cdr statements))))))
    (('guard expr stat) (prefix-reply? stat)) ;; FIXME: no test
    (($ <on>)
     (prefix-reply? stat))
    (($ <if>)
     (or (prefix-reply? (.then statement)) (prefix-reply? (.else statement))))
    (($ <reply> expression) #t)
    (_ #f)
    (_ (throw 'match-error (format #f "~a:prefix-reply?: no match: ~a\n" (current-source-location) statement)))))

(define (((provides-or-requires? direction) component) event)
  (if (is-a? component <component>)
      (pair?
       (filter
	(lambda (port)
          (and (equal? (.direction port) direction)
               (equal? (.port event) (.name port))))
	(.elements (.ports component))))
      #f))

(define ((provides? component) event)
  (((provides-or-requires? 'provides) component) event))

(define ((requires? component) event)
  (((provides-or-requires? 'requires) component) event))

(define ((provides-event? model) event)
  (and (is-a? model <component>)
       ((provides? model) event)))

(define ((requires-event? model) event)
  (and (is-a? model <component>)
       ((requires? model) event)))

(define (optional-chaos port) ;; FIXME: no test
  (let ((interface (.type port)))
    (if (member 'optional (map .event (gom:find-events (csp:import (.type port)))))
        (list "[|{" interface " .optional}|] " "CHAOS({" interface " .optional})")
        "")))

(define (ast-transform ast src)
  (ast-transform- ast (ast-transform-return ast src)))

(define (ast-transform* ast src)
  (let ((ast* (csp->gom ast))
        (src* (csp->gom src)))
    (ast-transform- ast* (ast-transform-return ast* src*))))

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

(define-class <csp-call> (<call>)
  (context :accessor .context :init-form (list) :init-keyword :context))

(define-class <csp-if> (<if>)
  (context :accessor .context :init-form (list) :init-keyword :context))

(define-method (display-slots (o <csp-if>) port)
  (sdisplay (.context o) port)
  (next-method))

(define-class <csp-on> (<on>)
  (the-end :accessor .the-end :init-value #f :init-keyword :the-end))

(define-class <csp-return> (<return>)
  (context :accessor .context :init-form (list) :init-keyword :context))

(define (csp->sugar ast)
  (match ast
    (('expression expression)
     (make <expression> :value (csp->gom expression)))
    (('on ('triggers triggers) statement the-end)
     (make <csp-on>
       :triggers (csp->gom (cadr ast))
       :statement (csp->gom statement)
       :the-end (csp->gom the-end)))
    (('on triggers statement the-end)
     (make <csp-on>
       :triggers (make <triggers>
                   :elements (csp->gom (map ast->trigger-sugar triggers)))
       :statement (csp->gom statement)
       :the-end (csp->gom the-end)))
    (('if ('ctx context) ('expression expression) then else)
     (make <csp-if>
       :context (cadr ast)
       :expression (make <expression>
                     :value (csp->gom expression))
       :then (csp->gom then)
       :else (csp->gom else)))
    (('call ('ctx context) name)
     (make <csp-call>
       :context (cadr ast)
       :identifier name))
    (('call ('ctx context) name arguments)
     (make <csp-call>
       :context (cadr ast)
       :identifier name
       :arguments (csp->gom arguments)))
    (('return ('ctx context) expression)
     (make <csp-return>
       :context (cadr ast)
       :expression (make <expression> :value (csp->gom expression))))
    ((h t ...) (map csp->sugar ast))
    (_ ast)))

(define (csp->gom ast)
  ((compose ast->gom csp->sugar ast->sugar) ast))

(define-method (ast-transform-return ast (o <on>))
  (let* ((model (or (gom:interface ast) (gom:component ast)))
	 (members (gom:member-names model))
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
  (ast-transform-return (csp->gom ast) (csp->gom src)))

(define ((valued-action? port?) src)
  (match src
    (($ <variable> name type ($ <expression> ($ <action>))) #t)
    (($ <assign> identifier ($ <expression> ($ <action>))) #t)
    (_ #f)))

(define (call? variable)
  (match variable
    (($ <variable> name type ($ <expression> ($ <call>))) #t)
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
           (locals (if (equal? locals '(<>))
                       '<>
                       (reduce (lambda (x y) (string-append "(" (element->csp ast y) "," (element->csp ast x) ")")) #f (cons "stack'" locals)))))
       (if (string-null? members)
           (list "(" locals ")")
           (list "(" members "),(" locals ")"))))
    (_ (throw 'match-error (format #f "~a:context->csp: no match: ~a\n" (current-source-location) context)))))

(define-method (ast-transform- ast (o <top>))
  (let* ((model (or (gom:interface ast) (gom:component ast)))
         (context (make-context (gom:member-names model) '())))
    (ast-transform- ast o #t context)))

(define-method (ast-transform- ast (o <top>) return context)
  o)

(define-method (ast-transform- ast (o <compound>) return context)
  (let* ((model (or (gom:interface ast) (gom:component ast)))
         (context (or context (make-context (gom:member-names model) '())))
         (port? (lambda (port)
                  (if ((is? <interface>) model) #f
                      (member port (map .name (.elements (.ports model)))))))
         (valued-action? (valued-action? port?)))
    (let loop ((statements (.elements o)) (context context))
      (if (null? statements)
          '()
          (let* ((statement (car statements))
                 (transformed (ast-transform- ast statement #f context))
                 (context (if (is-a? statement <variable>)
                              (context-extend context (.name statement))
                              context)))
            (if (>1 (length statements))
                (if (is-a? transformed <illegal>)
                    transformed
                    (list (if (is-a? statement <variable>)
                              (if (or (valued-action? statement) (call? statement))
                                  'context-active
                                  'context)
                              'semi)
                          transformed (loop (cdr statements) context)))
                transformed))))))

(define-method (ast-transform- ast (o <variable>) return context)
  (let* ((model (or (gom:interface ast) (gom:component ast)))
         (port? (lambda (port)
                  (if ((is? <interface>) model)
                      #f
                      (member port (map .name (.elements (.ports model)))))))
         (identifier (.name o)))
    (match (.expression o)
      (($ <expression> (and ($ <call>) (get! call)))
       (list context identifier (call)))
      (($ <expression> expression)
       (list context identifier expression)))))

(define-method (ast-transform- ast (o <function>) return context)
  (let* ((signature (.signature o))
         (parameters ((compose .elements .parameters) signature))
         (parameters (map .identifier parameters))
         (context (context-extend context (if (>1 (length parameters))
                                              (cons 'vector parameters)
                                              parameters)))
         (statement (.statement o))
         (name (.name o))
         (transformed (ast-transform- ast statement return context)))
    (make <function> :name name
          :signature signature
          :statement transformed)))

(define-method (ast-transform- ast (o <return>) return context)
  (make <csp-return> :context context :expression (.expression o)))

(define-method (ast-transform- ast (o <call>) return context)
  (make <csp-call>
    :context context
    :identifier (.identifier o)
    :arguments (.arguments o)))

(define-method (ast-transform- ast (o <assign>) return context)
  (ast-transform-assign (.identifier o) (.value (.expression o)) context))

(define-method (ast-transform-assign identifier (o <action>) context)
  (list 'assign-active (list context 'r' o)
        (context-assign context identifier 'r')))

(define-method (ast-transform-assign identifier (o <call>) context)
  (list 'assign-active (list context 'r' o)
        (context-assign context identifier 'r')))

(define-method (ast-transform-assign identifier (o <top>) context)
  (make <assign>
    :identifier context
    :expression
    (make <expression> :value
          (context-assign context identifier o))))

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

(define-method (ast-transform- ast (o <if>) return context)
  (let* ((expr (.expression o))
         (then (.then o))
         (else (.else o))
         (then-illegal? (prefix-illegal? then))
         (else-illegal? (prefix-illegal? else))
         (pred-then (if then-illegal? (list 'and 'IG expr) expr))
         (pred (if else-illegal? (list 'and '(! IG) pred-then) pred-then)))
    (make <csp-if>
      :context context
      :expression (make <expression> :value pred)
      :then (ast-transform- ast then return context)
      :else (or (ast-transform- ast else return context) '()))))

(define (=>string ast src)
  (match src
    (('ctx context) (context->csp ast context))
    (($ <expression>) (csp-expression->string ast src))
    (($ <arguments> arguments) (comma-join (map (lambda (x) (=>string ast x)) arguments)))
    ((h t ...) (->string (map (lambda (x) (=>string ast x)) src)))
    (_ (->string src))))

(define (csp-transform* ast src)
  (csp-transform (csp->gom ast) (csp->gom src)))

(define* (csp-transform ast src :optional (inevitable-optional? #f) (channel #f) (provided-on? #t))
  (let* ((model (or (gom:interface ast) (gom:component ast)))
	 (model-name (.name model))
	 (behaviour (.name (.behaviour model)))
         (component? (is-a? model <component>)))
    (=>string ast
     (match src
       (($ <csp-on>)
        (let* ((triggers (.elements (.triggers src)))
               (statement (.statement src))
               (the-end (.the-end src))
               (inevitable-optional? (or (member 'inevitable (map .event triggers))
                                         (member 'optional (map .event triggers))))
               (ig? (eq? statement 'IG))
               (channel (if (is-a? model <interface>) model-name (.port (car triggers))))
               (provided-on? (or (and (is-a? model <interface>) (not inevitable-optional?))
                                 (or (is-a? model <interface>) ((provides-event? model) (car triggers)))))
               (IG? (if ig? (if ((provides-event? model) (car triggers)) "IIG & "  "IG & ")))
               (event-names (comma-join (map .event triggers)))
               (transformed (if ig? #f (csp-transform ast statement inevitable-optional? channel provided-on?)))
               (transformed-end (csp-transform ast the-end inevitable-optional? channel provided-on?)))
          (list IG? channel "?x:{" event-names "}" " ->\n" transformed transformed-end)))
       (($ <expression>) src)
       (($ <reply> expression)
        (let ((expression (csp-transform ast expression inevitable-optional? channel provided-on?)))
          (list "(\\ P',V' @ " channel "." expression " -> P'(V'))")))
       (($ <csp-return> ($ <expression> expression) context)
        (let ((expression (csp-expression->string ast expression)))
          (list "returnvalue_(\\ (" context ") @ " expression ")")))
       (($ <return>) "skip_") ;; FIXME
       (('eventreturn) (let ((channel-return (if (and (not inevitable-optional?) provided-on?)
                                            (list "(\\ P',V' @ " channel ".return -> P'(V'))")
                                            (list "(\\ P',V' @ P'(V'))"))))
                    (list channel-return)))
       (('the-end members)
        (let* ((transition-end (if component? "transition_end -> "))
               (context (make-context members '()))
               (end (if (not inevitable-optional?) (list transition-end))))
          (list "(\\ V' @ " end model-name "_" behaviour "_" "(V'),(" context "))")))
       (($ <illegal>) "illegal -> STOP")
       (($ <function> name ($ <signature> type ($ <parameters> '())) statement)
        (let ((transformed (csp-transform ast statement inevitable-optional? channel provided-on?)))
          (list name " = \\ P',V' @ " transformed "(P',V')\n")))
       (($ <function> name signature statement)
        (let ((body (csp-transform ast statement inevitable-optional? channel provided-on?)))
          (list name " = \\ P',V',F' @ context_(F',\n" body ")(P',V')\n")))
       (($ <csp-call> identifier ($ <arguments> '()) context)
        (list "callvoid_(" identifier ")"))
       (($ <csp-call> identifier arguments context)
        (let ((arguments (.elements arguments)))
          (list "callvoid_(\\ P',V' @ " identifier " (P',V',\\ (" context ") @ (" arguments ")))")))
       (($ <csp-if>)
        (let ((context (.context src))
              (expression (csp-expression->string ast (.expression src)))
              (then (csp-transform ast (.then src) inevitable-optional? channel provided-on?))
              (else (csp-transform ast (.else src) inevitable-optional? channel provided-on?)))
          (list "\\ P',(" context ") @ ifthenelse_(" expression ",\n" then ",\n" else "\n)(P',(" context "))")))
       (('context-active (context var ($ <expression> ($ <action> ($ <trigger> port event)))) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on?)))
          (list "context_active_(sendrecv_(" port "," event "),\n" stat ")")))
       (('context-active (context var ($ <action> ($ <trigger> port event))) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on?)))
          (list "context_active_(sendrecv_("  port "," event "),\n" stat ")")))
       (('context-active (context var ($ <call> identifier ($ <arguments> '()))) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on?)))
          (list "context_active_(" identifier ",\n" stat ")")))
       (('context-active (context var ($ <call> identifier (and ($ <arguments>) (get! arguments)))) stat)
          (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on?)))
          (list "context_active_(\\ P',V' @ " identifier " (P',V',\\ (" context ") @ (" (arguments) ")),\n" stat ")")))
       (('assign-active (context var ($ <action> ($ <trigger> port event))) expressions)
        (let ((action (list "sendrecv_(" port "," event ")")))
          (list "assign_active_(" action ",\n\\ ((" context "))," var " @ (" expressions "))" )))
       (('assign-active (context var ($ <call> identifier (and ($ <arguments>) (get! arguments)))) expressions)
        (list "assign_active_(\\ P',V' @ " identifier " (P',V',\\ (" context ") @ (" (arguments) ")),\n\\ ((" context "))," var " @ (" expressions "))"))
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
  (let* ((model (or (gom:interface ast) (gom:component ast)))
	 (model-name (.name model)))
    (=>string
     ast
     (let* ((trigger (.trigger o))
            (channel (if (is-a? model <interface>) model-name (.port trigger)))
            (event-name (.event trigger))
            (channel-return (if ((requires-event? model) trigger) (list " -> " channel ".return"))))
       (list "(\\ P',V' @ " channel "!" event-name channel-return " -> P'(V'))")))))

(define-method (csp-transform ast (o <assign>) . rest)
  (=>string
   ast
   (list "assign_(\\ (" (.identifier o) ") @ (" (.value (.expression o)) "))")))

(define (hide-modeling model)
  (and-let* (((is-a? model <interface>))
             (name (.name model))
             (modeling (null-is-#f (map .event (modeling-events model)))))
            (string-append " \\ {|"
                           (comma-join
                            (map (lambda (x) (->string (list name "." x)))
                                 modeling))
                           "|} ")))
