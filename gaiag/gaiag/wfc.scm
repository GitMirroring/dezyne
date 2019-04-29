;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2014, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

(define-module (gaiag wfc)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 pretty-print)

  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag ast)

  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag util)

  #:export (
           ast:wfc
           ))

(define (ast:wfc o)
  (let* ((errors (append
                  (interface o)
                  (component o)
                  ((second-on) o)
                  (mixing-declarative-imperative o)
                  (action-context o))))
    (when (pair? errors)
      (for-each report-error errors)
      (exit 1)))
  o)

(define (report-error o)
  (let* ((ast (.ast o))
         (loc (.location ast)))
    (if loc
        (stderr "~a:~a:~a: error: ~a\n" (.file-name loc) (.line loc) (.column loc) (.message o))
        (stderr "error: ~a\n" (.message o)))))

(define (wfc-error o message)
  (make <error> #:ast o #:message message))

(define (action-context o)
  (let ((actions (tree-collect (is? <action>) o)))
    (filter-map (lambda (action)
                  (let ((p (.parent action)))
                    (cond ((and (not (is-a? p <variable>))
                                (or (is-a? p <expression>)
                                    (and (is-a? p <if>)
                                         (not (ast:eq? action (.then p)))
                                         (not (ast:eq? action (.else p))))))
                           (wfc-error action "action in expression"))
                          ((and (not (parent action <on>))
                                (not (parent action <function>)))
                           (wfc-error action "action outside on"))
                          ((and (is-a? (ast:type action) <void>)
                                (is-a? p <variable>))
                           (wfc-error action "void value not ignored as it ought to be"))
                          ((and (not (is-a? (ast:type action) <void>))
                                (not (is-a? p <assign>))
                                (not (is-a? p <variable>)))
                           (wfc-error action "valued action must be used in variable assignment"))
                          (else #f))))
                actions)))

(define (interface o)
  (match o
    ((and ($ <root> (= .elements elements))) (append-map interface elements))
    ((and ($ <interface>) (= .behaviour #f))
     (list (wfc-error o "interface must have a behaviour")))
    (_ '())))

(define (component o)
  (match o
    ((and ($ <root>) (= .elements elements)) (append-map component elements))
    ((and ($ <component>) (= .behaviour behaviour) (= ast:provided ports))
     (if (and behaviour
              (>0 (length (filter ast:provides? ports)))) '()
              (list (wfc-error o "component with behaviour must have a provides port"))))
    (_ '())))

(define* ((second-on #:optional (count 0)) o)
  (match o
    ((and ($ <root>) (= .elements elements)) (append-map (second-on) elements))
    (($ <system>) '())
    (($ <foreign>) '())
    (($ <interface>) (or (and=> (.behaviour o) (second-on)) '()))
    (($ <component>) (or (and=> (.behaviour o) (second-on)) '()))
    (($ <behaviour>) (or (and=> (.statement o) (second-on)) '()))
    (($ <compound>) (append-map (second-on count) (ast:statement* o)))
    (($ <on>)
     (if (>0 count) (list (wfc-error o "nested on"))
         ((second-on (1+ count)) (.statement o))))
    (($ <guard>) ((second-on count) (.statement o)))
    (_ '())))

(define (mixing-declarative-imperative o)
  (match o
    ((and ($ <root>) (= .elements elements)) (append-map mixing-declarative-imperative elements))
    (($ <system>) '())
    (($ <foreign>) '())
    (($ <interface>) (or (and=> (.behaviour o) mixing-declarative-imperative) '()))
    (($ <component>) (or (and=> (.behaviour o) mixing-declarative-imperative) '()))
    (($ <behaviour>) (or (and=> (.statement o) mixing-declarative-imperative) '()))
    ((and ($ <compound>) (? om:declarative?))
     (append
      (or (and-let* ((imperative
                      (null-is-#f (filter om:imperative? (ast:statement* o))))
                     (ast (car imperative)))
            (list (wfc-error ast "declarative statement expected")))
          '())
      (append-map mixing-declarative-imperative (ast:statement* o))))
    (($ <compound>)
     (append
      (or (and-let* ((declarative
                      (null-is-#f (filter om:declarative? (ast:statement* o))))
                     (ast (car declarative)))
            (list (wfc-error ast "imperative statement expected")))
          '())
      (append-map mixing-declarative-imperative (ast:statement* o))))
    (($ <on>) (mixing-declarative-imperative (.statement o)))
    (($ <guard>) (mixing-declarative-imperative (.statement o)))
    ((and ($ <if>) (= .then then) (= .else #f)) (mixing-declarative-imperative then))
    ((and ($ <if>) (= .then then) (= .else else)) (append (mixing-declarative-imperative then)
                                                          (mixing-declarative-imperative else)))
    (_ '())))

(define (ast-> ast)
  ((compose
    pretty-print
    om->list
    ast:wfc)
   ast))
