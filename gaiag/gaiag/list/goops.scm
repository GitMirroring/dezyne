;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag list goops)
  :use-module (gaiag macros)
  :use-module (gaiag list ast)
  :use-module (gaiag list csp)
  :use-module (gaiag list om)
  :use-module (gaiag list simulate)
  :use-module (gaiag list util))

(cond-expand-provide (current-module) '(list-om))

(re-export-modules
 (gaiag list ast)
 (gaiag list csp)
 (gaiag list om)
 (gaiag list simulate)
 (gaiag list util))
