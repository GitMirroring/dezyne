;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag util)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 match)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (language dezyne location)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)

  #:use-module (gaiag compare)
  #:use-module (gaiag display)

  #:use-module (gaiag misc)
  #:use-module (gaiag reader)
  #:use-module (gaiag om)

  #:export (
            ast-name
            is?
            as
            clone
            om->list
            om2list
            om:children
            om:filter
            om:find
            om:map
            symbol->class
            topological-sort
           ))

(define (drop-<> o)
  (string->symbol (string-drop (string-drop-right (symbol->string o) 1) 1)))

(define-method (ast-name (o <ast>))
  (let ((name (string-drop (string-drop-right (symbol->string (class-name (class-of o))) 1) 1)))
    (string->symbol
     (if (string-prefix? "om:" name) (string-drop name 3) name))))

(define-method (ast-name (o <class>))
  (drop-<> (class-name o)))

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
      (stderr "om->list om=~a\n" om)
      (apply throw (cons key args)))))

(define* (om2list o #:optional (marker null-symbol))
  (match o
    ((? (is? <ast>)) (cons (symbol-append (ast-name o) marker) (map om2list (om:children o))))
    ((h t ...) (map om2list o))
    (_ o)))

(define-method (om:children (o <ast>))
  (map (lambda (slot) (slot-ref o (slot-definition-name slot))) ((compose class-slots class-of) o)))

(define-method (om:children (o <ast-list>))
  (.elements o))

(define-method (om:filter pred (o <ast-list>))
  (filter pred (.elements o)))

(define-method (om:find pred (o <ast-list>))
  (find pred (.elements o)))

(define (om:map f o)
  (match o
    ((? (is? <ast-list>)) (clone o #:elements (map f (.elements o))))
    ((? (is? <ast>)) (clone o (om:map-initializer f)))
    (_ o)))

(define (((om:map-initializer f) o) name)
  (list (symbol->keyword name) (f (slot-ref o name))))

(define (pk o)
  (stderr ";; ~a\n" o)
  o)

(define-method (clone (o <ast>) (make-initializer <procedure>))
 (let* ((class (class-of o))
        (slots (class-slots class))
        (names (map slot-definition-name slots))
	(make-pair (lambda (name) (list (symbol->keyword name) (slot-ref o name))))
        (changed (map (make-initializer o) names))
        (original (map make-pair names)))
   (if (equal? original changed) o
       (let* ((cloned (apply make (cons class (apply append changed)))))
         (retain-source-properties o cloned)))))

(define-method (clone o . setters)
  (let* ((class (class-of o))
        (slots (class-slots class))
        (names (map slot-definition-name slots))
	(make-pair (lambda (name) (list (symbol->keyword name) (slot-ref o name))))
    	(paired-members (map make-pair names))
    	(paired-setters (fold (lambda (elem previous) (if (or (null? previous) (pair? (car previous)))
    							  (cons elem previous)
    							  (cons (list (car previous) elem) (cdr previous))))
    			      '() setters))
        (changed (lset-difference equal? paired-setters paired-members))
    	(unchanged (lset-difference (lambda (a b) (eq? (car a) (car b))) paired-members changed)))
    (if (null? changed) o
    	(apply make (cons class (apply append (append unchanged changed)))))))

(define-method (clone (o <ast>) . setters)
  (retain-source-properties o (next-method)))

(define (topological-sort lst)
  (receive (systems other) (partition (is? <system>) lst)
    (append
     (stable-sort other
                  (lambda (a b)
                    (or (and (is-a? a <data>)
                             (or (is-a? b <interface>)
                                 (is-a? b <component>)))
                        (and (is-a? a <interface>)
                             (is-a? b <component>)))))
     (reverse ((lambda (dag)
                 (if (null? dag)
                     '()
                     (let* ((adj-table (make-hash-table)) ;; SLIB was smarter about setting the length...
                            (sorted '()))
                       (letrec ((visit
                                 (lambda (u adj-list)
                                   ;; Color vertex u
                                   (hashq-set! adj-table u 'colored)
                                   ;; Visit uncolored vertices which u connects to
                                   (for-each (lambda (v)
                                               (let ((val (hashq-ref adj-table v)))
                                                 (if (not (eq? val 'colored))
                                                     (visit v (or val '())))))
                                             adj-list)
                                   ;; Since all vertices downstream u are visited
                                   ;; by now, we can safely put u on the output list
                                   (set! sorted (cons u sorted)))))
                         ;; Hash adjacency lists
                         (for-each (lambda (def)
                                     (hashq-set! adj-table (car def) (cdr def)))
                                   (cdr dag))
                         ;; Visit vertices
                         (visit (caar dag) (cdar dag))
                         (for-each (lambda (def)
                                     (let ((val (hashq-ref adj-table (car def))))
                                       (if (not (eq? val 'colored))
                                           (visit (car def) (cdr def)))))
                                   (cdr dag)))
                       sorted)))
               (map (lambda (o) (cons o (filter (is? <system>) (map .type ((compose .elements .instances) o))))) systems))))))
