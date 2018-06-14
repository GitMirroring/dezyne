;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2015, 2016, 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;; Copyright © 2014, 2015, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;; Copyright © 2014, 2015, 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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

           .event
           .event.direction
           .function
           .type
           .variable
           .instance

           resolve:component
           resolve:event
           resolve:instance
           resolve:interface
           resolve:variable
           ))

(define-method (add-constants (o <root>))
  (let* ((tvoid (make <void>))
         (tbool (make <bool>))
         (o (clone o #:elements (cons tvoid (cons tbool (.elements o))))))
    o))

(define (ast:resolve o) (add-constants o))

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
           (find (lambda (x) (om:equal? system (.name x))) (filter (negate (is? <data>)) (.elements (parent system <root>)))))
          (_ #f)))
    ((? symbol?) (resolve:component system (resolve:instance system o)))
    ((and ($ <binding>) (= .instance #f))
     ;;#f
     ;;(resolve:component system (om:binding-other-port system port))
     (let* ((bind (om:bind system (.port.name o)))
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
    (($ <scope.name>) (find (om:named o) ((compose .elements (cut parent o <root>)))))
    (($ <root>) (om:find (is? <interface>) o))
    ((h t ...) (find (is? <interface>) o))))

(define (resolve:variable model o)
  (find (om:named o) (om:variables model)))




(define-method (var? (o <ast>) name)
  (define (name? o) (and (eq? (.name o) name) o))
  (match o
    (($ <behaviour>) (find name? (ast:variable* o)))
    (($ <compound>) (or (find name? (filter (is? <variable>) (ast:statement* o))) (var? (.parent o) name)))
    (($ <function>) (or (find name? ((compose ast:formal* .signature) o)) (var? (.parent o) name)))
    (($ <formal>) (and (eq? (.name o) name) o))
    (($ <formal-binding>) (and (eq? (.name o) name) o));;(or (name? o) (.parent o) name)
    (($ <on>) (or (find (cut var? <> name) (append-map ast:formal* (ast:trigger* o))) (var? (.parent o) name)))
    (($ <variable>) (name? o))
    ((? (lambda (o) (is-a? (.parent o) <variable>))) (var? ((compose .parent .parent) o) name))
    (_ (var? (.parent o) name))))

(define-method (type? (o <ast>) name) ;;FIXME stop recursion when AST not fresh
  (define (name? e) (and (eq? (.scope+name (.name e)) (.scope+name name)) e))
  (define (scope? e)
    (cond ((is-a? e <scope.name>)
           (and (eq? ((->symbol-join '.) (om:scope+name e))
                     ((->symbol-join '.) (.scope name)))
                e))
          ((is-a? e <named>) (scope? (.name e)))
          (else #f))
    )
  (define (prefix? name1 name2)
    (or (null? name1) (and (pair? name2) (eq? (car name1) (car name2)) (prefix? (cdr name1) (cdr name2)))))
  (match o
         (($ <root>)
          (let ((scope (find scope? (.elements o))))
            (if (and scope (pair? (.scope name)))
                (type? scope name)
                (find name? (ast:type* o)))))
         (($ <interface>)
          (if (and (is-a? name <scope.name>) (prefix? (om:scope+name (.name o)) (om:scope+name name))) (find name? (ast:type* o))
              (type? (.parent o) name)))
         (($ <behaviour>) (or (find name? (ast:type* o)) (type? (.parent o) name)))
         ((? (is? <type>)) (name? o))
         (_ (type? (.parent o) name))))

(define-method (bind-instance? (o <ast>) name)
  (define (name? o) (and (eq? (.name o) name) o))
  (find name? (ast:instance* (parent o <system>))))

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
  (name-resolve (parent o <root>) <interface> (.scope+name (.type.name o))))

(define-method (.type (o <instance>))
  (or (name-resolve (parent o <root>) <system> (.scope+name (.type.name o)))
      (name-resolve (parent o <root>) <component> (.scope+name (.type.name o)))
      (name-resolve (parent o <root>) <foreign> (.scope+name (.type.name o)))))

(define-method (contains? container (o <ast>))
  (and (is-a? container <ast>)
       (or (eq? container o)
           (any (lambda (e) (contains? e o)) (om:children container)))))

(define-method (.port (model <component-model>) (o <trigger>))
  (and (.port.name o) (name-resolve model <port> (.port.name o))))

(define-method (.port (model <component-model>) (o <action>))
  (and (.port.name o) (name-resolve model <port> (.port.name o))))

(define-method (.port (o <trigger>))
  (and (.port.name o) (name-resolve (parent o <model>) <port> (.port.name o))))

(define-method (.port (o <action>))
  (and (.port.name o) (name-resolve (parent o <model>) <port> (.port.name o))))

(define-method (.port (o <reply>))
  (and (.port.name o) (name-resolve (parent o <model>) <port> (.port.name o))))

(define-method (.port (o <binding>))
  (if (.instance.name o)
      (name-resolve (.type (.instance o)) <port> (.port.name o))
      (name-resolve (parent o <model>) <port> (.port.name o))))


(define-method (event? (o <ast>) name)
  (define (name? o) (and (eq? (.name o) name) o))
  (case name
    ((inevitable) (clone ast:inevitable #:parent (parent o <interface>)))
    ((optional) (clone ast:optional #:parent (parent o <interface>)))
    (else (match o
            (($ <interface>) (find name? (ast:event* o)))
            ((and (or ($ <action>) ($ <trigger>)) (= .port #f)) (event? (parent o <interface>) name))
            ((and (or ($ <action>) ($ <trigger>)) (= .port port)) (event? (.type port) name))))))

(define-method (resolve:event (o <ast>) (name <symbol>))
  (event? o name))

(define-method (.event (o <action>))
  (event? o (.event.name o)))

(define-method (.event (o <trigger>))
  (event? o (.event.name o)))

(define-method (.event.direction (o <action>))
  ((compose .direction .event) o))

(define-method (.event.direction (o <trigger>))
  ((compose .direction .event) o))

(define-method (.function (model <model>) (o <call>))
  (and (.function.name o) (name-resolve model <function> (.function.name o))))

(define-method (.function (o <call>))
  (name-resolve (parent o <model>) <function> (.function.name o)))


(define-method (.variable (o <assign>))
  (var? o (.variable.name o)))

(define-method (.variable (o <field-test>))
  (var? o (.variable.name o)))

(define-method (.variable (o <formal-binding>))
  (var? o (.variable.name o)))

(define-method (.variable (o <var>))
  (var? o (.variable.name o)))


(define-method (.type (o <argument>))
  (type? o (.type.name o)))

(define-method (.type (o <enum-field>))
  (type? o (.type.name o)))

(define-method (.type (o <enum-literal>))
  (type? o (.type.name o)))

(define-method (.type (o <formal>))
  (type? o (.type.name o)))

(define-method (.type (o <signature>))
  (type? o (.type.name o)))

(define-method (.type (o <variable>))
  (type? o (.type.name o)))

(define-method (.instance (o <binding>))
  (and (.instance.name o) (bind-instance? o (.instance.name o))))

(define (ast-> ast)
  ((compose
    pretty-print
    om->list
    ast:resolve
    parse->om
    ) ast))
