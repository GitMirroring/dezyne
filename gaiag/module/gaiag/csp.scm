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

(define-module (gaiag csp)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)
  :use-module (ice-9 receive)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag asserts)

  :use-module (gaiag gaiag)
  :use-module (gaiag mangle)
  :use-module (gaiag misc)
  :use-module (gaiag normstate)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
  :use-module (gaiag wfc)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

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
           csp:norm

           make-context
           context-extend
           statement-on-p/r
           provides?
           requires?
           enum-type
           ))

(define (ast-> ast)
  (let ((gom ((gom:register ast->gom) ast #t)))
    (or (and-let* ((model (gom:model-with-behaviour gom)))
                  (generate-csp model))
        (let* ((models ((gom:filter <model>) gom))
               (message (format #f "gaiag: no component with behaviour: ~a\n"
                                (comma-join (map .name models)))))
          (stderr message)
          (throw 'csp message))))
  "")

(define-method (generate-csp (o <interface>))
  (and-let* ((root (make <root> :elements (list o))))
            (generate-csp o root)))

(define-method (generate-csp (o <component>))
  (and-let* ((interfaces (map csp:import (map .type ((compose .elements .ports) o))))

             (root (make <root> :elements (append interfaces (list o)))))
            (generate-csp o root)))

(define-method (generate-csp (o <model>) (root <root>))
  (let ((separate-asserts? (option-ref (parse-opts (command-line)) 'assert #f)))
    (and-let* ((norm ((gom:register csp:norm) root #t))
               (name (.name o))
               (model (gom:model-with-behaviour norm))
               (file-name (option-ref (parse-opts (command-line)) 'output (list name '.csp))))
              (dump-output file-name (lambda ()
                                       (animate-file (append (prefix-dir) '(templates combinators.csp.scm)) (csp-module model))
                                       (csp-model model)
                                       (if separate-asserts?
                                           (animate-string "\ninclude \"asserts.csp\"\n")
                                           (csp-asserts model))))
              (if separate-asserts? (dump-output "asserts.csp" (lambda () (csp-asserts model)))))))

(define (csp:import name)
  (gom:import name csp:norm))

(define (csp:norm ast)
  ((compose normstate mangle ast:wfc ast:resolve ast->gom ast:interface) ast))

(define (mangle ast)
  "experimental mangling"
  (or (and-let* ((component (gom:component ast))
                 ((member (.name component) '(mangle argument2))))
                (gom:mangle ast))
      ast))

(define-method (interfaces (o <component>))
  (map gom:import (delete-duplicates (sort (map .type ((compose .elements .ports) o)) symbol<))))

(define-method (csp-model (o <component>))
  (for-each csp-model (interfaces o))
  (animate-file (append (prefix-dir) '(templates component.csp.scm)) (csp-module o)))

(define-method (csp-model (o <interface>))
  (animate-file (append (prefix-dir) '(templates interface.csp.scm)) (csp-module o)))

(define-method (csp-asserts (o <component>))
  (for-each csp-asserts (interfaces o))
  (next-method))

(define-method (csp-asserts (o <model>))
  (for-each (csp-assert o) (assert-list o)))

(define-method (csp-assert (o <model>))
  (lambda (assert)
    (let* ((class (car assert))
           (model (cadr assert))
           (check (caddr assert))
           (template (assoc-ref asserts-alist (list class check))))
      (animate-string template (csp-module o)))))

(define asserts-alist
  `(
    ((component illegal) . "assert STOP [T= AS_#(.name model) _#((compose .name .behaviour) model) (false) \\ diff(Events,{illegal})\n")
    ((component deterministic) . "assert CO_#(.name model) _#((compose .name .behaviour) model)(true,true) :[deterministic]\n")
    ((component deadlock)  . "assert AS_#(.name model) _#((compose .name .behaviour) model) (false) :[deadlock free]\n")
    ((component compliance) . ,(gulp-template 'asserts/component-compliance.csp.scm))
    ((component livelock)  .  "assert AS_#(.name model) _#((compose .name .behaviour) model) (true) \\ diff(Events,{|illegal,#((compose .name gom:port) model) |}) :[livelock free]\n")
    ((interface deadlock) . ,(gulp-template 'asserts/interface-deadlock.csp.scm))
    ((interface livelock) . ,(gulp-template 'asserts/interface-livelock.csp.scm))))

(define-method (csp-module (o <model>))
  (let ((module (make-module 31 (list
                                 (resolve-module '(gaiag csp))
                                 ))))
    (module-define! module 'model o)
    module))

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
            (.name type)))

(define (csp-expression->string ast src) ;; FIXME: more tests
  (define (paren expression)
    (let ((value (if (is-a? expression <expression>) (.value expression) expression)))
      (if (or (number? value) (symbol? value) (is-a? value <var>))
          (csp-expression->string ast expression)
          (list "(" (csp-expression->string ast expression) ")"))))
  (match src
    (($ <var> identifier) identifier)
    (($ <expression>) (csp-expression->string ast (.value src)))
    ((or (? number?) (? string?) (? symbol?)) src)
    (($ <field> identifier field)
     (let ((enum (enum-type ast identifier)))
       (list "(" identifier " == " enum "_" field ")")))
    (($ <literal> scope type field) (list type "_" field))

    (($ <var> identifier) identifier)
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

(define-method (interface-events (o <component>)) ;; FIXME: no test
  (apply append (map (compose interface-events gom:import .type) ((compose .elements .ports) o))))

(define-method (interface-events (o <interface>))
  (let* ((events (map .name (.elements (.events o))))
         (modeling (map .event (modeling-events o))))
    (sort (append events modeling) symbol<)))

(define (modeling-event? event)
  (member (.event event) '(optional inevitable)))

(define (modeling-events interface)
  (filter modeling-event? (gom:find-triggers interface)))

(define-method (typed-elements (o <enum>))
   (map (lambda (x) (symbol-append (.name o) '_ x)) ((compose .elements .fields) o)))

(define-method (enum-values (o <component>))
  (append
   (apply append (map (compose enum-values gom:import .type) ((compose .elements .ports) o)))
   (next-method)))

(define-method (enum-values (o <model>))
  (apply append (map typed-elements (or (and=> (.behaviour o) gom:enums) '()))))

(define-method (return-value (o <enum>))
  (map (lambda (value) (symbol-append (.name o) '_ value)) ((compose .elements .fields) o)))

(define (add-return-if-empty returns)
  (if (null? returns)
      '(return)
      (append (apply append returns) (list 'return)))) ;; FIXME: add only return when needed

(define (return-values-port port) ;; FIMXE: no test
  (let ((interface (csp:import (.type port))))
    (return-values interface)))

(define-method (return-values (o <interface>)) ;; FIMXE: no test
  (add-return-if-empty (map return-value (gom:interface-enums o))))

(define-method (return-values (o <component>))
  (apply append (map (compose return-values gom:import .type) ((compose .elements .ports) o))))

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

(define-method (optional-chaos (o <interface>)) ;; FIXME: no test
  (let ((name (.name o)))
    (if (member 'optional (map .event (gom:find-triggers o)))
        (list " [|{CH_" name ".optional}|] " "CHAOS({CH_" name ".optional})")
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

(define-class <csp-reply> (<reply>)
  (context :accessor .context :init-form (list) :init-keyword :context))

(define-method (display-slots (o <csp-reply>) port)
  (sdisplay (.context o) port)
  (next-method))

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
    (('if ('ctx context) expression then else)
     (make <csp-if>
       :context (cadr ast)
       :expression (csp->gom expression)
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
    (('reply ('ctx context) expression)
     (make <csp-reply>
       :context (cadr ast)
       :expression (csp->gom expression)))
    (('return ('ctx context) expression)
     (make <csp-return>
       :context (cadr ast)
       :expression (csp->gom expression)))
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
    (($ <variable> name type ($ <action>)) #t)
    (($ <assign> identifier ($ <action>)) #t)
    (_ #f)))

(define-method (call? (o <variable>))
  (call? (.expression o)))

(define-method (call? (o <top>))
  #f)

(define-method (call? (o <call>))
  #t)

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
    (_ (->string (csp-expression->string ast x)))))

(define (context->csp ast context)
  (match context
    (('ctx context) (context->csp ast context))
    ((members locals ...)
     (let* ((members (comma-join (map (lambda (x) (csp-expression->string ast x)) members)))
            (members (if (string-null? members) '<> members))
            (locals (if (equal? locals '(<>))
                        '<>
                        (reduce (lambda (x y) (string-append "(" (element->csp ast y) "," (element->csp ast x) ")")) #f (cons "stack'" locals)))))
       (list "(" members "),(" locals ")")))
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
                              (if (or (valued-action? statement)
                                      (call? statement))
                                  'context-active
                                  'context)
                              'semi)
                          transformed (loop (cdr statements) context)))
                transformed))))))

(define-method (ast-transform- ast (o <variable>) return context)
  (ast-transform-variable (.name o) (.expression o) context))

(define-method (ast-transform-variable name (o <call>) context)
  (list context name o))

(define-method (ast-transform-variable name (o <top>) context)
  (list context name o))

(define-method (ast-transform- ast (o <function>) return context)
  (let* ((signature (.signature o))
         (parameters ((compose .elements .parameters) signature))
         (parameters (map .name parameters))
         (context (context-extend context (if (>1 (length parameters))
                                              (cons 'vector parameters)
                                              parameters)))
         (statement (.statement o))
         (name (.name o))
         (transformed (ast-transform- ast statement return context)))
    (make <function> :name name
          :signature signature
          :recursive (.recursive o)
          :statement transformed)))

(define-method (ast-transform- ast (o <expression>) return context)
  (let ((value (.value o)))
    (match (.value o)
      (($ <call>) (make <expression> :value (ast-transform- ast value return context)))
      (_ o))))

(define-method (ast-transform- ast (o <reply>) return context)
  (make <csp-reply>
    :context context
    :expression (ast-transform- ast (.expression o) return context)))

(define-method (ast-transform- ast (o <return>) return context)
  (make <csp-return>
    :context context
    :expression (ast-transform- ast (.expression o) return context)))

(define-method (ast-transform- ast (o <call>) return context)
  (make <csp-call>
    :context context
    :identifier (.identifier o)
    :arguments (.arguments o)))

(define-method (ast-transform- ast (o <assign>) return context)
  (ast-transform-assign (.identifier o) (.expression o) context))

(define-method (ast-transform-assign identifier (o <action>) context)
  (list 'assign-active (list context 'r' o)
        (context-assign context identifier 'r')))

(define-method (ast-transform-assign identifier (o <call>) context)
  (list 'assign-active (list context 'r' o)
        (context-assign context identifier 'r')))

(define-method (ast-transform-assign identifier (o <expression>) context)
  (make <assign>
    :identifier context
    :expression
    (make <expression> :value
          (context-assign context identifier (.value o)))))

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
  (let* ((expr (.value (.expression o)))
         (then (.then o))
         (else (.else o))
         (then-illegal? (prefix-illegal? then))
         (else-illegal? (prefix-illegal? else))
         (pred-then (if then-illegal? (list 'and 'IG expr) expr))
         (pred (if else-illegal? (list 'and '(! IG) pred-then) pred-then)))
    (make <csp-if>
      :context context
      :expression (make <expression> :value expr)
      :then (ast-transform- ast then return context)
      :else (or (ast-transform- ast else return context) '()))))

(define (=>string ast src)
  (match src
    (('ctx context) (context->csp ast context))
    (($ <expression> (and ($ <csp-call>) (get! call))) (csp-transform ast (call)))
    (($ <expression>) (csp-expression->string ast src))
    (($ <arguments> arguments) (comma-join (map (lambda (x) (=>string ast x)) arguments)))
    ((h t ...) (->string (map (lambda (x) (=>string ast x)) src)))
    (_ (->string src))))

(define (csp-transform* ast src)
  (csp-transform (csp->gom ast) (csp->gom src)))

(define* (csp-transform ast src :optional (inevitable-optional? #f) (channel #f) (provided-on? #t) (tail-recursive? #f))
  (let* ((model (or (gom:interface ast) (gom:component ast)))
	 (model-name (.name model))
	 (behaviour (.name (.behaviour model)))
         (component? (is-a? model <component>))
         (continuation-p (if tail-recursive? "PF'" "P'"))
         (continuation-pv (string-append continuation-p (if tail-recursive? ",VF'" ",V'"))))
    (=>string ast
     (match src
       (($ <csp-on>)
        (let* ((triggers (.elements (.triggers src)))
               (statement (.statement src))
               (the-end (.the-end src))
               (inevitable-optional? (or (member 'inevitable (map .event triggers))
                                         (member 'optional (map .event triggers))))
               (ig? (eq? statement 'IG))
               (channel (if (is-a? model <interface>) (list "CH_" model-name) (.port (car triggers))))
               (provided-on? (or (and (is-a? model <interface>) (not inevitable-optional?))
                                 (or (is-a? model <interface>) ((provides-event? model) (car triggers)))))
               (IG? (if ig? (if ((provides-event? model) (car triggers)) "IIG & "  "IG & ")))
               (event-names (comma-join (map .event triggers)))
               (transformed (if ig? #f (csp-transform ast statement inevitable-optional? channel provided-on? tail-recursive?)))
               (transformed-end (csp-transform ast the-end inevitable-optional? channel provided-on? tail-recursive?)))
          (list IG? channel "?x:{" event-names "}" " ->\n" transformed transformed-end (if ig? "(STOP,<>)" ""))))
       (($ <expression>) src)
       (($ <csp-reply> expression context)
        (let* ((channel (or channel (if (is-a? model <interface>) (list "CH_" model-name) (list "CH_" (.type (gom:port model)))))))
          (list "reply_(" channel ", " "(\\ (" context ") @ " expression "))")))
       (($ <return>) "skip_")
       (($ <csp-return> #f context) "skip_")
       (($ <csp-return> ($ <expression> expression) context)
        (let ((expression (csp-expression->string ast expression)))
          (list "returnvalue_(\\ (" context ") @ " expression ")")))
       (('eventreturn) (let ((channel-return (if (and (not inevitable-optional?) provided-on?)
                                            (list "(\\ P',V' @ " channel ".return -> P'(V'))")
                                            (list "skip_"))))
                    (list channel-return)))
       (('the-end members)
        (let* ((transition-end (if component? "transition_end -> "))
               (context (make-context members '()))
               (end (if (not inevitable-optional?) (list transition-end))))
          (list "(\\ V' @ " end model-name "_" behaviour "(V'),(" context "))")))
       (($ <illegal>) "illegal_")
       (($ <function> name ($ <signature> type ($ <parameters> '())) recursive? statement)
        (let ((transformed (csp-transform ast statement inevitable-optional? channel provided-on? recursive?))
              (continuation-pv (if recursive? "PF',VF'" "P',V'")))
          (list name " = \\ " continuation-pv " @ context_func_(" transformed ")(" continuation-pv ")\n")))
       (($ <function> name signature recursive? statement)
        (let ((body (csp-transform ast statement inevitable-optional? channel provided-on? recursive?))
              (continuation-pv (if recursive? "PF',VF'" "P',V'")))
          (list name " = \\ " continuation-pv ",F' @ context_func_args_(F',\n" body ")(" continuation-pv ")\n")))
       (($ <csp-call> identifier ($ <arguments> '()) context)
        (let ((continuation-pv (string-append continuation-p (if tail-recursive?  ",members_(V')" ",V'"))))
          (list "callvoid_(\\ P',V' @ " identifier "(" continuation-pv "))")))
       (($ <csp-call> identifier arguments context)
        (let ((continuation-pv (string-append continuation-p (if tail-recursive?  ",members_(V')" ",V'"))))
          (list "callvoid_(\\ P',V' @ " identifier "(" continuation-pv ",(\\ (" context ") @ (" arguments "))(V')))")))
       (($ <csp-if>)
        (let ((context (.context src))
              (expression (csp-expression->string ast (.expression src)))
              (then (csp-transform ast (.then src) inevitable-optional? channel provided-on? tail-recursive?))
              (else (csp-transform ast (.else src) inevitable-optional? channel provided-on? tail-recursive?)))
          (list "\\ P',(" context ") @ ifthenelse_(" expression ",\n" then ",\n" else "\n)(P',(" context "))")))
       (('context-active (context var ($ <action> ($ <trigger> port event))) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on? tail-recursive?)))
          (list "context_active_(sendrecv_("  port "," event "),\n" stat ")")))
       (('context-active (context var ($ <expression> ($ <action> ($ <trigger> port event)))) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on? tail-recursive?)))
          (list "context_active_(sendrecv_(" port "," event "),\n" stat ")")))

       (('context-active (context var ($ <call> identifier ($ <arguments> '()))) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on? tail-recursive?)))
          (list "context_active_(\\ P',V' @ " identifier " (" continuation-pv "),\n" stat ")")))

       (('context-active (context var ($ <call> identifier (and ($ <arguments>) (get! arguments)))) stat)
          (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on? tail-recursive?)))
          (list "context_active_(\\ P',V' @ " identifier " (" continuation-pv ",(\\ (" context ") @ (" (arguments) "))(V')),\n" stat ")")))

       (('assign-active (context var ($ <action> ($ <trigger> port event))) expressions)
        (let ((action (list "sendrecv_(" port "," event ")")))
          (list "assign_active_(" action ",\n\\ ((" context "))," var " @ (" expressions "))" )))
       (('assign-active (context var ($ <call> identifier (and ($ <arguments>) (get! arguments)))) expressions)
        (list "assign_active_(\\ P',V' @ " identifier " (" continuation-pv ",(\\ (" context ") @ (" (arguments) "))(V')),\n\\ ((" context "))," var " @ (" expressions "))"))
       (('context (context var expression) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on? tail-recursive?)))
          (list "context_(\\ (" context ") @ " expression ",\n" stat ")" )))
       (('semi stat1 stat2)
        (let ((first (csp-transform ast stat1 inevitable-optional? channel provided-on? tail-recursive?))
              (second (csp-transform ast stat2 inevitable-optional? channel provided-on? tail-recursive?)))
          (list "semi_(" first ",\n" second ")")))
       (('skip) "skip_")
       ('() "skip_")
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
            (channel (if (is-a? model <interface>) (list "CH_" model-name) (.port trigger)))
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
                            (map (lambda (x) (->string (list "CH_" name "." x)))
                                 modeling))
                           "|} ")))
