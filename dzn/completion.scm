;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (dzn completion)
  #:use-module (ice-9 match)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:export (complete
            context
            is-a?
            is?
            slot
            line-col->offset
            offset->line-col))

(define (offset->line-col offset text)
  "Lines start at position 1; columns at posion 0"
  (let ((offset (min (string-length text) offset)))
    (cons (1+ (string-count text #\newline 0 offset))
          (- offset (or (and=> (string-rindex text #\newline 0 offset) 1-) 0)))))

(define (line-col->offset line col text)
  "Lines start at position 1; columns at posion 0"
  (let loop ((ln 0) (offset 0))
    (if (= ln (1- line)) (+ offset col)
        (loop (1+ ln) (1+ (or (string-index text #\newline offset) 0))))))

(define (disjoin . predicates)
  (lambda (. arguments)
    (any (cute apply <> arguments) predicates)))

(define (conjoin . predicates)
  (lambda (. arguments)
    (every (cute apply <> arguments) predicates)))

(define (is-a? o symbol)
  (and (pair? o) (eq? symbol (car o))))

(define (is? symbol)
  (lambda (o) (is-a? o symbol)))

(define (slot o symbol)
  (find (is? symbol) (cdr o)))

(define (location? o)
  ((is? 'location) o))

(define (has-location? o)
  (and (pair? o) ((is? 'location) (last o))))

(define (at-location? o at)
  (and (pair? o)
       (or (let ((end (last o)))
             (and ((is? 'location) end)
                  (let ((from (second end))
                        (to (third end)))
                    (and (< from at) (<= at to)))))
           (find (cute at-location? <> at) o))))

(define (after-location? o at)
  (and (pair? o)
       (or (let ((end (last o)))
             (and ((is? 'location) end)
                  (let ((to (third end)))
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
         (and (pair? before) (last (filter (negate (disjoin symbol? location?)) before))))))

(define (tree-collect o predicate)
  (if (predicate o) (cons o (append-map (cute tree-collect <> predicate) o))
      '()))

(define (list-ports o)
  (match
   o
   ((? (is? 'port)) (list o))
   ((? pair?) (append-map list-ports o))
   (_ '())))

(define (list-interfaces o)
  (match
   o
   ((? (is? 'interface)) (list o))
   ((? pair?) (append-map list-interfaces o))
   (_ '())))

(define (list-enums o)
  (match
   o
   ((? (is? 'interface)) (append-map list-enums (cdr o)))
   ((? (is? 'enum)) `(,o))
   ((? pair?) (append-map list-enums o))
   (_ '())))

(define (list-events o)
  (match
   o
   ((? (is? 'interface)) (append-map list-events (cdr o)))
   ((? (is? 'event)) `(,o))
   ((? pair?) (append-map list-events o))
   (_ '())))

(define (get-name o)
  (match
   o
   ((? (is? 'port)) (get-name (fourth o)))
   ((? (is? 'compound-name)) (string-join (filter-map get-name (cdr o)) "."))
   ((? (is? 'type-name)) #f)
   ((? (is? 'event-name)) (get-name (second o)))
   ((? (is? 'name)) (second o))
   ((? pair?) (get-name (find get-name o)))
   (_ #f)))

(define (get-type o)
  (match
   o
   ((? (is? 'port)) (get-name (third o)))
   ((? pair?) (get-type (find get-type o)))
   (_ #f)))

(define (get-event-dir o)
  (match
   o
   ((? (is? 'event)) (get-event-dir (second o)))
   ((? (is? 'direction)) (string->symbol (second o)))
   ((? pair?) (get-event-dir (find get-event-dir o)))
   (_ #f)))

(define (get-port-dir o)
  (match
   o
   ((? (is? 'provides)) 'provides)
   ((? (is? 'requires)) 'requires)
   ((? pair?) (get-port-dir (find get-port-dir o)))
   (_ #f)))

(define (list-enum-names o)
  (map get-name (list-enums (or (find (is? 'interface) o) (find (is? 'root) o)))))

(define* (list-event-names o event-dir)
  (let* ((events (list-events (find (is? 'interface) o)))
         (events (filter (compose (cute eq? event-dir <>) get-event-dir) events)))
    (map get-name events)))

(define* (list-interface-names o)
  (map get-name (list-interfaces o)))

(define (port-dir->event-dir port-dir dir)
  (cond ((and (eq? 'provides port-dir) (eq? 'trigger dir)) 'in)
        ((and (eq? 'provides port-dir) (eq? 'action dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'trigger dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'action dir)) 'in)))

(define (list-port-event-names o dir) ;;dir 'trigger or 'action
  (let* ((ports (list-ports (find (is? 'component) o)))
         (interface-names (map get-type ports))
         (interfaces (filter (compose (cute member <> interface-names string=?)
                                      get-name)
                             (list-interfaces (find (is? 'root) o)))))
    (append-map (lambda (port)
                  (let* ((port-type (get-type port))
                         (port-dir (get-port-dir port))
                         (interface (find (compose (cute string=? port-type <>)
                                                   get-name)
                                          interfaces))
                         (events (filter-map
                                  get-name
                                  (filter (compose (cute eq? (port-dir->event-dir port-dir dir) <>)
                                                   get-event-dir)
                                          (list-events interface)))))
                    (map (cute string-append (get-name port) "." <>) events)))
                ports)))

(define (list-triggers context)
  (cond ((find (is? 'interface) context) (list-event-names context 'in))
        ((find (is? 'component) context) (list-port-event-names context 'trigger))
        (else '())))

(define (list-actions context)
  (cond ((find (is? 'interface) context) (list-event-names context 'out))
        ((find (is? 'component) context) (list-port-event-names context 'action))
        (else '())))

(define (list-formals port event context)
  (list-actions context))

(define (context o at)
  (let ((narrow (conjoin incomplete? (negate symbol?) (negate location?)))
        (context (reverse (tree-collect o (cute at-location? <> at)))))
    (if (null? context) `(,o)
        (let ((narrow (find narrow (cdar context))))
          (if narrow (cons narrow context)
              context)))))

(define (complete? o)
  ((disjoin string?
            (conjoin pair?
                     (compose symbol? first)
                     (compose (is? 'location) last)
                     (compose (cute every complete? <>)
                              (cute drop-right <> 1)
                              cdr))) o))

(define incomplete? (negate complete?))

(define (complete o context offset)
  (match
   o
   (('root (? (disjoin complete? location?)) ...) '("component" "interface"))
   (('interface (? (disjoin incomplete? location?)) ..1) '())
   ('types-and-events '("bool" "enum" "in" "out"))
   (('types-and-events types-events ...) '("behaviour" "bool" "enum" "in" "out"))
   ('type-name (cons* "bool" "void" (list-enum-names context)))
   ((and (? (is? 'ports)) (? (cute around-location? <> offset))) '("provides" "requires"))
   ((? (is? 'ports)) '("behaviour" "provides" "requires" "system"))
   ('body '("behaviour" "provides" "requires" "system"))
   ('behaviour '("behaviour" "bool" "enum" "in" "out"))
   (('behaviour-compound (? (disjoin incomplete? location?)) ...) '("on"))

   (('triggers (? (disjoin incomplete? location?)) ...) (list-triggers context))
   (('trigger port event (? (disjoin incomplete? location?)) ...) (list-formals port event context))
   (('on (? (is? 'triggers)) (? location?)) (list-actions context))

   ('statement (list-actions context))
   (('compound (? location?)) '("on")) ;;FIXME point solution: fixes component7.dzn
   (('compound (? (disjoin incomplete? location?)) ...) (list-actions context))
   ('BRACE-CLOSE #f)
   ((? symbol?) '())
   (_ (if (complete? o) '()
          (or (complete (find incomplete? (cdr o)) context offset)
              (complete (before-location? o offset) context offset))))))
