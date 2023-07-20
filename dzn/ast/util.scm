;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2018, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017, 2018, 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
;;; Copyright © 2019, 2020, 2022 Paul Hoogendijk <paul@dezyne.org>
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

(define-module (dzn ast util)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 curried-definitions)
  #:use-module ((oop goops)
                #:select (class-slots slot-definition-getter
                                      slot-definition-name slot-ref))

  #:use-module (dzn ast ast)
  #:use-module (dzn misc)

  #:export (as
            ast-name
            clone
            clone-base
            deep-clone
            drop-<>
            is?
            tree-collect
            tree-collect-filter
            tree-filter
            tree-find
            tree-map))

;;;
;;; Utilities.
;;;
(define-method (tree-find (predicate <applicable>) (o <top>))
  "Breadth first search of a tree element under O matching PREDICATE"
  (define (child* o)
    (let* ((class (class-of o))
           (slots (class-slots class))
           (names (map slot-definition-name slots))
           (children (map (cute slot-ref o <>) names)))
      children))
  (let ((children (child* o)))
    (or (any predicate children)
        (any (cute tree-find predicate <>) children))))

(define-method (tree-find (predicate <applicable>) (o <pair>))
  (or (any predicate o)
      (any (cute tree-find predicate <>) o)))


(define-method (tree-map f o) o)

(define-method (tree-map f (o <ast>))
  (define (setters f names getters)
    (zip (map symbol->keyword names)
         (map (lambda (g) ((compose f g) o)) getters)))
  (let* ((class (class-of (.node o)))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (getters (map slot-definition-getter slots))
         (changed (setters f names getters))
         (original (setters identity names getters)))
    (if (equal? original changed) o
        (apply clone (cons o (apply append changed))))))

(define-method (tree-map f (o <ast-list>))
  (clone o #:elements (map f (.elements o))))
(define-method (tree-map f (o <namespace>))
  (clone o #:elements (map f (.elements o)) #:name (f (.name o))))
(define-method (tree-map f (o <root>))
  (clone o #:elements (map f (.elements o))))

(define-method (tree-filter f (o <ast>))
  (and (f o) o))
(define-method (tree-filter f (o <ast-list>))
  (clone o #:elements (map (cute tree-filter f <>) (filter f (.elements o)))))

(define-method (tree-collect-filter filter-predicate predicate o)
  (if (and (filter-predicate o) (predicate o)) (list o) '()))

(define-method (tree-collect-filter filter-predicate predicate (o <ast>))
  (if (not (filter-predicate o)) '()
      (let* ((class (class-of (.node o)))
             (slots (class-slots class))
             (getters (map slot-definition-getter slots))
             (children
              (append-map
               (lambda (g)
                 (tree-collect-filter filter-predicate predicate (g o)))
               getters)))
        (if (predicate o) (cons o children)
            children))))

(define-method (tree-collect-filter filter-predicate predicate (o <ast-list>))
  (if (not (filter-predicate o)) '()
      (let ((children (append-map
                       (cute tree-collect-filter filter-predicate predicate <>)
                       (.elements o))))
        (if (predicate o) (cons o children) children))))

(define-method (tree-collect predicate o)
  (tree-collect-filter identity predicate o))

(define-method (clone-base o . setters)
  (define (make-pair name)
    (list (symbol->keyword name) (slot-ref o name)))
  (define (car-eq? a b)
    (eq? (car a) (car b)))
  (let* ((class (class-of o))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (paired-members (map make-pair names))
         (paired-setters
          (fold (lambda (elem previous)
                  (if (or (null? previous) (pair? (car previous)))
                      (cons elem previous)
                      (cons (list (car previous) elem) (cdr previous))))
                '()
                setters))
         (wrong (lset-difference equal?
                                 (map car paired-setters)
                                 (map car paired-members)))
         (changed (lset-difference equal? paired-setters paired-members))
         (unchanged (lset-difference car-eq? paired-members changed)))
    (when (pair? wrong)
      (error (format #f "WRONG SETTERS FOUND in ~a: ~a; names = ~a\n"
                     o wrong names)))
    (apply make (cons class (apply append (append unchanged changed))))))

(define-method (clone-base-unwrap o . setters)
  (let ((setters (if (memq #:parent setters) setters
                     (map ast:unwrap setters))))
    (apply clone-base (cons o setters))))

(define-method (clone-base-node (o <ast-node>) . setters)
  (apply clone-base-unwrap (cons o setters)))

(define-method (clone-base-ast (o <ast>) . setters)
  (apply clone-base-unwrap (cons o setters)))

(define-method (clone (o <ast-node>) . setters)
  (apply clone-base-node (cons o setters)))

(define-method (clone (o <ast>) . setters)
  (if (or (memq #:node setters) (memq #:parent setters))
      (apply clone-base-ast (cons o setters))
      (clone-base-ast o #:node (apply clone-base-node
                                      (cons (.node o) setters)))))

(define-method (deep-clone (o <ast-node>))
  (define (make-pair name)
    (list (symbol->keyword name)
          (deep-clone (slot-ref o name))))
  (let* ((class (class-of o))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (names (filter (negate (cute eq? <> 'parent)) names))
         (paired-members (map make-pair names)))
    (apply make (cons class (apply append paired-members)))))

(define-method (deep-clone (o <top>))
  o)

(define-method (deep-clone (o <pair>))
  (cons (deep-clone (car o))
        (deep-clone (cdr o))))

(define-method (deep-clone (o <ast>))
  ((@@ (dzn ast ast) make-wrapper)
   (deep-clone (ast:unwrap o))
   (.parent o)))

(define-method (drop-<> (o <string>))
  (string-drop (string-drop-right o 1) 1))

(define-method (drop-<> (o <symbol>))
  (string->symbol (drop-<> (symbol->string o))))

(define-method (ast-name (o <class>))
  (symbol->string (drop-<> (class-name o))))

(define-method (ast-name (o <top>))
  (ast-name (class-of o)))

(define-method (ast-name (o <ast-node>))
  (let* ((class (class-of o))
         (name (symbol->string (drop-<> (class-name class)))))
    (string-drop-right name 5)))

(define (as o c)
  (and (is-a? o c) o))

(define ((is? class) o)
  (and (is-a? o class) o))
