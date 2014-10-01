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
           csp->gom
           csp-component
           csp-module
	   ast-transform
	   csp-expression->string
	   csp-transform
           csp:norm

           assign
           extend
           statement-on-p/r
           provides?
           requires?
           enum-type

           <csp>
           <context>
           <csp-call>
           <csp-if>
           <csp-on>
           <csp-reply>
           <csp-return>
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
            (and-let* ((no-behaviour (null-is-#f (filter (negate .behaviour) interfaces)))
                       (message (format #f "gaiag: interface without behaviour: ~a\n"
                                        (comma-join (map .name no-behaviour)))))
                      (stderr message)
                      (throw 'csp message))
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

(define-method (valued? (model <model>) (o <on>))
  (gom:typed? model (car ((compose .elements .triggers) o))))


(define (behaviour->csp model default)

  (define (valued? o)
    (gom:typed? model o))

  (define (split-valued-void o)
    (receive (valued void) (partition valued? ((compose .elements .triggers) o))
      (let* ((statement (.statement o))
             (valued-on (if (pair? valued)
                            (list
                             (make <on>
                               :triggers (make <triggers> :elements valued)
                               :statement statement))
                            '()))
             (void-on (if (pair? void)
                          (list
                           (make <on>
                             :triggers (make <triggers> :elements void)
                             :statement statement))
                          '())))
        (append void-on valued-on))))

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
                     (let ((ons
                            (if (is-a? model <interface>)
                                ons
                                (append
                                 (filter identity (map (statement-on-p/r (provides? model)) ons))
                                 (filter identity (map (statement-on-p/r (requires? model)) ons))))))
                       (apply append (map split-valued-void ons)))))
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
        (list " [|{" name ".optional}|] " "CHAOS({" name ".optional})")
        "")))

(define-class <context> (<ast>)
  (members :accessor .members :init-form (list) :init-keyword :members)
  (locals :accessor .locals :init-form (list) :init-keyword :locals))

(define-class <csp> (<ast>)
  (context :accessor .context :init-value #f :init-keyword :context))

(define-class <csp-call> (<csp> <call>))

(define-class <csp-if> (<csp> <if>))

(define-class <csp-on> (<on>)
  (the-end :accessor .the-end :init-value #f :init-keyword :the-end))

(define-class <csp-reply> (<csp> <reply>))

(define-class <csp-return> (<csp> <return>))

(define (ast-transform ast src)
  (ast-transform- ast (ast-transform-return ast src)))

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

(define-method (ast-transform-return ast (o <on>))
  (let* ((model (or (gom:component ast) (gom:interface ast)))
	 (members (gom:member-names model))
         (triggers (.triggers o))
         (valued-triggers? (lambda (x) (gom:typed? model (car ((compose .elements .triggers) o))))))
    (let ((result (ast-transform-return ast (.statement o))))
      (match result
        (($ <compound> '())
         (make <csp-on>
           :triggers triggers
           :statement (make <compound>
                        :elements (list (list 'eventreturn)))
           :the-end (list 'the-end members)))
        ((? valued-triggers?)
         (make <csp-on>
           :triggers triggers
           :statement (make <compound> :elements (list result))
           :the-end (list 'the-end members)))
        (_
         (make <csp-on>
           :triggers triggers
           :statement (make <compound> :elements (list result (list 'eventreturn)))
           :the-end (list 'the-end members)))))))

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

(define-method (extend (o <context>) extension)
  (let ((members (.members o))
        (locals (.locals o)))
    (match extension
      (('vector identifiers ..1)
       (make <context>
         :members (frame-hide members 'hide_member identifiers)
         :locals (append (frame-hide locals 'hide_local identifiers)
                         (list extension))))
      ((? symbol?)
       (make <context>
         :members (frame-hide members 'hide_member (list extension))
         :locals (append (frame-hide locals 'hide_local (list extension))
                         (list extension))))
      ((h) (extend o h))
      ('() o))))

(define ((assign identifier expression) x)
  (match x
    (('vector expressions ...)
     (cons 'vector (map (assign identifier expression) expressions)))
    (_ (if (eq? x identifier) expression x))))

(define-generic assign)
(define-method (assign (o <context>) identifier expression)
  (make <context>
    :members (map (assign identifier expression) (.members o))
    :locals (map (assign identifier expression) (.locals o))))

(define (element->csp ast x)
  (match x
    (('vector expressions ...) (string-append "(" (comma-join (map (lambda (x) (csp-expression->string ast x)) expressions)) ")"))
    (_ (->string (csp-expression->string ast x)))))

(define-method (->csp ast (o <context>))
  (let* ((members (.members o))
         (locals (.locals o))
         (members (comma-join (map (lambda (x) (csp-expression->string ast x)) members)))
         (members (if (string-null? members) '<> members))
         (locals (if (equal? locals '(<>))
                     '<>
                     (reduce (lambda (x y)
                               (string-append "(" (element->csp ast y) ","
                                              (element->csp ast x) ")"))
                             #f (cons "stack'" locals)))))
    (list "(" members "),(" locals ")")))

(define* (ast-transform- ast o :optional (return #t) (context #f))
  (let* ((model (or (gom:component ast) (gom:interface ast)))
         (context (or context (make <context> :members (gom:member-names model))))
         (port? (lambda (port)
                  (if ((is? <interface>) model) #f
                      (member port (map .name (.elements (.ports model)))))))
         (valued-action? (valued-action? port?)))

    (match o

      (($ <compound> statements)
       (let loop ((statements statements) (context context))
         (if (null? statements)
             '()
             (let* ((statement (car statements))
                    (transformed (ast-transform- ast statement #f context))
                    (context (if (is-a? statement <variable>)
                                 (extend context (.name statement))
                                 context)))
               (if (>1 (length statements))
                   (if (is-a? transformed <illegal>)
                       transformed
                       (list (if (is-a? statement <variable>)
                                 (if (or (valued-action? statement)
                                         (call? statement))
                                     'context-active
                                     'context-open)
                                 'semi)
                             transformed (loop (cdr statements) context)))
                   (if (is-a? statement <variable>)
                       (list
                        (if (or (valued-action? statement)
                                (call? statement))
                            'context-active
                            'context-open)
                        transformed 'skip)
                       transformed))))))

      (($ <assign> identifier ($ <expression> value))
       (make <assign>
         :identifier context
         :expression (make <expression>
                       :value (assign context identifier value))))

      (($ <assign> identifier expression)
       (list 'assign-active (list context 'r' expression)
             (assign context identifier 'r')))

      (($ <call> identifier arguments)
       (make <csp-call>
         :context context
         :identifier identifier
         :arguments arguments))

      (($ <function> name signature recursive statement)
       (let* ((parameters ((compose .elements .parameters) signature))
              (parameters (map .name parameters))
              (context (extend context (if (>1 (length parameters))
                                                   (cons 'vector parameters)
                                                   parameters))))
         (make <function> :name name
               :signature signature
               :recursive recursive
               :statement (ast-transform- ast statement return context))))

      (($ <if> ($ <expression> expr) then else)
       (let* ((then-illegal? (prefix-illegal? then))
              (else-illegal? (prefix-illegal? else))
              (pred-then (if then-illegal? (list 'and 'IG expr) expr))
              (pred (if else-illegal? (list 'and '(! IG) pred-then) pred-then))
              (then-context (if (is-a? then <variable>)
                                (extend context (.name then))
                                context))
              (else-context (if (is-a? else <variable>)
                                (extend context (.name else))
                                context))
              (then-transformed (ast-transform- ast then return then-context))
              (else-transformed (ast-transform- ast else return else-context))
              (then (if (is-a? then <variable>)
                        (list (if (or (valued-action? then)
                                      (call? then))
                                  'context-active
                                  'context-open)
                              then-transformed 'skip)
                        then-transformed))
              (else (if (is-a? else <variable>)
                        (list (if (or (valued-action? else)
                                      (call? else))
                                  'context-active
                                  'context-open)
                              else-transformed 'skip)
                        else-transformed)))
         (make <csp-if>
           :context context
           :expression (make <expression> :value expr)
           :then then
           :else (or else '()))))

      (($ <csp-on> triggers statement the-end)
       (let ((result (ast-transform- ast statement)))
         (if (prefix-illegal? statement)
             (make <csp-on> :triggers triggers :statement 'IG :the-end result)
             (make <csp-on> :triggers triggers :statement result :the-end the-end))))

      (($ <reply> expression)
       (make <csp-reply>
         :context context
         :expression (ast-transform- ast expression return context)))

      (($ <return> expression)
       (make <csp-return>
         :context context
         :expression (ast-transform- ast expression return context)))

      (($ <variable> name type expression)
       ;;(list 'context-active (list context 'r' expression) (context-assign context name 'r'))
       (list context name expression))

      (($ <expression> (and ($ <call>) (get! call)))
       (make <expression> :value (ast-transform- ast (call) return context)))

      (_ o))))


(define (=>string ast src)
  (match src
    (($ <context>) (->csp ast src))
    (($ <expression> (and ($ <csp-call>) (get! call))) (csp-transform ast (call)))
    (($ <expression>) (csp-expression->string ast src))
    (($ <arguments> arguments) (comma-join (map (lambda (x) (=>string ast x)) arguments)))
    ((h t ...) (->string (map (lambda (x) (=>string ast x)) src)))
    (_ (->string src))))

(define* (csp-transform ast src :optional (inevitable-optional? #f) (channel #f) (provided-on? #t) (tail-recursive? #f))
  (let* ((model (or (gom:component ast) (gom:interface ast)))
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
               (channel (if (is-a? model <interface>) model-name (.port (car triggers))))
               (provided-on? (or (and (is-a? model <interface>) (not inevitable-optional?))
                                 (or (is-a? model <interface>) ((provides-event? model) (car triggers)))))
               (IG? (if ig? (if ((provides-event? model) (car triggers)) "IIG & "  "IG & ")))
               (event-names (comma-join (map .event triggers)))
               (transformed (if ig? #f (csp-transform ast statement inevitable-optional? channel provided-on? tail-recursive?)))
               (transformed-end (csp-transform ast the-end inevitable-optional? channel provided-on? tail-recursive?)))
          (list IG? channel "?x:{" event-names "}" " ->\n" transformed transformed-end (if ig? "(STOP,<>)" ""))))

       (($ <action> trigger)
        (let* ((channel (list "" (if (is-a? model <interface>) model-name (.port trigger))))
               (event-name (.event trigger))
               (channel-return (if ((requires-event? model) trigger) (list " -> " channel ".return"))))
          (list "(\\ P',V' @ " channel "!" event-name channel-return " -> P'(V'))")))

       (($ <assign> identifier ($ <expression> value))
        (list "assign_(\\ (" identifier ") @ (" value "))"))

       (($ <context>) src)

       (($ <expression>) src)

       (($ <csp-reply> expression context)
        (let* ((channel (or channel (if (is-a? model <interface>) model-name (.type (gom:port model))))))
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
               (context (make <context> :members members))
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
          (list "context_active_(sendrecv_("  (or port channel) "," event "),\n" stat ")")))
       (('context-active (context var ($ <call> identifier ($ <arguments> '()))) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on? tail-recursive?)))
          (list "context_active_(\\ P',V' @ " identifier " (" continuation-pv "),\n" stat ")")))

       (('context-active (context var ($ <call> identifier (and ($ <arguments>) (get! arguments)))) stat)
          (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on? tail-recursive?)))
          (list "context_active_(\\ P',V' @ " identifier " (" continuation-pv ",(\\ (" context ") @ (" (arguments) "))(V')),\n" stat ")")))

       (('assign-active (context var ($ <action> ($ <trigger> port event))) expressions)
        (let ((action (list "sendrecv_(" (or port channel) "," event ")")))
          (list "assign_active_(" action ",\n\\ ((" context "))," var " @ (" expressions "))" )))
       (('assign-active (context var ($ <call> identifier (and ($ <arguments>) (get! arguments)))) expressions)
        (list "assign_active_(\\ P',V' @ " identifier " (" continuation-pv ",(\\ (" context ") @ (" (arguments) "))(V')),\n\\ ((" context "))," var " @ (" expressions "))"))
       (('context-open (context var expression) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on? tail-recursive?)))
          (list "context_(\\ (" context ") @ " expression ",\n" stat ")" )))
       (('semi stat1 stat2)
        (let ((first (csp-transform ast stat1 inevitable-optional? channel provided-on? tail-recursive?))
              (second (csp-transform ast stat2 inevitable-optional? channel provided-on? tail-recursive?)))
          (list "semi_(" first ",\n" second ")")))
       ('skip "skip_")
       ('() "skip_")
       ((? symbol?) src)
       ((? string?) src)
       (_ (throw 'match-error (format #f "~a:csp-transform: no match: ~a\n" (current-source-location) src)))))))

(define (hide-modeling model)
  (and-let* (((is-a? model <interface>))
             (name (.name model))
             (modeling (null-is-#f (map .event (modeling-events model)))))
            (string-append " \\ {|"
                           (comma-join
                            (map (lambda (x) (->string (list "" name "." x)))
                                 modeling))
                           "|} ")))
