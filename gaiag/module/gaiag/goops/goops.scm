;;; Dezyne --- Dezyne command line tools
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag goops goops)
  :use-module (gaiag misc)
  :use-module (gaiag goops ast)
  :use-module (gaiag goops compare)
  :use-module (gaiag goops csp)
  :use-module (gaiag goops display)
  :use-module (gaiag goops om)
  :use-module (gaiag goops util))

(cond-expand-provide (current-module) '(goops-om))

(re-export-modules
 (gaiag goops ast)
 (gaiag goops compare)
 (gaiag goops csp)
 (gaiag goops display)
 (gaiag goops om)
 (gaiag goops simulate)
 (gaiag goops util))
