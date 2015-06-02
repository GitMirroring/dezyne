;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2014, 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

channel #(.name model): {#(comma-join (append (interface-events model om:in?) (list "the_end'") ))}
#(let ((events (interface-events model om:out?)))
   (if (pair? events)
       (list "channel " (.name model) "_'': {" (comma-join events) "}")))
channel #(.name model)_': {#(comma-join (return-values model))}
channel #(.name model)_in',#(.name model)_out': {#(comma-join (map (lambda (x) (list (.name model) "_'." x)) (return-values model)))}
channel #(.name model)_''': {modeling}

IF_#(.name model) _#((compose .name .behaviour) model)(IG,CS) = let
# (->string (map (lambda (x) (csp-transform model (ast-transform model x))) (om:functions model)))
#(.name model) _#((compose .name .behaviour) model) ((#(csp-comma-list (om:member-names model)))) = (
# (behaviour->csp (csp:import (.name model)))
[]
CS & #(.name model)?x:{#(comma-join (delete-duplicates (map .event (modeling-events model))))} -> illegal -> STOP
)

REORDER' = #(.name model)?x' -> (#(.name model)_in'?y' -> #(.name model).the_end' -> #(.name model)_out'!y' -> REORDER' [] #(.name model).the_end' -> REORDER')

compress(x) = let
transparent sbisim
transparent diamond
within sbisim(diamond(x))

within compress(if CS
                then #
(.name model) _#((compose .name .behaviour) model) (#(csp-comma-list (om:member-values (csp:import (.name model)))))
                else #
(.name model) _#((compose .name .behaviour) model) (#(csp-comma-list (om:member-values (csp:import (.name model)))))[[x<-#(.name model)_in'.x|x<-extensions(#(.name model)_in')]] [|{|#(.name model),#(.name model)_in',#(.name model).the_end'|}|] REORDER' [[#(.name model)_out'.x<-x|x<-extensions(#(.name model)_out')]] \ {|#(.name model)_in',#(.name model).the_end'|})

-- end of interface.csp.scm
