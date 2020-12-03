;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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
;;; Dezyne Language completion using parse trees.
;;;
;;; Code:

(define-module (dzn parse complete)
  #:use-module (ice-9 match)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)

  #:use-module (dzn misc)
  #:use-module (dzn parse lookup)
  #:use-module (dzn parse tree)

  #:export (complete
            complete:context))

;;;
;;; Parse tree context.
;;;

(define (at-location? o at)
  (and (pair? o)
       (or (let ((end (last o)))
             (and ((is? 'location) end)
                  (let ((from (.pos end))
                        (to (.end end)))
                    (and (<= from at)
                         (or (<= at to)
                             (incomplete? o))))))
           (find (cute at-location? <> at) o))))

(define (after-location? o at)
  (and (pair? o)
       (or (let ((end (last o)))
             (and ((is? 'location) end)
                  (let ((to (.end end)))
                    (> to at))))
           (find (cute after-location? <> at) o))))

(define (around-location? o at)
  (and (pair? o)
       (receive (after before)
           (partition (cute after-location? <> at) (cdr o))
         (and (pair? before) (pair? after)))))

(define (before-location? o at)
  (and (pair? o)
       (receive (after before)
           (partition (cute after-location? <> at) (cdr o))
         (and (pair? before) (last (filter (negate (disjoin symbol? tree:location?)) before))))))

(define (complete:context o at)
  (let ((narrow (conjoin incomplete? (negate symbol?) (negate tree:location?)))
        (context (reverse (tree:collect o (cute at-location? <> at)))))
    (if (null? context) `(,o)
        (let ((narrow (find narrow (cdar context))))
          (if narrow (cons narrow context)
              context)))))


;;;
;;; Tree to (dotted) name string.
;;;

(define (tree:type-name o)
  (match o
    ((? (is? 'port)) (tree:dotted-name (.type-name o)))
    ((? pair?) (tree:type-name (find tree:type-name o)))
    (_ #f)))

(define (.direction o)
  (match o
    (('direction (? string? direction) rest ...) direction)
    ((? (is? 'event)) (slot o 'direction))
    ((? (is? 'port)) (slot o 'direction))))

(define (tree:event-dir o)
  (match o
    ((? (is? 'event)) (tree:event-dir (.direction o)))
    ((? (is? 'direction)) (string->symbol (.direction o)))
    ((? pair?) (tree:event-dir (find tree:event-dir o)))
    (_ #f)))

(define (tree:port-dir o)
  (match o
    ((? (is? 'provides)) 'provides)
    ((? (is? 'requires)) 'requires)
    ((? pair?) (tree:port-dir (find tree:port-dir o)))
    (_ #f)))

(define (context:enum-names o)
  (map tree:dotted-name (tree:enum* (or (slot o 'interface) (slot o 'root)))))

(define (context:int-names o)
  (map tree:dotted-name (tree:int* (or (slot o 'interface) (slot o 'root)))))

(define (context:type-names o)
  (map tree:dotted-name (tree:type* (or (slot o 'interface) (slot o 'root)))))

(define* (context:event-names o event-dir #:key (predicate identity))
  (let* ((events (tree:event* (find (is? 'interface) o)))
         (events (filter (conjoin predicate (compose (cute eq? event-dir <>) tree:event-dir)) events)))
    (map tree:dotted-name events)))

(define* (context:interface-names o)
  (map tree:dotted-name (tree:interface* o)))

(define (port-dir->event-dir port-dir dir)
  (cond ((and (eq? 'provides port-dir) (eq? 'trigger dir)) 'in)
        ((and (eq? 'provides port-dir) (eq? 'action dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'trigger dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'action dir)) 'in)))

(define* (context:port-event-names o   ;context
                                   dir ;'trigger or 'action
                                   #:key (event-predicate identity))
  (let* ((ports (tree:port* (find (is? 'component) o)))
         (interface-names (map tree:type-name ports))
         (interfaces (filter (compose (cute member <> interface-names string=?)
                                      tree:dotted-name)
                             (tree:interface* (find (is? 'root) o)))))
    (define (port->event-names port)
      (let* ((port-type (tree:type-name port))
             (port-dir (tree:port-dir port))
             (interface (find (compose (cute string=? port-type <>)
                                       tree:dotted-name)
                              interfaces))
             (events (filter
                      tree:dotted-name
                      (filter (conjoin event-predicate
                                       (compose (cute eq? (port-dir->event-dir port-dir dir) <>)
                                        tree:event-dir))
                              (tree:event* interface)))))
        (define (event->name event)
          (let* ((port (tree:dotted-name port))
                 (formals (map tree:dotted-name (tree:formal* event)))
                 (formals (string-join formals ", "))
                 (event (tree:dotted-name event)))
            (format #f "~a.~a(~a)" port event formals)))
        (map event->name events)))
    (append-map port->event-names ports)))

(define* (context:trigger-names o #:key (event-predicate identity))
  (cond ((slot o 'interface) (context:event-names o 'in #:predicate event-predicate))
        ((slot o 'component) (context:port-event-names o 'trigger #:event-predicate event-predicate))
        (else '())))

(define* (context:action-names o #:key (event-predicate identity))
  (cond ((slot o 'interface) (context:event-names o 'out #:predicate event-predicate))
        ((slot o 'component) (context:port-event-names o 'action #:event-predicate event-predicate))
        (else '())))

(define* (tree:function-names o #:key (type-predicate identity))
  (let* ((functions (tree:function* o))
         (functions (filter (compose type-predicate .type-name) functions)))
    (define (function->name f)
      (let* ((name (tree:dotted-name f))
             (formals (map (const "_") (tree:formal* f)))
             (formals (string-join formals ", ")))
        (format #f "~a(~a)" name formals)))
    (map function->name functions)))

(define (tree:enum-value-names o)
  (assert-type o 'enum)
  (let* ((name (.name o))
         (fields (tree:field* o)))
    (map (cute string-append (tree:dotted-name name) "." <>)
         (map tree:dotted-name fields))))

(define (tree:type-value-names o)
  (cond ((is-a? o 'enum) (tree:enum-value-names o))
        ((is-a? o 'int) (tree:int-value-names o))
        ((is-a? o 'bool) '("false" "true"))
        (else '())))

(define (context:locals o)
  (let loop ((scope (parent-context o tree:scope?)))
    (if (or (not scope) (is-a? (.tree scope) 'behaviour-compound)) '()
        (append (tree:variable* (.tree scope))
                (loop (parent-context scope tree:scope?))))))

(define (context:members o)
  (let ((scope (parent-context o 'behaviour-compound)))
    (tree:variable* (.tree scope))))

(define (complete:variable-names type context)
  (let* ((variables (append (context:locals context)
                            (context:members context)))
         (type-name (.name type))
         (variables (filter (compose (cute tree:name-equal? <> type-name) .type-name) variables)))
    (map tree:dotted-name variables)))

(define (complete:type-names context)
  (cons* "bool" "void" (context:type-names context)))

(define (complete-enum o context)
  (assert-type o 'enum)
  (let ((name (.name o)))
    (append
     (complete:variable-names o context)
     (tree:function-names
      (parent context 'behaviour)
      #:type-predicate (cute tree:name-equal? <> name))
     (context:action-names
      context
      #:event-predicate (compose (cute tree:name-equal? <> name) .type-name))
     (tree:type-value-names o))))

(define (complete-enum-literal o name context)
  (assert-type o 'enum-literal)
  (let* ((type-name (.type-name o))
         (field     (.field o))
         (enum      (tree:lookup type-name context)))
    (cond
     ((not enum)
      (complete:type-names context))
     ((equal? field name)
      (tree:type-value-names enum))
     ((not (parent context 'on))
      (tree:type-value-names enum))
     (else
      (append
       (complete:variable-names enum context)
       (tree:function-names
        (parent context 'behaviour)
        #:type-predicate (cute tree:name-equal? <> type-name))
       (context:action-names
        context
        #:event-predicate (compose (cute tree:name-equal? <> type-name) .type-name))
       (tree:type-value-names enum))))))

(define (complete-on o context)
  (assert-type o 'on)
  (let* ((triggers  (tree:trigger* o))
         (trigger   (and (pair? triggers) (car triggers)))
         (port      (and trigger (tree:lookup (.port-name trigger) context)))
         (interface (and port (tree:lookup (.type-name port) context)))
         (event     (and interface (tree:lookup (.event-name trigger) (list interface))))
         (type-name (and event (.type-name event)))
         (type      (and type-name (tree:lookup type-name context))))
    (cond ((not type)
           (complete:type-names context))
          (else
           (append
            (complete:variable-names type context)
            (tree:type-value-names type))))))


;;;
;;; Entry point.
;;;

(define (complete o context offset)
  (match o
    (('root (? (disjoin complete? tree:location?)) ...)
     '("component" "enum" "import" "interface" "namespace" "subint"))
    ((? (is? 'file-name))
     (complete (.tree (.parent context)) (.parent context) offset))
    (('interface (? (disjoin incomplete? tree:location?)) ..1)
     '())
    ;; FIXME: for component-empty
    ((and (? (is? 'component))
          (? complete?))
     (cond ((and (not (.behaviour o))
                 (not (.system o)))
            '("behaviour" "provides" "requires" "system"))
           (else '())))
    ((or (? (is? 'provides)) (? (is? 'requires)))
     (context:interface-names (parent context 'root)))
    ('types-and-events
     '("bool" "enum" "in" "out"))
    (('types-and-events types-events ...)
     '("behaviour" "bool" "enum" "in" "out"))
    ('type-name
     (complete:type-names context))
    ((and (? (is? 'ports)) (? (cute around-location? <> offset)))
     '("provides" "requires"))
    ((or 'body
         (? (is? 'ports)))
     '("behaviour" "provides" "requires" "system"))
    ('behaviour
     '("behaviour" "bool" "enum" "in" "out"))
    (('behaviour-compound (? (disjoin incomplete? tree:location?)) ...)
     (let ((incomplete (find incomplete? (cdr o))))
       (cond ((is-a? incomplete 'on)
              (context:trigger-names context))
             (else '("on")))))

    ((? (is? 'name))
     (cond ((parent context 'enum-literal)
            => (cute complete-enum-literal <> o context))
           ((parent context 'reply)
            (let ((on (parent-context context 'on)))
             (complete-on (.tree on) context)))
           (else
            (complete (.tree (.parent context)) (.parent context) offset))))

    (('triggers (? (disjoin incomplete? tree:location?)) ...)
     (context:trigger-names context))
    ((? (is? 'trigger))
     (context:trigger-names context))
    (('on (? (is? 'triggers)) (? tree:location?))
     (context:action-names context))
    ((and (? (is? 'variable)) (? incomplete?))
     (let* ((type-name (.type-name o))
            (type (false-if-exception (tree:lookup type-name context)))
            (type (tree:lookup type-name context))
            (expression (false-if-exception (.expression o)))
            (expression (and expression (.value expression))))
       (cond ((not type)
              (complete:type-names context))
             ((or (not (is-a? type 'enum))
                  (and (not expression)
                       (not (parent context 'on))))
              (tree:type-value-names type))
             ((not expression)
              (complete-enum type context))
             (else
              '()))))
    ('statement
     (context:action-names context))
    (('compound (? tree:location?))
     '("on")) ;;FIXME point solution: fixes component7.dzn

    (('compound (? (disjoin incomplete? tree:location?)) ...)
     (context:action-names context))
    ((? (is? 'action))
     (context:action-names context))

    ((or 'BRACE-CLOSE
         'BRACE-OPEN
         (? symbol?))
     '())
    (_ (if (complete? o) '()
           (or (complete (find incomplete? (cdr o)) context offset)
               (complete (before-location? o offset) context offset))))))

;; TODO: rewrite above as:
;; (define (complete o context offset)
;;   (match o
;;     ((? (is? 'trigger)) (context:trigger-names context))
;;     ((? (is? 'name)) (complete (.tree (.parent context)) (.parent context) offset))
;;     (_ '())))
