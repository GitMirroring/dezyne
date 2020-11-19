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
;;; Dezyne Language parse tree library.
;;;
;;; Code:

;;; XXX TODO: use MATCH instead of first, second, third, forth
;;; XXX TODO: sort-out tree:name, lookup:name
;;; XXX TODO: split into accessors (.name) and utilities (tree:name)

(define-module (gaiag parse tree)
  #:use-module (ice-9 match)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)

  #:use-module (gash util)

  #:export (complete?
            incomplete?
            context?
            is-a?
            is?
            location?
            has-location?
            parent
            type?
            tree?
            slot

            .file-name
            .parent
            .tree

            tree:collect
            tree:import*
            tree:location
            tree:name
            tree:offset

            tree:action*
            tree:formal*
            tree:enum-name* ;;; FIXME
            tree:trigger*))

;;;
;;; Parse tree predicates.
;;;

(define tree:types ;;; XXX incomplete
  '(action
    add-var
    behaviour
    behaviour-compound
    bool
    component
    compound
    compound-name
    enum
    enum-name
    event
    event-name
    events
    expression
    import
    interface
    literal
    name
    port
    ports
    provides
    requires
    root
    subint
    system
    trigger
    trigger
    trigger-formals
    triggers
    type-name
    variable
    void))

(define (tree? o)
  (match o
    (((? symbol? (? (cute memq <> tree:types)) type) slot ...)
     type)
    (((? symbol?) slot ...)
     (warn "XXX tree? noisy fallback:" o))
    (_ #f)))

(define (is-a? o symbol)
  (and (pair? o) (eq? symbol (car o))))

(define (is? symbol)
  (lambda (o) (is-a? o symbol)))

(define (slot o symbol)
  (find (is? symbol) (cdr o)))

(define (type? o)
  (match o
    (((? symbol? (or 'bool 'component 'interface 'port 'system 'void) type) slot ...)
     type)
    (_ #f)))

(define (location? o)
  ((is? 'location) o))

(define (has-location? o)
  (and (pair? o) ((is? 'location) (last o))))


(define (complete? o)
  ((disjoin string?
            (conjoin pair?
                     (compose symbol? first)
                     (compose (is? 'location) last)
                     (compose (cute every complete? <>)
                              (cute drop-right <> 1)
                              cdr))) o))

(define incomplete? (negate complete?))

(define (context? context)
  (and (pair? context) (tree? (car context))))

(define (.tree context)
  (and (context? context) (car context)))

(define (.parent context)
  (and (context? context) (cdr context)))

(define (parent context type)
  (let loop ((context (.parent context)))
    (and (context? context)
         (let ((tree (.tree context)))
           (if (is-a? tree type) tree
               (and tree
                    (loop (.parent context))))))))


;;;
;;; Parse tree accessors.
;;;

(define (.file-name o)
  (match o
   (('import (? string? file-name) location ...) file-name)
   (_ #f)))

(define (tree:collect o predicate)
  (if (predicate o) (cons o (append-map (cute tree:collect <> predicate) o))
      '()))

(define (tree:import* context)
  (if (is-a? context 'root)
      (filter (is? 'import) (cdr context))
      '()))

(define (tree:port* o)
  (match
   o
   ((? (is? 'port)) (list o))
   ((? pair?) (append-map tree:port* o))
   (_ '())))

(define (tree:interface* o)
  (match
   o
   ((? (is? 'interface)) (list o))
   ((? pair?) (append-map tree:interface* o))
   (_ '())))

(define (tree:enum* o)
  (match
   o
   ((? (is? 'interface)) (append-map tree:enum* (cdr o)))
   ((? (is? 'enum)) `(,o))
   ((? pair?) (append-map tree:enum* o))
   (_ '())))

(define (tree:event* o)
  (match
   o
   ((? (is? 'interface)) (append-map tree:event* (cdr o)))
   ((? (is? 'event)) `(,o))
   ((? pair?) (append-map tree:event* o))
   (_ '())))

(define (tree:name o)
  (match
   o
   ((? (is? 'port)) (tree:name (fourth o)))
   ((? (is? 'compound-name)) (string-join (filter-map tree:name (cdr o)) "."))
   ((? (is? 'type-name)) #f)
   ((? (is? 'event-name)) (tree:name (second o)))
   ((? (is? 'name)) (second o))
   ((? pair?) (tree:name (find tree:name o)))
   (_ #f)))

(define (tree:location o)
  (match o
    (((? symbol?) (? pair? alist) ...) (assoc 'location alist))
    (_ #f)))

(define (tree:offset o)
  (let ((location (tree:location o)))
    (match location
      (('location start end)
       start))))

(define (tree:type o)
  (match
   o
   ((? (is? 'port)) (tree:name (third o)))
   ((? pair?) (tree:type (find tree:type o)))
   (_ #f)))

(define (tree:event-dir o)
  (match
   o
   ((? (is? 'event)) (tree:event-dir (second o)))
   ((? (is? 'direction)) (string->symbol (second o)))
   ((? pair?) (tree:event-dir (find tree:event-dir o)))
   (_ #f)))

(define (tree:port-dir o)
  (match
   o
   ((? (is? 'provides)) 'provides)
   ((? (is? 'requires)) 'requires)
   ((? pair?) (tree:port-dir (find tree:port-dir o)))
   (_ #f)))

(define (tree:enum-name* o)
  (map tree:name (tree:enum* (or (find (is? 'interface) o) (find (is? 'root) o)))))

(define* (tree:event-name* o event-dir)
  (let* ((events (tree:event* (find (is? 'interface) o)))
         (events (filter (compose (cute eq? event-dir <>) tree:event-dir) events)))
    (map tree:name events)))

(define* (tree:interface-name* o)
  (map tree:name (tree:interface* o)))

(define (port-dir->event-dir port-dir dir)
  (cond ((and (eq? 'provides port-dir) (eq? 'trigger dir)) 'in)
        ((and (eq? 'provides port-dir) (eq? 'action dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'trigger dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'action dir)) 'in)))

(define (tree:port-event-name* o dir) ;;dir 'trigger or 'action
  (let* ((ports (tree:port* (find (is? 'component) o)))
         (interface-names (map tree:type ports))
         (interfaces (filter (compose (cute member <> interface-names string=?)
                                      tree:name)
                             (tree:interface* (find (is? 'root) o)))))
    (append-map (lambda (port)
                  (let* ((port-type (tree:type port))
                         (port-dir (tree:port-dir port))
                         (interface (find (compose (cute string=? port-type <>)
                                                   tree:name)
                                          interfaces))
                         (events (filter-map
                                  tree:name
                                  (filter (compose (cute eq? (port-dir->event-dir port-dir dir) <>)
                                                   tree:event-dir)
                                          (tree:event* interface)))))
                    (map (cute string-append (tree:name port) "." <>) events)))
                ports)))

(define (tree:trigger* context)
  (cond ((find (is? 'interface) context) (tree:event-name* context 'in))
        ((find (is? 'component) context) (tree:port-event-name* context 'trigger))
        (else '())))

(define (tree:action* context)
  (cond ((find (is? 'interface) context) (tree:event-name* context 'out))
        ((find (is? 'component) context) (tree:port-event-name* context 'action))
        (else '())))

(define (tree:formal* port event context)
  (tree:action* context))
