;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

-- drop_one_local: V => V
drop_one_local_((M', (L', L0'))) = (M', L')

-- send_: (c: channel, e:event) => (P,V)->Proc
send_(c',e') = \P',V' @ c'!e' -> P'(V')
-- skip_: () => (P,V)->Proc
skip_ = \P',V' @ P'(V')
-- sendrecv_: (c: channel, e:event) => (P,V)->Proc
sendrecv_(c',e') = \P',V' @ c'!e'  -> c'?r' -> returnvalue_(\V' @ r')(P',V')
-- callvoid_: (B': (P,V)->Proc) => (P,V)->Proc
callvoid_(B') = \P',V' @ B'(P', V')
-- callvoid_args_: (B': (P,V)->Proc, F': V'->V') => (P,V)->Proc
callvoid_args_(B',F') = \P',V' @ B'(P', V', F')
-- assign_: (F': V -> V) => (P,V) -> Proc
assign_(F') = \ P', V' @ P'(F'(V'))
-- assign_active_: C':(P,V)->Proc, A: (V,val)->V) => (P,V)->Proc
assign_active_(C', A') = \P',V' @ C'(\((M', r'),L') @ P'(A'((M',L'),r')), V')
-- returnvalue_: (F: V->val) => (P,V)->Proc
returnvalue_(F') = \P',(M',L') @ P'(((M',  F'((M', L'))), L'))
-- the_end_: P => V->Proc
the_end_(P') = \V' @ transition_end -> P'(V')

-- semi_: (S1,S2: (P,V)->Proc) => (P,V) -> Proc
semi_(S1',S2') = \ P', V' @ S1'( \ V'' @ S2'(P', V''), V')
-- ifthenelse: (E': val,  S1,S2: (P,V)->Proc) => (P,V) -> Proc
ifthenelse_(E',S1',S2') = \ P', V' @ if E' then S1'(P',V') else S2'(P',V')
-- context_: (F': V->val, S': (P,V)->Proc) => (P,V)->Proc
context_(F', S') = \ P', (M', L') @ S'((\V2' @ P'(drop_one_local_(V2'))), (M', (L', F'((M', L')))))
-- context_active_: (C':(P,V)->Proc, S: (P,V)->Proc) => (P,V)->Proc
context_active_(C', S') = \P',V' @ C'(\((M', r'),L') @ S'(\V2' @ P'(drop_one_local_(V2')), (M', (L',r'))), V')

datatype event_enumeration_alphabet =
#(pipe-join (append
             (delete-duplicates
              (sort
               (append (apply append (map port-events ((compose ast:ports ast:component) ast)))
                       (enum-values (ast:component ast))
                       (return-values (ast:component ast)))
             symbol<))))

channel illegal

# (map-ports #{
channel #.port : {#(comma-join (append (port-events port) (return-values-port port)))}
#} ((compose ast:ports ast:component) ast))
# (map-interfaces #{
channel #.interface : {#(comma-join (append (interface-events interface) (return-values-interface interface)))}
#} (delete-duplicates (map ast:type ((compose ast:ports ast:component) ast))))
  # (map-ports #{
#.interface _#.behaviour(IG) = let
# (->string (map (lambda (x) (csp-transform interface (ast-transform interface x))) (ast:functions (ast:behaviour interface))))
#.interface _#.behaviour _((#(context->csp ast (make-context ((compose ast:member-names ast-norm) .interface) '())))) =
# (map-guards #{(# (csp-expression->string (ast:ast .interface) (ast:expression guard))) & (
# ((->join "\n  []\n  ") (map (lambda (on) (csp-transform (ast:ast .interface) (ast-transform (ast:ast .interface) on)))
   ((gom:statements-of-type 'on) (gom:statement guard)))))
#} ((gom:statements-of-type 'guard) (gom:statement (ast:behaviour (ast-norm .interface)))))
within #.interface _#.behaviour _((#(context->csp ast (make-context ((compose (ast:member-values value) ast-norm) .interface) '(<>))))) #.optional-chaos

#} ((compose ast:ports ast:component) ast))
#.component _#.behaviour (IIG,IG) = let
# (->string (map (lambda (x) (csp-transform component (ast-transform component x))) (ast:functions (ast:behaviour component))))
#.component _#.behaviour _((#(context->csp ast (make-context ((compose ast:member-names ast:component) ast) '())))) = transition_begin -> (
# (map-guards #{ (# (csp-expression->string component (ast:expression guard))) & (
# ((->join "\n  []\n  ") (map (lambda (on) (csp-transform component (ast-transform component on)))
    (append
      (filter identity (map (statement-on-p/r (provides? component)) ((gom:statements-of-type 'on) (gom:statement guard))))
      (filter identity (map (statement-on-p/r (requires? component)) ((gom:statements-of-type 'on) (gom:statement guard))))))))
#} ((gom:statements-of-type 'guard) ((compose gom:statement ast:behaviour ast:component) ast))))
within #.component _#.behaviour _((#(context->csp ast (make-context ((compose (ast:member-values value) ast:component) ast) '(<>)))))

channel extensions_over_empty_channels_is_undefined
channel IN,OUT : {#
 (comma-join (list (map-ports #{#
(comma-join (map (lambda (x) (list .port "." (ast:name x))) (filter ast:out? (ast:events port))))#}
  (filter ast:requires? ((compose ast:ports ast:component) ast)) ",") 'extensions_over_empty_channels_is_undefined))}

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
#{#(comma-join (map (lambda (x) (list .port "." x)) (filter (lambda (x) (member x '(inevitable optional))) (port-events port)))) #}
   ((compose ast:ports ast:component) ast) ",")))}
ClientCalls = {#
 (map-ports
#{#(comma-join (map (lambda (x) (list .port "." (ast:name x))) (filter ast:in? (ast:events port)))) #}
   (filter ast:provides? ((compose ast:ports ast:component) ast)))}
UsedModeling = {#
 (map-ports
#{#(comma-join (map (lambda (x) (list .port "." x)) (filter (lambda (x) (member x '(inevitable optional))) (port-events port)))) #}
   (filter ast:requires? ((compose ast:ports ast:component) ast)) ",")}
within compress((#.component _#.behaviour (IIG,true) [[x<-OUT.x|x<-extensions(OUT)]] [[x<-reorder_in.x|x<-extensions(reorder_in)]]
[|diff({|OUT,transition_begin,transition_end,reorder_in,#(comma-join (map ast:name ((compose ast:ports ast:component) ast)))|},Exclude)|]
(((# (let ((required_processes (map-ports #{
#.interface _#.behaviour(true) [[#.interface .x<-#.port .x|x<-extensions(#.interface)]]
#} (filter ast:requires? ((compose ast:ports ast:component) ast)) " ||| "))) (if (string-null? required_processes) 'STOP required_processes))) [[x<-IN.x|x<-extensions(IN)]]
[|union({|IN|},UsedModeling)|]
SEMANTICS(IN,OUT,ClientCalls,UsedModeling)))) [[reorder_out.x<-x|x<-extensions(reorder_out)]]\{transition_begin,transition_end})
