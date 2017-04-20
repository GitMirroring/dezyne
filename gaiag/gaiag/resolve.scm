;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2015, 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;; Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)
  #:use-module (srfi srfi-1)

  #:use-module (language dezyne location)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast2om)
  #:use-module (gaiag om)
  #:use-module (gaiag util)

  #:use-module (gaiag reader)
  #:use-module (gaiag annotate)
  #:use-module (gaiag misc)
  #:use-module (gaiag reader)

  #:export (
           ast:resolve
           om:resolve
           report-errors
           ))

(define (ast:resolve o)
  (match o
    (($ <root> (models ...)) (resolve-root o))
    ((? (is? <model>)) (resolve-model o))
    (_  o)))

(define (resolve-error o symbol message)
  (make <error> #:ast o #:message (format #f message symbol)))

(define (undefined-error o identifier)
  (resolve-error o identifier "undefined identifier: ~a"))

(define (type-mismatch o expected actual)
  (make <error> #:ast o #:message (format #f "type mismatch: ~a expected, found: ~a" expected actual)))

(define (resolve-root o)
  (map om:register-type (om:types o))
  (let* ((resolved (make <root>
                     #:elements (map resolve-top-model (ast:reorder (.elements o)))))
         (errors (null-is-#f ((om:collect <error>) resolved))))
    (and=> errors report-errors)
    resolved))

(define (ast:reorder o)
  (match o
    (($ <root>)
     (make <root> #:elements (ast:reorder (.elements o))))
    ((models ...)
     (append
                   (filter (is? <import>) models)
                   (filter (is? <type>) models)
                   (filter (is? <interface>) models)
                   (filter (is? <component>) models)
                   (filter (is? <system>) models)))
    (_ o)))

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
     ((compose om:register-model resolve-model) o))
    (_ ((resolve o '()) o))))

(define (resolve-model o)
  (match o
    (($ <interface>)
     ((compose om:register-model (resolve o '())) o))
    (($ <component>)
     ((compose om:register-model (resolve o '())) o))
    (_ ((resolve o '()) o))))

(define ((resolve model locals) o)
  (match o
    (($ <type>) (retain-source-properties o (resolve- model o locals)))
    ((? (is? <type>)) o)
    (($ <import>) o)
    (_ (retain-source-properties o (resolve- model o locals)))))

(define (type-equal? a b)
  (cond ((is-a? a <enum>) (equal? a b))
        (else (eq? (class-of a) (class-of b)))))

(define (->symbol o)
  (match o
    (($ <type> name) (->symbol name))
    (($ <enum> name field) (->symbol name))
    (('dotted name ...) ((->symbol-join '.) name))
    (($ <scope.name>) ((->symbol-join '.) (om:scope+name o))) 
    (_ o)))

(define (resolve- model o locals)

  (define (as-enum identifier) (and=> (as-type identifier) (is? <enum>)))
  (define (extern? identifier) (and=> (as-type identifier) (is? <extern>)))
  (define (int? identifier) (and=> (as-type identifier) (is? <int>)))

  (define (event? o)
    (or (as o <event>)
        (and (is-a? model <interface>)
             (not (var? o)) (om:event model o))))

  (define (interface? o)
    (match o
      (($ <interface>) o)
      (($ <scope.name>) (om:interface o))
      (('dotted scope ... name) (om:interface (make <scope.name> #:scope scope #:name name)))))

  (define (function? identifier) (om:function model identifier))
  (define (member? identifier) (om:variable model identifier))
  (define (port? o) (or (as o <port>)
                        (and (is-a? model <component>) (om:port model o))))

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
      (($ <type> ('dotted '* scope ... name)) ((om:type model) (make <type> #:name (make <scope.name> #:scope scope #:name name))))
      (($ <type> ('dotted scope ... name)) (=> failure)
       (or ((om:type model) (make <type> #:name (make <scope.name> #:scope (append (om:scope+name model) scope) #:name name)))
           ((om:type model) (make <type> #:name (make <scope.name> #:scope scope #:name name)))
           (failure)))
      (_ ((om:type model) o))))

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
       (and-let* ((enum (om:enum model (make <type> #:name (make <scope.name> #:scope scope #:name name))))
                  ((member field ((compose .elements .fields) enum))))
         enum))
      (_ #f)))

  (match o
    (($ <var> (and (? (negate var?)) (get! identifier)))
     (undefined-error o (identifier)))

    (($ <assign> ('dotted port name) expression)
     (make <assign>
       #:variable (.variable o)
       #:expression ((resolve model locals) expression)))

    (($ <assign> (and (? (negate var?)) (get! identifier)))
     (undefined-error o (identifier)))

    (($ <field> (and (? (negate var?)) (get! identifier)))
     (undefined-error o (identifier)))

    (($ <action> #f (and (? (negate event-or-function?)) (get! identifier)))
     (resolve-error o (identifier) "undefined function or event: ~a"))

    (($ <call> (and (? symbol?) (? (negate event-or-function?)) (get! identifier)))
     (resolve-error o (identifier) "undefined function or event: ~a"))

    (($ <call> function ($ <arguments> (arguments ...))) (=> failure)
     (let* ((function (or (as function <function>) (function? function)))
            (formals ((compose .elements .formals .signature) function))
            (argument-count (length arguments))
            (formal-count (length formals)))
       (if (= argument-count formal-count) (failure)
           (resolve-error o (.name function)
                          (format #f "function ~a expects ~a arguments, found: ~a" "~a" formal-count argument-count)))))

    (($ <variable> name (and (? (negate as-type)) (get! type)) expression)
     (resolve-error (type) (->symbol (type)) "undefined type: ~a"))

    (($ <variable> name (and (? (negate extern?)) (get! type)) ($ <expression> (? unspecified?)))
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
     (make <formal> #:name name #:type ((resolve model locals) type) #:direction direction))

    (($ <call> function (and ($ <arguments> (arguments ...)) (get! arguments)) last?)
     (let* ((function (or (as function <function>) (function? function))))
       (make <call> #:function function #:arguments ((resolve model locals) (arguments)) #:last? last?)))

    (($ <type>)
     (or (as-type o)
         (as-type (append (om:scope+name model) (.name o)))
         (undefined-error o (.name o))))

    ((and ($ <event>) (= .signature signature))
     (clone o #:signature ((resolve model '()) signature)))

    (($ <data>) o)
    (($ <enum>) o)
    (($ <extern>) o)
    ((and ($ <field>) (= .variable variable)) 
        (clone o #:variable (var? variable)))
    (($ <illegal>) o)
    (($ <int>) o)
    (($ <literal> (? (is? <type>))) o)
    (($ <literal>)
      (let ((type (make <type> #:name (.type o))))
        (clone o #:type ((resolve model locals) type))))
    (($ <otherwise>) (make <otherwise>))

    ((and ($ <port>) (= .type ('dotted scope ... name)))
     (let* ((name (make <scope.name> #:scope scope #:name name))
            (type (interface? name)))
       (if (not type) (resolve-error o type "undefined interface: ~a")
           (clone o #:type type))))
    ((and ($ <port>) (= .type type))
     (let ((type (interface? type)))
       (if (not type) (resolve-error o type "undefined interface: ~a")
           (clone o #:type type))))
    (($ <signature> type (? unspecified?))
     (make <signature>
       #:type ((resolve model locals) type)
       #:formals '(formals)))
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
           (let ((event (or (as e <event>) (om:event port e))))
             (if (not event) (resolve-error o e "undefined event: ~a")
                 (clone o
                        #:port port
                        #:event event
                        #:arguments ((resolve model locals) arguments)))))))

    ((and ($ <var>) (= .variable v)) (=> failure)
     (let ((variable (var? v)))
       (if (not variable) (resolve-error o v "undeclared identifier: ~a")
           (clone o #:variable variable))))

    ((? symbol?)
     (undefined-error 'programming-error o))

    (($ <action> #f (and (? function?) (get! function)))
     (make <call> #:function (function? (function))))

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
           (let ((event (or (as e <event>) (om:event port e))))
             (if (not event) (resolve-error o e "undefined event: ~a")
                 (clone o
                        #:port port
                        #:event event
                        #:arguments ((resolve model locals) arguments)))))))

    (($ <assign> variable
        ($ <expression> ($ <call> (and (? event?) (get! event)))))
     (make <assign>
       #:variable (var? variable)
       #:expression (make <action> #:event (event? event))))

    (($ <assign> variable ($ <expression> (and ($ <call>) (get! call))))
     (make <assign> 
       #:variable (var? variable)
       #:expression ((resolve model locals) (call))))

    ;; FIXME: expr/call-> decide which one to produce in parser
    (($ <assign> variable ($ <call> (and (? event?) (get! event))))
     (make <assign>
       #:variable (var? variable)
       #:expression (make <action> #:event (event? event))))

    (($ <assign> variable (and ($ <call>) (get! call)))
     (make <assign> 
       #:variable (var? variable)
       #:expression ((resolve model locals) (call))))

    (($ <assign> variable
        ($ <expression> ($ <var> (and (? event?) (get! event)))))
     (make <assign>
       #:variable (var? variable)
       #:expression (make <action> #:event (event? event))))

    (($ <assign> variable
        ($ <expression> ($ <var> (and (? function?) (get! function)))))
     (make <assign>
       #:variable (var? variable)
       #:expression (make <call> #:function (function? (function)))))

    (($ <assign> variable
        ($ <expression> ('dotted (and (? port?) (get! port)) event)))
     (make <assign>
       #:variable (var? variable)
       #:expression ((resolve model locals) (make <action> #:port (port) #:event event))))

    (($ <assign> variable ($ <expression> (and ($ <action>) (get! action))))
     (make <assign>
       #:variable (var? variable)
       #:expression ((resolve model locals) (action))))

    (($ <assign> variable
        ($ <expression> ($ <var> (and (? function?) (get! function)))))
     (make <assign>
       #:variable (var? variable)
       #:expression (make <call> #:function (function? (function)))))

    (($ <assign> variable (and ($ <expression>) (get! expression)))
     (make <assign>
       #:variable (var? variable)
       #:expression ((resolve model locals) (expression))))

    (($ <assign> variable expression)
     (make <assign>
       #:variable (var? variable)
       #:expression ((resolve model locals) expression)))

    (($ <formal> name type direction)
     (make <formal>
       #:name name
       #:type ((resolve model locals) type)
       #:direction direction))

    (($ <formal> name type)
     (make <formal>
       #:name name
       #:type ((resolve model locals) type)))

    (($ <variable> name type
        ($ <expression> ($ <call> (and (? event?) (get! event)))))
     (make <variable>
       #:name name
       #:type ((resolve model locals) type)
       #:expression (make <action> #:event (event? event))))

    (($ <variable> name type ($ <expression> (and ($ <call>) (get! call))))
     (make <variable>
       #:name name
       #:type ((resolve model locals) type)
       #:expression ((resolve model locals) (call))))

    (($ <variable> name type
        ($ <expression> ($ <var> (and (? event?) (get! event)))))
     (make <variable>
       #:type ((resolve model locals) type)
       #:name name
       #:expression (make <action> #:event (event? event))))

    (($ <variable> name type ($ <expression> (and ($ <action>) (get! action))))
     (make <variable>
       #:name name
       #:type ((resolve model locals) type)
       #:expression ((resolve model locals) (action))))

    (($ <variable> name type ($ <expression> ('dotted (and (? port?) (get! port)) event)))
     (make <variable>
       #:name name
       #:type ((resolve model locals) type)
       #:expression ((resolve model locals) (make <action> #:port (port) #:event event))))

    (($ <variable> name type
        ($ <expression> ($ <var> (and (? function?) (get! function)))))
     (make <variable>
       #:name name
       #:type ((resolve model locals) type)
       #:expression (make <call> #:function (function? (function)))))

    (($ <variable> name type expression)
     (make <variable>
       #:name name
       #:type ((resolve model locals) type)
       #:expression ((resolve model locals) expression)))

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
     (make <field> #:variable (variable) #:field (field)))

    (('dotted scope ... name field) (=> failure)
     (let ((enum (as (or (as-type (make <type> #:name (make <scope.name> #:scope scope #:name name)))
                         (as-type (make <type> #:name (make <scope.name> #:scope (append (om:scope+name model) scope) #:name name))))
                     <enum>)))
       (if (not enum) (failure)
           (if (member field ((compose .elements .fields) enum))
               (make <literal> #:type (.name enum) #:field field)
               (and
                (resolve-error o field "undefined enum field: ~a")
                )))))

    (('dotted (? var?) field)
     (resolve-error o field "undefined enum field: ~a"))

    (($ <expression> value)
     (make <expression> #:value ((resolve model locals) value)))

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

    ((and ($ <component>) (= .behaviour (? unspecified?)))
     (clone o
            #:ports (make <ports> #:elements (map (resolve model '()) (om:ports o)))
            #:behaviour #f))

    (($ <component>)
     (let ((o (clone o #:ports (make <ports> #:elements (map (resolve model '()) (om:ports o))))))
       (clone o #:behaviour ((resolve o '()) (.behaviour o)))))

    (($ <behaviour> name types ports variables functions statement)
     (let* ((ports (make <ports> #:elements (map (resolve model '()) (.elements ports))))
            (model (clone model #:behaviour (clone o #:ports ports)))
            (o (clone o
                      #:ports ports
                      #:variables ((resolve model '()) variables)))
            (model (clone model #:behaviour o)))
       (clone o
              #:functions ((resolve model '()) functions)
              #:statement ((resolve model '()) statement))))

    (($ <system>)
     (let ((o (clone o #:ports (make <ports> #:elements (map (resolve model '()) (om:ports o))))))
       (clone o
              #:instances ((resolve o '()) (.instances o))
              #:bindings ((resolve o '()) (.bindings o)))))

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
    (($ <binding>) o) ;; FIXME
    ((and ($ <instance>) (= .type ($ <scope.name>)))
     o)
    ((and ($ <instance>) (= .type ('dotted scope ... name)))
     (let* ((scoped (make <scope.name> #:scope scope #:name name))
            (component (om:import scoped)))
       (clone o #:type (.name component))))
    (($ <variables> (variables ...))
     (let ((variables (map (range-check model) variables)))
       (make <variables> #:elements (map (resolve model '()) variables))))
    (($ <reply> expression port)
     (make <reply> #:expression ((resolve model locals) expression) #:port port))
    (($ <return> expression)
     (make <return> #:expression ((resolve model locals) expression)))
    ((? (is? <ast>)) (om:map (lambda (o) ((resolve model locals) o)) o))
    ((? om:expression?) (map (lambda (o) ((resolve model locals) o)) o))
    (_ o)))

(define ((resolve-triggers model) o)

  (define (event? o)
    (or (as o <event>)
        (and (is-a? model <interface>) (om:event model o))))
  (define (member? m) (or (as m <variable>) (om:variable model m)))
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
           (let ((event (or (as e <event>) (om:event port e))))
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
                   (clone o #:port port #:event event #:formals formals)))))))
    (($ <formal>) o)
    ((and ($ <formal-binding>) (= .variable v))
     (let ((variable (or (as v <variable>)
                         (member? v))))
       (if (not variable) (resolve-error o v "undeclared identifier: ~a")
           (clone o #:variable variable))))))

(define ((range-check model) variable)
  (define (as-int-type type) (om:integer model type))
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
  (define (member? identifier) (om:variable model identifier))
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
  (and-let* ((function (om:function model name))
             (compound (.statement function))
             (calls (null-is-#f ((om:collect return-call) compound)))
             (names (delete-duplicates (sort (map
                                              (compose .function-name return-call)
                                              calls) symbol<))))
            (or (member name seen)
                (any identity
                     (map (recurses? model (cons name seen)) names)))))

(define (ast-> ast)
  ((compose
    om->list
    ast:resolve
    ast->om
    ) ast))
