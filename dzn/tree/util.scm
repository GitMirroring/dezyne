;;; Snuik --- An IRC bot using guile-8sync
;;; Copyright © 2020, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>;;;
;;; This file is part of Snuik.
;;;
;;; Snuik is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Snuik is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Snuik.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn tree util)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)

  #:use-module (dzn goops define-method-star)
  #:use-module (dzn goops goops)
  #:use-module (dzn goops util)
  #:use-module (dzn tree context)
  #:use-module (dzn tree tree)
  #:use-module (dzn misc)

  #:export (clone+root
            graft
            graft*
            tree:collect
            tree:copy
            tree:get
            tree:graft
            tree:filter
            tree:find
            tree:transform))

(define-method (tree:copy (parent <tree>) (o <tree>))
  (let ((o (deep-copy o)))
    (tree:memoize-context o (tree:context parent))
    o))

(define-method (tree:copy (parent <tree>) (o <top>))
  "Do not copy, nor memoize non-<tree> objects without children."
  o)

(define-method (graft (parent <tree>) (o <tree>))
  (tree:copy parent o))

(define-method (graft (o <tree>) . keyword-values)
  (let ((parent (tree:parent o)))
    (unless parent
      (apply throw 'no-parent "graft without parent" o keyword-values))
    (tree:copy parent (apply clone o keyword-values))))

(define-method (graft* (parent <tree>) (o <tree>) . keyword-values)
  (tree:copy parent (apply clone o keyword-values)))


;;;
;;; Tree utilities.
;;;
(define-method (tree:find (predicate <applicable>) (o <object>))
  "Breadth first search of a tree element under O for with PREDICATE."
  (let* ((actual-keyword-values (keyword+child* o))
         (children (append-map
                    (match-lambda
                          ((keyword (values ...))
                           values)
                          ((keyword value)
                           (list value)))
                    actual-keyword-values)))
    (or (any predicate children)
        (any (cute tree:find predicate <>)
             (filter (disjoin (is? <string>) (is? <number>) (is? <boolean>))
                     children)))))

(define-method (tree:find (predicate <applicable>) (o <pair>))
  (or (any predicate o)
      (any (cute tree:find predicate <>) o)))

(define-method (tree:find (predicate <applicable>) (o <top>)) (predicate o))

(define-method* (tree:collect (o <object>) (predicate <applicable>) #:key
                              (stop? identity))
  (if (not (stop? o)) '()
      (let ((children (append-map
                       (cut tree:collect <> predicate #:stop? stop?)
                       (child* o))))
        (if (predicate o) (cons o children)
            children))))

(define-method* (tree:collect (o <top>) (predicate <applicable>) #:key
                              (stop? identity))
  (if (and (stop? o) (predicate o)) (list o)
      '()))

(define-method* (tree:get (o <top>) (predicate <applicable>) #:key
                          (stop? identity))
  (match (tree:collect o predicate #:stop? stop?)
    ((found) found)
    (() #f)
    ((found garbage ..1) (throw 'found-multiple (cons found garbage)))))

(define-method (tree:graft (o <tree>) (kloon <tree>))
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
              (keyword-values (keyword+child* ancestor))
              (keyword-values (map (replace orig kloon) keyword-values))
              (keyword-values (apply append keyword-values)))
         `(,ancestor . ,(apply clone ancestor keyword-values))))))
  (let* ((context (context:parent (tree:context o)))
         (ancestor+root (fold clone-children `(,o . ,kloon) context))
         (root (match ancestor+root ((ancestor . root) root))))
    root))

(define-method (clone+root (o <tree>) . keyword-values)
  "Clone O and its ancestors including root and return multiple values:
the clone and the cloned root."
  (let ((kloon (apply clone o keyword-values)))
    (values kloon (tree:graft o kloon))))

(define-method (tree:transform (o <tree>) (predicate <applicable>)
                               (transform <applicable>))
  (tree:transform o `((,predicate . ,transform))))

(define-method (tree:transform (o <tree>) predicates+transforms)
  "Transform each element in the tree matching PREDICATE using TRANSFORM.
Note that TRANSFORM returning #f effectively removes o from the
tree."
  (define transform-keyword-value
    (match-lambda
      ((keyword (values ...))
       `(,keyword ,(filter-map
                    (cute tree:transform <> predicates+transforms)
                    values)))
      ((keyword value)
       `(,keyword ,(tree:transform value predicates+transforms)))))
  (let ((tree:transform (cute tree:transform <> predicates+transforms)))
    (let* ((keyword-values (keyword+child* o))
           (keyword-values'
            (map transform-keyword-value keyword-values))
           (parent (tree:parent o))
           (o (if (every equal? keyword-values' keyword-values) o
                  (let* ((class (class-of o))
                         (keyword-values (apply append keyword-values'))
                         (o (apply make class keyword-values)))
                    (if (is-a? o <tree:root>) (tree:memoize-context* o)
                        (tree:memoize-context* o parent))))))
      (fold (match-lambda*
              (((predicate . transform) o)
               (if (not (predicate o)) o
                   (transform o))))
            o predicates+transforms))))

(define-method (tree:transform (o <top>) predicates+transforms)
  o)
