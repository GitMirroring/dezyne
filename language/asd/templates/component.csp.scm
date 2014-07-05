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

ifthenelse(E',S1',S2') = \ P', V' @ if E' then S1'(P',V') else S2'(P',V')
semi(S1',S2') = \ P', V' @ S1'( \ V'' @ S2'(P', V''), V')
assign(F') = \ P', V' @ P'(F'(V'))

datatype event_enumeration_alphabet =
#(pipe-join (append
             (delete-duplicates
              (sort
               (append (apply append (map port-triggers ((compose ast:ports ast:component) ast)))
                       (enum-values (ast:component ast))
                       (return-values (ast:component ast)))
             symbol<))))

channel illegal

# (map-ports #{
channel #.interface ,#.port : {#(comma-join (append (port-triggers port) (return-values-port port)))}
#} ((compose ast:ports ast:component) ast))
# (map-ports #{
#.interface _#.behaviour(IG) = let
#.interface _#.behaviour _((# (comma-join (map ast:name ((compose ast:variables ast:behaviour ast-norm) .interface))))) =
# (map-guards #{(# (csp-expression->string (ast:expression guard))) & (
# ((->join "\n  []\n  ") (map (lambda (on) (csp-transform (ast:ast .interface) (ast-transform (ast:ast .interface) on)))
   ((ast:statements-of-type 'on) (ast:statement guard)))))
#} (reverse ((ast:statements-of-type 'guard) (ast:statement (ast:behaviour (ast-norm .interface))))))
within #.interface _#.behaviour _((#(comma-join (map (lambda (x) (value (ast:expression x))) ((compose ast:variables ast:behaviour ast-norm) .interface))))) #.optional-chaos

#} ((compose ast:ports ast:component) ast))
#.component _#.behaviour (IIG,IG) = let
#.component _#.behaviour _((#(comma-join (map ast:name ((compose ast:variables ast:behaviour ast:component) ast))))) = transition_begin -> (
# (map-guards #{ (# (csp-expression->string (ast:expression guard))) & (
# ((->join "\n  []\n  ") (map (lambda (on) (csp-transform component (ast-transform component on)))
    (append
      (filter identity (map (statement-on-p/r (provides? component)) ((ast:statements-of-type 'on) (ast:statement guard))))
      (filter identity (map (statement-on-p/r (requires? component)) ((ast:statements-of-type 'on) (ast:statement guard))))))))
#} (reverse ((ast:statements-of-type 'guard) ((compose ast:statement ast:behaviour ast:component) ast)))))
within #.component _#.behaviour _((#(comma-join (map (lambda (x) (value (ast:expression x))) ((compose ast:variables ast:behaviour ast:component) ast)))))

channel extensions_over_empty_channels_is_undefined
channel IN,OUT : {#
 (comma-join (list (map-ports #{#
(comma-join (map (lambda (x) (list .port "." (ast:name x))) (filter ast:out? (ast:events port))))#}
  (filter ast:requires? ((compose ast:ports ast:component) ast))) 'extensions_over_empty_channels_is_undefined))}

SINGLETHREADED = true

channel transition_begin, transition_end

channel reorder_in,reorder_out : {# (map (lambda (x) (comma-join (map (lambda (y) (symbol-append (ast:name x) '. y)) (return-values-port x)))) (filter ast:provides? ((compose ast:ports ast:component) ast)))}

SEMANTICS(in',out',client',modeling') = let
Q'(s') = length(s') < card({|in'|}) & in'?x' -> Q'(s'^<x'>)
       []
       length(s') > 0 & out'!head(s') -> Q'(tail(s'))
       []
       length(s') == card({|in'|}) & in'?x' -> illegal -> STOP

R'(A') = ([] x' : A' @ x' -> R'(A'))
       []
       reorder_in?x' -> reorder_out!x' -> R'(A')

S'    = let

Idle(c') = transition_begin -> ([] x' : union(client',modeling') @ x' -> Busy(c',<>))

Busy(c',r') = c' == 0 & transition_end -> (if r' == <> then Idle(0) else reorder_out!head(r') -> Idle(0))
            []
            c' > 0 & transition_end -> transition_begin -> Busy(c',r')
            []
            c' < card({|in'|}) & ([] x' : {|in'|} @ x' -> Busy(c'+1,r'))
            []
            c' > 0 & ([] x' : {|out'|} @ x' -> Busy(c'-1,r'))
            []
            r' == <> & reorder_in?x' -> Busy(c',<x'>)
            []
            r' != <> & reorder_in?x' -> illegal -> STOP

within Idle(0)

within Q'(<>) [|{|in',out'|}|] if SINGLETHREADED then S' else R'(Union({{|in',out',transition_begin,transition_end|},client',modeling'}))

#.component _#.behaviour _Component(IIG) = let
compress(x) = let
transparent sbisim
transparent diamond
within sbisim(diamond(x))
Exclude = {#
  (comma-join (list (map (lambda (x) (comma-join (map (lambda (y) (symbol-append (ast:name x) '. y)) (return-values-port x)))) (filter ast:provides? ((compose ast:ports ast:component) ast))) (map-ports
#{#(comma-join (map (lambda (x) (list .port "." (ast:name x))) (filter ast:out? (ast:events port)))) #}
   (filter ast:provides? ((compose ast:ports ast:component) ast)))
 (map-ports
#{#(comma-join (map (lambda (x) (list .port "." x)) (filter (lambda (x) (member x '(inevitable optional))) (port-triggers port)))) #}
   ((compose ast:ports ast:component) ast) ",")))}
ClientCalls = {#
 (map-ports
#{#(comma-join (map (lambda (x) (list .port "." (ast:name x))) (filter ast:in? (ast:events port)))) #}
   (filter ast:provides? ((compose ast:ports ast:component) ast)))}
UsedModeling = {#
 (map-ports
#{#(comma-join (map (lambda (x) (list .port "." x)) (filter (lambda (x) (member x '(inevitable optional))) (port-triggers port)))) #}
   (filter ast:requires? ((compose ast:ports ast:component) ast)))}
within compress((#.component _#.behaviour (IIG,true) [[x<-OUT.x|x<-extensions(OUT)]] [[x<-reorder_in.x|x<-extensions(reorder_in)]]
[|diff({|OUT,transition_begin,transition_end,reorder_in,#(comma-join (map ast:name ((compose ast:ports ast:component) ast)))|},Exclude)|]
(((# (let ((required_processes (map-ports #{
#.interface _#.behaviour(true) [[#.interface .x<-#.port .x|x<-extensions(#.interface)]]
#} (filter ast:requires? ((compose ast:ports ast:component) ast)) " ||| "))) (if (string-null? required_processes) 'STOP required_processes))) [[x<-IN.x|x<-extensions(IN)]]
[|union({|IN|},UsedModeling)|]
SEMANTICS(IN,OUT,ClientCalls,UsedModeling)))) [[reorder_out.x<-x|x<-extensions(reorder_out)]]\{transition_begin,transition_end})
