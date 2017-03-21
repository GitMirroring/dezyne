;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
;;; Copyright © 2015, 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag om)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)

  #:use-module (system foreign)
  #:use-module (language dezyne location)

  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast2om)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)
  #:use-module (gaiag resolve)

  #:use-module (gaiag annotate)
  #:use-module (gaiag macros)
  #:use-module (gaiag misc)
  #:use-module (gaiag reader)

  #:export (
           om:port*


           om:bind
           om:bind-other-port
           om:binding
           om:bindings
           om:binding-other
           om:binding-other-port
           om:blocking?
           om:instance-name
           om:collect
           om:component
           om:declarative?
           om:dir-matches?
           om:enum
           om:enums
           om:event
           om:events
           om:expression?
           om:extern
           om:filter:p
           om:find-triggers
           om:function
           om:functions
           om:imperative?
           om:import
           om:imported?
           om:in?
           om:integers
           om:instance
           om:instances
           om:instance-name
           om:instance-binding?
           om:interface-enums
           om:integer
           om:interface
           om:interface-types
           om:interfaces
           om:modeling?
           om:model-with-behaviour
           om:name
           om:named
           om:operator?
           om:out-formals
           om:out-or-inout?
           om:out?
           om:outer-scope?
           om:parent
           om:parse-dzn
           om:port
           om:port-event
           om:ports
           om:port-bind
           om:port-bind?
           om:port-binding?
           om:public-types
           om:provided
           om:provides?
           om:register
           om:register-model
           om:register-type
           om:reply-enums
           om:reply-types
           om:required
           om:requires?
           om:scope
           om:scope+name
           om:scope-join ;; JUNKME
           om:scope-name
           om:type
           om:type-name
           om:typed?
           om:types
           om:variable
           om:variables
           om:void?
           ))

(define (deprecated . where)
  (stderr "DEPRECATED:~a\n" where))

;;; AST-LIST shorthands
(define* (om:events- o #:optional (predicate? identity))
  (filter predicate?
          (match o
            (($ <interface>) ((compose .elements .events) o))
            (($ <port>) ((compose om:events om:import .type) o)))))

(define om:events (pure-funcq om:events-))

(define* (om:enums #:optional (model #f))
  (filter (is? <enum>) (om:types model)))

(define* (om:externs #:optional (model #f))
  (filter (is? <extern>) (om:types model)))

(define* (om:integers #:optional (model #f))
  (filter (is? <int>) (om:types model)))


;;; list lookup

;; WIP
(define-method (om:argument* (o <arguments>)) (.elements o))
(define-method (om:binding* (o <bindings>)) (.elements o))
(define-method (om:statement* (o <compound>)) (.elements o))
(define-method (om:event* (o <events>)) (.elements o))
(define-method (om:field* (o <fields>)) (.elements o))
(define-method (om:formal* (o <formals>)) (.elements o))
(define-method (om:function* (o <functions>)) (.elements o))
(define-method (om:instance* (o <instances>)) (.elements o))
(define-method (om:port* (o <ports>)) (.elements o))
(define-method (om:model* (o <root>)) (.elements o))
(define-method (om:trigger* (o <triggers>)) (.elements o))
(define-method (om:type* (o <types>)) (.elements o))
(define-method (om:variable* (o <variables>)) (.elements o))

(define-method (om:argument* (o <trigger>)) ((compose om:argument* .arguments) o))
(define-method (om:binding* (o <system>)) ((compose om:binding* .bindings) o))
(define-method (om:function* (o <behaviour>)) ((compose om:function* .functions) o))
(define-method (om:statement* (o <behaviour>)) ((compose om:statement* .statement) o))


(define (om:bindings o)
  (match o
    (($ <system>) ((compose .elements .bindings) o))))

(define (om:functions model)
  ((compose .elements .functions .behaviour) model))

(define (om:instances o)
  (match o
    (($ <interface>) '())
    (($ <component>) o)
    (($ <system>) ((compose .elements .instances) o))))

(define (om:ports- o)
  (match o
    (($ <interface>) '())
    (($ <component> name ($ <ports> (ports ...))) ports)
    (($ <behaviour> name types ($ <ports> (ports ...))) ports)
    (($ <system> name ($ <ports> (ports ...))) ports)))

(define om:ports (pure-funcq om:ports-))

(define* (om:types #:optional (model #f))
  (append
   (match model
     (($ <root> (models ...)) (filter (is? <*type*>) models))
     (($ <behaviour> b types) (.elements types))
     (($ <interface> name types events ($ <behaviour> b btypes)) (append (.elements btypes) (.elements types)))
     (($ <component> name ports ($ <behaviour> b btypes))
      (append (.elements btypes) (om:interface-types model)))
     (($ <component> name ports) (om:interface-types model))
     (($ <system> name ports) (om:interface-types model))
     (($ <import> name) '())
     (#f '())
     ((? unspecified?) '()))
   (globals)))

(define-method (om:variables (o <model>))
  (match o
    (($ <system>) '())
    ((= .behaviour #f) '())
    (_ ((compose .elements .variables .behaviour) o))))




(define (om:provided o)
  (filter om:provides? (om:ports o)))

(define (om:required o)
  (filter om:requires? (om:ports o)))


(define (om:interface-enums o)
  (match o
    (($ <interface>) (om:filter (is? <enum>) (.types o)))
    (($ <port>) (om:enums o))
    (($ <component>)
     (append-map om:interface-enums ((compose .elements .ports) o)))
    (($ <system>)
     (append-map om:interface-enums ((compose .elements .ports) o)))))


;;; SINGLE-LOOKUP

;; FIXME -- whut?
;; (define (om:event model o)
;;   (find (om:named o) (om:events model)))

(define (om:enum model identifier)
  (as ((om:type model) identifier) <enum>))
(define (om:extern model identifier)
  (as ((om:type model) identifier) <extern>))
(define (om:integer model identifier)
  (as ((om:type model) identifier) <int>))

(define (om:event o trigger)
  (match (cons o trigger)
    ((($ <port>) . (? symbol?))
     (find (lambda (x) (eq? (.name x) trigger)) (om:events o)))
    ((($ <interface>) . (? symbol?))
     (find (lambda (x) (eq? (.name x) trigger)) (.elements (.events o))))
    ((($ <interface>)  . (? (is? <trigger>)))
     (if (not (as (.event trigger) <event>)) (om:event o (.event trigger))
         (.event trigger)))
    ((($ <component>)  . (? (is? <trigger>)))
     (if (not (as (.event trigger) <event>)) (om:event (om:interface (.port trigger)) (.event trigger))
         (.event trigger)))
    (_ #f)))

(define (om:function model o)
  (find (om:named o) (om:functions model)))

(define (om:instance model o)
  (match o
    ((? symbol?)
     (find (lambda (x) (eq? (.name x) o)) ((compose .elements .instances) model)))
    (($ <binding>) (or (om:instance model (.instance o))
                       (om:import (.type (om:port model (.port bind))))))
    (($ <bind>) (om:instance model (om:instance-binding? o)))
    (($ <port>) (om:instance model (om:instance-binding? (om:port-bind model (.name o)))))
    ((? boolean?) #f)))

(define (om:port-bind? bind)
  (and (om:port-binding? bind)
       bind))

(define (om:port-binding? bind)
  (or (and (not (.instance (.left bind)))
           (.left bind))
      (and (not (.instance (.right  bind)))
           (.right bind))))

(define (om:instance-binding? bind)
  (or (and (not (.instance (.left bind)))
           (.right bind))
      (and (not (.instance (.right  bind)))
           (.left bind))))

(define (om:port-bind system o)
  (match o
    ((? symbol?)
     (find (lambda (bind) (and=> (om:port-bind? bind)
                                 (lambda (b)
                                   (eq? (.port (om:port-binding? b)) o))))
           ((compose .elements .bindings) system)))
    (($ <port>) (om:port-bind system (.name o)))))

(define (om:bind system o)
  (let* ((binds ((compose .elements .bindings) system)))
    (match o
      ((? symbol?) ;; FIXME: port need not be unique
       (deprecated (current-source-location))
       (find (lambda (bind) (or (eq? (.port (.left bind)) o)
                                (eq? (.port (.right bind)) o)))
           binds))
      (($ <binding> instance port)
       (find (lambda (bind)
               (or (and (eq? (.instance (.left bind)) instance)
                                     (eq? (.port (.left bind)) port))
                                (and (eq? (.instance (.right bind)) instance)
                                     (eq? (.port (.right bind)) port))))
             binds)))))

(define (om:bind-other-port bind port) ;; FIXME: port need not be unique
  (deprecated (current-source-location))
  (if (eq? (.port (.left bind)) port) (.right bind) (.left bind)))

(define (om:binding system o)
  (match o
    ((? symbol?)
     (deprecated (current-source-location))
     (let ((bind (om:bind system o)))
       (if (eq? (.port (.left bind)) o) (.left bind) (.right bind))))
    (($ <binding> instance port)
     (let ((bind (om:bind system o)))
       (and bind
            (if (and (eq? (.instance (.left bind)) instance)
                     (eq? (.port (.left bind)) port)) (.left bind)
                     (.right bind)))))))

(define (om:binding-other-port system port) ;; FIXME: port need not be unique
  (deprecated (current-source-location))
  (let* ((bind (om:bind system port)))
    (om:bind-other-port bind port)))

(define (om:binding-other system binding)
  (let ((bind (om:bind system binding)))
    (if (and (eq? (.instance (.left bind)) (.instance binding))
             (eq? (.port (.left bind)) (.port binding)))
        (.right bind)
        (.left bind))))

(define (om:instance-name bind)
  (or (.instance (.left bind)) (.instance (.right bind))))

(define* (om:component system #:optional o)
  (match o
    (#f (match system
          (($ <component>) system)
          (($ <root>) (om:find (is? <component>) system))
          (_ #f)))
    ((? symbol?) (om:component system (om:instance system o)))
    (($ <binding> #f port)
     ;;#f
     ;;(om:component system (om:binding-other-port system port))
     (let* ((bind (om:bind system port))
            (instance (om:instance-name bind)))
       (om:component system instance)))
    (($ <binding> instance port) (om:component system instance))
    (($ <bind>) (om:component system (om:instance-name o)))
    (($ <instance> name type) (om:import type))
    (($ <port> name type) (om:import type))))

(define (om:interface o)
  (match o
    (($ <port>) (om:import (.type o)))
    (($ <interface>) o)
    ((? (is? <model>)) (om:interface (om:port o)))
    (($ <scope.name>) (cached-model o))
    (($ <root>) (om:find (is? <interface>) o))
    ((h t ...) (find (is? <interface>) o))))

(define* (om:port model #:optional (o #f))
  (match o
    (($ <binding>)
     (let* ((port (.port o)))
       (or
        (and-let* ((name (.instance o))
                   (instance (om:instance model name))
                   (type (and=> instance .type))
                   (component (om:import type)))
                  (om:port component port))
        (om:port model port))))
    (_ (find (if o (om:named o)
                 (lambda (x) (eq? (.direction x) 'provides)))
             (append (.elements (.ports model))
                     (if (and (is-a? model <component>) (.behaviour model))
                         (.elements (.ports (.behaviour model)))
                         '()))))))

(define (om:variable model o)
  (find (om:named o) (om:variables model)))

(define (unspecified? x) (eq? x *unspecified*))

;;; TYPES

(define (om:type-name o)
  (match o
    (($ <enum>) 'enum)
    (($ <extern>) ((->symbol-join '_) (om:scope+name o)))
    (($ <int>) 'int)
    (($ <type> 'bool) 'bool)
    (($ <type> 'void) 'void)))

(define ((om:type model) o)
  (match o
    ((? symbol?) (find (om:named (make <scope.name> #:scope (om:scope+name model) #:name o)) (om:types model)))
    (($ <type> 'bool) o)
    (($ <type> 'void) o)
    (($ <type> name)
     (or (find (om:named name) (om:types model))
         (find (om:scoped (om:scope+name model) name) (om:types))))
    (($ <variable> name type expression) ((om:type model) type))
    (($ <formal> name type) ((om:type model) type))
    (($ <formal> name type direction) ((om:type model) type))))

(define ((om:named name) ast)
  ;;(stderr "\nom:named[~a]: ~a" name ast)
  (match name
    ((? symbol?) (or (eq? name (.name ast)) ((om:named (make <scope.name> #:name name)) ast)))
    (_ (equal? (.name ast) name))))

(define ((om:scoped scope name) ast)
  (let ((r ((om:scoped- scope name) ast)))
    ;;(stderr "\nom:scoped[~a, ~a]: ~a ==> ~a\n" scope name ast r)
    r))

(define ((om:scoped- scope name) ast)
  (if (null? (om:scope name)) (eq? (om:name ast) (om:name name))
      (equal? (append scope (om:scope+name ast)) (om:scope+name name))))

;;; NAME/NAMESPACE/SCOPE
(define (om:scope+name o)
  ;;(stderr "om:scope+name o=~a\n" o)
  (match o
    (($ <scope.name>) (append (.scope o) (list (.name o))))
    (($ <instance> x name) (om:scope+name name))
    (($ <port> x name) (om:scope+name name))
    (($ <type> 'bool) '(bool))
    (($ <type> 'void) '(void))
    ((? (is? <scoped>)) ((compose om:scope+name .name) o))))

(define* ((om:scope-name #:optional (infix '_)) o)
  (let ((infix (if (symbol? infix) infix
                   (string->symbol infix))))
    ((->symbol-join infix) (om:scope+name o))))

(define (om:outer-scope? model o) ;; FIXME
  (let ((model-scope (om:scope+name model)))
    (and
     (>1 (length o)) ;; huh?
     (not (and
           (>= (length o) (length model-scope))
           (equal? model-scope (list-head o (length model-scope))))))))

(define* ((om:scope-join #:optional (model #f) (infix '_)) o)
  (define (global-scope?)
    (and model (>1 (length o))
         (not (eq? ((compose car om:scope+name) model) (car o)))))
  (let* ((infix (if (symbol? infix) infix
		    (string->symbol infix)))
         (scope (if (not model) o
                    (if (global-scope?) (cons null-symbol o)
                        (drop-prefix (om:scope+name model) o)))))
    ((->symbol-join infix) scope)))

(define (om:name o)
  ((compose last om:scope+name) o))

(define (om:scope o)
  (drop-right (om:scope+name o) 1))

;;; UTILITIES

(define (om:blocking? o)
  (match o
    (($ <component>)
     (and-let* ((behaviour (.behaviour o))
                (blocking ((om:collect <blocking>) behaviour)))
       (pair? blocking)))
    (_ #f)))

(define ((collect predicate) o)
  (match o
    ((? (compose null-is-#f predicate)) (list o))
    (($ <compound> (statements ...))
     (filter identity (apply append (map (collect predicate) statements))))
    (($ <blocking> s) (filter identity ((collect predicate) s)))
    (($ <guard> e s) (filter identity ((collect predicate) s)))
    (($ <on> t s) (filter identity ((collect predicate) s)))
    (($ <if> e t f) (append (filter identity ((collect predicate) t))
                            (filter identity ((collect predicate) f))))
    ;; FIXME: recurse through whole AST
    (($ <interface> name types events behaviour) (filter identity ((collect predicate) behaviour)))
    (($ <component> name ports behaviour) (filter identity ((collect predicate) behaviour)))
    (($ <behaviour> name types ports variables functions statement) (filter identity ((collect predicate) statement)))
    ((h t ...)
     (filter identity (apply append (map (collect predicate) o))))
    (_ '())))

(define ((om:collect x) o)
  (match x
    ((? procedure?) ((collect x) o))
    (_ ((collect (is? x)) o))))

(define ((om:filter:p x) o)
  (let ((filter (if (is-a? o <ast>) om:filter filter)))
    (match x
      (symbol? (filter (is? x) o))
      (procedure? (filter x o)))))

(define* (om:find-triggers ast #:optional (found '()))
  (match ast
    ((or ($ <interface>) ($ <component>))
     (or (and=> (.behaviour ast) om:find-triggers) '()))
    (($ <behaviour>) (or (and=> (.statement ast) om:find-triggers) '()))
    (($ <compound> (statements ...))
     (delete-duplicates (sort (append (apply append (map om:find-triggers statements))) om:<)))
    (($ <blocking>) (om:find-triggers (.statement ast) found))
    (($ <on>) (om:find-triggers (.triggers ast)))
    (($ <triggers> (triggers ...)) triggers)
    (($ <guard>) (om:find-triggers (.statement ast) found))
    (($ <system>) (append-map om:find-triggers (map (lambda (i) (om:component ast i)) (om:instances ast))))
    (_ '())))

(define (om:interface-types o)
  ;;(stderr "om:interface-types o=~a\n" o)
  (match o
    (($ <interface>) (om:public-types o))
    (($ <port>) ((compose om:public-types om:import .type) o))
    ((? (is? <model>)) (append-map om:interface-types (om:ports o)))))

(define (om:public-types o)
  ;;(stderr "PUBLIC[~a]: ~a\n" (.name o) ((compose .elements .types) o))
  (match o
    ((? (is? <interface>)) ((compose .elements .types) o))
    (_ '())))

(define (om:reply-enums o)
  (filter (is? <enum>) (om:reply-types o)))

(define (om:reply-types o)
  (match o
    (($ <interface>)
     (let* ((events (filter om:typed? (om:events o)))
            (types (delete-duplicates (map (compose .type .signature) events))))
       (filter-map (om:type o) types)))
    (($ <component>)
     (delete-duplicates (append-map (compose om:reply-types om:import .type) ((compose .elements .ports) o))))
    (_ '())))

(define (om:out-formals o)
  (match o
    (($ <interface>)
     (filter om:out-or-inout? (append-map (compose .elements .formals .signature) (om:events o))))
    (_ '())))

(define* (om:typed? o #:optional (trigger #f))
  (if trigger
      (om:typed? (om:event o trigger))
      (match o
        (($ <event>)
         (let ((type ((compose .type .signature) o)))
           (and (not (eq? (.name type) 'void)) type)))
        ((? (is? <modeling-event>)) #f)
        ((? boolean?) #f))))


(define (om:declarative? o)
  (or (and (is-a? o <statement>)
           (or (as o <bind>)
               (as o <binding>)
               (as o <blocking>)
               (as o <guard>)
               (as o <instance>)
               (as o <on>)
               (and (is-a? o <compound>)
                    (>0 (length (.elements o)))
                    (om:declarative? (car (.elements o))))))
      (and (pair? o)
           (om:declarative? (car o)))))

(define (om:imperative? o)
  (and (is-a? o <statement>)
       (not (om:declarative? o))))

;; JUNK ME
(define (om:models-with-behaviour o)
  (filter .behaviour (append (om:filter (is? <component>) o)
                             (om:filter (is? <interface>) o))))

(define (om:model-with-behaviour o)
  (and-let* ((models (null-is-#f (om:models-with-behaviour o))))
            (car models)))

(define (om:in? o)
  (match o
    (($ <event>) (eq? (.direction o) 'in))
    ((? (is? <modeling-event>)) #t)
    (($ <formal>) (or (eq? (.direction o) 'in) (not (.direction o))))
    (($ <trigger>) #t)))

(define (om:out? o)
  (match o
    (($ <event>) (eq? (.direction o) 'out))
    ((? (is? <modeling-event>)) #f)
    (($ <formal>) (eq? (.direction o) 'out))
    (($ <trigger>) #f)))

(define (om:out-or-inout? o)
  (match o
    (($ <formal>)
     (or (eq? (.direction o) 'out)
         (eq? (.direction o) 'inout)))))

(define (om:provides? o)
  (eq? (.direction o) 'provides))

(define (om:requires? o)
  (eq? (.direction o) 'requires))

(define ((om:dir-matches? port) event)
  (or (and (eq? (.direction port) 'provides)
           (eq? (.direction event) 'in))
      (and (eq? (.direction port) 'requires)
           (eq? (.direction event) 'out))))

(define om:binary-operators
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

(define om:unary-operators
  '(
    group
    !
    ))

(define om:operators
  (append om:binary-operators om:unary-operators))

(define (om:operator? o)
  (memq o om:operators))

(define (om:expression? o)
  (match o
    (($ <expression>) o)
    (((? om:operator?) h t ...) o)
    (_ #f)))

(define-method (om:modeling? (o <trigger>))
  (is-a? (.event o) <modeling-event>))

(define (om:void? model o)
  (and (not (om:modeling? o)) (not (om:typed? model o))))

(define (om:id o) ((compose pointer-address scm->pointer) o))

(define (om:parent o t)
  (match o
    (($ <system>) #f)
    ((? (is? <model>))
     (om:parent ((compose .statement .behaviour) o) t))
    (($ <blocking>) (or (and (eq? (om:id (.statement o)) (om:id t)) o)
                        (om:parent (.statement o) t)))
    (($ <guard>) (or (and (eq? (om:id (.statement o)) (om:id t)) o)
                     (and (eq? (om:id (.expression o)) (om:id t)) o)
                     (om:parent (.statement o) t)))
    (($ <on>) (or (and (eq? (om:id (.statement o)) (om:id t)) o)
                  (om:parent (.statement o) t)))
    ((? (is? <ast-list>))
     (if (member (om:id t) (map om:id (.elements o)))
         o
         (let loop ((elements (.elements o)))
           (if (null? elements)
               #f
               (let ((parent (om:parent (car elements) t)))
                 (if parent parent
                     (loop (cdr elements))))))))
    (_ #f)))


;;;; reading/caching
(define *ast-alist* '())

(define (om:interfaces)
  (filter (is? <interface>) *ast-alist*))

(define (cache-model! name o)
  (set! *ast-alist* (assoc-set! *ast-alist* name o))
  o)

(define (cached-model name)
  (assoc-ref *ast-alist* name))

(define (globals)
  (filter (is? <*type*>) (map cdr *ast-alist*)))

(define (om:register-model o)
  (if (not (cached-model (.name o)))
      (cache-model! (.name o) o))
  o)

(define om:register-type om:register-model)

(define* ((om:register transform #:optional (clear? #f)) ast)
  (let ((om (transform ast)))
    (if clear?
        (set! *ast-alist* (filter (lambda (x) (is-a? (cdr x) <*type*>)) *ast-alist*)))
    (for-each om:register-model (om:filter (is? <model>) om))
    (for-each om:register-type (om:filter (is? <*type*>) om))
    om))

(define* (import-ast name #:optional (transform (compose ast:resolve ast->om)))
  (and-let* ((ast (null-is-#f (read-ast name (om:register transform))))
             (models (null-is-#f (filter (is? <model>) ast))))
    (find (lambda (model) (equal? (.name model) name)) models)))

(define* (om:import name #:optional (transform (compose ast:resolve ast->om)))
  (or (cached-model name)
      (and-let* ((ast (import-ast name transform)))
        (cache-model! name ast))))

(define* (om:parse-dzn string #:optional (register (om:register (compose ast:resolve ast->om))))
  (parse-dzn string register))

;;;; OM handling

(define (basename- o)
  (string->symbol (basename (symbol->string o))))

(define (in-file? o file)
  (let ((file (if (string? file) (string->symbol file) file)))
    (and-let* ((model-file (source-file o))
               (model-file (if (string? model-file) (string->symbol model-file) model-file)))
              (eq? (basename- file) (basename- model-file)))))

(define (parse-opts x)  ((@@ (gaiag gaiag) parse-opts) x))

(define (om:imported? o)
  (if (assoc 'imported? (source-properties o))
      (source-property o 'imported?)
      (and-let* (((>2 (length (command-line))))
                 (file (car (option-ref (parse-opts (command-line)) '() '(#f)))))
                (cond
                 ((string= file "-") #f)
                 ((string= file "/dev/stdin") #f)
                 ((string-suffix? ".scm" file) #f)
                 (else (not (in-file? o file)))))))


(define (ast-> ast)
  ((compose
    om->list
    ast->om
    ast->annotate
    ) ast))
