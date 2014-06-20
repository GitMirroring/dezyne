;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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


datatype event_alphabet =
#(pipe-join (append (delete-duplicates (sort (apply append (map port-triggers (ast:body (ast:ports (ast:component ast))))) symbol<)) '(return)))

datatype enumeration_alphabet =
#(pipe-join (delete-duplicates (sort (enum-values (ast:component ast)) symbol<)))

channel illegal

# (map-ports #{
channel #.interface ,#.port : {#(comma-join (append (port-triggers port) '(return)))} 
#} (ast:body (ast:ports (ast:component ast))))


# (map-ports #{
#.interface _#.behaviour(IG) = let
#.interface _#.behaviour _(# (map ast:identifier (ast:body (ast:variables (ast:behaviour (ast:ast .interface)))))) =
# (map-guards
#{  (#(list (cadr (ast:expression *guard-def*)) " == " (caddr (ast:expression *guard-def*)))) & (
  )
[]
#} (ast:statements-guard (ast:body (ast:statements (ast:behaviour (ast:ast .interface))))))
#} (filter ast:requires? (ast:body (ast:ports (ast:component ast)))))

#.component _#.behaviour (IIG,IG) = let
#.component _#.behaviour _(#(comma-join (sort (map ast:identifier (ast:body (ast:variables (ast:behaviour (ast:component ast))))) symbol<))) = 

# (map-guards #{
 (# (list (cadr (ast:expression *guard-def*)) " == " (caddr (ast:expression *guard-def*)))) & transition_begin -> (
  )
[]
#} (ast:statements-guard (ast:body (ast:statements (ast:behaviour (ast:component ast))))))

assert #.component _#.behaviour _Component :[deadlock free]
assert #.component _#.behaviour(true,true) :[deterministic]
assert STOP [T= #.component _#.behaviour _Component \ diff(Events,{illegal})
assert #.interface _#.interface-behaviour(false) [[#.interface .x<-#.port .x|x<-extensions(#.interface)]] \ {#.port .optional,#.port .inevitable} [FD=
#.component _#.behaviour _Component \ diff(Events,{|illegal,#.port |}) \ {#.port .optional,#.port .inevitable} 

# (map-ports #{
assert #.interface _#.behaviour(false) :[deadlock free]
assert #.interface _#.behaviour(true) :[livelock free]
#} (filter ast:requires? (ast:body (ast:ports (ast:component ast)))))
assert #.interface _#.interface-behaviour (false) :[deadlock free]
assert #.interface _#.interface-behaviour (true) :[livelock free]

