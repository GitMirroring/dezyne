;;; Snuik --- An IRC bot using guile-8sync
;;; Copyright © 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn tree lookup)
  ;;#:use-module (srfi srfi-1)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)

  #:use-module (dzn goops goops)
  #:use-module (dzn goops util)
  #:use-module (dzn tree accessor)
  #:use-module (dzn tree context)
  #:use-module (dzn tree tree)

  #:export (tree:lookup))

(define-method (tree:lookup (root <tree:root>) (scope <tree:scope>) name)
  "Find NAME in SCOPE using (%symbol-table)."
  (and scope
       (let ((name* (tree:name* name)))
         (match name*
           (("/" . name*)
            (tree:lookup root (tree:name*->name name*)))
           (_
            (let* ((scope name
                          (match name*
                            ((name)
                             (values scope name))
                            ((name* ... name)
                             (let* ((scope-name (tree:name*->name name*))
                                    (scope (tree:lookup scope scope-name)))
                               (values scope name)))))
                   (context (and=> scope tree:context)))
              (let loop ((context context))
                (match context
                  (((and (? (is? <tree:scope>)) scope) . rest)
                   (let ((key (cons (tree:id scope) name)))
                     (or (hash-ref (%symbol-table) key)
                         (loop rest))))
                  ((context . rest)
                   (loop rest))
                  (() #f)
                  (#f #f)))))))))

(define-method (tree:lookup (o <tree>) name)
  (let ((scope (or (as o <tree:scope>) (tree:ancestor o <tree:scope>)))
        (root (or (as o <tree:root>) (tree:ancestor o <tree:root>))))
    (tree:lookup root scope name)))

(define-method (tree:lookup name)
  (tree:lookup name name))
