;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
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
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

;; goops --> goeps sed -ri -e "s/[(][$] <([^>]*)>[)]/(\'\1 _ ___)/g" -e "s/[(][$] <([^>]*)> ([a-z]+)[)]/(\'\1 \2 ___)/g" -e "s/[(][$] <([^>]*)> /(\'\1 /g" module/g/resolve.scm
;; goeps --> goops sed -ri -e "s/[(]\' ([a-z]+) _ ___[)]/('\1 _ ___)/g" -e "s/[(]\' ([a-z]+) ([a-z]+) ___[)]/('\1 \2)/g"

(read-set! keywords 'prefix)

(define-module
   (g resolve)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (srfi srfi-1)

  :use-module (language dezyne location)

  :use-module (gaiag annotate)
  :use-module (gaiag misc)
  

   :use-module (g om)
   :use-module (g reader)

  :export (
           ast:resolve
           gom:resolve
           report-errors
           ))

(cond-expand
 (goops-om
  (use-modules (oop goops)))
 (else #t))

(define (ast:resolve o)
  (stderr "ast:resolve: ~a\n" o)
  (match o
    (('root _ ___) (resolve-root o))
    ((h t ...) ((compose gom:resolve ast->om) o))
    ((or ('interface _ ___) ('component _ ___)) ((resolve-model o '()) o))
    (_  o)))

(define (resolve-error o symbol message)
  (make <error> :ast o :message (format #f message symbol)))

(define (undefined-error o identifier)
  (resolve-error o identifier "undefined identifier: ~a"))

(define (type-mismatch o expected actual)
  (make <error> :ast o :message (format #f "type mismatch: ~a expected, found: ~a" expected actual)))

(define (resolve-root o)
  (map gom:register-type (gom:types o))
  (let* ((resolved (make <root>
                     :elements (map resolve-top-model (ast:reorder (.elements o)))))
         (errors (null-is-#f ((gom:collect <error>) resolved))))
    (and=> errors report-errors)
    resolved))

(define gom:resolve resolve-root)

(define (ast:reorder o)
  (stderr "ast:reorder: ~a\n" o)
  (match o
    (('root models) (make <root> :elements (ast:reorder models)))
    ((models ...)
     (stderr "MODELS: ~a\n"     (append
      (filter (is? <import>) models)
      (filter (is? <type>) models)
      (filter (is? <interface>) models)
      (filter (is? <component>) models)
      (filter (is? <system>) models)))
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
     ((compose gom:register-model (lambda (m) ((resolve-model m '()) m))) o))
    (_ ((resolve-model o '()) o))))

(define ((resolve-model model locals) o)
  (match o
    (('system _ ___) o)
    (('type _ ___) o)
    (('import _ ___) o)    
    (_ (retain-source-properties o (resolve-model- model o locals)))))

(define (resolve:import name)
  (gom:import name resolve:gom))

(define (resolve:gom ast)
  ((compose ast:resolve ast->gom ast:public) ast))

(define (type-equal? a b)
  (match (cons a b)
    (((? (is? <enum>)) . (? (is? <type>)))
     (and (or (eq? (.scope a) (.scope b))
              (and (eq? (.scope a) '*global*)
                   (not (.scope b))))
          (eq? (.name a) (.name b))))
    (((? (is? <type>)) . (? (is? <type>)))
     (and (eq? (.scope a) (.scope b))
          (eq? (.name a) (.name b))))
    (((? symbol?) . (? (is? <type>)))
     (and (not (.scope b))
          (eq? a (.name b))))
    (((? symbol?) . (? symbol?))
     (and (not (.scope b))
          (eq? a (.name b))))))

(define (->symbol o)
  (match o
    (('type name #f) name)
    (('type name scope) (symbol-append scope '. name))
    (('value type field)  (symbol-append type '. field))
    (('enum name #f field) name)
    (('enum name scope field)  (symbol-append scope '. name))
    (_ o)))

(define (resolve-model- model o locals)

  (define (enum? identifier) (gom:enum model identifier))
  (define (extern? type) (gom:extern model type))
  (define (event? identifier)
    (and (is-a? model <interface>)
         (not (var? identifier)) (gom:event model identifier)))
  (define (function? identifier) (gom:function model identifier))
  (define (int? identifier) (gom:integer model identifier))
  (define (member? identifier) (gom:variable model identifier))
  (define (port? name) (and (is-a? model <component>) (gom:port model name)))

  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
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
                 (enum (gom:enum model type)))
                (member field (.elements (.fields enum))))))

  (define (type? type) ((gom:type model) type))

  (define (fake:type model o)
    (match o
      (('expression expression ___) (fake:type model expression))
      ('false (make <type> :name 'bool))
      ('true (make <type> :name 'bool))
      (('data _ ___) (make <type> :name 'data))
      ((? number?) (make <type> :name 'int))
      (('literal scope name field)
       (and-let* ((enum (gom:enum model (make <type>
                                          :scope scope
                                          :name name)))
                  ((member field ((compose .elements .fields) enum))))
                 enum))
      (('value type field)
       (and-let* ((enum (gom:enum model (make <type>
                                          :name type)))
                  ((member field ((compose .elements .fields) enum))))
                 enum))
      (_ #f)))

  (match o
    (('var (and (? (negate var?)) (get! identifier)))
     (undefined-error o (identifier)))

    (('assign (and (? (negate var?)) (get! identifier)))
     (undefined-error o (identifier)))

    (('action ('trigger #f
                    (and (? (negate event-or-function?)) (get! identifier))))
     (resolve-error o (identifier) "undefined function or event: ~a"))

    (('call (and (? symbol?) (? (negate event-or-function?)) (get! identifier)))
     (resolve-error o (identifier) "undefined function or event: ~a"))

    (('call identifier ('arguments arguments ___)) (=> failure)
     (let* ((function (function? identifier))
            (parameters ((compose .elements .parameters .signature) function))
            (argument-count (length arguments))
            (parameter-count (length parameters)))
       (if (= argument-count parameter-count)
           (failure)
           (resolve-error o identifier
                          (format #f "function ~a expects ~a arguments, found: ~a" "~a" parameter-count argument-count)))))

    (('variable name (and (? (negate type?)) (get! type)) expression)
     (let* ((scope (.scope (type)))
            (name (.name (type)))
            (name (if scope
                      (symbol-append scope '. name)
                      name)))
      (resolve-error (type) name "undefined type: ~a")))

    (('variable name (and (? (negate extern?)) (get! type)) ('expression (? unspecified?)))
      (resolve-error o name "undefined variable value: ~a"))

    (('variable name type expression) (=> failure)
     (or (and-let* ((e-type (fake:type model expression))
                    ((not (type-equal? e-type type)))
                    ((if (eq? (.name e-type) 'data)
                         (not (gom:extern model type))))
                    ((if (eq? (.name e-type) 'int)
                         (not (gom:integer model type)))))
                   (type-mismatch expression (->symbol type) (->symbol e-type)))
         (failure)))

    ((or 'false 'true) o)
    ((or 'and 'or) o)
    ((or '! '+ '- '/ '*) o)
    ((or '== '!= '< '<= '> '>= 'group) o)

    (('parameter name type direction)
     (make <parameter> :name name :type ((resolve-model model locals) type) :direction direction))

    (('call identifier (and ('arguments _ ___) (get! arguments)))
     (make <call>
       :identifier identifier
       :arguments ((resolve-model model locals) (arguments))))

    (('type (and (? enum?) (get! enum)) #f)
     (make <type> :scope (.scope (enum? (enum))) :name (enum)))
    
    (('type (and (? int?) (get! int)) #f)
     (make <type> :scope (.scope (int? (int))) :name (int)))

    (('event name signature direction)
     (make <event>
       :name name
       :direction direction
       :signature ((resolve-model model '()) signature)))

    (('action _ ___) o)
    (('call _ ___) o)    
    (('data _ ___) o)
    (('enum _ ___) o)
    (('event _ ___) o)
    (('extern _ ___) o)    
    (('field _ ___) o)
    (('illegal _ ___) o)
    (('int _ ___) o)
    (('literal _ ___) o)
    (('otherwise _ ___) o)
    (('port _ ___) o)
    (('signature _ ___) o)
    (('trigger _ ___) o)
    (('triggers _ ___) o)    
    (('type _ ___) o)
    (('var _ ___) o)

    ((? symbol?) (undefined-error #f o))

    (('action ('trigger #f (and (? function?) (get! identifier))))
     (make <call> :identifier (identifier)))

    (('action _ ___) o)

    (('assign identifier
        ('expression ('call (and (? event?) (get! event)))))
     (make <assign>
       :identifier identifier
       :expression (make <action> :trigger (make <trigger> :event (event)))))

    (('assign identifier ('expression (and ('call _ ___) (get! call))))
     (make <assign> :identifier identifier
           :expression ((resolve-model model locals) (call))))

    (('assign identifier
        ('expression ('var (and (? event?) (get! event)))))
     (make <assign>
       :identifier identifier
       :expression (make <action> :trigger (make <trigger> :event (event)))))

    (('assign identifier
        ('expression ('var (and (? function?) (get! function)))))
     (make <assign>
       :identifier identifier
       :expression (make <call> :identifier (function))))

    (('assign identifier
        ('expression ('value (and (? port?) (get! port)) event)))
     (make <assign>
       :identifier identifier
       :expression (make <action>
                     :trigger (make <trigger> :port (port) :event event))))

    (('assign identifier ('expression (and ('action _ ___) (get! action))))
     (make <assign>
       :identifier identifier
       :expression ((resolve-model model locals) (action))))

    (('assign identifier
        ('expression ('var (and (? function?) (get! function)))))
     (make <assign>
       :identifier identifier
       :expression (make <call> :identifier (function))))

    (('assign identifier (and ('expression _ ___) (get! expression)))
     (make <assign>
       :identifier identifier
       :expression ((resolve-model model locals) (expression))))

    (('assign identifier expression)
     (make <assign>
       :identifier identifier
       :expression ((resolve-model model locals) expression)))

    (('variable name type
        ('expression ('call (and (? event?) (get! event)))))
     (make <variable>
       :type ((resolve-model model locals) type)
       :name name
       :expression (make <action> :trigger
                         (make <trigger> :event (event)))))

    (('variable name type ('expression (and ('call _ ___) (get! call))))
     (make <variable>
       :type ((resolve-model model locals) type)
       :name name
       :expression ((resolve-model model locals) (call))))

    (('variable name type
        ('expression ('var (and (? event?) (get! event)))))
     (make <variable>
       :type ((resolve-model model locals) type)
       :name name
       :expression (make <action> :trigger
                         (make <trigger> :event (event)))))

    (('variable name type ('expression (and ('action _ ___) (get! action))))
     (make <variable>
       :type ((resolve-model model locals) type)
       :name name
       :expression ((resolve-model model locals) (action))))

    (('variable name type ('expression ('value (and (? port?) (get! port)) event)))
     (make <variable>
       :type ((resolve-model model locals) type)
       :name name
       :expression (make <action> :trigger (make <trigger> :port (port) :event event))))

    (('variable name type
        ('expression ('var (and (? function?) (get! function)))))
     (make <variable>
       :type ((resolve-model model locals) type)
       :name name
       :expression (make <call> :identifier (function))))

    (('variable name type expression)
     (make <variable>
       :type ((resolve-model model locals) type)
       :name name
       :expression ((resolve-model model locals) expression)))

    (('value (and (? enum?) (get! enum))
        (and (? (enum-field? (enum))) (get! field)))
     (make <literal> :scope (.scope (enum? (enum))) :type (enum) :field (field)))

    (('value (and (? var?) (get! type)) (? (member-field? (type))))
     (make <field> :identifier (type) :field (.field o)))    

    (('value (? enum?) field)
     (resolve-error o field "undefined enum field: ~a"))

    (('value (? var?) field)
     (resolve-error o field "undefined enum field: ~a"))

    (
      ;;('expression value ___)
      ('expression value)
     (make <expression> :value ((resolve-model model locals) value)))

    (('function name ('signature type ('parameters)) recursive? statement)
     (make <function>
       :name name
       :signature ((resolve-model model locals) (.signature o))
       :recursive (and ((recurses? model) name) 'recursive)
       :statement ((resolve-model model '()) statement)))

    (('function name ('signature type ('parameters parameters ___)) recursive? statement)
     (let ((locals (let loop ((parameters parameters) (locals locals))
                     (if (null? parameters)
                         locals
                         (loop (cdr parameters)
                               (acons (.name (car parameters)) (car parameters) locals))))))
       (make <function>
         :name name
         :signature ((resolve-model model locals) (.signature o))
         :recursive (and ((recurses? model) name) 'recursive)
         :statement ((resolve-model model locals) statement))))

    ;; no parameters... ugh?
    (('function name ('signature type ___) recursive? statement)
     (make <function>
       :name name
       :signature ((resolve-model model locals) (.signature o))
       :recursive (and ((recurses? model) name) 'recursive)
       :statement ((resolve-model model '()) statement)))

    (('compoundx statements)
     (make <compound>
       :elements
       (let loop ((statements statements) (locals locals))
         (if (null? statements)
             '()
             (let* ((statement (car statements))
                    (locals (match statement
                              (('variable name type expression)
                               (acons name statement locals))
                              (_ locals))))
               (let ((resolved ((resolve-model model locals) (car statements))))
                 (cons resolved (loop (cdr statements) locals))))))))

    (('guard expression statement)
       (make <guard>
         :expression ((resolve-model model '()) expression)
         :statement ((resolve-model model locals) statement)))

    (('on triggers statement)
     (let* ((parameters (apply append (map (compose .elements .arguments)
                                           (.elements triggers))))
            (locals (let loop ((parameters parameters) (locals locals))
                      (if (null? parameters)
                          locals
                          (loop (cdr parameters)
                                (acons ((compose .name .value car) parameters) (car parameters) locals))))))
       (make <on>
         :triggers ((resolve-model model '()) triggers)
         :statement ((resolve-model model locals) statement))))

    (('interface name types events behaviour)
     (make <interface>
       :name name
       :types types
       :events (gom:map (resolve-model model '()) events)
       :behaviour ((resolve-model model '()) behaviour)))

    (('component name ports behaviour)
       (make <component>
         :name name
         :ports ports
         :behaviour ((resolve-model model '()) behaviour)))

    (('component name ports) o)    

    (('behaviour name types variables functions statement)
     (make <behaviour>
       :name name
       :types types
       :variables ((resolve-model model '()) variables)
       :functions (gom:map (resolve-model model '()) functions)
       :statement (gom:map (resolve-model model '()) statement)))

    (('functions functions)
     (make <functions> :elements (map (resolve-model model '()) functions)))

    (('variables variables)
     (stderr "variables: o:~a\n" o)
     (stderr "variables: v:~a\n" variables)     
     (let ((variables (map (range-check model) variables)))
       (make <variables> :elements (map (resolve-model model '()) variables))))

    ((? (is? <ast>)) (gom:map (lambda (o) ((resolve-model model locals) o)) o))
    ((h t ...) (map (lambda (o) ((resolve-model model locals) o)) o))
    (_ o)))

(define ((range-check model) variable)
  (define (int-type? type) (gom:integer model type))
  (stderr "TYPES: ~a\n" (gom:types model))
  (stderr "VAR: ~a\n" variable)
  (or (and-let* ((int (int-type? (.type variable)))
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
  (define (member? identifier) (gom:variable model identifier))
  (match o
    (('expression expression ___) (evaluate model expression))
    ((? number?) o)
    (('+ a b) (+ (evaluate model a) (evaluate model b)))
    (('- a b) (- (evaluate model a) (evaluate model b)))
    (('* a b) (* (evaluate model a) (evaluate model b)))
    (('/ a b) (/ (evaluate model a) (evaluate model b)))
    (('var name ___) (evaluate model (.expression (member? name))))
    (('group g) g)))

(define* ((recurses? model :optional (seen '())) name)
  (define (return-call ast)
    (match ast
      (('call _ ___) ast)
      (('assign name (and ('call _ ___) (get! call))) (call))
      (('variable name type (and ('call _ ___) (get! call))) (call))
      (_ #f)))
  (and-let* ((function (gom:function model name))
             (compound (.statement function))
             (calls (null-is-#f ((gom:collect return-call) compound)))
             (names (delete-duplicates (sort (map
                                              (compose .identifier return-call)
                                              calls) symbol<))))
            (or (member name seen)
                (any identity
                     (map (recurses? model (cons name seen)) names)))))

(define (ast-> ast)
  ((compose gom->list ast:resolve ast->gom ast->annotate) ast))
