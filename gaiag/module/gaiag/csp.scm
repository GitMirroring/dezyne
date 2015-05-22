;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
;; Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
  :use-module (gaiag norm)  
  :use-module (gaiag norm-state)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
  :use-module (gaiag wfc)

  :use-module (oop goops)
  ;;:use-module (oop goops describe)
  :use-module (gaiag om)

  :export (
           ast->
           behaviour->csp
           csp:import
           csp-component
           csp-module
	   ast-transform
	   csp-transform
           csp:norm
           csp-queue-size
           om->csp

           assign
           extend
           provides?
           requires?

           <semi>
           <context-vector>
           <context>
           <csp-assign>
           <csp-call>
           <csp-if>
           <csp-on>
           <csp-reply>
           <csp-return>
           <csp-variable>
           <csp>
           <voidreply>
           <skip>
           ))

(define-method (om->csp (om <ast>))
  (let ((name (and=> (option-ref (parse-opts (command-line)) 'model #f)
                     string->symbol)))
    (or (and-let* ((models (null-is-#f (om:models-with-behaviour om)))
                   (model (if name (find (om:named name) models) (car models))))
                  (generate-csp model))
        (let* ((models ((om:filter <model>) om))
               (models (comma-join (map .name models)))
               (message (if name
                            "gaiag: no model [name=~a] with behaviour: ~a\n"
                            "gaiag: no model with behaviour: ~a\n"))
               (message (format #f message name models)))
          (stderr message)
          (throw 'csp message)))))

(define (ast-> ast)
  (let ((om ((om:register ast->om) ast #t)))
    (om->csp om))
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
    (and-let* ((norm ((om:register csp:norm) root #t))
               (name (.name o))
               (model (om:model-with-behaviour norm))
               (file-name (option-ref (parse-opts (command-line)) 'output (list name '.csp))))
              (dump-output file-name (lambda ()
                                       (csp-file 'combinators.csp.scm (csp-module model))
                                       (csp-model model)
                                       (if separate-asserts?
                                           (animate-string "\ninclude \"asserts.csp\"\n")
                                           (csp-asserts model))
                                       (if (option-ref (parse-opts (command-line)) 'lts #f)
                                           (let ((models (append (interfaces model) (list model))))
                                             (map csp-lts models)
                                             (assembly-lts model)))))
              (if separate-asserts? (dump-output "asserts.csp" (lambda () (csp-asserts model)))))))

(define (csp:import name)
  (om:import name csp:norm))

(define (csp:norm ast)
  ((compose csp-norm-state mangle ast:wfc ast:resolve ast->om ast:interface) ast))

(define (mangle ast)
  "experimental mangling"
  (or (and-let* ((component (om:component ast))
                 ((member (.name component) '(mangle argument2))))
                (om:mangle ast))
      ast))

(define ((demangle-var model) var)
  (or (and-let* (((member (.name model) '(co_mangle co_argument2 if_I)))
                 (svar (symbol->string var))
                 ((string-prefix? "va_" svar)))
                (string->symbol (string-drop svar 3)))
      var))

(define-method (interfaces (o <interface>))
  '())

(define-method (interfaces (o <component>))
  (map om:import (delete-duplicates (sort (map .type ((compose .elements .ports) o)) symbol<))))

(define-method (assembly-lts (o <component>))
  (csp-file 'assembly-lts.csp.scm (csp-module o)))

(define-method (assembly-lts (o <interface>)))

(define-method (csp-lts (o <component>))
  (csp-file 'component-lts.csp.scm (csp-module o)))

(define-method (csp-lts (o <interface>))
  (csp-file 'interface-lts.csp.scm (csp-module o)))

(define-method (csp-model (o <component>))
  (for-each csp-model (interfaces o))
  (csp-file 'component.csp.scm (csp-module o)))

(define-method (csp-model (o <interface>))
  (csp-file 'interface.csp.scm (csp-module o)))

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
    ((component completeness) . ,(gulp-template 'asserts/component-completeness.csp.scm))
    ((component illegal) . "assert STOP [T= AS_#(.name model) _#((compose .name .behaviour) model) (false) \\ diff(Events,{illegal})\n")
    ((component deterministic) . "assert CO_#(.name model) _#((compose .name .behaviour) model)(true,true)[[#(.type (om:port model))_'.x<-#(.name (om:port model))_'.x|x<-extensions(#(.name (om:port model))_')]] :[deterministic]\n")
    ((component deadlock)  . "assert AS_#(.name model) _#((compose .name .behaviour) model) (false) :[deadlock free]\n")
    ((component compliance) . ,(gulp-template 'asserts/component-compliance.csp.scm))
    ((component livelock)  .  "assert AS_#(.name model) _#((compose .name .behaviour) model) (true) \\ diff(Events,{|#(comma-join (append (required-modeling-events model) (list \"illegal\" ((compose .name om:port) model) ((compose .name om:port) model))))_'#(->string (if (not (null? (filter om:out? (om:events (om:port model))))) (list \",\" ((compose .name om:port) model)\"_''\")))|}) :[livelock free]\n")
    ((interface completeness) . ,(gulp-template 'asserts/interface-completeness.csp.scm))
    ((interface deadlock) . ,(gulp-template 'asserts/interface-deadlock.csp.scm))
    ((interface livelock) . ,(gulp-template 'asserts/interface-livelock.csp.scm))))

(define-method (csp-module (o <model>))
  (let ((module (make-module 31 (list
                                 (resolve-module '(gaiag csp))
                                 ))))
    (module-define! module 'model o)
    module))

(define (csp-file file-name module)
  (parameterize ((template-dir (append (prefix-dir) '(templates csp))))
    (animate-file file-name module)))

(define-method (valued? (model <model>) (o <on>))
  (om:typed? model (car ((compose .elements .triggers) o))))


(define (behaviour->csp model)

  (define (void? o)
    (om:void? model o))

  (define (split-valued-void o)
    (receive (valued void) (partition void? ((compose .elements .triggers) o))
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

  (define (splitted-ons statement)
    (apply append (map split-valued-void ((om:statements-of-type 'on) statement))))

  (let ((default "STOP"))
    (or (string-null-is-#f
         ((->join "\n[]\n")
          (append
           (map
            (lambda (guard)
              (let ((expression (csp-expression->string model (.expression guard) '()))
                    (ons (splitted-ons (.statement guard))))
                (list
                 "(" expression ") & (\n"
                 (or (string-null-is-#f
                      ((->join "\n []\n  ")
                       (map (lambda (on)
                              (csp-transform model (ast-transform model on)))
                            (let ((ons
                                   (if (is-a? model <interface>)
                                       ons
                                       (append
                                        (filter identity (map (statement-on-p/r- (provides? model)) ons))
                                        (filter identity (map (statement-on-p/r- (requires? model)) ons))))))
                              ons))))
                     default)
                 ")")))
            ((om:statements-of-type 'guard) (om:statement (.behaviour model))))
           (map (lambda (on) (csp-transform model (ast-transform model on)))
                (splitted-ons (om:statement (.behaviour model)))))))
        default)))

(define-method (csp-expression->string (model <model>) src locals)
  (define (member? identifier) (om:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))

  (define (paren expression)
    (let ((value (if (is-a? expression <expression>) (.value expression) expression)))
      (if (or (number? value) (symbol? value) (is-a? value <var>))
          (csp-expression->string model expression locals)
          (list "(" (csp-expression->string model expression locals) ")"))))
  (match src
    (($ <var> identifier) identifier)
    (($ <expression>) (csp-expression->string model (.value src) locals))
    ((or (? number?) (? string?) (? symbol?)) src)
    (($ <field> identifier field)
     (let* ((var (var? identifier))
            (type (and=> var .type))
            (name (and=> type .name)))
       (list "(" identifier " == " name "_" field ")")))
    (($ <literal> scope type field) (list type "_" field))

    (($ <var> identifier) identifier)
    (('group expression) (list "(" (csp-expression->string model expression locals) ")"))
    (('! expression) (->string (list "(" "not " (paren expression) ")")))
    (((or 'and 'or '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (csp-expression->string model lhs locals))
           (rhs (csp-expression->string model rhs locals))
           (op (car src)))
       (list "(" lhs " " op " " rhs ")")))
    (*unspecified* #f)
    (_ (throw 'match-errorand (format #f "~a:no match: ~a" (current-source-location) src)))))

(define* (port-events port :optional (predicate? identity)) ;; FIXME: no test
  (let ((interface (csp:import (.type port))))
    (interface-events interface predicate?)))

(define-method (interface-events (o <component>) predicate?) ;; FIXME: no test
  (apply append (map (compose (lambda (x) (interface-events x predicate?)) om:import .type) ((compose .elements .ports) o))))

(define-method (interface-events (o <interface>) predicate?)
  (let* ((events ((compose .elements .events) o))
         (events (filter predicate? events))
         (events (map .name events))
         (modeling (modeling-events o))
         (modeling (filter predicate? modeling))
         (modeling (map .event modeling)))
    (delete-duplicates (sort (append events modeling) symbol<))))

(define (modeling-event? event)
  (member (.event event) '(optional inevitable)))

(define-method (modeling-events (o <interface>))
  (filter modeling-event? (om:find-triggers o)))

(define-method (required-modeling-events (o <component>))
  (apply append
         (map (lambda (port)
                (map (lambda (event) (->string (list (.name port) '. (.event event))))
                     (modeling-events (csp:import (.type port)))))
              (filter om:requires? (om:ports o)))))

(define-method (typed-elements (o <enum>))
   (map (lambda (x) (symbol-append (.name o) '_ x)) ((compose .elements .fields) o)))

(define-method (enum-values (o <component>))
  (append
   (apply append (map (compose enum-values om:import .type) ((compose .elements .ports) o)))
   (next-method)))

(define-method (enum-values (o <model>))
  (apply append (map typed-elements (append (or (and=> (.behaviour o) om:enums) '()) (om:enums)))))

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
  (add-return-if-empty (map return-value (om:reply-enums o))))

(define-method (return-values (o <component>))
  (apply append (map (compose return-values om:import .type) ((compose .elements .ports) o))))

(define ((statement-on-p/r- predicate) on)
  (statement-on-p/r predicate on))

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

(define (hide-modeling model)
  (and-let* (((is-a? model <interface>))
             (name (.name model))
             (modeling (null-is-#f (delete-duplicates (map .event (modeling-events model))))))
            (string-append " \\ {|"
                           (comma-join
                            (append (map (lambda (x) (->string (list name "." x)))
                                 modeling) (list (->string (list name "_'''")))))
                           "|} ")))

(define-method (optional-chaos (o <interface>)) ;; FIXME: no test
  (let ((name (.name o)))
    (if (member 'optional (map .event (om:find-triggers o)))
        (list " [|{" name ".optional}|] " "CHAOS({" name ".optional})")
        "")))

(define-class <context> (<ast>)
  (members :accessor .members :init-form (list) :init-keyword :members)
  (locals :accessor .locals :init-form (list) :init-keyword :locals))

(define-class <context-vector> (<ast-list>))

(define-class <contexted> (<ast>)
  (context :accessor .context :init-value #f :init-keyword :context))

(define-class <csp-call> (<call> <contexted>))

(define-class <semi> (<ast>)
  (statement :accessor .statement :init-value #f :init-keyword :statement)
  (continuation :accessor .continuation :init-value #f :init-keyword :continuation))

(define-class <csp-variable> (<variable> <contexted>)
  (continuation :accessor .continuation :init-value #f :init-keyword :continuation))

(define-class <csp-assign> (<assign> <contexted>)
  (expressions :accessor .expressions :init-value #f :init-keyword :expressions))

(define-class <skip> (<ast>))

(define-class <csp-if> (<if> <contexted>))

(define-class <csp-on> (<on> <contexted>))

(define-class <csp-reply> (<reply> <contexted>))

(define-class <csp-return> (<return> <contexted>))

(define-class <the-end> (<contexted>))

(define-class <voidreply> (<ast>))

(define (ast-transform ast src)
  (ast-transform- ast (ast-transform-return ast (purge-data ast (tail-call src)))))

(define-method (purge-data (root <root>) o)
  (let ((model (or (om:component root) (om:interface root))))
    (purge-data model o)))

(define-method (purge-data (model <model>) o . locals)

  (define (member? identifier) (om:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
  (define (extern? identifier) (and=> (var? identifier)
                                      (lambda (var)
                                        (om:extern model (.type var)))))
  (define (extern-type? type) (om:extern model type))

  (define (purge-parameter-list function arguments)
    (let ((types (map .type ((compose .elements .parameters .signature) function))))
      (let loop ((arguments arguments) (types types))
        (if (null? arguments)
                arguments
                (append
                 (if (extern-type? (car types))
                     '()
                     (list (car arguments)))
                 (loop (cdr arguments) (cdr types)))))))

  (match o

    (($ <compound> statements)
     (make <compound>
       :elements
       (let loop ((statements statements) (locals locals))
         (if (null? statements)
             '()
             (let* ((statement (car statements))
                    (locals (match statement
                              (($ <variable> name type expression)
                               (acons name statement locals))
                              (_ locals))))
               (let ((purged (purge-data model (car statements) locals)))
                 (cons purged (loop (cdr statements) locals))))))))

    (($ <call> identifier ($ <arguments> arguments) last?)
       (make <call>
         :identifier identifier
         :arguments (make <arguments> :elements (purge-parameter-list (om:function model identifier) arguments))
         :last? last?))

    (($ <function> name ($ <signature> type ($ <parameters> parameters)) recursive? statement)
     ;; FIXME: extend locals?
     (make <function>
       :name name
       :signature (make <signature>
                    :type type
                    :parameters (make <parameters> :elements (purge-parameter-list o parameters)))
       :recursive recursive?
       :statement (purge-data model statement locals)))

    (($ <assign> (? extern?) expression) (make <skip>))

    (($ <variable> name (? extern-type?) expression) (make <skip>))

    (($ <return> ($ <expression> ($ <data>))) (make <skip>))

    (($ <event>) o)
    (($ <field>) o)
    (($ <literal>) o)
    (($ <otherwise>) o)
    (($ <port>) o)
    (($ <trigger>) o)
    (($ <type>) o)
    (($ <var>) o)

    ((? (is? <ast>)) (om:map (lambda (o) (purge-data model o locals)) o))
    ((h t ...) (map (lambda (o) (purge-data model o locals)) o))
    (_ o)))

(define (tail-call o)
  (match o
    (($ <function> name signature recursive? statement)
     (make <function>
       :name name
       :signature signature
       :recursive recursive?
       :statement (or (mark-last statement) statement)))
    (_ o)))

(define-method (mark-last (o <statement>))

  (match o

    (($ <compound> statements)
     (and-let* ((statements
                 (let loop ((statements (reverse statements)) (collect '()))
                   (if (null? statements)
                       #f
                       (let* ((statement (car statements))
                              (marked? (mark-last statement)))
                         (if marked?
                             (reverse (append collect (cons marked? (cdr statements))))
                             (loop (cdr statements) (cons statement collect))))))))
               (make <compound> :elements statements)))

    (($ <call> identifier arguments)
     (make <call> :identifier identifier :arguments arguments :last? #t))

    (($ <if> expression then else)
     (let ((then- (mark-last then))
           (else- (and else (mark-last else))))
       (if (and (not then-) (not else-))
           #f
           (make <if>
             :expression expression
             :then (or then- then)
             :else (or else- else)))))

    (($ <assign> identifier (and ($ <call>) (get! call)))
     (make <assign> :identifier identifier :expression (mark-last (call))))

    (($ <variable> name type (and ($ <call>) (get! call)))
     (make <variable> :name name :type type :expression (mark-last (call))))

    (($ <skip>) #f)

    (($ <return> #f) #f)

    (_ o)))

(define-method (ast-transform-return ast o)
  (match o
    (($ <compound> statements)
     (let ((result
            (let loop ((statements (map (lambda (x) (ast-transform-return ast x)) statements)))
              (if (null? statements)
                  '()
                  (cons (car statements) (loop (cdr statements)))))))
       (if (=1 (length result))
           (car result)
           (make <compound> :elements result))))
    (($ <on> triggers statement)
     (let* ((model (or (om:component ast) (om:interface ast)))
            (members (om:member-names model))
            (valued-triggers? (lambda (x) (om:typed? model ((compose car .elements) triggers)))))
       (let ((result (ast-transform-return ast statement)))
         (match result
           (($ <compound> '())
            (make <csp-on>
              :triggers triggers
              :statement (make <compound> :elements (list (make <voidreply>)))
              :context (make <context> :members members)))
           ((? valued-triggers?)
            (make <csp-on>
              :triggers triggers
              :statement (make <compound> :elements (list result))
              :context (make <context> :members members)))
           (_
            (make <csp-on>
              :triggers triggers
              :statement (make <compound> :elements (list result (make <voidreply>)))
              :context (make <context> :members members)))))))
    (_ o)))

(define ((valued-action? port?) src)
  (match src
    (($ <variable> name type ($ <action>)) #t)
    (($ <assign> identifier ($ <action>)) #t)
    (_ #f)))

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
            (($ <context-vector> identifiers)
             (cons (make <context-vector> :elements (loop identifiers index))
                   (loop (cdr frame) (+ index (length identifiers)))))
            (_ (throw 'match-error (format #f "~a:frame-hide: no match: ~a\n" (current-source-location) i))))))))

(define-method (extend (o <context>) extension)
  (let ((members (.members o))
        (locals (.locals o)))
    (match extension
      ('() o)
      ((h) (extend o h))
      (($ <parameters> parameters) (extend o (map .name parameters)))
      ((identifiers ...)
       (extend o (make <context-vector> :elements extension)))
      (($ <context-vector> identifiers)
       (make <context>
         :members (frame-hide members 'hide_member identifiers)
         :locals (append (frame-hide locals 'hide_local identifiers)
                         (list extension))))
      ((? symbol?)
       (make <context>
         :members (frame-hide members 'hide_member (list extension))
         :locals (append (frame-hide locals 'hide_local (list extension))
                         (list extension)))))))

(define ((assign- identifier expression) x)
  (match x
    (($ <context-vector> expressions)
     (make <context-vector>
       :elements (map (assign- identifier expression) expressions)))
    (_ (if (eq? x identifier) expression x))))

(define-method (assign (o <context>) identifier expression)
  (make <context>
    :members (map (assign- identifier expression) (.members o))
    :locals (map (assign- identifier expression) (.locals o))))

(define (element->csp ast o locals)
  (match o
    (($ <context-vector> expressions)
     (let ((expressions
            (map (lambda (o) (csp-expression->string ast o locals)) expressions)))
       (string-append "(" (comma-join expressions) ")")))
    (_ (->string (csp-expression->string ast o locals)))))

(define-method (->csp ast (o <context>))
  (let* ((members (.members o))
         (locals (.locals o))
         (members (comma-join (map (lambda (x) (csp-expression->string ast x locals)) members)))
         (members (if (string-null? members) '<> members))
         (locals (if (equal? locals '(<>))
                     '<>
                     (reduce (lambda (x y)
                               (string-append "(" (element->csp ast y locals) ","
                                              (element->csp ast x locals) ")"))
                             #f (cons "stack'" locals)))))
    (list "(" members "),(" locals ")")))

(define* (ast-transform- ast o :optional (return #t) (context #f))
  (let* ((model (or (om:component ast) (om:interface ast)))
         (context (or context (make <context> :members (om:member-names model))))
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
                    (new-context (if (is-a? statement <variable>)
                                     (extend context (.name statement))
                                     context))
                    (var? (is-a? statement <variable>))
                    (class (if var? <csp-variable> <semi>))
                    (name (if var? (.name statement)))
                    (type (if var? (.type statement)))
                    (expression (if var? (.expression statement)))
                    (count (length statements)))
               (if (or (and (=1 count)
                            (is-a? statement <variable>))
                       (and (>1 count)
                            (not (is-a? transformed <illegal>))))
                   (make class
                     :context context
                     :name name
                     :type type
                     :expression expression
                     :statement transformed
                     :continuation (if (>1 count)
                                       (loop (cdr statements) new-context)
                                       (make <skip>)))
                   transformed)))))

      (($ <assign> identifier ($ <expression> value))
       (make <csp-assign>
         :identifier identifier
         :context (make <context> :members '(unused))
         :expression context
         :expressions (assign context identifier value)))

      (($ <assign> identifier expression)
       (make <csp-assign>
         :context context
         :identifier identifier
         :expression expression
         :expressions (assign context identifier 'r')))

      (($ <call> identifier arguments last?)
       (make <csp-call>
         :context context
         :identifier identifier
         :arguments arguments
         :last? last?))

      (($ <function> name signature recursive statement)
       (let* ((context (extend context (.parameters signature))))
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
                        (make <csp-variable>
                          :context then-context
                          :name (.name then)
                          :type (.type then)
                          :expression (.expression then)
                          :continuation (make <skip>))
                        then-transformed))
              (else (if (is-a? else <variable>)
                        (make <csp-variable>
                          :context else-context
                          :name (.name else)
                          :type (.type else)
                          :expression (.expression else)
                          :continuation (make <skip>))
                        else-transformed)))
         (make <csp-if>
           :context context
           :expression (make <expression> :value expr)
           :then then
           :else (or else '()))))

      (($ <csp-on> context triggers statement)
       (let ((result (ast-transform- ast statement)))
         (if (prefix-illegal? statement)
             (make <csp-on> :context 'IG :triggers triggers :statement result)
             (make <csp-on> :context context :triggers triggers :statement result))))

      (($ <reply> expression)
       (make <csp-reply>
         :context context
         :expression (ast-transform- ast expression return context)))

      (($ <return> #f) o)

      (($ <return> expression)
       (make <csp-return>
         :context context
         :expression (ast-transform- ast expression return context)))

      (($ <variable> name type expression)
       (make <csp-variable>
         :context context
         :name name
         :type type
         :expression expression))

      (($ <expression> (and ($ <call>) (get! call)))
       (make <expression> :value (ast-transform- ast (call) return context)))

      (_ o))))


(define (=>string ast src locals)
  (match src
    (($ <context>) (->csp ast src))
    (($ <expression> (and ($ <csp-call>) (get! call))) (csp-transform ast (call)))
    (($ <expression>) (csp-expression->string ast src locals))
    (($ <arguments> arguments) (comma-join (map (lambda (x) (=>string ast x locals)) arguments)))
    ((h t ...) (->string (map (lambda (x) (=>string ast x locals)) src)))
    (_ (->string src))))

(define* (csp-transform ast src :optional (inevitable-optional? #f) (channel #f) (provided-on? #t) (locals '()))
  (let ((model (or (om:component ast) (om:interface ast))))
    (csp-transform model src inevitable-optional? channel provided-on? locals)))

(define-generic csp-transform)

(define-method (csp-transform (model <model>) src inevitable-optional? channel provided-on? locals)
  (define (member? identifier) (om:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
  (define (int-type? type) (om:integer model type))
  (define (int? identifier) (and=> (var? identifier)
                                   (lambda (var) (int-type? (.type var)))))

  (let* ((model-name (.name model))
         (channel (if (is-a? model <interface>) model-name (.type (om:port model))))
	 (behaviour (.name (.behaviour model)))
         (component? (is-a? model <component>)))

    (=>string model
     (match src

       (($ <context>) src)
       (($ <expression>) src)

       (($ <action> trigger)
        (let* ((event-name (.event trigger))
               (suffix (if (om:out? (om:event model trigger)) "_''" ""))
               (channel (if (is-a? model <interface>) model-name  (.port trigger)))
               (channel-return (if ((requires-event? model) trigger) (list " -> " channel "_'.return")))
               (channel (list channel suffix)))
          (list "(\\ P',V' @ " channel "!" event-name channel-return " -> P'(V'))")))


       (($ <csp-assign> context identifier ($ <action> (and ($ <trigger> port event) (get! trigger))) expressions)
        (let ((action (list "semi_(send_(" (list (or port channel) (if (om:out? (om:event model (trigger))) "_''")) "," event "),recv_(" (or port channel) "_'," event "))")))
          (list "assign_active_(" action ",\n\\ (" context ")," "r'" " @ (" expressions "))" )))

       (($ <csp-assign> context (and (? int?) (get! identifier)) ($ <call> function arguments) expressions)
        (let* ((range (.range (int? (identifier))))
               (lo (.from range))
               (hi (.to range))
               (call (make <csp-call> :context context :identifier function :arguments arguments))
               (call (csp-transform model call inevitable-optional? channel provided-on? locals)))
          (list "let " function "_result' = " call " within assign_int_active_(" function "_result',\n\\ (" context ")," "r'" " @ (" expressions ")," lo "<=" lo " and " hi "<=" hi ")")))

       (($ <csp-assign> context identifier ($ <call> function arguments) expressions)
        (let* ((call (make <csp-call> :context context :identifier function :arguments arguments))
               (call (csp-transform model call inevitable-optional? channel provided-on? locals)))
          (list "assign_active_(" call ",\n\\ (" context ")," "r'" " @ (" expressions "))")))

       (($ <csp-assign> context (and (? int?) (get! identifier)) expression expressions)
        (let* ((range (.range (int? (identifier))))
               (lo (.from range))
               (hi (.to range)))
         (list "assign_int_((\\ (" expression ") @ (" expressions ")),(\\ (" expression ") @ " lo "<=" (identifier) " and " (identifier) "<=" hi "))")))

       (($ <csp-assign> context identifier expression expressions)
        (list "assign_(\\ (" expression ") @ (" expressions "))"))

       (($ <csp-call> context identifier ($ <arguments> '()) lmodel?)
        (let ((continuation-p (if lmodel? "PF'" "P'")))
         (list "call_(\\ P',V' @ " identifier "(" continuation-p ",V'))")))

       (($ <csp-call> context identifier arguments lmodel?)
        (let ((continuation-p (if lmodel? "PF'" "P'")))
         (list "call_args_(\\ P',V' @ " identifier "(" continuation-p ",V'),(\\ (" context ") @ (" arguments ")))")))

       (($ <function> name ($ <signature> type ($ <parameters> '())) recursive? statement)
        (let ((transformed (csp-transform model statement inevitable-optional? channel provided-on? locals)))
          (list name "(PF',V') = (" transformed ")(PF',V')\n")))

       (($ <function> name ($ <signature> type ($ <parameters> parameters)) recursive? statement)
        (let* ((locals (let loop ((parameters parameters) (locals locals))
                         (if (null? parameters)
                             locals
                             (loop (cdr parameters)
                                   (acons (.name (car parameters)) (car parameters) locals)))))
               (transformed (csp-transform model statement inevitable-optional? channel provided-on? locals)))
          (list name "(PF',V') = (" transformed ")(PF',V')\n")))

       (($ <csp-if>)
        (let ((context (.context src))
              (expression (csp-expression->string model (.expression src) locals))
              (then (csp-transform model (.then src) inevitable-optional? channel provided-on? locals))
              (else (csp-transform model (.else src) inevitable-optional? channel provided-on? locals)))
          (list "ifthenelse_(\\ (" context ") @ (" expression "),\n" then ",\n" else "\n)")))

       (($ <illegal>) "illegal_")

       (($ <csp-on> 'IG ($ <triggers> triggers) statement)
        (let* ((real-triggers (filter (negate modeling-event?) triggers))
               (modeling-triggers (filter modeling-event? triggers))
               (modeling-triggers (map .event modeling-triggers))
               (trigger-in? (lambda (trigger) (om:in? (om:event model trigger)))))
          (receive (ins outs) (partition trigger-in? real-triggers)
            (let* ((channel (if (is-a? model <interface>) model-name (.port (car triggers))))
                   (IG (if ((provides-event? model) (car triggers)) "IIG & "  "IG & "))
                   (event-names (comma-join (map .event triggers)))
                   (transformed (csp-transform model statement inevitable-optional? channel provided-on? locals)))
              ((->join "\n[]\n")
               (list (if (pair? ins)
                         (list IG (if (is-a? model <interface>) model-name (.port (car ins))) "?x:{" (comma-join (append modeling-triggers (map .event ins))) "} ->\n" transformed "(STOP,<>)")
                         (if (pair? modeling-triggers)
                             (list IG (if (is-a? model <interface>) model-name channel) "?x:{" (comma-join modeling-triggers) "} ->\n" transformed "(STOP,<>)")
                             '()))
                     (if (pair? outs)
                         (list IG (if (is-a? model <interface>) model-name (.port (car outs))) "_''?x:{" (comma-join (map .event outs)) "} ->\n" transformed "(STOP,<>)")
                         '())))))))

       (($ <csp-on> context ($ <triggers> triggers) statement)
        (let* ((real-triggers (filter (negate modeling-event?) triggers))
               (modeling-triggers (filter modeling-event? triggers))
               (modeling-triggers (map .event modeling-triggers))
               (trigger-in? (lambda (trigger) (om:in? (om:event model trigger)))))
          (receive (ins outs) (partition trigger-in? real-triggers)
           (let* ((the-end (make <the-end> :context context))
                  (inevitable-optional? (or (member 'inevitable (map .event triggers))
                                            (member 'optional (map .event triggers))))
                  (channel (if (is-a? model <interface>) model-name (.port (car triggers))))
                  (provided-on? (or (and (is-a? model <interface>) (not inevitable-optional?))
                                    (or (is-a? model <interface>) ((provides-event? model) (car triggers)))))
                  (event-names (comma-join (map .event triggers)))
                  (transformed (csp-transform model statement inevitable-optional? channel provided-on? locals))
                  (transformed-end (csp-transform model the-end inevitable-optional? channel provided-on? locals)))
             ;;(list channel "?x:{" event-names "}" " ->\n" transformed transformed-end)
             ((->join "\n[]\n")
              (list  (if (pair? ins)
                         (list (if (is-a? model <interface>) model-name (.port (car ins))) "?x:{" (comma-join (append modeling-triggers (map .event ins))) "} ->\n" transformed transformed-end)
                         (if (pair? modeling-triggers)
                             (list (if (is-a? model <interface>) model-name channel) "?x:{" (comma-join modeling-triggers) "} ->\n" transformed transformed-end)
                             '()))
                     (if (pair? outs)
                         (list (if (is-a? model <interface>) model-name (.port (car outs))) "_''?x:{" (comma-join (map .event outs)) "} ->\n" transformed transformed-end)
                         '())))))))

       (($ <csp-reply> context expression)
        (list "reply_(" channel "_', " "(\\ (" context ") @ " expression "))"))

       (($ <return>) "skip_")

       (($ <csp-return> context ($ <expression> expression))
        (let ((expression (csp-expression->string model expression locals)))
          (list "returnvalue_(\\ (" context ") @ " expression ")")))

       (($ <semi> statement continuation)
        (let* ((transformed (csp-transform model statement inevitable-optional? channel provided-on? locals))
               (locals (match statement
                         (($ <csp-variable> name type expression)
                          (acons name statement locals))
                         (_ locals)))
               (continuation (csp-transform model continuation inevitable-optional? channel provided-on? locals)))
          (list "semi_(" transformed ",\n" continuation ")")))

       (($ <skip>) "skip_")

       (($ <csp-variable> context name type ($ <action> ($ <trigger> port event)) continuation)
        (let* ((locals (acons name src locals))
               (continuation (csp-transform model continuation inevitable-optional? channel provided-on? locals)))
          (list "context_active_(semi_(send_(" (or port channel) "," event "),recv_(" (or port channel) "_'," event ")),\n" continuation ")")))

       (($ <csp-variable> context name (and (? int-type?) (get! type)) ($ <call> identifier arguments) continuation)
        (let* ((range (.range (int-type? (type))))
               (lo (.from range))
               (hi (.to range))
               (locals (acons name src locals))
               (call (make <csp-call>  :context context :identifier identifier :arguments arguments))
               (call (csp-transform model call inevitable-optional? channel provided-on? locals))
               (continuation (csp-transform model continuation inevitable-optional? channel provided-on? locals)))
          (list "let " identifier "_result' = "  call " within context_int_active_(" identifier "_result'," lo "<= "lo " and " hi "<=" hi ",\n" continuation ")")))

       (($ <csp-variable> context name type ($ <call> identifier arguments) continuation)
        (let* ((call (make <csp-call>  :context context :identifier identifier :arguments arguments))
               (call (csp-transform model call inevitable-optional? channel provided-on? locals))
               (continuation (csp-transform model continuation inevitable-optional? channel provided-on? locals)))
          (list "context_active_(" call ",\n" continuation ")")))

       (($ <csp-variable> context name (and (? int-type?) (get! type)) expression continuation)
        (let* ((range (.range (int-type? (type))))
               (lo (.from range))
               (hi (.to range))
               (locals (acons name src locals))
               (continuation (csp-transform model continuation inevitable-optional? channel provided-on? locals)))
          (list "context_int_(\\ (" context ") @ " expression ",\\ (" context ") @ " lo " <= " expression " and " expression "<=" hi ",\n" continuation ")" )))

       (($ <csp-variable> context name type expression continuation)
        (let* ((locals (acons name src locals))
               (continuation (csp-transform model continuation inevitable-optional? channel provided-on? locals)))
          (list "context_(\\ (" context ") @ " expression ",\n" continuation ")" )))

       (($ <voidreply>)
        (let ((channel-return
               (if (and (not inevitable-optional?) provided-on?)
                       (list "(\\ P',V' @ " channel "_'.return -> P'(V'))")
                       (if (is-a? model <component>)
                           (list "skip_")
                           (list "(\\ P',V' @ " channel "_'''.modeling -> P'(V'))")))))
          (list channel-return)))

       (($ <the-end> context)
        (let* ((end (if component? "transition_end -> " (list channel ".the_end' -> "))))
          (list "(\\ V' @ " end model-name "_" behaviour "(V'),(" context "))")))

       ('() "skip_")

       ((? symbol?) src)

       ((? string?) src)

       (_ (throw 'match-error (format #f "~a:csp-transform: no match: ~a\n" (current-source-location) src)))) locals)))

(define (csp-queue-size) (option-ref (parse-opts (command-line)) 'queue-size 3))
