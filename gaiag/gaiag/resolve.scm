;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2015, 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;; Copyright © 2014, 2015, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

  #:use-module (gaiag location)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (oop goops describe)
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

           .function
           .variable

           resolve:component
           resolve:event
           resolve:function
           resolve:instance
           resolve:interface
           resolve:variable
           ))

(define (ast:resolve o)
  (match o
    (($ <root>) (resolve-root o))
    (($ <call>) ((resolve (parent <model> o) '()) o))
    ((? (is? <model>)) (resolve-model o))
    (_  o)))

(define (resolve-error o symbol message)
  (make <error> #:ast o #:message (format #f message symbol)))

(define (undefined-error o identifier)
  (resolve-error o identifier "undefined identifier: ~a"))

(define (type-mismatch o expected actual)
  (make <error> #:ast o #:message (format #f "type mismatch: ~a expected, found: ~a" expected actual)))

(define-method (resolve-root (o <root>))
  (let* ((resolved ((compose
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

(define (->symbol o)
  (match o
    (($ <type>) (->symbol (.name o)))
    (($ <enum>) (->symbol (.name o)))
    (($ <scope.name>) ((->symbol-join '.) (om:scope+name o)))
    (_ o)))

(define* (resolve:types root #:optional (model #f))
  (append
   (om:types model) ;; FIXME: deprecated
   (resolve:globals root)))

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

(define (resolve:globals root)
  (filter (is? <type>) (.elements root)))

(define (resolve:function model o)
  (find (om:named o) (om:functions model)))

(define (resolve:instance model o)
  (match o
    ((? symbol?)
     (find (lambda (x)
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
           (find (lambda (x) (om:equal? system (.name x))) (filter (negate (is? <data>)) (.elements (parent <root> system)))))
          (_ #f)))
    ((? symbol?) (resolve:component system (resolve:instance system o)))
    ((and ($ <binding>) (= .instance #f))
     ;;#f
     ;;(resolve:component system (om:binding-other-port system port))
     (let* ((bind (om:bind system (.port@ o)))
            (instance (om:instance-name bind)))
       (resolve:component system instance)))
    (($ <binding>) (resolve:component system (.instance o)))
    (($ <bind>) (resolve:component system (om:instance-name o)))
    (($ <instance>) (.type o))
    (($ <port>) (resolve:interface (.type o)))))

(define (resolve:interface o)
  (match o
    (($ <port>) (resolve:interface (.type o)))
    (($ <interface>) o)
    ((? (is? <model>)) (resolve:interface (om:port o)))
    (($ <scope.name>) (find (om:named o) ((compose .elements (parent <root> o)))))
    (($ <root>) (om:find (is? <interface>) o))
    ((h t ...) (find (is? <interface>) o))))

(define ((resolve:type-of model) o)
  (match o
    (($ <variable>) ((resolve:type model) (.type o)))
    (($ <formal>) ((resolve:type model) (.type o)))))

(define ((resolve:type model) o)
  (match o
    ((? symbol?) (find (resolve:named (make <scope.name> #:scope (om:scope+name model) #:name o)) (resolve:types (parent <root> o) model)))

    (($ <bool>) o)
    (($ <enum>) o)
    (($ <data>) o)
    (($ <extern>) o)
    (($ <void>) o)
    (($ <int>) o)

    (($ <scope.name>)
     (or (find (resolve:named o) (resolve:types (parent <root> o) model))
         (find (resolve:scoped (om:scope+name model) o) (resolve:types (parent <root> o)))))
    ((and ($ <type>) (= .name name))
     ((resolve:type model) name))))

(define ((resolve:named name) ast)
  (match name
    ((? symbol?) (or (eq? name (.name ast)) ((resolve:named (make <scope.name> #:name name)) ast)))
    (_ (om:equal? (.name ast) name))))

(define ((resolve:scoped scope name) ast)
  (if (null? (om:scope name)) (eq? (om:name ast) (om:name name))
      (equal? (append scope (om:scope+name ast)) (om:scope+name name))))

(define-method (var? (o <ast>) id)
  (match o
    (($ <behaviour>) (find (cut var? <> id) (ast:variable* o)))
    (($ <compound>) (or (find (cut var? <> id) (filter (is? <variable>) (ast:statement* o))) (var? (.parent o) id)))
    (($ <function>) (or (find (cut var? <> id) ((compose ast:formal* .signature) o)) (var? (.parent o) id)))
    (($ <formal>) (and (eq? (.name o) id) o))
    (($ <on>) (or (find (cut var? <> id) (append-map ast:formal* (ast:trigger* o))) (var? (.parent o) id)))
    (($ <variable>) (and (eq? (.name o) id) o))
    ((? (lambda (o) (is-a? (.parent o) <variable>))) (var? ((compose .parent .parent) o) id))
    (_ (var? (.parent o) id)))
  )

(define (resolve:variable model o)
  (find (om:named o) (om:variables model)))

(define (resolve- model o locals)

  (define (as-enum identifier) (and=> (as-type identifier) (is? <enum>)))
  (define (extern? identifier) (and=> (as-type identifier) (is? <extern>)))
  (define (int? identifier) (and=> (as-type identifier) (is? <int>)))

  (define (interface? o)
    (match o
      (($ <interface>) o)
      (($ <scope.name>) (resolve:interface o))))

  (define (component? o)
    (match o
      (($ <component-model>) o)
      (($ <scope.name>) (resolve:component o))))

  (define (instance? identifier)
    (or (as identifier <instance>) (resolve:instance model identifier)))

  (define (function? identifier)
    (resolve:function model identifier))

  (define (event? ctx o)
    (or (as o <event>)
      (and (is-a? model <interface>)
           (not (var? ctx o)) (resolve:event model o))))

  (define (event-or-function? ctx o)
    (or (function? o) (event? ctx o)))

  (define (member? identifier) (resolve:variable model identifier))
  (define (port? o) (or (as o <port>)
                        (and (or (is-a? model <component>) (is-a? model <foreign>)) (om:port model o))))


  (define (unspecified? x) (eq? x *unspecified*))

  (define (enum-field? identifier)
    (lambda (field)
      (and-let* ((enum (as-enum identifier)))
        (member field (.elements (.fields enum))))))

  (define (as-type o)
    ((resolve:type model) o))

  (define (resolve-assign-expression o)
    (match o
      (($ <call>)
       ((resolve model locals) o))

      (($ <action>)
       ((resolve model locals) o))

      ((and ($ <literal>) (get! expression))
       ((resolve model locals) (expression)))

      (_
       ((resolve model locals) o))))

  (match o
    ((and ($ <var>) (= .variable.name (? (negate (cut var? o <>)))))
     (undefined-error o (.variable o)))

    ((and ($ <assign>) (= .variable.name (? (negate (cut var? o <>)))))
     (undefined-error o (.variable o)))

    ((and ($ <field-test>) (= .variable.name (? (negate (cut var? o <>)))))
     (undefined-error o (.variable o)))

    ((and ($ <action>) (= .port #f) (? (negate (compose (cut event-or-function? o <>) .event))))
     (resolve-error o (.event o) "undefined function or event: ~a"))

    ((and ($ <call>) (? (compose symbol? .function)) (? (negate (compose (cut event-or-function? o <>) .function))))
     (resolve-error o (.function o) "undefined function or event: ~a"))

    (($ <call>) (=> failure)
     (let* ((function (function? (.function.name o)))
            (formals (ast:formal* function))
            (argument-count (length (ast:argument* o)))
            (formal-count (length formals)))
       (if (= argument-count formal-count) (failure)
           (resolve-error o (.function o)
                          (format #f "function ~a expects ~a arguments, found: ~a" "~a" formal-count argument-count)))))

    ((and ($ <variable>) (? (negate (compose as-type .type))))
     (resolve-error (.type o) (->symbol (.type o)) "undefined type: ~a"))

    ((and ($ <variable>) (? (negate (compose extern? .type))) (? (compose (is? <literal>) .expression)) (? (compose unspecified? .value .expression)))
     (resolve-error o (.name o) "undefined variable value: ~a"))

    ((or 'false 'true) o)
    ((or 'and 'or) o)
    ((or '! '+ '- '/ '*) o)
    ((or '== '!= '< '<= '> '>= 'group) o)

    (($ <formal>)
     (clone o #:type ((resolve model locals) (.type o))))

    ((and ($ <call>))
     (clone o #:arguments ((resolve model locals) (.arguments o))))

    (($ <type>)
     (or (as-type o)
         (as-type (append (om:scope+name model) (.name o)))
         (undefined-error o (.name o))))

    ((and ($ <event>) (= .signature signature))
     (clone o #:signature ((resolve model '()) signature)))

    (($ <data>) o)
    (($ <enum>) o)
    (($ <extern>) o)
    (($ <field-test>) o)
    (($ <illegal>) o)
    (($ <int>) o)
    ((and ($ <enum-literal>) (? (compose (is? <type>) .type))) o)
    (($ <enum-literal>)
     (clone o #:type ((resolve:type model) (.type o))))
    (($ <otherwise>) o)

    ((and ($ <port>))
     (let* ((type (.type o))
            (type (interface? type)))
       (if (not type) (resolve-error o type "undefined interface: ~a")
           o)))

    (($ <signature>)
     (clone o
            #:type ((resolve model locals) (.type o))
            #:formals ((resolve model locals) (.formals o))))
    ((and ($ <trigger>) (= .port #f) (? (compose (cut event? o <>) .event)))
     (clone o #:arguments ((resolve model locals) (.arguments o))))
    ((and ($ <trigger>) (= .port #f))
     (resolve-error o (.event o) "undefined event: ~a"))
    ((and ($ <trigger>)) (=> failure)
     (let* ((p (.port o))
            (e (.event o))
            (port (port? p)))
       (if (not port) (resolve-error o p "undefined port: ~a")
           (let ((event (or (as e <event>) (resolve:event port e))))
             (if (not event) (resolve-error o e "undefined event: ~a")
                 (clone o
                        #:event event
                        #:arguments ((resolve model locals) (.arguments o))))))))

    ((and ($ <var>) (= .variable.name v))
     (let ((variable (var? o v)))
       (if (not variable) (resolve-error o v "undeclared identifier: ~a")
           o)))

    ((? symbol?)
     (undefined-error 'programming-error o))

    ((and ($ <action>) (= .port #f) (? (compose (cut event? o <>) .event)) (= .event event) (= .arguments arguments))
     (clone o #:event (event? o event) #:arguments ((resolve model locals) arguments)))

    ((and ($ <action>) (= .port #f))
     (resolve-error o (.event o) "undefined event: ~a"))

    ((and ($ <action>) (= .port p) (= .event e) (= .arguments arguments)) (=> failure)
     (let ((port (port? p)))
       (if (not port) (resolve-error o p "undefined port: ~a")
           (let ((event (or (as e <event>) (resolve:event port e))))
             (if (not event) (resolve-error o e "undefined event: ~a")
                 (clone o
                        #:event event
                        #:arguments ((resolve model locals) arguments)))))))

    (($ <assign>)
     (clone o
            #:expression (resolve-assign-expression (.expression o))))

    (($ <formal>)
     (clone o #:type ((resolve model locals) (.type o))))

    (($ <variable>)
     (clone o
            #:type ((resolve model locals) (.type o))
            #:expression (resolve-assign-expression (.expression o))))

    ((and (? (is? <literal>)) (= .value value))
     (clone o #:value ((resolve model locals) value)))

    ((and (? (is? <unary>)) (= .expression expression))
     (clone o #:expression ((resolve model locals) expression)))

    ((and (? (is? <binary>)) (= .left left) (= .right right))
     (clone o #:left ((resolve model locals) left) #:right ((resolve model locals) right)))

    (($ <function>)
     (let* ((signature ((resolve model locals) (.signature o)))
            (formals ((compose .elements .formals) signature))
            (locals (let loop ((formals formals) (locals locals))
                      (if (null? formals)
                          locals
                          (loop (cdr formals)
                                (acons (.name (car formals)) (car formals) locals))))))
       (clone o
              #:signature signature
              #:recursive (and ((recurses? model) (.name o)) 'recursive)
              #:statement ((resolve model locals) (.statement o)))))

    (($ <compound>)
     (clone o
            #:elements
            (let loop ((statements (.elements o)) (locals locals))
              (if (null? statements)
                  '()
                  (let* ((statement (car statements))
                         (statement ((resolve model locals) statement))
                         (locals (match statement
                                   (($ <variable>)
                                    (acons (.name statement) ((resolve model locals) statement) locals))
                                   (_ locals))))
                    (cons statement (loop (cdr statements) locals)))))))

    (($ <blocking>)
     (clone o #:statement ((resolve model locals) (.statement o))))

    (($ <guard>)
     (clone o
            #:expression ((resolve model locals) (.expression o))
            #:statement ((resolve model locals) (.statement o))))

    (($ <on>)
     (let* ((triggers ((resolve-triggers model) (.triggers o)))

            (on-formals (append-map (compose .elements .formals) (.elements triggers)))
            (locals (let loop ((on-formals on-formals) (locals locals))
                      (if (null? on-formals)
                          locals
                          (loop (cdr on-formals)
                                (let* ((on-formal ((resolve-triggers model) (car on-formals)))
                                       (name (.name on-formal)))
                                  (acons name on-formal locals)))))))
       (clone o
              #:triggers triggers
              #:statement ((resolve model locals) (.statement o)))))

    (($ <interface>)
     (let ((o (clone o #:events ((resolve o '()) (.events o)))))
       (clone o #:behaviour ((resolve o '()) (.behaviour o)))))

    (($ <foreign>)
     (clone o #:ports (clone (.ports o) #:elements (map (resolve model '()) (om:ports o)))))

    ((and ($ <component>) (= .behaviour (? unspecified?)))
     (clone o
            #:ports (clone (.ports o) #:elements (map (resolve model '()) (om:ports o)))
            #:behaviour #f))

    (($ <component>)
     (let* ((ports (ast:port* o))
            (elements (map (resolve model '()) ports))
            (ports (clone (.ports o) #:elements elements))
            (o (clone o #:ports ports)))
       (clone o #:behaviour ((resolve o '()) (.behaviour o)))))

    (($ <behaviour>)
     (let* ((ports (clone (.ports o) #:elements (map (resolve model '()) ((compose .elements .ports) o))))
            (o (clone o #:ports ports))
            (model (clone model #:behaviour o))

            (o (clone o #:variables ((resolve model '()) (.variables o))))
            (model (clone model #:behaviour o))

            (functions (clone (.functions o) #:elements (map (resolve model '()) ((compose .elements .functions) o))))
            (o (clone o #:functions functions))

            (model (clone model #:behaviour o)))
       (clone o #:statement ((resolve model '()) (.statement o)))))

    (($ <system>)
     (let* ((o (clone o #:ports (clone (.ports o) #:elements (map (resolve model '()) (om:ports o)))))
            (o (clone o #:instances ((resolve o '()) (.instances o)))))
       (clone o #:bindings ((resolve o '()) (.bindings o)))))

    ((and ($ <if>) (= .expression expression) (= .then then) (= .else else))
     (clone o
            #:expression ((resolve model locals) expression)
            #:then ((resolve model locals) then)
            #:else (and (not (eq? else *unspecified*))
                        else ((resolve model locals) else))))
    ((or ($ <arguments>) ($ <bindings>) ($ <events>) ($ <triggers>) ($ <instances>))
     (clone o #:elements (map (resolve model locals) (.elements o))))
    ((or ($ <functions>) ($ <formals>))
     (clone o #:elements (map (resolve model '()) (.elements o))))
    ((and ($ <instance>) (= .type.name type-name))
     (let ((type (component? type-name)))
       (if (not type) (resolve-error o type "undefined component: ~a")
           o)))
    (($ <binding>)
     (let* ((instance (.instance o))
            (inst (instance? instance))
            (component (or (and=> inst .type) model))
            (port-name (.port.name o))
            (port (om:port component port-name)))
       (if (and instance (not inst))
           (resolve-error o instance "undeclared instance: ~a")
           (clone o #:instance inst))))
    (($ <variables>)
     (let ((variables (map (range-check model) (.elements o))))
       (clone o #:elements (map (resolve model '()) variables))))
    ((and ($ <reply>) (= .expression expression) (= .port p))
     (let ((port (port? p)))
       (if (and p (not port)) (resolve-error o p "undefined port: ~a")
           (clone o #:expression ((resolve model locals) expression)))))
    ((and ($ <return>) (= .expression expression))
     (clone o #:expression ((resolve model locals) expression)))
    ((? (is? <ast>)) (tree-map (lambda (o) ((resolve model locals) o)) o))
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
    (($ <triggers>) (tree-map (resolve-triggers model) o))
    ((and ($ <trigger>) (= .port #f) (= .event 'inevitable)) (clone o #:event ast:inevitable))
    ((and ($ <trigger>) (= .port #f) (= .event 'optional)) (clone o #:event ast:optional))
    ((and ($ <trigger>) (= .port #f) (= .event e))
     (let ((event (event? e)))
       (if (not event) (resolve-error o e "undefined event: ~a")
           (clone o #:event event))))
    ((and ($ <trigger>) (= .port p) (= .event e) (= .formals formals))
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
                        (formals (clone (.formals o) #:elements formals)))
                   (clone o
                          ;;#:port port
                          #:event event
                          #:formals formals)))))))
    (($ <formal>) o)
    ((and ($ <formal-binding>) (= .variable.name v))
     (let ((variable (var? o v)))
       (if (not variable) (resolve-error o v "undeclared identifier: ~a")
           o)))))

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
    ((? number?) o)
    (('+ a b) (+ (evaluate model a) (evaluate model b)))
    (('- a b) (- (evaluate model a) (evaluate model b)))
    (('* a b) (* (evaluate model a) (evaluate model b)))
    (('/ a b) (/ (evaluate model a) (evaluate model b)))
    (($ <var>) (evaluate model (.expression (member? (.name o)))))
    (('group g) g)))

(define* ((recurses? model #:optional (seen '())) name)
  (define (return-call ast)
    (match ast
      (($ <call>) ast)
      ((and ($ <assign>) (? (compose (is? <call>) .expression)) (= .expression call)) call)
      ((and ($ <variable>) (? (compose (is? <call>) .expression)) (= .expression call)) call)
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
          (append (ast:port* root)
                  (om:behaviour-ports root))))
   ((eq? <function> class)
    (find (lambda (m)
            (equal? o (.name m)))
          ((compose .elements .functions .behaviour) root)))))

(define name-resolve (pure-funcq name-resolve))

(define-method (.type (o <port>))
  (name-resolve (parent <root> o) <interface> (.scope+name (.type@ o))))

(define-method (.type (o <instance>))
  (or (name-resolve (parent <root> o) <system> (.scope+name (.type@ o)))
      (name-resolve (parent <root> o) <component> (.scope+name (.type@ o)))
      (name-resolve (parent <root> o) <foreign> (.scope+name (.type@ o)))))

(define-method (contains? container (o <ast>))
  (and (is-a? container <ast>)
       (or (eq? container o)
           (any (lambda (e) (contains? e o)) (om:children container)))))

(define-method (.port (model <component-model>) (o <trigger>))
  (and (.port@ o) (name-resolve model <port> (.port@ o))))

(define-method (.port (model <component-model>) (o <action>))
  (and (.port@ o) (name-resolve model <port> (.port@ o))))

(define-method (.port (o <trigger>))
  (and (.port@ o) (name-resolve (parent <model> o) <port> (.port@ o))))

(define-method (.port (o <action>))
  (and (.port@ o) (name-resolve (parent <model> o) <port> (.port@ o))))

(define-method (.port (o <reply>))
  (and (.port@ o) (name-resolve (parent <model> o) <port> (.port@ o))))

(define-method (.port (o <binding>))
  (if (.instance o)
      (name-resolve (.type (.instance o)) <port> (.port@ o))
      (name-resolve (parent <model> o) <port> (.port@ o))))

(define-method (.function (model <model>) (o <call>))
  (and (.function@ o) (name-resolve model <function> (.function@ o))))

(define-method (.function (o <call>))
  (name-resolve (parent <model> o) <function> (.function@ o)))

(define-method (.variable (o <var>))
  (var? o (.variable@ o)))

(define-method (.variable (o <field-test>))
  (var? o (.variable@ o)))

(define-method (.variable (o <assign>))
  (var? o (.variable@ o)))

(define-method (.variable (o <formal-binding>))
  (var? o (.variable@ o)))

(define (ast-> ast)
  ((compose
    pretty-print
    om->list
    ast:resolve
    parse->om
    ) ast))
