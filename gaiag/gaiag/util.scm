;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (language dezyne location)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag goops)

  #:use-module (gaiag compare)
  #:use-module (gaiag display)

  #:use-module (gaiag misc)
  #:use-module (gaiag reader)

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
	(bar (lambda (name) (list (symbol->keyword name) (slot-ref o name))))
        (changed (map (make-initializer o) names))
        (original (map bar names)))
   (if (equal? original changed) o
       (begin
         ;(stderr "clone2\n")
         (let* ((cloned (apply make (cons class (apply append changed)))))
                   (retain-source-properties o cloned))))))

(define-method (clone o . setters)
  (let* ((class (class-of o))
        (slots (class-slots class))
        (names (map slot-definition-name slots))
	(bar (lambda (name) (list (symbol->keyword name) (slot-ref o name))))
    	(paired-members (map bar names))
    	(paired-setters (fold (lambda (elem previous) (if (or (null? previous) (pair? (car previous)))
    							  (cons elem previous)
    							  (cons (list (car previous) elem) (cdr previous))))
    			      '() setters))
        (changed (lset-difference equal? paired-setters paired-members))
    	(unchanged (lset-difference (lambda (a b) (eq? (car a) (car b))) paired-members changed)))
    (if (null? changed) o
    	(begin
          ;(stderr "clone1\n")
          (apply make (cons class (apply append (append unchanged changed))))))))

(define-method (clone (o <ast>) . setters)
  (retain-source-properties o (next-method)))

