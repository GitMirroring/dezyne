;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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


(define-module (peg)
  #:use-module (peg codegen)
  #:use-module (peg string-peg)
  ;; Note: the most important effect of using string-peg is not whatever
  ;; functions it exports, but the fact that it adds a new handler to
  ;; peg-sexp-compile.
  #:use-module (peg simplify-tree)
  #:use-module (peg using-parsers)
  #:use-module (peg cache)
  #:re-export (define-peg-pattern
               define-peg-string-patterns
               match-pattern
               search-for-pattern
               compile-peg-pattern
               keyword-flatten
               context-flatten
               peg:start
               peg:end
               peg:string
               peg:tree
               peg:substring
               peg-record?))
