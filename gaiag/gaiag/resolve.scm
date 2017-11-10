;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2015, 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;; Copyright © 2014, 2015, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag resolve)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)
  #:use-module (system foreign)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (language dezyne location)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag compare)
  #:use-module (gaiag ast)
  #:use-module (gaiag util)

  #:use-module (gaiag parse)
  #:use-module (gaiag annotate)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)

  #:export (
           ast:resolve
           report-errors

           ast:extend-scope
           ast:model-scope
           ast:root-scope
           ast:scope
           ast:scope-model
           ast:scope-root
           ast:set-scope
           ast:set-model-scope
           .function

           resolve:component
           resolve:event
           resolve:function
           resolve:instance
           resolve:interface
           resolve:variable
           ))

(define (ast:resolve o)
  (match o
    (($ <root> (models ...)) (resolve-root o))
    (($ <call>) ((resolve (ast:model-scope) '()) o))
    ((? (is? <model>)) (resolve-model o))
    (_  o)))

(define (resolve-error o symbol message)
  (make <error> #:ast o #:message (format #f message symbol)))

(define (undefined-error o identifier)
  (resolve-error o identifier "undefined identifier: ~a"))

(define (type-mismatch o expected actual)
  (make <error> #:ast o #:message (format #f "type mismatch: ~a expected, found: ~a" expected actual)))

(define-method (resolve-root (o <root>))
  (let* ((resolved ((compose-root
                     (cut resolve-selection <> <system>)
                     (cut resolve-selection <> <component>)
                     (cut resolve-selection <> <foreign>)
                     (cut resolve-selection <> <interface>)
                     (cut resolve-selection <> <type>)
                     (cut resolve-selection <> <import>))
                    o))
         (errors (null-is-#f ((om:collect <error>) resolved))))
    (and=> errors report-errors)
    resolved))

(define-method (resolve-selection (o <root>) class)
  (clone o
    #:elements (receive (selection rest)
                        (partition (is? class) (.elements o))
                        (let ((resolved (map resolve-top-model selection)))
                          (append rest resolved )))))


(define (report-error o)
  (and-let* ((ast (.ast o))
             (message (.message o))
             (message
              (or (and-let* (((supports-source-properties? ast))
                             (loc (source-property ast 'loc))
                             (loc (if (list? loc) (source-property loc 'loc) loc))
                             (properties (source-location->user-source-properties loc)))
                            (format #f "~a:~a:~a: error: ~a\n"
                                    (or (assoc-ref properties 'filename) "<unknown file>")
                                    (assoc-ref properties 'line)
                                    (assoc-ref properties 'column)
                                    message))
                  (format #f "<unknown location>: error: ~a: ~a\n" ast message))))
            (stderr message)))

(define (report-errors errors)
  (for-each report-error errors)
  (cond ((or (member "--debug" (command-line))
             (member "test-suite/run-tests" (command-line)))
         (throw 'well-formed errors))
        ((or (member "--coverage" (command-line))
             (member "../coverage" (command-line)))
         '())
        (else (exit 1))))

(define (resolve-top-model o)
  (match o
    ((? (is? <model>))
     (resolve-model o))
    (_ ((resolve o '()) o))))

(define (resolve-model o)
  (match o
    ((or ($ <interface>) ($ <component>) ($ <foreign>))
     ((resolve o '()) o))
    (_ ((resolve o '()) o))))

(define ((resolve model locals) o)
  (match o
    (($ <type>) (resolve- model o locals))
    ((? (is? <type>)) o)
    (($ <import>) o)
    (_ (retain-source-properties o (resolve- model o locals)))))

(define (type-equal? a b)
  (cond ((is-a? a <enum>) (om:equal? a b))
        (else (eq? (class-of a) (class-of b)))))

(define (->symbol o)
  (match o
    (($ <type> name) (->symbol name))
    (($ <enum> name field) (->symbol name))
    (('dotted name ...) ((->symbol-join '.) name))
    (($ <scope.name>) ((->symbol-join '.) (om:scope+name o)))
    (_ o)))

;; Pre-resolve by-name lookups
(define resolve:binary-operators
  '(
    <
    <=
    >
    >=
    +
    -
    and
    or
    ==
    !=
    ))

(define resolve:unary-operators
  '(
    group
    !
    ))

(define resolve:operators
  (append resolve:binary-operators resolve:unary-operators))

(define (resolve:operator? o)
  (memq o resolve:operators))

(define (resolve:expression? o)
  (match o
    (($ <expression>) o)
    (((? resolve:operator?) h t ...) o)
    (_ #f)))


(define* (resolve:types #:optional (model #f))
  (append
   (match model
     (($ <root> (models ...)) (filter (is? <type>) models))
     (($ <behaviour> b types) (.elements types))
     (($ <interface> name types events ($ <behaviour> b btypes)) (append (.elements btypes) (.elements types)))
     (($ <component> name ports ($ <behaviour> b btypes))
      (append (.elements btypes) (om:interface-types model)))
     ((? (is? <component-model>) name ports) (om:interface-types model))
     (($ <import> name) '())
     (#f '())
     ((? unspecified?) '()))
   (resolve:globals)))

(define (resolve:event o trigger)
  (match (cons o trigger)
    ((($ <port>) . (? symbol?))
     (find (lambda (x) (eq? (.name x) trigger)) (om:events o)))
    ((($ <interface>) . (? symbol?))
     (find (lambda (x) (eq? (.name x) trigger)) (.elements (.events o))))
    ((($ <interface>)  . (? (is? <trigger>)))
     (if (not (as (.event trigger) <event>)) (resolve:event o (.event trigger))
         (.event trigger)))
    ((($ <component>)  . (? (is? <trigger>)))
     (if (not (as (.event trigger) <event>)) (resolve:event (resolve:interface ((.port o) trigger)) (.event trigger))
         (.event trigger)))
    (_ #f)))

(define (resolve:globals)
  (filter (is? <type>) ((compose .elements ast:root-scope))))

(define (resolve:function model o)
  (find (om:named o) (om:functions model)))

(define (resolve:instance model o)
  (match o
    ((? symbol?)
     (find (lambda (x) ;;(stderr "om:instance: ~a; ~a\n" o x)
                   (eq? (.name x) o)) ((compose .elements .instances) model)))
    (($ <binding>) (or (.instance o)
                       (.type ((.port model) o))))
    (($ <bind>) (resolve:instance model (om:instance-binding? o)))
    (($ <port>) (resolve:instance model (om:instance-binding? (om:port-bind model o))))
    ((? boolean?) #f)))

(define* (resolve:component system #:optional o)
  (match o
    (#f (match system
          (($ <foreign>) system)
          (($ <component>) system)
          (($ <root>) (om:find (disjoin (is? <component>) (is? <foreign>)) system))
          (($ <scope.name>) ;(cached-model system)
           (find (lambda (x) ;;(stderr "KANARIE: ~a ~a\n" system (.name x))
                         (om:equal? system (.name x))) (filter (negate (is? <data>)) (.elements (car (ast:scope-root))))))
          (_ #f)))
    ((? symbol?) (resolve:component system (resolve:instance system o)))
    (($ <binding> #f port-name)
     ;;#f
     ;;(resolve:component system (om:binding-other-port system port))
     (let* ((bind (om:bind system port-name))
            (instance (om:instance-name bind)))
       (resolve:component system instance)))
    (($ <binding> instance port-name) (resolve:component system instance))
    (($ <bind>) (resolve:component system (om:instance-name o)))
    (($ <instance>) (.type o))
    (($ <port>) (resolve:interface (.type o)))))

(define (resolve:interface o)
  (match o
    (($ <port>) (resolve:interface (.type o)))
    (($ <interface>) o)
    ((? (is? <model>)) (resolve:interface (om:port o)))
    (($ <scope.name>) (find (om:named o) ((compose .elements ast:root-scope))))
    (($ <root>) (om:find (is? <interface>) o))
    ((h t ...) (find (is? <interface>) o))))

(define ((resolve:type model) o)
  (match o
    ((? symbol?) (find (resolve:named (make <scope.name> #:scope (om:scope+name model) #:name o)) (resolve:types model)))

    (($ <bool>) o)
    (($ <enum>) o)
    (($ <data>) o)
    (($ <extern>) o)
    (($ <void>) o)
    (($ <int>) o)

    (($ <type> 'bool) (make <bool>))
    (($ <type> 'void) (make <void>))
    ((and ($ <type>) (= .name name))
     (or (find (resolve:named name) (resolve:types model))
         (find (resolve:scoped (om:scope+name model) name) (resolve:types))))
    (($ <variable> name type expression) ((resolve:type model) type))
    (($ <formal> name type) ((resolve:type model) type))
    (($ <formal> name type direction) ((resolve:type model) type))))

(define ((resolve:named name) ast)
;  (stderr "\nom:named[~a]: ~a" name ast)
  (match name
    ((? symbol?) (or (eq? name (.name ast)) ((resolve:named (make <scope.name> #:name name)) ast)))
    (_ (om:equal? (.name ast) name))))

(define ((resolve:scoped scope name) ast)
  (if (null? (om:scope name)) (eq? (om:name ast) (om:name name))
      (equal? (append scope (om:scope+name ast)) (om:scope+name name))))

(define (resolve:enum model identifier)
  (as ((resolve:type model) identifier) <enum>))

(define (resolve:variable model o)
  (find (om:named o) (om:variables model)))

(define (resolve- model o locals)

  (define (as-enum identifier) (and=> (as-type identifier) (is? <enum>)))
  (define (extern? identifier) (and=> (as-type identifier) (is? <extern>)))
  (define (int? identifier) (and=> (as-type identifier) (is? <int>)))

  (define (event? o)
    (or (as o <event>)
        (and (is-a? model <interface>)
             (not (var? o)) (resolve:event model o))))

  (define (interface? o)
    (match o
      (($ <interface>) o)
      (($ <scope.name>) (resolve:interface o))
      (('dotted scope ... name) (resolve:interface (make <scope.name> #:scope scope #:name name)))))

  (define (component? o)
    (match o
      (($ <component-model>) o)
      (($ <scope.name>) (resolve:component o))
      (('dotted scope ... name) (resolve:component (make <scope.name> #:scope scope #:name name)))))

  (define (instance? identifier)
    (or (as identifier <instance>) (resolve:instance model identifier)))

  (define (function? identifier) (resolve:function model identifier))

  (define (member? identifier) (resolve:variable model identifier))
  (define (port? o) (or (as o <port>)
                        (and (or (is-a? model <component>) (is-a? model <foreign>)) (om:port model o))))

  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? v) (or (as v <variable>) (as v <formal>) (local? v) (member? v)))
  (define (unspecified? x) (eq? x *unspecified*))

  (define (event-or-function? o)
    (or (function? o) (event? o)))

  (define (enum-field? identifier)
    (lambda (field)
      (and-let* ((enum (as-enum identifier)))
        (member field (.elements (.fields enum))))))

  (define (member-field? identifier)
    (lambda (field)
      (and-let* ((variable (var? identifier))
                 (type (.type variable))
                 (enum (as-type type)))
        (member field (.elements (.fields enum))))))

  (define (as-type o)
    (match o
      (($ <type> ('dotted '* scope ... name))
       ((resolve:type model) (clone o #:name (make <scope.name> #:scope scope #:name name))))
      (($ <type> ('dotted scope ... name)) (=> failure)
       (or ((resolve:type model) (clone o #:name (make <scope.name> #:scope (append (om:scope+name model) scope) #:name name)))
           ((resolve:type model) (clone o #:name (make <scope.name> #:scope scope #:name name)))
           (failure)))
      (_ ((resolve:type model) o))))

  (define (fake:type model o)
    (match o
      (($ <expression> expression) (fake:type model expression))
      ('false (make <bool>))
      ('true (make <bool>))
      (($ <data>) (make <extern>))
      ((? number?) (make <int>))
      (('dotted name field)
       (and-let* ((enum (or (as-type (make <type> #:name (make <scope.name> #:name name)))
                            (as-type (make <type> #:name (make <scope.name> #:scope (om:scope+name model) #:name name)))))
                  ((member field ((compose .elements .fields) enum))))
         enum))
      (('dotted field) #f)
      (('dotted scope ... name field)
       (and-let* ((enum (resolve:enum model (make <type> #:name (make <scope.name> #:scope scope #:name name))))
                  ((member field ((compose .elements .fields) enum))))
         enum))
      (_ #f)))

  (define (resolve-assign-expression o)
    (match o
      (($ <call> (and (? event?) (get! event)))
       (make <action> #:event (event? event)))

      (($ <call>)
       ((resolve model locals) o))

      (('dotted (and (? event?) (get! event)))
       (make <action> #:event (event? event)))

      (($ <var> (and (? event?) (get! event)))
       (make <action> #:event (event? event)))

      (('dotted (and (? function?) (get! function)))
       (make <call> #:function (.name (function? (function)))))

      (($ <var> (and (? function?) (get! function)))
       (make <call> #:function (.name (function? (function)))))

      (('dotted (and (? port?) (get! port)) event)
       ((resolve model locals) (make <action> #:port (port) #:event event)))

      (($ <action>)
       ((resolve model locals) o))

      (($ <var> (and (? function?) (get! function)))
       (make <call> #:function (.name (function? (function)))))

      ((and ($ <literal>) (get! expression))
       ((resolve model locals) (expression)))

      (_
       ((resolve model locals) o))))

  (match o
    (($ <var> (and (? (negate var?)) (get! identifier)))
     (undefined-error o (identifier)))

    (($ <assign> ('dotted port name) expression)
     (make <assign>
       #:variable (.variable o)
       #:expression ((resolve model locals) expression)))

    (($ <assign> (and (? (negate var?)) (get! identifier)))
     (undefined-error o (identifier)))

    (($ <field-test> (and (? (negate var?)) (get! identifier)))
     (undefined-error o (identifier)))

    (($ <action> #f (and (? (negate event-or-function?)) (get! identifier)))
     (resolve-error o (identifier) "undefined function or event: ~a"))

    (($ <call> (and (? symbol?) (? (negate event-or-function?)) (get! identifier)))
     (resolve-error o (identifier) "undefined function or event: ~a"))

    (($ <call> function-name ($ <arguments> (arguments ...))) (=> failure)
     (let* ((function (function? function-name))
            (formals ((compose .elements .formals .signature) function))
            (argument-count (length arguments))
            (formal-count (length formals)))
       (if (= argument-count formal-count) (failure)
           (resolve-error o function-name
                          (format #f "function ~a expects ~a arguments, found: ~a" "~a" formal-count argument-count)))))

    (($ <variable> name (and (? (negate as-type)) (get! type)) expression)
     (resolve-error (type) (->symbol (type)) "undefined type: ~a"))

    (($ <variable> name (and (? (negate extern?)) (get! type)) ($ <expression> (? unspecified?)))
     (resolve-error o name "undefined variable value: ~a"))

    (($ <variable> name (and (? (negate extern?)) (get! type)) ($ <literal> (? unspecified?)))
     (resolve-error o name "undefined variable value: ~a"))

    (($ <variable> name type expression) (=> failure)
     (or (and-let* ((e-type (fake:type model expression))
                    (v-type (as-type type))
                    ((not (type-equal? e-type v-type)))
                    (actual (as-type type))
                    ((if (is-a? e-type <extern>)
                         (not (is-a? actual <extern>))))
                    ((if (is-a? e-type <int>)
                         (not (is-a? actual <int>)))))
           (type-mismatch expression (->symbol (.name v-type)) (->symbol e-type)))
         (failure)))

    ((or 'false 'true) o)
    ((or 'and 'or) o)
    ((or '! '+ '- '/ '*) o)
    ((or '== '!= '< '<= '> '>= 'group) o)

    (($ <formal> name type direction)
     (clone o #:type ((resolve model locals) type)))

    (($ <call> function-name (and ($ <arguments> (arguments ...)) (get! arguments)) last?)
     (clone o #:arguments ((resolve model locals) (arguments))))

    (($ <type>)
     (or (as-type o)
         (as-type (append (om:scope+name model) (.name o)))
         (undefined-error o (.name o))))

    ((and ($ <event>) (= .signature signature))
     (clone o #:signature ((resolve model '()) signature)))

    (($ <data>) o)
    (($ <enum>) o)
    (($ <extern>) o)
    ((and ($ <field-test>) (= .variable variable))
     (clone o #:variable ((resolve model locals) (var? variable))))
    (($ <illegal>) o)
    (($ <int>) o)
    (($ <enum-literal> (? (is? <type>))) o)
    (($ <enum-literal>)
      (let ((type (make <type> #:name (.type o))))
        (clone o #:type ((resolve model locals) type))))
    (($ <otherwise>) o)

    ((and ($ <port>) (= .type@ ('dotted scope ... name)))
     (let* ((name (make <scope.name> #:scope scope #:name name))
            (type (interface? name)))
       (if (not type) (resolve-error o type "undefined interface: ~a")
           (clone o #:type (.name type)))))

    ((and ($ <port>) (= .type type))
     (let ((type (interface? type)))
       (if (not type) (resolve-error o type "undefined interface: ~a")
           o)))

    (($ <signature> type formals)
     (clone o
            #:type ((resolve model locals) type)
            #:formals ((resolve model locals) formals)))
    (($ <trigger> #f e arguments) (=> failure)
     (let ((event (event? e)))
       (if (not event) (failure)
           (clone o
                  #:event event
                  #:arguments ((resolve model locals) arguments)))))
    (($ <trigger> #f event arguments)
     (resolve-error o event "undefined event: ~a"))
    (($ <trigger> p e arguments) (=> failure)
     (let ((port (port? p)))
       (if (not port) (resolve-error o p "undefined port: ~a")
           (let ((event (or (as e <event>) (resolve:event port e))))
             (if (not event) (resolve-error o e "undefined event: ~a")
                 (clone o
                        ;;#:port port
                        #:event event
                        #:arguments ((resolve model locals) arguments)))))))

    ((and ($ <var>) (= .variable v))
     (let ((variable (var? v)))
       (if (not variable) (resolve-error o v "undeclared identifier: ~a")
           (clone o #:variable ((resolve model locals) variable)))))

    ((? symbol?)
     (undefined-error 'programming-error o))

    (($ <action> #f (and (? function?) (get! function)))
     (make <call> #:function (.name (function? (function)))))

    (($ <action> #f e arguments) (=> failure)
     (let ((event (event? e)))
       (if (not event) (failure)
           (clone o
                  #:event event
                  #:arguments ((resolve model locals) arguments)))))

    (($ <action> #f event arguments)
     (resolve-error o event "undefined event: ~a"))

    (($ <action> p e arguments) (=> failure)
     (let ((port (port? p)))
       (if (not port) (resolve-error o p "undefined port: ~a")
           (let ((event (or (as e <event>) (resolve:event port e))))
             (if (not event) (resolve-error o e "undefined event: ~a")
                 (clone o
                        ;;#:port port
                        #:event event
                        #:arguments ((resolve model locals) arguments)))))))

    (($ <assign> variable expression)
     (make <assign>
       #:variable (var? variable)
       #:expression (resolve-assign-expression expression)))

    (($ <formal> name type direction)
     (make <formal>
       #:name name
       #:type ((resolve model locals) type)
       #:direction direction))

    (($ <formal> name type)
     (make <formal>
       #:name name
       #:type ((resolve model locals) type)))

    (($ <variable> name type expression)
     (make <variable>
       #:name name
       #:type ((resolve model locals) type)
       #:expression (resolve-assign-expression expression)))

    (('dotted '* scope ... name)
     ((resolve model locals) (make <scope.name> #:scope scope #:name name)))

    (('dotted scope ... name) (=> failure) ;;FIXME
     (or ((resolve model locals)
          (and (pair? scope)
               (> (length scope) 1) (and=> (as (or (as-type (make <type> #:name (make <scope.name> #:scope scope #:name name)))
                                                   (as-type (make <type> #:name (make <scope.name> #:scope (append (om:scope+name model) scope) #:name name))))
                                               <enum>)
                                           .name)))
         (failure)))

    (('dotted (and (? var?) (get! name)))
     (let ((variable (var? (name))))
       (make <var> #:variable ((resolve model locals) variable))))

    (('dotted name) (=> failure)
     (or ((resolve model locals)
          (and-let* ((type (as-type (append (om:scope+name model) (list name)))))
            (.name type)))
         (failure)))

    (('dotted (and (? var?) (get! variable)) (and (? (member-field? (variable)) (get! field))))
     (make <field-test> #:variable (var? (variable)) #:field (field)))

    (('dotted scope ... name field) (=> failure)
     (let ((enum (as (or (as-type (make <type> #:name (make <scope.name> #:scope scope #:name name)))
                         (as-type (make <type> #:name (make <scope.name> #:scope (append (om:scope+name model) scope) #:name name))))
                     <enum>)))
       (if (not enum) (failure)
           (if (member field ((compose .elements .fields) enum))
               (make <enum-literal> #:type enum #:field field)
               (resolve-error o field "undefined enum field: ~a")))))

    (('dotted (? var?) field)
     (resolve-error o field "undefined enum field: ~a"))

    ((and (? (is? <literal>)) (= .value value))
     (clone o #:value ((resolve model locals) value)))

    ((and (? (is? <unary>)) (= .expression expression))
     (clone o #:expression ((resolve model locals) expression)))

    ((and (? (is? <binary>)) (= .left left) (= .right right))
     (clone o #:left ((resolve model locals) left) #:right ((resolve model locals) right)))

    (('dotted t ...)
     (resolve-error o o "undefined dotted: ~a")
     o)

    (($ <function> name ($ <signature> type ($ <formals> ())) recursive? statement)
     (make <function>
       #:name name
       #:signature ((resolve model locals) (.signature o))
       #:recursive (and ((recurses? model) name) 'recursive)
       #:statement ((resolve model locals) statement)))

    (($ <function> name ($ <signature> type ($ <formals> (formals ...))) recursive? statement)
     (let ((locals (let loop ((formals formals) (locals locals))
                     (if (null? formals)
                         locals
                         (loop (cdr formals)
                               (acons (.name (car formals)) (car formals) locals))))))
       (make <function>
         #:name name
         #:signature ((resolve model locals) (.signature o))
         #:recursive (and ((recurses? model) name) 'recursive)
         #:statement ((resolve model locals) statement))))

    (($ <compound> (statements ...))
     (make <compound>
       #:elements
       (let loop ((statements statements) (locals locals))
         (if (null? statements)
             '()
             (let* ((statement (car statements))
                    (locals (match statement
                              (($ <variable> name type expression)
                               (acons name statement locals))
                              (_ locals))))
               (let ((resolved ((resolve model locals) (car statements))))
                 (cons resolved (loop (cdr statements) locals))))))))

    (($ <blocking> statement)
     (make <blocking> #:statement ((resolve model locals) statement)))

    (($ <guard> expression statement)
     (make <guard>
       #:expression ((resolve model locals) expression)
       #:statement ((resolve model locals) statement)))

    (($ <on> triggers statement)
     (let* ((triggers ((resolve-triggers model) triggers))

            (on-formals (append-map (compose .elements .formals) (.elements triggers)))
            (locals (let loop ((on-formals on-formals) (locals locals))
                      (if (null? on-formals)
                          locals
                          (loop (cdr on-formals)
                                (let* ((on-formal ((resolve-triggers model) (car on-formals)))
                                       (name (.name on-formal)))
                                  (acons name on-formal locals)))))))
       (make <on>
         #:triggers triggers
         #:statement ((resolve model locals) statement))))

    (($ <interface> name types events behaviour)
     (let ((o (clone o #:events ((resolve o '()) events))))
       (clone o #:behaviour ((resolve o '()) behaviour))))

    (($ <foreign>)
     (clone o #:ports (make <ports> #:elements (map (resolve model '()) (om:ports o)))))

    ((and ($ <component>) (= .behaviour (? unspecified?)))
     (clone o
            #:ports (make <ports> #:elements (map (resolve model '()) (om:ports o)))
            #:behaviour #f))

    (($ <component>)
     (let ((o (clone o #:ports (make <ports> #:elements (map (resolve model '()) (om:ports o))))))
       (clone o #:behaviour ((resolve o '()) (.behaviour o)))))

    (($ <behaviour> name types ports variables functions statement)
     (let* ((ports (make <ports> #:elements (map (resolve model '()) (.elements ports))))
            (o (clone o #:ports ports))
            (model (clone model #:behaviour o))
            (functions (make <functions> #:elements (ast:set-model-scope model (map (resolve model '()) (.elements functions)))))
            (o (clone o #:functions functions))
            (model (clone model #:behaviour o))
            (o (clone o #:variables (ast:set-model-scope model ((resolve model '()) variables))))
            (model (clone model #:behaviour o)))
       (clone o #:statement (ast:set-model-scope model ((resolve model '()) statement)))))

    (($ <system>)
     (let* ((o (clone o #:ports (make <ports> #:elements (map (resolve model '()) (om:ports o)))))
            (o (clone o #:instances ((resolve o '()) (.instances o)))))
       (clone o #:bindings ((resolve o '()) (.bindings o)))))

    (($ <if> expression then else)
     (make <if>
       #:expression ((resolve model locals) expression)
       #:then ((resolve model locals) then)
       #:else (and (not (eq? else *unspecified*))
                   else ((resolve model locals) else))))
    (($ <arguments> (arguments ...))
     (make <arguments> #:elements (map (resolve model locals) arguments)))
    (($ <bindings> (bindings ...))
     (make <bindings> #:elements (map (resolve model locals) bindings)))
    (($ <events> (events ...))
     (make <events> #:elements (map (resolve model '()) events)))
    (($ <triggers> (triggers ...))
     (make <triggers> #:elements (map (resolve model locals) triggers)))
    (($ <functions> (functions ...))
     (make <functions> #:elements (map (resolve model '()) functions)))
    (($ <formals> (formals ...))
     (make <formals> #:elements (map (resolve model '()) formals)))
    (($ <instances> (instances ...))
     (make <instances> #:elements (map (resolve model locals) instances)))
    ((and ($ <instance>) (= .type.name ('dotted scope ... name)))
     (let* ((name (make <scope.name> #:scope scope #:name name))
            (type (component? name)))
       (if (not type) (resolve-error o type "undefined component: ~a")
           o)))
    ((and ($ <instance>) (= .type.name type-name))
     (let ((type (component? type-name)))
       (if (not type) (resolve-error o type "undefined component: ~a")
           o)))
    (($ <binding>)
     (let* ((instance (.instance o))
            (inst (instance? instance))
            ;;(foo (stderr "INST: ~a .TYPE: ~a\n" inst (and=> inst .type)))
            (component (or (and=> inst .type) model))
            ;;(foo (stderr "COMPONENT: ~a\n" component))
            (port-name (.port.name o))
            (port (om:port component port-name)))
       (if (and instance (not inst))
           (resolve-error o instance "undeclared instance: ~a")
           (clone o #:instance inst))))
    (($ <variables> (variables ...))
     (let ((variables (map (range-check model) variables)))
       (make <variables> #:elements (map (resolve model '()) variables))))
    (($ <reply> expression p)
     (let ((port (port? p)))
       (if (and p (not port)) (resolve-error o p "undefined port: ~a")
           (clone o #:expression ((resolve model locals) expression)))))
    (($ <return> expression)
     (make <return> #:expression ((resolve model locals) expression)))
    ((? (is? <ast>)) (om:map (lambda (o) ((resolve model locals) o)) o))
    ((? resolve:expression?) (map (lambda (o) ((resolve model locals) o)) o))
    (_ o)))

(define ((resolve-triggers model) o)

  (define (event? o)
    (or (as o <event>)
        (and (is-a? model <interface>) (resolve:event model o))))
  (define (member? m) (or (as m <variable>) (resolve:variable model m)))
  (define (port? o)
    (or (as o <port>)
        (and (is-a? model <component>) (om:port model o))))
  (match o
    (($ <triggers> (triggers ...)) (om:map (resolve-triggers model) o))
    (($ <trigger> #f 'inevitable) (clone o #:event ast:inevitable))
    (($ <trigger> #f 'optional) (clone o #:event ast:optional))
    (($ <trigger> #f e formals)
     (let ((event (event? e)))
       (if (not event) (resolve-error o e "undefined event: ~a")
           (clone o #:event event))))
    (($ <trigger> p e formals)
     (let ((port (port? p)))
       (if (not port) (resolve-error o p "undefined port: ~a")
           (let ((event (or (as e <event>) (resolve:event port e))))
             (if (not event) (resolve-error o e "undefined event: ~a")
                 (let* ((resolve-formal (lambda (e f)
                                          (let ((f (clone f
                                                          #:type (.type e)
                                                          #:direction (.direction e))))
                                                ((resolve-triggers model) f))))
                        (event-formals ((compose .elements .formals .signature) event))
                        (formals (.elements formals))
                        (formal-count (length formals))
                        (formals (map resolve-formal
                                      event-formals
                                      (append (list-head formals formal-count)
                                              (list-tail event-formals formal-count))))
                        ;; FIXME: resolve-error check length if not <illegal>
                        (formals (make <formals> #:elements formals)))
                   (clone o
                          ;;#:port port
                          #:event event
                          #:formals formals)))))))
    (($ <formal>) o)
    ((and ($ <formal-binding>) (= .variable v))
     (let ((variable (or (as v <variable>)
                         (member? v))))
       (if (not variable) (resolve-error o v "undeclared identifier: ~a")
           (clone o #:variable variable))))))

(define ((range-check model) variable)
  (define (as-int-type type) (as type <int>))
  (or variable
      (and-let* ((int (as-int-type (.type variable)))
                 (range (.range int))
                 (expression (.expression variable))
                 (value (evaluate model expression))
                 (from (.from range))
                 (to (.to range))
                 ((or (< value from) (> value to))))
                (resolve-error variable
                               (.name variable)
                               (format #f "variable ~a out of range, expected ~a..~a, found: ~a" "~a" from to value)))
      variable))

(define (evaluate model o)
  (define (member? identifier) (resolve:variable model identifier))
  (match o
    (($ <expression> expression) (evaluate model expression))
    ((? number?) o)
    (('+ a b) (+ (evaluate model a) (evaluate model b)))
    (('- a b) (- (evaluate model a) (evaluate model b)))
    (('* a b) (* (evaluate model a) (evaluate model b)))
    (('/ a b) (/ (evaluate model a) (evaluate model b)))
    (($ <var> name) (evaluate model (.expression (member? name))))
    (('group g) g)))

(define* ((recurses? model #:optional (seen '())) name)
  (define (return-call ast)
    (match ast
      (($ <call>) ast)
      (($ <assign> name (and ($ <call>) (get! call))) (call))
      (($ <variable> name type (and ($ <call>) (get! call))) (call))
      (_ #f)))
  (define (.function-name call)
    (or (and=> (as (.function call) <function>) .name) (.function call)))
  (and-let* ((function (resolve:function model name))
             (compound (.statement function))
             (calls (null-is-#f ((om:collect return-call) compound)))
             (names (delete-duplicates (sort (map
                                              (compose .function-name return-call)
                                              calls) symbol<))))
            (or (member name seen)
                (any identity
                     (map (recurses? model (cons name seen)) names)))))



(define-method (.scope+name (o <top>))
  (match o (('dotted scope ... name) (symbol-join (cdr o)))))

(define-method (.scope+name (o <scope.name>))
  (symbol-join (append (.scope o) (list (.name o)))))

(define (name-resolve root class o)
  (cond
   ((or (eq? <interface> class) (eq? <system> class) (eq? <component> class) (eq? <foreign> class))
    (find (lambda (m)
            (and (is-a? m class)
                 (equal? o (.scope+name (.name m)))))
          (.elements root)))
   ((eq? <port> class)
    (find (lambda (m)
            (equal? o (.name m)))
          (append ((compose .elements .ports) root)
                  (om:behaviour-ports root))))
   ((eq? <function> class)
    (find (lambda (m)
             (equal? o (.name m)))
          ((compose .elements .functions .behaviour) root)))))

(define name-resolve (pure-funcq name-resolve))

(define ast:scope (make-parameter 'error-ast:scope-not-set))

(define-syntax ast:set-scope
  (syntax-rules ()
    ((_ o e1 e2 ...)
     (parameterize ((ast:scope (list o))) e1 e2 ...))))

(define-syntax ast:extend-scope
  (syntax-rules ()
    ((_ o e1 e2 ...)
     (parameterize ((ast:scope (cons o (ast:scope)))) e1 e2 ...))))

(define-syntax ast:set-model-scope
  (syntax-rules ()
    ((_ o e1 e2 ...)
     (let* ((prev (ast:scope-model))
            (parent (if prev (cdr prev) (ast:scope-root))))
       (parameterize ((ast:scope (cons o parent))) e1 e2 ...)))))

(define (ast:scope-root)
  (let ((scope (ast:scope)))
    (find-tail (lambda (e)
            (if (is-a? e <ast>)
                (is-a? e <root>)
                (eq? (car e) 'root)))
          scope)))

(define (ast:scope-model)
  (let ((scope (ast:scope)))
    (find-tail (lambda (e)
                 (if (is-a? e <ast>)
                     (is-a? e <model>)
                     (eq? (car e) 'model)))
               scope)))

(define (ast:root-scope) (and=> (ast:scope-root) car))
(define (ast:model-scope) (and=> (ast:scope-model) car))

(define-public (compose-root . f)
  (lambda (o)
    (fold-right
     (lambda (elem previous)
       (ast:set-scope previous (elem previous))) o f)))

(define-method (.type (o <port>))
  (name-resolve (car (ast:scope-root)) <interface> (.scope+name (.type@ o))))

(define-method (.type (o <instance>))
  (or (name-resolve (car (ast:scope-root)) <system> (.scope+name (.type@ o)))
      (name-resolve (car (ast:scope-root)) <component> (.scope+name (.type@ o)))
      (name-resolve (car (ast:scope-root)) <foreign> (.scope+name (.type@ o)))))

(define-method (contains? container (o <ast>))
  (and (is-a? container <ast>)
       (or (eq? container o)
           (any (lambda (e) (contains? e o)) (om:children container)))))

(define-method (.port (model <component-model>) (o <trigger>))
  (and (.port@ o) (name-resolve model <port> (.port@ o))))

(define-method (.port (model <component-model>) (o <action>))
  (and (.port@ o) (name-resolve model <port> (.port@ o))))

(define-method (.port (o <trigger>))
  (and (.port@ o) (name-resolve (car (ast:scope-model)) <port> (.port@ o))))

(define-method (.port (o <action>))
  (and (.port@ o) (name-resolve (car (ast:scope-model)) <port> (.port@ o))))

(define-method (.port (o <reply>))
  (and (.port@ o) (name-resolve (car (ast:scope-model)) <port> (.port@ o))))

(define-method (.port (o <binding>))
  (if (.instance o)
      (name-resolve (.type (.instance o)) <port> (.port@ o))
      (name-resolve (car (ast:scope-model)) <port> (.port@ o))))

(define-method (.function (model <model>) (o <call>))
  (and (.function@ o) (name-resolve model <function> (.function@ o))))

(define-method (.function (o <call>))
  (and (.function@ o) (name-resolve (car (ast:scope-model)) <function> (.function@ o))))

(define (ast-> ast)
  ((compose-root
    pretty-print
    om->list
    ast:resolve
    parse->om
    ) ast))
