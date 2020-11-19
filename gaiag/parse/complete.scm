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

;;; XXX TODO: use MATCH instead of first, second, third, fourth

(define-module (gaiag parse complete)
  #:use-module (ice-9 match)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)

  #:use-module (gash util)
  #:use-module (gaiag parse tree)

  #:export (complete
            complete:context))

;;;
;;; Parse tree context.
;;;

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

(define (complete:context o at)
  (let ((narrow (conjoin incomplete? (negate symbol?) (negate location?)))
        (context (reverse (tree:collect o (cute at-location? <> at)))))
    (if (null? context) `(,o)
        (let ((narrow (find narrow (cdar context))))
          (if narrow (cons narrow context)
              context)))))


;;;
;;; Entry point.
;;;

(define (complete o context offset)
  (match
   o
   (('root (? (disjoin complete? location?)) ...) '("component" "interface"))
   (('interface (? (disjoin incomplete? location?)) ..1) '())
   ('types-and-events '("bool" "enum" "in" "out"))
   (('types-and-events types-events ...) '("behaviour" "bool" "enum" "in" "out"))
   ('type-name (cons* "bool" "void" (tree:enum-name* context)))
   ((and (? (is? 'ports)) (? (cute around-location? <> offset))) '("provides" "requires"))
   ((? (is? 'ports)) '("behaviour" "provides" "requires" "system"))
   ('body '("behaviour" "provides" "requires" "system"))
   ('behaviour '("behaviour" "bool" "enum" "in" "out"))
   (('behaviour-compound (? (disjoin incomplete? location?)) ...) '("on"))

   (('triggers (? (disjoin incomplete? location?)) ...) (tree:trigger* context))
   (('trigger port event (? (disjoin incomplete? location?)) ...) (tree:formal* port event context))
   (('on (? (is? 'triggers)) (? location?)) (tree:action* context))

   ('statement (tree:action* context))
   (('compound (? location?)) '("on")) ;;FIXME point solution: fixes component7.dzn
   (('compound (? (disjoin incomplete? location?)) ...) (tree:action* context))
   ('BRACE-CLOSE #f)
   ((? symbol?) '())
   (_ (if (complete? o) '()
          (or (complete (find incomplete? (cdr o)) context offset)
              (complete (before-location? o offset) context offset))))))
