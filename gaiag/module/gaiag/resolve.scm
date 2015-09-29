;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

(define-module (gaiag resolve)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (gaiag list match)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (srfi srfi-1)

  :use-module (language dezyne location)

  :use-module (gaiag om)

  :use-module (gaiag reader)
  :use-module (gaiag annotate)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :export (
           ast:resolve
           om:resolve
           report-errors
           ))

(define (ast:resolve o)
  (match o
    (('root models ...) (resolve-root o))
    ((? (is? <model>)) (resolve-model o))
    (_  o)))

(define (resolve-error o symbol message)
  (make <error> :ast o :message (format #f message symbol)))

(define (undefined-error o identifier)
  (resolve-error o identifier "undefined identifier: ~a"))

(define (type-mismatch o expected actual)
  (make <error> :ast o :message (format #f "type mismatch: ~a expected, found: ~a" expected actual)))

(define (resolve-root o)
  (map om:register-type (om:types o))
  (let* ((resolved (make <root>
                     :elements (map resolve-top-model (ast:reorder (.elements o)))))
         (errors (null-is-#f ((om:collect <error>) resolved))))
    (and=> errors report-errors)
    resolved))

(define (ast:reorder o)
  (match o
    (($ <root>)
     (make <root> :elements (ast:reorder (.elements o))))
    ((models ...)
     (append
                   (filter (is? <import>) models)
                   (filter (is? <*type*>) models)
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
    (($ <system>) o)
    (($ <*type*>) o)
    (($ <import>) o)
    (_ (retain-source-properties o (resolve- model o locals)))))

(define (resolve:import name)
  (om:import name resolve:om))

(define (resolve:om ast)
  ((compose ast:resolve ast->om ast:public) ast))

(define (type-equal? a b)
  (equal? (.name a) (.name b)))

(define (->symbol o)
  (match o
    (($ <type> name) (->symbol name))
    (($ <enum> name field) (->symbol name))
    (('name name ...) ((->symbol-join '.) name))
    (_ o)))

(define ((om:ensure-scope scope) name)
  (cond ((member name '(bool void)) name)
        ((and (>2 (length name)) (eq? ((compose car om:scope) name) '*))
         (cons 'name ((compose cddr) name)))
        (else
         (cons 'name (append scope (drop-prefix scope (.elements name)))))))

(define (resolve- model o locals)

  (define (enum? identifier) (and=> (type? identifier) (is? <enum>)))
  (define (extern? identifier) (and=> (type? identifier) (is? <extern>)))
  (define (int? identifier) (and=> (type? identifier) (is? <int>)))

  (define (event? identifier)
    (and (is-a? model <interface>)
         (not (var? identifier)) (om:event model identifier)))
  (define (function? identifier) (om:function model identifier))
  (define (member? identifier) (om:variable model identifier))
  (define (port? name) (and (is-a? model <component>) (om:port model name)))

  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (local? identifier) (member? identifier)))
  (define (unspecified? x) (eq? x *unspecified*))

  (define (event-or-function? identifier)
    (or (function? identifier) (event? identifier)))

  (define (enum-field? identifier)
    (lambda (field)
      (and-let* ((enum (enum? identifier)))
                (member field (.elements (.fields enum))))))

  (define (member-field? identifier)
    (lambda (field)
      (and-let* ((variable (var? identifier))
                 (type (.type variable))
                 (enum (type? type)))
                (member field (.elements (.fields enum))))))

  (define (type? o)
    (match o
      (($ <type> ('name name)) (=> failure) (or ((om:type model) (make <type> :name (append (.name model) (list name)))) (failure)))
      (($ <type> ('name '* rest ...)) ((om:type model) (make <type> :name (cons 'name rest))))
      (_ ((om:type model) o))))

  (define (fake:type model o)
    (match o
      (($ <expression> expression) (fake:type model expression))
      ('false (make <type> :name 'bool))
      ('true (make <type> :name 'bool))
      (($ <data>) (make <type> :name 'data))
      ((? number?) (make <type> :name 'int))
      (('name type field)
       (and-let* ((enum (or (type? (make <type> :name (make <name> :elements (list type))))))
                  ((member field ((compose .elements .fields) enum))))
                 enum))
      (('name scope ... field)
       (and-let* ((enum (om:enum model (make <type> :name (make <name> :elements scope))))
                  ((member field ((compose .elements .fields) enum))))
                 enum))
      (_ #f)))

  (match o
    ('root o)
    (($ <var> (and (? (negate var?)) (get! identifier)))
     (undefined-error o (identifier)))

    (($ <assign> (and (? (negate var?)) (get! identifier)))
     (undefined-error o (identifier)))

    (($ <action> ($ <trigger> #f
                    (and (? (negate event-or-function?)) (get! identifier))))
     (resolve-error o (identifier) "undefined function or event: ~a"))

    (($ <call> (and (? symbol?) (? (negate event-or-function?)) (get! identifier)))
     (resolve-error o (identifier) "undefined function or event: ~a"))

    (($ <call> identifier ('arguments arguments ...)) (=> failure)
     (let* ((function (function? identifier))
            (formals ((compose .elements .formals .signature) function))
            (argument-count (length arguments))
            (formal-count (length formals)))
       (if (= argument-count formal-count) (failure)
           (resolve-error o identifier
                          (format #f "function ~a expects ~a arguments, found: ~a" "~a" formal-count argument-count)))))

    (($ <variable> name (and (? (negate type?)) (get! type)) expression)
     (resolve-error (type) (->symbol (type)) "undefined type: ~a"))

    (($ <variable> name (and (? (negate extern?)) (get! type)) ($ <expression> (? unspecified?)))
      (resolve-error o name "undefined variable value: ~a"))

    (($ <variable> name type expression) (=> failure)
     (or (and-let* ((e-type (fake:type model expression))
                    (v-type (type? type))
                    ((not (type-equal? e-type v-type)))
                    (actual (type? type))
                    ((if (eq? (.name e-type) 'data)
                         (not (is-a? actual <extern>))))
                    ((if (eq? (.name e-type) 'int)
                         (not (is-a? actual <int>)))))
                   (type-mismatch expression (->symbol (.name v-type)) (->symbol e-type)))
         (failure)))

    ((or 'false 'true) o)
    ((or 'and 'or) o)
    ((or '! '+ '- '/ '*) o)
    ((or '== '!= '< '<= '> '>= 'group) o)

    (($ <formal> name type direction)
     (make <formal> :name name :type ((resolve model locals) type) :direction direction))

    (($ <call> identifier (and ('arguments arguments ...) (get! arguments)) last?)
     (make <call> :identifier identifier :arguments ((resolve model locals) (arguments)) :last? last?))

    (($ <type> name) (=> failure)
     (or (and-let* ((type (type? o)))
                   (make <type> :name (.name type)))
         (and-let* ((type (type? (append (.name model) (cdr name)))))
                   (make <type> :name (.name type)))
         (failure)
         (undefined-error o name)))

    (($ <event> name signature direction)
     (make <event> :name name :signature ((resolve model '()) signature) :direction direction))

    (($ <data>) o)
    (($ <enum>) o)
    (($ <event>) o)
    (($ <extern>) o)
    (($ <field>) o)
    (($ <illegal>) o)
    (($ <int>) o)
    (($ <literal>) o)
    (($ <otherwise>) (make <otherwise>))
    (($ <port>) o)
    (($ <signature> type (? unspecified?))
     (make <signature>
       :type ((resolve model locals) type)
       :formals '(formals)))
    (($ <signature> type formals)
     (make <signature>
       :type ((resolve model locals) type)
       :formals ((resolve model locals) formals)))
    (($ <trigger> port event arguments)
     (make <trigger> :port port :event event :arguments ((resolve model locals) arguments)))
    (($ <var>) o)

    ((? symbol?)
     (undefined-error 'programming-error o))

    (($ <action> ($ <trigger> #f (and (? function?) (get! identifier))))
     (make <call> :identifier (identifier)))

    (($ <action> trigger) (make <action> :trigger ((resolve model locals) trigger)))

    (($ <assign> identifier
        ($ <expression> ($ <call> (and (? event?) (get! event)))))
     (make <assign>
       :identifier identifier
       :expression (make <action> :trigger (make <trigger> :event (event)))))

    (($ <assign> identifier ($ <expression> (and ($ <call>) (get! call))))
     (make <assign> :identifier identifier
           :expression ((resolve model locals) (call))))

    (($ <assign> identifier ($ <call> (and (? event?) (get! event))))
     (make <assign>
       :identifier identifier
       :expression (make <action> :trigger (make <trigger> :event (event)))))

    (($ <assign> identifier (and ($ <call>) (get! call)))
     (make <assign> :identifier identifier
           :expression ((resolve model locals) (call))))

    (($ <assign> identifier
        ($ <expression> ($ <var> (and (? event?) (get! event)))))
     (make <assign>
       :identifier identifier
       :expression (make <action> :trigger (make <trigger> :event (event)))))

    (($ <assign> identifier
        ($ <expression> ($ <var> (and (? function?) (get! function)))))
     (make <assign>
       :identifier identifier
       :expression (make <call> :identifier (function))))

    (($ <assign> identifier
        ($ <expression> ('name (and (? port?) (get! port)) event)))
     (make <assign>
       :identifier identifier
       :expression (make <action>
                     :trigger (make <trigger> :port (port) :event event))))

    (($ <assign> identifier ($ <expression> (and ($ <action>) (get! action))))
     (make <assign>
       :identifier identifier
       :expression ((resolve model locals) (action))))

    (($ <assign> identifier
        ($ <expression> ($ <var> (and (? function?) (get! function)))))
     (make <assign>
       :identifier identifier
       :expression (make <call> :identifier (function))))

    (($ <assign> identifier (and ($ <expression>) (get! expression)))
     (make <assign>
       :identifier identifier
       :expression ((resolve model locals) (expression))))

    (($ <assign> identifier expression)
     (make <assign>
       :identifier identifier
       :expression ((resolve model locals) expression)))

    (($ <formal> name type direction)
     (make <formal>
       :name name
       :type ((resolve model locals) type)
       :direction direction))

    (($ <formal> name type)
     (make <formal>
       :name name
       :type ((resolve model locals) type)))

    (($ <variable> name type
        ($ <expression> ($ <call> (and (? event?) (get! event)))))
     (make <variable>
       :name name
       :type ((resolve model locals) type)
       :expression (make <action> :trigger
                         (make <trigger> :event (event)))))

    (($ <variable> name type ($ <expression> (and ($ <call>) (get! call))))
     (make <variable>
       :name name
       :type ((resolve model locals) type)
       :expression ((resolve model locals) (call))))

    (($ <variable> name type
        ($ <expression> ($ <var> (and (? event?) (get! event)))))
     (make <variable>
       :type ((resolve model locals) type)
       :name name
       :expression (make <action> :trigger
                         (make <trigger> :event (event)))))

    (($ <variable> name type ($ <expression> (and ($ <action>) (get! action))))
     (make <variable>
       :name name
       :type ((resolve model locals) type)
       :expression ((resolve model locals) (action))))

    (($ <variable> name type ($ <expression> ('name (and (? port?) (get! port)) event)))
     (make <variable>
       :name name
       :type ((resolve model locals) type)
       :expression (make <action> :trigger (make <trigger> :port (port) :event event))))

    (($ <variable> name type
        ($ <expression> ($ <var> (and (? function?) (get! function)))))
     (make <variable>
       :name name
       :type ((resolve model locals) type)
       :expression (make <call> :identifier (function))))

    (($ <variable> name type expression)
     (make <variable>
       :name name
       :type ((resolve model locals) type)
       :expression ((resolve model locals) expression)))

    (('name '* rest ...)
     ((resolve model locals) (cons 'name rest)))

    (('name name ...) (=> failure)
     (or (and-let* ((enum (enum? o)))
                   (.name enum))
         (failure)))

    (('name (and (? var?) (get! name)))
     (make <var> :name (name)))

    (('name name) (=> failure)
     (or (and-let* ((type (type? (append (.name model) (list name)))))
                   (.name type))
         (failure)))

    (('name (and (? var?) (get! type)) (? (member-field? (type))))
     (make <field> :identifier (type) :field (om:name o)))

    (('name scope name field) (=> failure)
     (let* ((name `(name ,scope ,name))
            (enum (enum? o)))
       (if (not enum) (failure)
           (make <literal> :name (.name enum) :field field))))

    (('name (? var?) field)
     (resolve-error o field "undefined enum field: ~a"))

    (('name scope ... field) (=> failure)
     (or (and-let* ((enum (enum? (make <type> :name (make <name> :elements scope)))))
                   (if (member field ((compose .elements .fields) enum))
                       (make <literal> :name (.name enum) :field field)
                       (and
                        (resolve-error o field "undefined enum field: ~a"))))
         (failure)))

    (($ <expression> value)
     (make <expression> :value ((resolve model locals) value)))

    (('name t ...)
     o)

    ;; (($ <function> name ($ <signature> type) recursive? statement)
    ;;  (stderr "WIERD\n")
    ;;  (make <function>
    ;;    :name name
    ;;    :signature ((resolve model locals) (.signature o))
    ;;    :recursive (and ((recurses? model) name) 'recursive)
    ;;    :statement ((resolve model locals) statement)))

    (($ <function> name ($ <signature> type ('formals)) recursive? statement)
     (make <function>
       :name name
       :signature ((resolve model locals) (.signature o))
       :recursive (and ((recurses? model) name) 'recursive)
       :statement ((resolve model locals) statement)))

    (($ <function> name ($ <signature> type ('formals formals ...)) recursive? statement)
     (let ((locals (let loop ((formals formals) (locals locals))
                     (if (null? formals)
                         locals
                         (loop (cdr formals)
                               (acons (.name (car formals)) (car formals) locals))))))
       (make <function>
         :name name
         :signature ((resolve model locals) (.signature o))
         :recursive (and ((recurses? model) name) 'recursive)
         :statement ((resolve model locals) statement))))

    (('compound statements ...)
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
               (let ((resolved ((resolve model locals) (car statements))))
                 (cons resolved (loop (cdr statements) locals))))))))

    (($ <guard> expression statement)
       (make <guard>
         :expression ((resolve model locals) expression)
         :statement ((resolve model locals) statement)))

    (($ <on> triggers statement)
     (let* ((triggers (resolve-on-triggers triggers))
            (arguments (append-map (compose .elements .arguments) (.elements triggers)))
            (locals (let loop ((arguments arguments) (locals locals))
                      (if (null? arguments)
                          locals
                          (loop (cdr arguments)
                                (let* ((argument (car arguments))
                                       (name ((compose .name .value) argument))
                                       (name (if (pair? name) (car name) name)))
                                 (acons name argument locals)))))))
       (make <on>
         :triggers triggers
         :statement ((resolve model locals) statement))))

    (($ <interface> name types events behaviour)
     (make <interface>
       :name name
       :types types
       :events ((resolve o '()) events)
       :behaviour ((resolve o '()) behaviour)))

    (($ <component> name ports (? unspecified?))
     (make <component> :name name :ports ports))

    (($ <component> name ports behaviour)
       (make <component>
         :name name
         :ports ports
         :behaviour ((resolve o '()) behaviour)))

    (($ <behaviour> name types variables functions statement)
     (make <behaviour>
       :name name
       :types types
       :variables ((resolve model '()) variables)
       ;; om:map denx0r?
       :functions ((resolve model '()) functions)
       :statement ((resolve model '()) statement)
       ;;:functions (om:map (resolve model '()) functions)
       ;;:statement (om:map (resolve model '()) statement)
     ))

    (($ <if> expression then else)
     (make <if>
       :expression ((resolve model locals) expression)
       :then ((resolve model locals) then)
       :else (and (not (eq? else *unspecified*))
                  else ((resolve model locals) else))))
    (('arguments arguments ...)
     (make <arguments> :elements (map (resolve model locals) arguments)))
    (('events events ...)
     (cons 'events (map (resolve model '()) events)))
    (('triggers triggers ...) o)
    (('functions functions ...)
     (make <functions> :elements (map (resolve model '()) functions)))
    (('formals formals ...)
     (make <formals> :elements (map (resolve model '()) formals)))
    (('variables variables ...)
     (let ((variables (map (range-check model) variables)))
       (make <variables> :elements (map (resolve model '()) variables))))
    (($ <reply> expression)
     (make <reply> :expression ((resolve model locals) expression)))
    (($ <return> expression)
     (make <return> :expression ((resolve model locals) expression)))
    ((? (is? <ast>)) (om:map (lambda (o) ((resolve model locals) o)) o))
    ((h t ...) (map (lambda (o) ((resolve model locals) o)) o))
    (_ o)))

(define (resolve-on-triggers o)
  (match o
    (('triggers triggers ...) (om:map resolve-on-triggers o))
    (($ <trigger> p e ('arguments)) o)
    (($ <trigger> p e arguments)
     (rsp o (make <trigger> :port p :event e :arguments (resolve-on-triggers arguments))))
    (('arguments arguments ...) (om:map resolve-on-triggers o))
    (($ <expression> (and ('name name) (get! value)))
     (rsp o (make <expression> :value (rsp (value) (make <var> :name name)))))
    (($ <expression> ($ <var> name)) o)))

(define ((range-check model) variable)
  (define (int-type? type) (om:integer model type))
  (or variable
      (and-let* ((int (int-type? (.type variable)))
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

(define* ((recurses? model :optional (seen '())) name)
  (define (return-call ast)
    (match ast
      (($ <call>) ast)
      (($ <assign> name (and ($ <call>) (get! call))) (call))
      (($ <variable> name type (and ($ <call>) (get! call))) (call))
      (_ #f)))
  (and-let* ((function (om:function model name))
             (compound (.statement function))
             (calls (null-is-#f ((om:collect return-call) compound)))
             (names (delete-duplicates (sort (map
                                              (compose .identifier return-call)
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
