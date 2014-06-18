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
%(pipe-join (append (unique (sort (append (event-names (component-ports (component ast))) '(inevitable optional)) symbol<)) '(return)))

% (map-ports 
"channel %.interface ,%.port : {%(comma-join (append (map port-name (port-events port)) '(return)))}
" (component-ports (component ast)))

%.component _(IIG,IG) = let
%.component _%.behaviour (%(comma-join (map variable-name (behaviour-variables (component-behaviour (component ast)))))) = 

% (map-guards
" (% (list (cadr (guard-expression *guard-def*)) '== (caddr (guard-expression *guard-def*)))) & transition_begin -> ()
" (statements-guard (behaviour-statements (component-behaviour (component ast)))))


assert %.component _%.behaviour _Component :[deadlock free]
assert %.component _%.behaviour(true,true) :[deterministic]
assert STOP [T= %.component _%.behaviour _Component \ diff(Events,{illegal})
assert %.interface _%.interface-behaviour(false) [[%.interface .x<-%.port .x|x<-extensions(%.interface)]] \ {%.port .optional,%.port .inevitable} [FD=
%.component _%.behaviour _Component \ diff(Events,{|illegal,%.port |}) \ {%.port .optional,%.port .inevitable} %
(map-ports
"
assert %.interface _%.behaviour(false) :[deadlock free]
assert %.interface _%.behaviour(true) :[livelock free]" (filter port-requires? (component-ports (component ast))))
assert %.interface _%.interface-behaviour (false) :[deadlock free]
assert %.interface _%.interface-behaviour (true) :[livelock free]
