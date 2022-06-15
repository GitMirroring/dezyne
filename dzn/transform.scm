;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
;;; Export a list of AST transformations to be exposed to the user.
;;;
;;; Code:

(define-module (dzn transform)
  #:use-module (dzn normalize)
  #:use-module (dzn vm normalize)

  #:export (normalize:compounds-wrap)
  #:re-export (add-function-return
               add-explicit-temporaries
               normalize:compounds
               normalize:event
               normalize:state
               purge-data
               remove-otherwise
               remove-behavior))

(define (normalize:compounds-wrap o)
  (normalize:compounds o #:wrap-imperative? #t))
