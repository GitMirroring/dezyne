;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag util)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 match)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)

  #:use-module (gaiag resolve)
  #:use-module (gaiag compare)
  #:use-module (gaiag display)

  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag ast)

  #:export (
            ast-name
            is?
            as
            om->list
            om:children
            om:filter
            om:find
            drop-<>
            symbol->class
            symbol-join
            topological-sort
           ))

(define (drop-<> o)
  (string->symbol (string-drop (string-drop-right (symbol->string o) 1) 1)))

(define-method (ast-name (o <top>))
  (drop-<> (class-name (class-of o))))

(define-method (ast-name (o <class>))
  (drop-<> (class-name o)))

(define (symbol-join ls)
  (reduce (lambda (a b) (symbol-append a '. b)) (string->symbol "") ls))

(define (symbol->class x) (symbol-append '< x '>))

(define (as o c)
  (and (is-a? o c) o))

(define ((is? class) o)
  (and (is-a? o class) o))

(define (om->list om)
  (catch #t
    (lambda ()
      (with-input-from-string
          (with-output-to-string (lambda () (write om)))
        read))
    (lambda (key . args)
      (apply throw (cons key args)))))

(define-method (om:children (o <ast>))
  (map (lambda (slot) (slot-ref o (slot-definition-name slot))) ((compose class-slots class-of) o)))

(define-method (om:children (o <ast-list>))
  (.elements o))

(define-method (om:filter pred (o <ast-list>))
  (filter pred (.elements o)))

(define-method (om:find pred (o <ast-list>))
  (find pred (.elements o)))

(define (topological-sort lst)

  (define (key x) ((compose .name .name) x))
  (define (sort dag)
    (if (null? dag)
        '()
        (let* ((adj-table (make-hash-table))
               (foo (for-each (lambda (def) (hashq-set! adj-table (key (car def)) (cdr def))) dag))
               (sorted '()))

          (define (visit node children)
            (if (eq? 'visited (hashq-ref adj-table (key node))) (error "double visit")
                (begin
                  (hashq-set! adj-table (key node) 'visited)
                  ;; Visit unvisited nodes which node connects to
                  (for-each (lambda (child)
                              (let ((val (hashq-ref adj-table (key child))))
                                ;;(stderr "val1: ~a ~a\n" (.name child) val)
                                (if (not (eq? val 'visited))
                                    (visit child (or val '())))))
                            children)
                  ;; Since all nodes downstream node are visited
                  ;; by now, we can safely put node on the output list
                  (set! sorted (cons node sorted)))))


          ;; Visit nodes
          (visit (caar dag) (cdar dag))
          (for-each (lambda (def)
                      (let ((val (hashq-ref adj-table (key (car def)))))
                        ;;(stderr "val2: ~a ~a\n" (.name (car def)) val)
                        (if (not (eq? val 'visited))
                            (visit (car def) (cdr def)))))
                    (cdr dag))
          sorted)))

  (receive (systems other) (partition (is? <system>) lst)
    (append
     (stable-sort other
                  (lambda (a b)
                    (or (and (is-a? a <data>)
                             (or (is-a? b <interface>)
                                 (is-a? b <component>)
                                 (is-a? b <foreign>)))
                        (and (is-a? a <interface>)
                             (or (is-a? b <component>)
                                 (is-a? b <foreign>))))))
     (reverse (sort (map (lambda (o) (cons o
                                           (filter (is? <system>)
                                                   (map .type (ast:instance* o)))))
                         systems))))))
