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

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module ((oop goops)
                #:select (class-slots slot-definition-name slot-ref))

  #:use-module (dzn ast accessor)
  #:use-module (dzn ast context)
  #:use-module (dzn ast goops)
  #:use-module (dzn goops util)
  #:use-module (dzn misc)

  #:export (ast-name
            clone
            clone-top
            clone+root
            graft
            graft*
            tree-collect
            tree-collect-filter
            tree-graft
            tree-filter
            tree-find
            tree-map
            tree-transform)
  #:re-export (constructor-name))

(define ast:keyword+child* (@@ (dzn ast context) ast:keyword+child*))
(define ast:child* (@@ (dzn ast context) ast:child*))

;;;
;;; Clone, graft.
;;;
(define-method (keyword-values+mutate? (o <object>) . keyword-values)
  "Return multiple values; the full list of paired KEYWORD-VALUES to
create a fresh clone, and #true if any slots need mutation."
  (define (car-eq? a b)
    (eq? (car a) (car b)))
  (let* ((actual-keyword-values (ast:keyword+child* o))
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

(define-method (deep-copy (o <object>))
  "Make a unique identical copy of O and of its children."
  (let* ((class (class-of o))
         (keyword-values (ast:keyword+child* o))
         (keyword-copies (map (match-lambda
                                ((keyword (values ...))
                                 (list keyword (map deep-copy values)))
                                ((keyword value)
                                 (list keyword (deep-copy value))))
                              keyword-values))
         (keyword-copies (apply append keyword-copies)))
    (apply make class keyword-copies)))

(define-method (deep-copy (o <top>))
  "Do not copy objects without children."
  o)

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
(define-method (ast-name (o <class>))
  (symbol->string (constructor-name o)))

(define-method (ast-name (o <top>))
  (ast-name (class-of o)))


;;;
;;; Tree utilities.
;;;
(define-method (tree-find (predicate <applicable>) (o <object>))
  "Breadth first search of a tree element under O for with PREDICATE."
  (let* ((actual-keyword-values (ast:keyword+child* o))
         (children (append-map
                    (match-lambda
                          ((keyword (values ...))
                           values)
                          ((keyword value)
                           (list value)))
                    actual-keyword-values)))
    (or (any predicate children)
        (any (cute tree-find predicate <>)
             (filter (disjoin (is? <string>) (is? <number>) (is? <boolean>))
                     children)))))

(define-method (tree-find (predicate <applicable>) (o <pair>))
  (or (any predicate o)
      (any (cute tree-find predicate <>) o)))

(define-method (tree-find (predicate <applicable>) (o <top>)) (predicate o))

(define-method (tree-map f (o <object>))
  (let* ((class (class-of o))
         (actual-keyword-values (ast:keyword+child* o))
         (keyword-values (map (match-lambda
                                ((keyword (values ...))
                                 (list keyword (map f values)))
                                ((keyword value)
                                 (list keyword (f value))))
                              actual-keyword-values))
         (keyword-values (apply append keyword-values)))
    (if (equal? keyword-values actual-keyword-values) o
        (apply make class keyword-values))))

(define-method (tree-map f (o <top>)) o)

(define-method (tree-filter f (o <ast>))
  (and (f o) o))
(define-method (tree-filter f (o <ast-list>))
  (clone o #:elements (map (cute tree-filter f <>) (filter f (.elements o)))))

(define-method (tree-collect-filter filter-predicate predicate (o <object>))
  (if (not (filter-predicate o)) '()
      (let ((children (append-map
                       (cute tree-collect-filter filter-predicate predicate <>)
                       (ast:child* o))))
        (if (predicate o) (cons o children)
            children))))

(define-method (tree-collect-filter filter-predicate predicate (o <top>))
  (if (and (filter-predicate o) (predicate o)) (list o) '()))

(define-method (tree-collect predicate o)
  (tree-collect-filter identity predicate o))

(define-method (tree-graft (o <ast>) (kloon <ast>))
  "XXX FIXME? Clone O and its ancestors including root returning
multiple values: the clone and the cloned root."
  (define (replace orig kloon)
    (match-lambda
      ((keyword value)
       (let ((value (or (and (pair? value)
                             (map (lambda (v)
                                    (if (eq? v orig) kloon
                                        v))
                                  value))
                        (and (eq? value orig) kloon)
                        value)))
         `(,keyword ,value)))))
  (define clone-children
    (match-lambda*
      ((ancestor (orig . kloon))
       (let* ((class (class-of ancestor))
              (keyword-values (ast:keyword+child* ancestor))
              (keyword-values (map (replace orig kloon) keyword-values))
              (keyword-values (apply append keyword-values)))
         `(,ancestor . ,(apply clone ancestor keyword-values))))))
  (let* ((context (.parent (ast:context o)))
         (ancestor+root (fold clone-children `(,o . ,kloon) context))
         (root (match ancestor+root ((ancestor . root) root))))
    root))

(define-method (clone+root (o <ast>) . keyword-values)
  "Clone O and its ancestors including root and return multiple values:
the clone and the cloned root."
  (let ((kloon (apply clone o keyword-values)))
    (values kloon (tree-graft o kloon))))

(define-method (tree-transform (o <ast>) predicate transform)
  (tree-transform o `((,predicate . ,transform))))

(define-method (tree-transform (o <ast>) predicates+transforms)
  "Transform each element in the tree matching PREDICATE using TRANSFORM.
Note that TRANSFORM returning #f effectively removes o from the
tree."
  (define tree-transform-keyword-value
    (match-lambda
      ((keyword (values ...))
       `(,keyword ,(filter-map
                    (cute tree-transform <> predicates+transforms)
                    values)))
      ((keyword value)
       `(,keyword ,(tree-transform value predicates+transforms)))))
  (let ((tree-transform (cute tree-transform <> predicates+transforms)))
    (let* ((keyword-values (ast:keyword+child* o))
           (keyword-values'
            (map tree-transform-keyword-value keyword-values))
           (parent (.parent o))
           (o (if (every equal? keyword-values' keyword-values) o
                  (let* ((class (class-of o))
                         (keyword-values (apply append keyword-values'))
                         (o (apply make class keyword-values)))
                    (if (is-a? o <root>) (ast:memoize-context* o)
                        (ast:memoize-context* o parent))))))
      (fold (match-lambda*
              (((predicate . transform) o)
               (if (not (predicate o)) o
                   (transform o))))
            o predicates+transforms))))

(define-method (tree-transform (o <top>) predicates+transforms)
  o)
