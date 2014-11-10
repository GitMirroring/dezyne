;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (gaiag gom)
  :use-module (ice-9 pretty-print)

  :use-module (gaiag annotate)
  :use-module (gaiag misc)

  :use-module (oop goops)
  :use-module (oop goops describe)

  :use-module (gaiag gom ast)
  :use-module (gaiag gom compare)
  :use-module (gaiag gom gom)
  :use-module (gaiag gom display)
  :use-module (gaiag gom util))

(re-export-modules
 (gaiag gom ast)
 (gaiag gom compare)
 (gaiag gom gom)
 (gaiag gom display)
 (gaiag gom map)
 (gaiag gom util))

(define (ast-> ast)
  ((compose gom->list ast->gom ast->annotate) ast))
