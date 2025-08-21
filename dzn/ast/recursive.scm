;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
;;; Copyright © 2019, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019 Rob Wieringa <rma.wieringa@gmail.com>
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

(define-module (dzn ast recursive)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)

  #:use-module (dzn ast ast)
  #:use-module (dzn ast normalize)
  #:use-module (dzn ast)
  #:use-module (dzn misc)
  #:export (annotate-recursion))

(define-method (set-recursive (o <behavior>))
  (define (mark-recursive f)
    (if (not (ast:recursive? f)) f
        (clone f #:recursive? #t)))
  (let* ((functions (.functions o))
         (function-list (.elements functions))
         (function-list (map mark-recursive function-list))
         (functions (clone functions #:elements function-list)))
    (clone o #:functions functions)))

(define (annotate-recursion o)
  (match o
    (($ <behavior>)
     (set-recursive o))
    ((? (%normalize:short-circuit?))
     o)
    ((or ($ <interface>) ($ <component>))
     (clone o #:behavior (and=> (.behavior o) set-recursive)))
    ((? (is? <ast>))
     (tree-map annotate-recursion o))
    (_
     o)))
