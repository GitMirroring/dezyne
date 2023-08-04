;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)
  #:use-module ((oop goops)
                #:select (class-slots slot-definition-name slot-ref))

  #:use-module (dzn ast ast)
  #:use-module (dzn ast accessor)
  #:use-module (dzn ast context)
  #:use-module (dzn misc)

  #:export (ast-name
            clone
            clone-top
            drop-<>
            graft
            graft*
            tree-collect
            tree-collect-filter
            tree-filter
            tree-find
            tree-map))

;;;
;;; Clone, graft.
;;;
(define-method (keyword-values+mutate? (o <object>) . keyword-values)
  "Return multiple values; the full list of paired KEYWORD-VALUES to
create a fresh clone, and #true if any slots need mutation."
  (define (make-pair name)
    (list (symbol->keyword name) (slot-ref o name)))
  (define (car-eq? a b)
    (eq? (car a) (car b)))
  (let* ((class (class-of o))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (actual-keyword-values (map make-pair names))
         (keyword-values
          (fold (lambda (elem previous)
                  (if (or (null? previous) (pair? (car previous)))
                      (cons elem previous)
                      (cons (list (car previous) elem) (cdr previous))))
                '()
                keyword-values))
         (invalid (lset-difference equal?
                                   (map car keyword-values)
                                   (map car actual-keyword-values)))
         (mutate (lset-difference equal?
                                  keyword-values
                                  actual-keyword-values))
         (missing (lset-difference car-eq?
                                   actual-keyword-values
                                   keyword-values))
         (keyword-values (append missing keyword-values)))
    (when (pair? invalid)
      (let ((slots (map car actual-keyword-values)))
        (error (format #f "invalid keyword arguments in ~a: ~a; slots = ~a\n"
                       o invalid slots))))
    (values keyword-values (pair? mutate))))

(define-method (clone-top (o <object>) . keyword-values)
  "Return fresh clone of O, mutating slots from KEYWORD-VALUES."
  (let ((paired-keyword-values
         (apply keyword-values+mutate? o keyword-values))
        (class (class-of o)))
    (apply make class (apply append paired-keyword-values))))

(define-method (clone (o <ast>) . keyword-values)
  (apply clone-top o keyword-values))

(define-method (deep-copy (o <ast>))
  "Make a unique identical copy of O and of its children."
  (define (make-pair name)
    (list (symbol->keyword name)
          (deep-copy (slot-ref o name))))
  (let* ((class (class-of o))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (paired-members (map make-pair names)))
    (apply make class (apply append paired-members))))

(define-method (deep-copy (o <top>))
  "Do not copy objects without children."
  o)

(define-method (deep-copy (o <pair>))
  "Support lists"
  (cons (deep-copy (car o))
        (deep-copy (cdr o))))

(define-method (deep-copy* (parent <ast>) (o <ast>))
  (let ((o (deep-copy o)))
    (ast:memoize-context o (ast:context parent))
    o))

(define-method (deep-copy* (parent <ast>) (o <top>))
  "Do not copy, nor memoize non-<ast> objects without children."
  o)

(define-method (graft (parent <ast>) (o <ast>))
  (deep-copy* parent o))

(define-method (graft (o <ast>) . keyword-values)
  (let ((parent (.parent o)))
    (unless parent
      (apply throw 'no-parent "graft without parent" o keyword-values))
    (deep-copy* parent (apply clone o keyword-values))))

(define-method (graft* (parent <ast>) (o <ast>) . keyword-values)
  (deep-copy* parent (apply clone o keyword-values)))


;;;
;;; Ast utilities.
;;;
(define-method (drop-<> (o <string>))
  (string-drop (string-drop-right o 1) 1))

(define-method (drop-<> (o <symbol>))
  (string->symbol (drop-<> (symbol->string o))))

(define-method (ast-name (o <class>))
  (symbol->string (drop-<> (class-name o))))

(define-method (ast-name (o <top>))
  (ast-name (class-of o)))


;;;
;;; Tree utilities.
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
  (define (setters f names)
    (zip (map symbol->keyword names)
         (map (compose f (cute slot-ref o <>)) names)))
  (let* ((class (class-of o))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (changed (setters f names))
         (original (setters identity names)))
    (if (equal? original changed) o
        (apply clone o (apply append changed)))))

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
      (let* ((class (class-of o))
             (slots (class-slots class))
             (slot-names (map slot-definition-name slots))
             (elements (filter-map (cute slot-ref o <>) slot-names))
             (children (append-map
                        (cute tree-collect-filter filter-predicate predicate <>)
                        elements)))
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
