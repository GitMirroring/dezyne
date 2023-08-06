;;; Snuik --- An IRC bot using guile-8sync
;;; Copyright © 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2023 Rutger van Beusekom <rutger@dezyne.org>;;;
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
;;; Implement efficient O(1) parent lookup by using a hash table from
;;; object O to context, where context looks like:
;;;
;;;     (o ... ancestor-0 ... ancestor-n ... root)
;;;
;;; in %context parameter.
;;;
;;; Code:

(define-module (dzn goops context)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)

  #:use-module (dzn goops goops)
  #:use-module (dzn goops util)
  #:use-module (dzn misc)

  #:export (%root
            %context
            <tree>
            <tree:root>
            context:parent
            tree:ancestor
            tree:context
            tree:id
            tree:memoize-context
            tree:memoize-context*
            tree:parent
            tree:path
            with-root))

;;;
;;; Types and parameters.
;;;
(define-class* <tree> (<object>))
(define-class* <tree:root> (<tree>))

;; The context table.
(define %context (make-parameter #f))

;; The current root.
(define (%root) (hashq-ref (%context) 'root))


;;;
;;; Context, id, memoize.
;;;
(define-method (tree:context? (o <pair>))
  "Return #true value O if O is a context, a list of <tree>."
  (match o
    (((? (is? <tree>)) ..1) o)
    (_ #f)))

(define-method (tree:context? (o <top>))
  #f)

(define-method (tree:id (o <tree>))
  (object:id o))

(define-method (tree:memoize-context (o <tree>) context)
  "Fill context lookup table from O down."
  (let ((context (cons o context)))
    (hashq-set! (%context) o context)
    (for-each (cute tree:memoize-context <> context)
              (filter (is? <tree>) (child* o)))))

(define-method (tree:memoize-context (root <tree:root>))
  "Create new context lookup hash table for ROOT in %context."
  (parameterize ((%context (make-hash-table 512)))
    (tree:memoize-context root '())
    (hashq-set! (%context) 'root root)
    (%context)))

(define-method (tree:memoize-context* (o <tree>) (parent <tree>))
  "Add O to context lookup table using context of PARENT."
  (hashq-set! (%context) o (cons o (tree:context parent)))
  o)

(define-method (tree:memoize-context* (o <tree:root>))
  "Add O to context lookup table."
  (hashq-set! (%context) o `(,o))
  o)

(define-method (tree:context (o <tree>))
  (hashq-ref (%context) o))

(define-method (with-root (procedure <applicable>))
  "Apply procedure on the ROOT, memoize all contexts under the new ROOT
and maintain them in %CONTEXT, dropping the previous contexts.  This
method is a convenience wrapper around tree:memoize-context for a ROOT."
  (lambda (root)
    (let ((root (procedure root)))
      (%context (tree:memoize-context root))
      root)))


;;;
;;; Parent, ancestor, path.
;;;
(define-method (context:tree (o <pair>))
  (match o
    (((and (? (is? <tree>)) ast) (? (is? <tree>)) ...) ast)
    (_ #f)))

(define-method (context:parent (context <list>))
  (match context
    ((o context ...) context)
    (_ #f)))

(define-method (tree:parent (o <tree>))
  (let ((parent (and=>
                 (and=>
                  (and=> (tree:context o) context:parent)
                  tree:context?)
                 context:tree)))
    (when (eq? parent o)
      (throw 'parent-loop (tree:context o)))
    parent))

(define-method (tree:parent (o <tree:root>) (type <class>))
  (and (tree:context o) (next-method)))

(define-method (tree:ancestor (context <pair>) (class <class>))
  (let loop ((context (context:parent context)))
    (and (tree:context? context)
         (let ((ast (context:tree context)))
           (if (is-a? ast class) context
               (and ast
                    (loop (context:parent context))))))))

(define-method (tree:ancestor (o <tree>) (type <class>))
  (let ((context (tree:context o)))
    (unless context
      (throw 'no-context type (tree:id o) o))
    (and=>
     (and=> context (cute tree:ancestor <> type))
     context:tree)))

(define-method (tree:ancestor (o <tree:root>) (type <class>))
  (and (tree:context o) (next-method)))

(define-method (tree:ancestor (o <tree>) (predicate <procedure>))
  (and=> (tree:ancestor (tree:context o) predicate)
         context:tree))

(define-method (tree:ancestor (o <tree:root>) (predicate <procedure>))
  #f)

(define-method (tree:path (o <tree>))
  (tree:path o (negate identity)))

(define-method (tree:path (o <tree>) (stop? <applicable>))
  (unfold stop? identity tree:parent o))
