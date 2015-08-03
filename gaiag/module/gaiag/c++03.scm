;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (gaiag c++03)
  :use-module (ice-9 curried-definitions)
  :use-module (gaiag list match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag c)
  :use-module (gaiag c++)
  :use-module (gaiag code)
  :use-module (gaiag indent)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :use-module (gaiag ast)

  :export (ast->)
  )

(define ast-> (@@ (gaiag c++) ast->))
(define c++:scope-join (@@ (gaiag c++) c++:scope-join))
(define c++:scope-name (@@ (gaiag c++) c++:scope-name))
