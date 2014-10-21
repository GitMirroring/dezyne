;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

-- interface.csp.scm

channel #(.name model): {#(comma-join (interface-events model gom:in?))}
#(let ((events (interface-events model gom:out?)))
   (if (pair? events)
       (list "channel " (.name model) "_'': {" (comma-join events) "}")))
channel #(.name model)_': {#(comma-join (return-values model))}

IF_#(.name model) _#((compose .name .behaviour) model)(IG,CS) = let
# (->string (map (lambda (x) (csp-transform model (ast-transform model x))) (gom:functions (.behaviour model))))
#(.name model) _#((compose .name .behaviour) model) ((#(->csp model (make <context> :members ((compose gom:member-names csp:import) (.name model)))))) =
# (behaviour->csp
 (csp:import (.name model))
 (->string (list (.name model) '_ ((compose .name .behaviour) model) "((" (->csp model (make <context> :members ((compose gom:member-names csp:import) (.name model)))) "))" )))
[]
CS & #(.name model)?x:{#(comma-join (delete-duplicates (map .event (modeling-events model))))} -> illegal_(STOP,<>)

within if CS then #
(.name model) _#((compose .name .behaviour) model) ((#(->csp model (make <context> :members ((compose gom:member-values csp:import) (.name model)) :locals '(<>)))))
             else #
(.name model) _#((compose .name .behaviour) model) ((#(->csp model (make <context> :members ((compose gom:member-values csp:import) (.name model)) :locals '(<>)))))#(optional-chaos model)

-- end of interface.csp.scm
