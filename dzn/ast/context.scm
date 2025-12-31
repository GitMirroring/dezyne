;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2023, 2026 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2023 Rutger van Beusekom <rutger@dezyne.org>
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
;;; Implement efficient O(1) parent lookup by using a hash table from
;;; object O to context, where context looks like:
;;;
;;;     (o ... ancestor-0 ... ancestor-n ... root)
;;;
;;; in %context parameter.
;;;
;;; Code:

(define-module (dzn ast context)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module ((oop goops)
                #:select (class-slots slot-definition-name slot-ref))

  #:use-module (dzn ast ast)
  #:use-module (dzn misc)

  #:export (%root
            %context
            .parent

            ast:context
            ast:context
            ast:context?
            ast:memoize-context
            ast:parent
            ast:path
            with-root))

;;;
;;; Context, parent.
;;;

;; The context table.
(define %context (make-parameter #f))

;; The current root.
(define (%root) (hashq-ref (%context) 'root))

(define-method (ast:context? (o <pair>))
  (match o
    (((? (is? <ast>)) (? (is? <ast>)) ...) o)
    (_ #f)))

(define-method (ast:context? (o <top>))
  #f)

(define-method (ast:keyword+child* (o <object>))
  (let* ((class (class-of o))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (keywords (map symbol->keyword names))
         (children (map (cute slot-ref o <>) names)))
    (zip keywords children)))

(define-method (ast:child* (o <object>))
  (append-map (match-lambda
                ((keyword (children ...)) children)
                ((keyword child) (list child)))
              (ast:keyword+child* o)))

(define-method (ast:memoize-context (o <ast>) context)
  "Fill context lookup table from O down."
  (let ((context (cons o context)))
    (unless (%context)
      (throw 'no-context "ast:memoize-context"))
    (hashq-set! (%context) o context)
    (for-each (cute ast:memoize-context <> context)
              (filter (is? <ast>) (ast:child* o)))))

(define-method (ast:memoize-context (root <root>))
  "Create new context lookup hash table for ROOT in %context."
  (parameterize ((%context (make-hash-table 512)))
    (ast:memoize-context root '())
    (hashq-set! (%context) 'root root)
    (%context)))

(define-method (ast:context (o <ast>))
  (unless (%context)
    (throw 'no-context "ast:context"))
  (hashq-ref (%context) o))

(define-method (with-root (procedure <applicable>))
  "Apply procedure on the ROOT, memoize all contexts under the new ROOT
and maintain them in %CONTEXT, dropping the previous contexts.  This
method is a convenience wrapper around ast:memoize-context for a ROOT."
  (lambda (root)
    (let ((root (procedure root)))
      (%context (ast:memoize-context root))
      root)))


;;;
;;; Algorithmic accessors.
;;;
(define-method (.ast (o <pair>))
  (match o
    (((and (? (is? <ast>)) ast) (? (is? <ast>)) ...) ast)
    (_ #f)))

(define-method (.parent (context <list>))
  (match context
    ((o context ...) context)
    (_ #f)))

(define-method (.parent (o <ast>))
  (let ((parent (and=>
                 (and=>
                  (and=> (ast:context o) .parent)
                  ast:context?)
                 .ast)))
    (when (eq? parent o)
      (throw 'parent-loop (ast:context o)))
    parent))

(define-method (ast:parent (context <pair>) (class <class>))
  (let loop ((context (.parent context)))
    (and (ast:context? context)
         (let ((ast (.ast context)))
           (if (is-a? ast class) context
               (and ast
                    (loop (.parent context))))))))

(define-method (ast:parent (o <ast>) (type <class>))
  (let ((context (ast:context o)))
    (unless context
      (throw 'no-context type (.id o) o))
    (and=>
     (and=> context (cute ast:parent <> type))
     .ast)))

(define-method (ast:parent (o <root>) (type <class>))
  (and (ast:context o) (next-method)))

(define-method (ast:parent (o <bool>) (type <class>))
  (and (ast:context o) (next-method)))

(define-method (ast:parent (o <int>) (type <class>))
  (and (ast:context o) (next-method)))

(define-method (ast:parent (o <void>) (type <class>))
  (and (ast:context o) (next-method)))

(define-method (ast:parent (o <ast>) (predicate <applicable>))
  (let loop ((o o))
    (if (predicate o) o
        (loop (.parent o)))))

(define-method (ast:parent (o <root>) (predicate <applicable>))
  #f)

(define-method (ast:path (o <ast>))
  (ast:path o (negate identity)))

(define-method (ast:path (o <ast>) stop?)
  (unfold stop? identity .parent o))
