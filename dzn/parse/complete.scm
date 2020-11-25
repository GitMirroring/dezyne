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
                    (and (<= from at) (<= at to)))))
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

(define (tree:enum-names o)
  (map tree:dotted-name (tree:enum* (or (slot o 'interface) (slot o 'root)))))

(define* (tree:event-names o event-dir)
  (let* ((events (tree:event* (find (is? 'interface) o)))
         (events (filter (compose (cute eq? event-dir <>) tree:event-dir) events)))
    (map tree:dotted-name events)))

(define* (tree:interface-names o)
  (map tree:dotted-name (tree:interface* o)))

(define (port-dir->event-dir port-dir dir)
  (cond ((and (eq? 'provides port-dir) (eq? 'trigger dir)) 'in)
        ((and (eq? 'provides port-dir) (eq? 'action dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'trigger dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'action dir)) 'in)))

(define (tree:port-event-names o dir) ;;dir 'trigger or 'action
  (let* ((ports (tree:port* (find (is? 'component) o)))
         (interface-names (map tree:type-name ports))
         (interfaces (filter (compose (cute member <> interface-names string=?)
                                      tree:dotted-name)
                             (tree:interface* (slot o 'root)))))
    (append-map (lambda (port)
                  (let* ((port-type (tree:type-name port))
                         (port-dir (tree:port-dir port))
                         (interface (find (compose (cute string=? port-type <>)
                                                   tree:dotted-name)
                                          interfaces))
                         (events (filter-map
                                  tree:dotted-name
                                  (filter (compose (cute eq? (port-dir->event-dir port-dir dir) <>)
                                                   tree:event-dir)
                                          (tree:event* interface)))))
                    (map (cute string-append (tree:dotted-name port) "." <>) events)))
                ports)))

(define (tree:trigger-names o)
  (let ((tree (.tree o)))
    (cond ((find (is? 'interface) o) (tree:event-names o 'in))
          ((find (is? 'component) o) (tree:port-event-names o 'trigger))
          (else '()))))

(define (tree:action-names o)
  (let ((tree (.tree o)))
    (cond ((find (is? 'interface) o) (tree:event-names o 'out))
          ((find (is? 'component) o) (tree:port-event-names o 'action))
          (else '()))))

(define (tree:formal-names port event o)
  (tree:action-names o))


;;;
;;; Entry point.
;;;

(define (complete o context offset)
  (match o
    (('root (? (disjoin complete? tree:location?)) ...) '("component" "interface"))
    (('interface (? (disjoin incomplete? tree:location?)) ..1) '())
    ('types-and-events '("bool" "enum" "in" "out"))
    (('types-and-events types-events ...) '("behaviour" "bool" "enum" "in" "out"))
    ('type-name (cons* "bool" "void" (tree:enum-names context)))
    ((and (? (is? 'ports)) (? (cute around-location? <> offset))) '("provides" "requires"))
    ((? (is? 'ports)) '("behaviour" "provides" "requires" "system"))
    ('body '("behaviour" "provides" "requires" "system"))
    ('behaviour '("behaviour" "bool" "enum" "in" "out"))
    (('behaviour-compound (? (disjoin incomplete? tree:location?)) ...) '("on"))

    ((? (is? 'name)) (complete (.tree (.parent context)) (.parent context) offset))

    (('triggers (? (disjoin incomplete? tree:location?)) ...) (tree:trigger-names context))
    ((? (is? 'trigger)) (tree:trigger-names context))

    (('on (? (is? 'triggers)) (? tree:location?)) (tree:action-names context))

    ('statement (tree:action-names context))
    (('compound (? tree:location?)) '("on")) ;;FIXME point solution: fixes component7.dzn

    (('compound (? (disjoin incomplete? tree:location?)) ...) (tree:action-names context))
    ((? (is? 'action)) (tree:action-names context))

    ('BRACE-CLOSE '())
    ('BRACE-OPEN '())
    ((? symbol?) '())
    (_ (if (complete? o) '()
           (or (complete (find incomplete? (cdr o)) context offset)
               (complete (before-location? o offset) context offset))))))

;; TODO: rewrite above as:
;; (define (complete o context offset)
;;   (match o
;;     ((? (is? 'trigger)) (tree:trigger-names context))
;;     ((? (is? 'name)) (complete (.tree (.parent context)) (.parent context) offset))
;;     (_ '())))
