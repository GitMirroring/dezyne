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

action(S) = \ P, V @ S; P(V)
ifthenelse(E,S1,S2) = \ P, V @ if E then S1(P,V) else S2(P,V)
semi(S1,S2) = \ P, V @ S1( \ V' @ S2(P, V'), V)
assign(F) = \ P, V @ P(F(V))

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
#.interface _#.behaviour _((# (map ast:identifier (ast:body (ast:variables (ast:behaviour (ast-norm .interface))))))) =
# (map-guards #{(# (csp-expression->string (ast:expression guard))) & (
# (map-statements-on #{ #
    (when illegal? (if provides-event? "IIG & " "IG & ")) #.interface ?x:{#
    (comma-join (map event->string events)) } -> #
    (if illegal? 
        "illegal -> STOP"
        (append
         (if provides-event?
              (list .interface "." .event " -> ")
              '(""))
         (map (lambda (x) (list .interface "." (->string x) " -> " 
                                (when (and (requires? x)
                                           (not (or (member 'inevitable events) (member 'optional events))))
                                  (list (action->string x) ".return -> ")))) 
              actions)
         (if (or (member 'inevitable events) (member 'optional events))
             '("")
             (list .interface ".return -> "))
        (list .interface "_" .behaviour "_((" (comma-join actuals) "))")))
#}
    ((ast:statements-of-type 'on) (ast:statement guard)) "  []\n"))
#} (reverse ((ast:statements-of-type 'guard) (ast:statement (ast:behaviour (ast-norm .interface))))))
within #.interface _#.behaviour _((#(comma-join (map (lambda (x) (value (ast:initial-value x))) (ast:body (ast:variables (ast:behaviour (ast-norm .interface)))))))) #.optional-chaos

#} (ast:body (ast:ports (ast:component ast))))
#.component _#.behaviour (IIG,IG) = let
#.component _#.behaviour _((#(comma-join (map ast:identifier (ast:body (ast:variables (ast:behaviour (ast:component ast)))))))) = transition_begin -> (
# (map-guards #{ (# (csp-expression->string (ast:expression guard))) & (
# (map-statements-on #{ #
    (when illegal? (if provides-event? "IIG & " "IG & ")) #.event-port ?x:{#
    (comma-join (map event->string events)) } -> #
    (map (lambda (x) (list (->string x) " -> " 
                           (when (requires? x)
                             (list (action->string x) ".return -> ")
                             ))) actions) #
    (if illegal? 
        "illegal -> STOP"
        (append
         (if (or (member 'inevitable events) (member 'optional events))
             '("")
             (append
              (if provides-event?
                  (list channel ".return -> ")
                  '())
              '("transition_end -> ")))
        (list .module "_" .behaviour "_((" (comma-join actuals) "))")))
#}
    (append
      (filter identity (map (statement-on-p/r provides?) ((ast:statements-of-type 'on) (ast:statement guard))))
      (filter identity (map (statement-on-p/r requires?) ((ast:statements-of-type 'on) (ast:statement guard))))) "[]\n"))
#} (reverse ((ast:statements-of-type 'guard) (ast:statement (ast:behaviour (ast:component ast)))))))
within #.component _#.behaviour _((#(comma-join (map (lambda (x) (value (ast:initial-value x))) (ast:body (ast:variables (ast:behaviour (ast:component ast))))))))

channel IN,OUT : {#
 (map-ports #{
   #(comma-join (map (lambda (x) (list .port "." (ast:identifier x))) (filter ast:out? (ast:body (ast:events port)))))#}
  (filter ast:requires? (ast:body (ast:ports (ast:component ast)))))}

SINGLETHREADED = true

channel transition_begin, transition_end

channel reorder_in,reorder_out : {# (map (lambda (x) (list (ast:identifier x) ".return")) (filter ast:provides? (ast:body (ast:ports (ast:component ast)))))}

SEMANTICS(in_,out_,client_,modeling_) = let
Q(s) = length(s) < card({|in_|}) & in_?x -> Q(s^<x>)
       []
       length(s) > 0 & out_!head(s) -> Q(tail(s))
       []
       length(s) == card({|in_|}) & in_?x -> illegal -> STOP

R(A) = ([] x : A @ x -> R(A))
       []
       reorder_in?x -> reorder_out!x -> R(A)

S    = let

Idle(c) = transition_begin -> ([] x : union(client_,modeling_) @ x -> Busy(c,<>))

Busy(c,r) = c == 0 & transition_end -> (if r == <> then Idle(0) else reorder_out!head(r) -> Idle(0))
            []
            c > 0 & transition_end -> transition_begin -> Busy(c,r)
            []
            c < card({|in_|}) & ([] x : {|in_|} @ x -> Busy(c+1,r))
            []
            c > 0 & ([] x : {|out_|} @ x -> Busy(c-1,r))
            []
            r == <> & reorder_in?x -> Busy(c,<x>)

within Idle(0)

within Q(<>) [|{|in_,out_|}|] if SINGLETHREADED then S else R(Union({{|in_,out_,transition_begin,transition_end|},client_,modeling_}))

#.component _#.behaviour _Component = let
compress(x) = let
transparent sbisim
transparent diamond
within sbisim(diamond(x))
Exclude = {#.port .return,#
 (map-ports
#{#(comma-join (map (lambda (x) (list .port "." (ast:identifier x))) (filter ast:out? (ast:body (ast:events port))))) #}
   (filter ast:provides? (ast:body (ast:ports (ast:component ast))))),#
 (map-ports
#{#(comma-join (map (lambda (x) (list .port "." x)) (filter (lambda (x) (member x '(inevitable optional))) (port-triggers port)))) #}
   (ast:body (ast:ports (ast:component ast))) ",")}
ClientCalls = {#
 (map-ports
#{#(comma-join (map (lambda (x) (list .port "." (ast:identifier x))) (filter ast:in? (ast:body (ast:events port))))) #}
   (filter ast:provides? (ast:body (ast:ports (ast:component ast)))))}
UsedModeling = {#
 (map-ports
#{#(comma-join (map (lambda (x) (list .port "." x)) (filter (lambda (x) (member x '(inevitable optional))) (port-triggers port)))) #}
   (filter ast:requires? (ast:body (ast:ports (ast:component ast)))))}
within compress((#.component _#.behaviour (false,true) [[x<-OUT.x|x<-extensions(OUT)]] [[x<-reorder_in.x|x<-extensions(reorder_in)]]
[|diff({|OUT,transition_begin,transition_end,reorder_in,#(comma-join (map ast:identifier (ast:body (ast:ports (ast:component ast)))))|},Exclude)|]
(((# (map-ports #{
#.interface _#.behaviour(true) [[#.interface .x<-#.port .x|x<-extensions(#.interface)]]
#} (filter ast:requires? (ast:body (ast:ports (ast:component ast)))) " ||| ")) [[x<-IN.x|x<-extensions(IN)]]
[|union({|IN|},UsedModeling)|]
SEMANTICS(IN,OUT,ClientCalls,UsedModeling)))) [[reorder_out.x<-x|x<-extensions(reorder_out)]]\{transition_begin,transition_end})

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
