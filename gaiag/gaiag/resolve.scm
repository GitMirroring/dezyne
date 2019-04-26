;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2015, 2016, 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;; Copyright © 2014, 2015, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (oop goops describe)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag compare)
  #:use-module (gaiag ast)
  #:use-module (gaiag util)

  #:use-module (gaiag parse)
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
         (o (clone o #:elements (cons tvoid (cons tbool (ast:top* o))))))
    o))

(define (ast:resolve o) (add-constants o))

(define (resolve:instance model o)
  (match o
    ((? symbol?)
     (find (lambda (x)
                   (eq? (.name x) o)) (ast:instance* model)))
    (($ <end-point>) (or (.instance o)
                       (.type ((.port model) o))))
    (($ <binding>) (resolve:instance model (om:instance-binding? o)))
    (($ <port>) (resolve:instance model (om:instance-binding? (om:port-bind model o))))
    ((? boolean?) #f)))

(define* (resolve:component system #:optional o)
  (match o
    (#f (match system
          (($ <foreign>) system)
          (($ <component>) system)
          (($ <root>) (om:find (disjoin (is? <component>) (is? <foreign>)) system))
          (($ <scope.name>) ;(cached-model system)
           (find (lambda (x) (ast:equal? system (.name x))) (filter (negate (is? <data>)) (ast:top* (parent system <root>)))))
          (_ #f)))
    ((? symbol?) (resolve:component system (resolve:instance system o)))
    ((and ($ <end-point>) (= .instance #f))
     ;;#f
     ;;(resolve:component system (om:binding-other-port system port))
     (let* ((bind (om:bind system (.port.name o)))
            (instance (om:instance-name bind)))
       (resolve:component system instance)))
    (($ <end-point>) (resolve:component system (.instance o)))
    (($ <binding>) (resolve:component system (om:instance-name o)))
    (($ <instance>) (.type o))
    (($ <port>) (resolve:interface (.type o)))))

(define (resolve:interface o)
  (match o
    (($ <port>) (resolve:interface (.type o)))
    (($ <interface>) o)
    ((? (is? <model>)) (resolve:interface (om:port o)))
    (($ <scope.name>) (find (om:named o) ((compose ast:top* (cut parent o <root>)))))
    (($ <root>) (om:find (is? <interface>) o))
    ((h t ...) (find (is? <interface>) o))))

(define (resolve:variable model o)
  (find (om:named o) (om:variables model)))

(define-method (var? (o <ast>) name)
  (define (name? o) (and (eq? (.name o) name) o))
  (match o
    (($ <behaviour>) (find name? (ast:variable* o)))
    ((? (is? <compound>)) (or (find name? (filter (is? <variable>) (ast:statement* o))) (var? (.parent o) name)))
    (($ <function>) (or (find name? ((compose ast:formal* .signature) o)) (var? (.parent o) name)))
    (($ <formal>) (and (eq? (.name o) name) o))
    (($ <formal-binding>) (and (eq? (.name o) name) o));;(or (name? o) (.parent o) name)
    (($ <on>) (or (find (cut var? <> name) (append-map ast:formal* (ast:trigger* o))) (var? (.parent o) name)))
    (($ <variable>) (name? o))
    ((? (lambda (o) (is-a? (.parent o) <variable>))) (var? ((compose .parent .parent) o) name))
    (_ (var? (.parent o) name))))











;; (define-method (ast:name-equal? (a <scope.name>) (b <named>))
;;   (warn 'ast:name-equal 'a a 'b b '=> (equal? (om:scope+name a) (om:scope+name b))))

(define-method (ast:name-equal? (a <symbol>) (b <symbol>))
  (eq? a b))

(define-method (ast:name-equal? (a <symbol>) (b <named>))
  ;;(stderr "ast:name-equal? ~s =? ~s\n" a b)
  (let ((name (.name b)))
    (receive (scope name)
        (match name
          ((and ($ <scope.name>) (= .scope scope) (= .name name)) (values scope name))
          (_ (values '() name)))
      (and (null? scope) (eq? a name)))))

(define-method (ast:name-equal? (a <symbol>) (b <ast>))
  ;;(stderr "ast:name-equal? ~s =? ~s\n" a b)
  #f)

(define-method (ast:lookup (o <scope>) (name <scope.name>))
;;  (stderr "ast:lookup[~s]: ~s\n" o name)
  (let ((scope (.scope name)))
    (if (null? scope) (if (ast:name-equal? (.name name) o) o
                          (ast:lookup o (.name name)))
        (let* ((first (car scope))
               (first-scope (ast:lookup o first)))
          (if (not first-scope) (error "boo")
              (let ((name (clone name #:scope (cdr scope))))
                ;;(stderr "found first scope:~s\n" first-scope)
                (ast:lookdown first-scope name)))))))

(define-method (ast:lookdown (o <scope>) (name <scope.name>))
;;  (stderr "ast:lookdown[~s]: ~s\n" o name)
  (let ((name (.name name))
        (scope (.scope name)))
    (if (null? scope) (find (cut ast:name-equal? name <>) (ast:declaration* o))
        (let* ((first (car scope))
               (first-scope (ast:lookdown o first)))
          (if (not first-scope) (error "boo")
              (let ((name (clone name #:scope (cdr scope))))
                ;;(stderr "found first scope:~s\n" first-scope)
                (ast:lookdown first-scope name)))))))

(define-method (ast:lookdown (o <ast>) (name <scope.name>))
;;  (stderr "ast:lookdown <ast>[~s]: ~s\n" o name)
  #f)

(define-method (ast:lookup (o <ast>) name)
;;  (stderr "ast:lookup <ast> 2 [~s]: ~s\n" o name)
  (ast:lookup (parent o <scope>) name))

(define-method (ast:lookup (o <scope>) (name <symbol>))
;;  (stderr "ast:lookup 3 [~s]: ~s\n" o name)
  (or (find (cut ast:name-equal? name <>) (ast:declaration* o))
      (let ((p (.parent o)))
        (and p
             (ast:lookup (parent p <scope>) name)))))

(define-method (ast:declaration* (o <namespace>))
  (ast:top* o))

(define-method (ast:declaration* (o <interface>))
  (append (ast:type* o) (ast:event* o)))

(define-method (ast:declaration* (o <component-model>))
  (ast:port* o))

(define-method (ast:declaration* (o <system>))
  (append (ast:port* o) (ast:instance* o)))

(define-method (ast:declaration* (o <behaviour>))
  (append (ast:type* o) (ast:function* o) (ast:variable* o)))

(define-method (ast:declaration* (o <compound>))
  (ast:variable* o))

(define-method (ast:declaration* (o <function>))
  (ast:formal* o))

(define-method (ast:declaration* (o <trigger>))
  (ast:formal* o))

(define-method (ast:declaration* (o <enum>))
  (ast:field* o))


(define-method (type? (o <ast>) name)
  (ast:lookup o name))

(define-method (type?- (o <ast>) name) ;;FIXME stop recursion when AST not fresh
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
  (define (full-name name here)
    (cond ((null? here) name)
          ((eq? (car (->list name)) (last here))
           (clone name #:scope (append here (.scope name)) #:name (.name name)))
          (else (full-name name (drop here 1)))))
  (match o
         (($ <root>)
          (let ((scope (find scope? (ast:top* o))))
            (if (and scope (pair? (.scope name)))
                (type?- scope name)
                (find name? (ast:type* o)))))
         (($ <interface>)
          (if (and (is-a? name <scope.name>) (prefix? (om:scope+name (.name o)) (om:scope+name name))) (find name? (ast:type* o))
              (type?- (.parent o) (full-name name (->list (.name o))))))
         (($ <behaviour>) (or (find name? (ast:type* o)) (type?- (.parent o) name)))
         ((? (is? <type>)) (name? o))
         (_ (type?- (.parent o) name))))


(define-method (bind-instance? (o <ast>) name)
  (define (name? o) (and (eq? (.name o) name) o))
  (find name? (ast:instance* (parent o <system>))))

(define-method (->list (o <scope.name>))
  (append (.scope o) (list (.name o))))

(define-method (.scope+name (o <scope.name>))
  (symbol-join (append (.scope o) (list (.name o)))))

(define (name-resolve scope class o)
  (cond
   ((or (eq? <interface> class) (eq? <system> class) (eq? <component> class) (eq? <foreign> class))
    (find (lambda (m)
            (and (is-a? m class)
                 (equal? o (.scope+name (.name m)))))
          (ast:top* scope)))
   ((eq? <port> class)
    (find (lambda (m)
            (equal? o (.name m)))
          (append (ast:port* scope)
                  (om:behaviour-ports scope))))
   ((eq? <function> class)
    (find (lambda (m)
            (equal? o (.name m)))
          ((compose ast:function* .behaviour) scope)))))

(define name-resolve (pure-funcq name-resolve))

(define-method (.type (o <port>))
  (name-resolve (parent o <root>) <interface> (.scope+name (.type.name o))))

(define-method (.type (o <instance>))
  (or (name-resolve (parent o <root>) <system> (.scope+name (.type.name o)))
      (name-resolve (parent o <root>) <component> (.scope+name (.type.name o)))
      (name-resolve (parent o <root>) <foreign> (.scope+name (.type.name o)))
      (name-resolve (parent o <root>) <interface> (.scope+name (.type.name o)))))

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

(define-method (.port (o <trigger-return>))
  (and (.port.name o) (name-resolve (parent o <model>) <port> (.port.name o))))

(define-method (.port (o <end-point>))
  (if (.instance.name o)
      (name-resolve (.type (.instance o)) <port> (.port.name o))
      (name-resolve (parent o <model>) <port> (.port.name o))))

(define-method (event? (o <ast>) name)
  (define (name? o) (and (eq? (.name o) name) o))
  (cond
    ((eq? name 'inevitable) (clone (ast:inevitable) #:parent (parent o <interface>)))
    ((eq? name 'optional) (clone (ast:optional) #:parent (parent o <interface>)))
    (else (match o
            (($ <interface>) (find name? (ast:event* o)))
            ((and (or (? (is? <action>)) ($ <trigger>)) (= .port #f)) (event? (parent o <interface>) name))
            ((and (or (? (is? <action>)) ($ <trigger>)) (= .port port)) (event? (.type port) name))))))

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

(define-method (.instance (o <end-point>))
  (and (.instance.name o) (bind-instance? o (.instance.name o))))

(define (ast-> ast)
  ((compose
    pretty-print
    om->list
    ast:resolve)
   ast))
