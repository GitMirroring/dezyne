;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
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

(define-module (gaiag resolve)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (srfi srfi-1)

  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :use-module (oop goops)
  :use-module (gaiag gom)

  :export (
           ast->
           ast:resolve
           gom:resolve
           ))

(define-method (ast:resolve (o <list>))
  ((compose gom:resolve ast->gom) o))

(define-method (ast:resolve (o <root>))
  (gom:resolve o))

(define-method (ast:resolve (o <model>))
  (resolve-model o o))

(define-method (ast:resolve (o <ast>))
  o)

(define-method (gom:resolve (o <root>))
  (make <root> :elements (map resolve-top-model (.elements o))))

(define-method (resolve-top-model (o <model>))
  ((compose gom:register-model (lambda (m) (resolve-model m m)) resolve-mixed) o))

(define-method (resolve-top-model (o <ast>))
  (resolve-model o o))

(define (resolve-mixed o)
  (match o
    (($ <component> name ports behaviour)
     (let ((cache-interfaces (map resolve:import (map .type ((compose .elements .ports) o)))))
       (make <component>
         :name name
         :ports ports
         :behaviour (resolve-mixed behaviour))))
    (($ <interface> name ($ <types> types) ($ <events> types-events) behaviour)
     (receive (types- events) (partition (lambda (x)
                                           (or (is-a? x <enum>) (is-a? x <int>))) types-events)
       (make <interface>
         :name name
         :types (make <types> :elements (append types types-))
         :events (make <events> :elements events)
         :behaviour (resolve-mixed behaviour))))

    (($ <behaviour> name types variables ($ <functions> functions) ($ <compound> mixed))
     (receive (functions- statements) (partition (is? <function>) mixed)
       (make <behaviour>
         :name name
         :types types
         :variables variables
         :functions (make <functions> :elements (append functions functions-))
         :statement (make <compound> :elements statements))))
    (_ o)))

(define-method (resolve-model (model <model>))
  (lambda (o) (resolve-model model o)))

(define-method (resolve-model (model <imports>) (o <imports>))
  o)

(define-method (resolve-model (model <model>) o)
  (resolve-model model o '()))

(define-method (resolve-model (model <model>) o locals)
  (let ((resolved (resolve-model- model o locals)))
    (and-let* (((supports-source-properties? o))
               (loc (source-property o 'loc))
               ((supports-source-properties? resolved)))
              (set-source-property! resolved 'loc loc))
    resolved))

(define (resolve:import name)
  (gom:import name resolve:gom))

(define (resolve:gom ast)
  ((compose ast:resolve ast->gom) ast))

(define-method (type-equal? (a <type>) (b <type>))
  (and (eq? (.scope a) (.scope b))
       (eq? (.name a) (.name b))))

(define-method (type-equal? (a <symbol>) (b <type>))
  (and (not (.scope b))
       (eq? a (.name b))))

(define-method (type-equal? (a <symbol>) (b <symbol>))
  (eq? a b))

(define-method (resolve-model- (model <model>) o locals)

  (define (interface-enums port)
    (map (lambda (enum)
           (make <enum>
             :name (make <type> :name (.name enum) :scope (.type port))
             :fields (.fields enum)))
         ((compose gom:enums resolve:import .type) port)))

  (define (port? port)
    (if (is-a? model <interface>)
        #f
        (member port (map .name (.elements (.ports model))))))

  (define (enum? identifier)
    (member identifier (map .name (gom:enums model))))

  (define (function? identifier)
    (member identifier (gom:function-names model)))

  (define (enum-field? identifier)
    (lambda (field)
      (and-let* ((enum (find (lambda (x) (eq? (.name x) identifier))
                             (gom:enums model))))
                (member field (.elements (.fields enum))))))

  (define (member-field? identifier)
    (lambda (field)
      (and-let* ((variable (or (gom:variable model identifier)
                               (gom:variable (map cdr locals) identifier)))
                 (type (.type variable))
                 (enums (append
                         (gom:enums model)
                         (apply append
                                (if (is-a? model <component>) (map interface-enums (.elements (.ports model))) '()))))
                 (enum (find (lambda (enum)
                               (type-equal? (.name enum) type)) enums)))
                (member field (.elements (.fields enum))))))

  (define (member? identifier)
    (find (lambda (m) (eq? (.name m) identifier)) (gom:variables model)))

  (define (local? identifier) (assoc-ref locals identifier))

  (define (var? identifier) (or (member? identifier) (local? identifier)))

  (match o
    (($ <action> (and (? (lambda (i) (member i (gom:function-names model))))
                      (get! identifier)))
     (make <call> :identifier (identifier)))

    (($ <assign> identifier ($ <expression> (and ($ <call>) (get! call))))
     (make <assign> :identifier identifier
           :expression (resolve-model model (call) locals)))

    (($ <assign> identifier
        ($ <expression> ($ <value> (and (? port?) (get! port)) event)))
     (make <assign>
       :identifier identifier
       :expression (make <action>
                     :trigger (make <trigger> :port (port) :event event))))

    (($ <assign> identifier
        ($ <expression> (and (? function?) (get! function))))
     (make <assign>
       :identifier identifier
       :expression (make <call> :identifier (function))))

    (($ <assign> identifier (and ($ <expression>) (get! expression)))
     (make <assign>
       :identifier identifier
       :expression (resolve-model model (expression) locals)))

    (($ <assign> identifier expression)
     (make <assign>
       :identifier identifier
       :expression (resolve-model model expression locals)))

    (($ <variable> name type ($ <expression> (and ($ <call>) (get! call))))
     (make <variable>
       :type type
       :name name
       :expression (resolve-model model (call) locals)))

    (($ <variable> name type
        ($ <expression> ($ <value> (and (? port?) (get! port)) event)))
     (make <variable>
       :type type
       :name name
       :expression (make <action> :trigger
                         (make <trigger> :port (port) :event event))))

    (($ <variable> name type ($ <expression> (and (? function?) (get! function))))
     (make <variable>
       :type type
       :name name
       :expression (make <call> :identifier (function))))

    (($ <variable> name type expression)
     (make <variable>
       :type type
       :name name
       :expression (resolve-model model expression locals)))

    (($ <value> (and (? enum?) (get! enum))
        (and (? (enum-field? (enum))) (get! field)))
     (make <literal> :scope #f' :type (enum) :field (field)))

    (($ <value> (and (? var?) (get! type)) (? (member-field? (type))))
     (make <field> :identifier (type) :field (.field o)))

    (($ <expression> value)
     (make <expression> :value (resolve-model model value locals)))

    ((and (? symbol?) (? var?)) (make <var> :name o))

    (($ <function> name ($ <signature> type ($ <parameters> '())) recursive? statement)
     (make <function>
       :name name
       :signature (.signature o)
       :recursive (and ((recurses? model) name) 'recursive)
       :statement (resolve-model model statement)))

    (($ <function> name ($ <signature> type ($ <parameters> parameters)) recursive? statement)
     (let ((locals (let loop ((parameters parameters) (locals locals))
                     (if (null? parameters)
                         locals
                         (loop (cdr parameters)
                               (acons (.name (car parameters)) (car parameters) locals))))))
       (make <function>
         :name name
         :signature (.signature o)
         :recursive (and ((recurses? model) name) 'recursive)
         :statement (resolve-model model statement locals))))

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
               (let ((resolved (resolve-model model (car statements) locals)))
                 (cons resolved (loop (cdr statements) locals))))))))

    (($ <field>) o)
    (($ <var>) o)

    (($ <interface> name ($ <types> types) ($ <events> types-events) behaviour)
     (receive (types- events) (partition (lambda (x)
                                           (or (is-a? x <enum>) (is-a? x <int>))) types-events)
       (make <interface>
         :name name
         :types (make <types> :elements (append types types-))
         :events (make <events> :elements events)
         :behaviour (gom:map (resolve-model model) behaviour))))


    (($ <behaviour> name types variables ($ <functions> functions) ($ <compound> mixed))
     (receive (functions- statements) (partition (is? <function>) mixed)
       (make <behaviour>
         :name name
         :types types
         :variables (gom:map (resolve-model model) variables)
         :functions (gom:map (resolve-model model) (make <functions> :elements (append functions functions-)))
         :statement (gom:map (resolve-model model) (make <compound> :elements statements)))))

    ((? (is? <ast>)) (gom:map (lambda (o) (resolve-model model o locals)) o))
    ((h t ...) (map (lambda (o) (resolve-model model o locals)) o))
    (_ o)))

(define* ((recurses? model :optional (seen '())) name)
  (define (return-call ast)
    (match ast
      (($ <call>) ast)
      (($ <assign> name (and ($ <call>) (get! call))) (call))
      (($ <variable> name type (and ($ <call> body) (get! call))) (call))
      (_ #f)))
  (and-let* ((function (gom:function model name))
             (compound (.statement function))
             (calls (null-is-#f (gom:collect return-call compound)))
             (names (delete-duplicates (sort (map .identifier calls) symbol<))))
            (or (member name seen)
                (any identity
                     (map (recurses? model (cons name seen)) names)))))

(define-method (resolve-model (model <system>) o)

  (let ((binding (lambda (o)
                   (match o
                     ((? symbol?) (make <binding> :instance #f :port o))
                     (($ <value> instance port) (make <binding> :instance instance :port port))
                     (($ <binding>) o)
                     (_ o)))))

    (match o

      (($ <system> name ports instances bindings)
       (let* ((instances (gom:map (resolve-model model) instances))
              (bindings (gom:map (resolve-model model) bindings))
              (rinstances (append (gom:collect <instance> instances)
                                  (gom:collect <instance> bindings)))
              (rbindings  (append (gom:collect <bind> instances)
                                  (gom:collect <bind> bindings))))
         (make <system>
           :name name
           :ports ports
           :instances (make <instances> :elements rinstances)
           :bindings (make <bindings> :elements rbindings))))

      (($ <bind> left right)
       (make <bind> :left (binding left) :right (binding right)))

      ((? (is? <ast>)) (gom:map (resolve-model model) o))
      ((h t ...) (map (resolve-model model) o))

      (_ o))))

(define (ast-> ast)
  ((compose gom->list ast:resolve ast->gom) ast))
