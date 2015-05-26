;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag ast)
  :use-module (gaiag misc)

  :use-module (gaiag goops goops)
  ;;:use-module (gaiag list goops)

  :export (
           ))

(cond-expand
 (goops-om
  (cond-expand-provide (current-module) '(goops-om))
  (re-export-modules
   (gaiag goops goops)))
 (list-om
  (cond-expand-provide (current-module) '(list-om))
  (re-export-modules
   (gaiag list goops)))
 (else
  (re-export-modules
   (gaiag goops goops)
   ;;(gaiag list goops)
   )))

(define ast-> identity)
