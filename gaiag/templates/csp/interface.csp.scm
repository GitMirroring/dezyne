;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2014, 2015, 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
channel #.scope_model _': {#(comma-join (reverse (append (return-values model) (list "blocked"))))}
channel #.scope_model _in',#.scope_model _out': {#(comma-join (map (lambda (x) (list .scope_model "_'." x)) (append (return-values model) (list "blocked"))))}
channel #.scope_model _'': {#(comma-join (let ((out-events (interface-events model om:out?))) (if (null? out-events) (list 'extensions_over_empty_channels_is_undefined) out-events)))}

channel #.scope_model _''': {inevitable,optional,modeling,silent}

IF_#.scope_model _(IG,CS) = let
# (->string (map (lambda (x) (csp-transform model (ast-transform model x))) (om:functions model)))
#(behaviour-interface->csp model)

REORDER' = 
let
Star(c', P') = P' [] c'?x' -> Star(c', P')
Switch(c', P', Q') = P' [] c'?x' -> Star(c', Q') 
within
#.scope_model ?x' -> Star(#.scope_model _'', (#.scope_model _in'?y' -> Star(#.scope_model _'', #.scope_model .the_end' -> #.scope_model _out'!y' -> REORDER') [] #.scope_model .the_end' -> REORDER'))
[]
#.scope_model _'''?x':{inevitable,optional} -> Switch(#.scope_model _'', #.scope_model .the_end' -> #.scope_model _'''.silent -> REORDER', #.scope_model .the_end' -> #.scope_model _'''.modeling -> REORDER')

compress(x) = let
transparent sbisim
transparent diamond
within sbisim(diamond(x))

within compress((if CS
                then #
.scope_model _(#(comma-space-join (map (lambda (x) (csp-expression->string model x '())) (om:member-values (csp:import (.name model))))))
                else #
.scope_model _(#(comma-space-join (map (lambda (x) (csp-expression->string model x '())) (om:member-values (csp:import (.name model)))))) #(optional-chaos model))
               [[x<-#.scope_model _in'.x|x<-extensions(#.scope_model _in')]] [|{|#.scope_model ,#.scope_model _in',#.scope_model _'',#.scope_model _'''.inevitable,#.scope_model _'''.optional|}|] REORDER' [[#.scope_model _out'.x<-x|x<-extensions(#.scope_model _out')]] \ {|#.scope_model _in',#.scope_model .the_end'|})

-- end of interface.csp.scm
