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

channel #.scope_model : {#(comma-join (append (interface-events model om:in?) (list "the_end'") ))}
#(let ((events (interface-events model om:out?)))
   (if (pair? events)
       (list "channel " .scope_model "_'': {" (comma-join events) "}")))
channel #.scope_model _': {#(comma-join (return-values model))}
channel #.scope_model _in',#.scope_model _out': {#(comma-join (map (lambda (x) (list .scope_model "_'." x)) (return-values model)))}
channel #.scope_model _''': {modeling}

IF_#.scope_model _#((compose .name .behaviour) model)(IG,CS) = let
# (->string (map (lambda (x) (csp-transform model (ast-transform model x))) (om:functions model)))
#(behaviour-interface->csp model)

REORDER' = #.scope_model ?x' -> (#.scope_model _in'?y' -> #.scope_model .the_end' -> #.scope_model _out'!y' -> REORDER' [] #.scope_model .the_end' -> REORDER')

compress(x) = let
transparent sbisim
transparent diamond
within sbisim(diamond(x))

within compress((if CS
                then #
.scope_model _#((compose .name .behaviour) model) (#(comma-space-join (map (lambda (x) (csp-expression->string model x '())) (om:member-values (csp:import .scope_model )))))
                else #
.scope_model _#((compose .name .behaviour) model) (#(comma-space-join (map (lambda (x) (csp-expression->string model x '())) (om:member-values (csp:import .scope_model ))))) #(optional-chaos model))
               [[x<-#.scope_model _in'.x|x<-extensions(#.scope_model _in')]] [|{|#.scope_model ,#.scope_model _in',#.scope_model .the_end'|}|] REORDER' [[#.scope_model _out'.x<-x|x<-extensions(#.scope_model _out')]] \ {|#.scope_model _in',#.scope_model .the_end'|})

-- end of interface.csp.scm
