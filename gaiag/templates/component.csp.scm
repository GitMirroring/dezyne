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
send_(c',e')(P', V') = c'!e' -> P'(V')
-- skip_: () => (P,V)->Proc
skip_(P', V') = P'(V')
-- sendrecv_: (c: channel, e:event) => (P,V)->Proc
sendrecv_(c',e')(P', V') =  c'!e'  -> c'?r' -> returnvalue_(\V' @ r')(P', V')
-- callvoid_: (B': (P,V)->Proc) => (P,V)->Proc
callvoid_(B')(P', V') = B'(P', V')
-- callvoid_args_: (B': (P,V)->Proc, F': V'->V') => (P,V)->Proc
callvoid_args_(B',F')(P', V') = B'(P', V', F')
-- assign_: (F': V -> V) => (P,V) -> Proc
assign_(F')(P', V') = P'(F'(V'))
-- assign_active_: C':(P,V)->Proc, A: (V,val)->V) => (P,V)->Proc
assign_active_(C', A')(P', V') = C'(\((M', r'),L') @ P'(A'((M',L'),r')), V')
-- returnvalue_: (F: V->val) => (P,V)->Proc
returnvalue_(F')(P', (M',L')) = P'(((M',  F'((M', L'))), L'))
-- the_end_: P => V->Proc
the_end_(P', V') = transition_end -> P'(V')

-- semi_: (S1,S2: (P,V)->Proc) => (P,V) -> Proc
semi_(S1',S2')(P', V') = S1'(\V'' @ S2'(P', V''),V')
-- ifthenelse: (E': val,  S1,S2: (P,V)->Proc) => (P,V) -> Proc
ifthenelse_(E',S1',S2')(P', V') =  if E' then S1'(P', V') else S2'(P', V')
-- context_: (F': V->val, S': (P,V)->Proc) => (P,V)->Proc
-- context_(F', S')(P')((M', L')) = S'((\V2' @ P'(drop_one_local_(V2'))), (M', (L', F'((M', L')))))
-- context_(v', S')(P', (M', L')) = S'((\(M',L2') @ P'((M',L'))), (M', (L', v')))
context_(F', S')(P', (M', L')) = S'((\ (M',L2') @ P'((M',L'))), (M', (L', F'((M', L')))))
-- context_active_: (C':(P,V)->Proc, S: (P,V)->Proc) => (P,V)->Proc
context_active_(C', S')(P', V') = C'(\((M', r'),L') @ S'(\V2' @ P'(drop_one_local_(V2')), (M', (L',r'))), V')
context_func_(S')(P', (M1', L1')) = S'((\(M2',L2') @ P'((M2',L1'))), (M1', <>))
context_func_args_(v', S')(P', (M1', L1')) = S'((\(M2',L2') @ P'((M2',L1'))), (M1', (<>, v')))

datatype event_enumeration_alphabet =
#(pipe-join (append
             (delete-duplicates
              (sort
               (append (apply append (map port-events ((compose .elements .ports gom:component) ast)))
                       (enum-values (gom:component ast))
                       (return-values (gom:component ast)))
             symbol<))))

channel illegal

# (map-ports #{
channel #.port.name : {#(comma-join (append (port-events port) (return-values-port port)))}
#} ((compose .elements .ports gom:component) ast))
# (map-interfaces #{
channel #.interface.name : {#(comma-join (append (interface-events interface) (return-values-interface interface)))}
#} (delete-duplicates (map .type ((compose .elements .ports gom:component) ast))))
  # (map-ports #{
#.interface.name _#.behaviour.name(IG) = let
# (->string (map (lambda (x) (csp-transform interface (ast-transform interface x))) (gom:functions (.behaviour interface))))
#.interface.name _#.behaviour.name _((#(context->csp ast (make-context ((compose gom:member-names csp:import) .interface.name) '())))) =
# (behaviour->csp
 (csp:import .interface.name)
 (->string (list .interface.name '_ .behaviour.name '_ "((" (context->csp ast (make-context ((compose gom:member-names csp:import) .interface.name) '())) "))" )))


within #.interface.name _#.behaviour.name _((#(context->csp ast (make-context ((compose gom:member-values csp:import) .interface.name) '(<>))))) #.optional-chaos

#} ((compose .elements .ports gom:component) ast))
#.component _#.behaviour.name (IIG,IG) = let
# (->string (map (lambda (x) (csp-transform component (ast-transform component x))) (gom:functions (.behaviour component))))
#.component _#.behaviour.name _((#(context->csp ast (make-context ((compose gom:member-names gom:component) ast) '())))) = transition_begin -> (
#(behaviour->csp (gom:component ast)
 (->string (list .component '_ .behaviour.name '_ "((" (context->csp ast (make-context ((compose gom:member-names gom:component) ast) '())) "))" )))
)

within #.component _#.behaviour.name _((#(context->csp ast (make-context ((compose gom:member-values gom:component) ast) '(<>)))))

channel extensions_over_empty_channels_is_undefined
channel IN,OUT : {#
 (comma-join (list (map-ports #{#
(comma-join (map (lambda (x) (list .port.name "." (.name x))) (filter gom:out? (gom:events port csp:import))))#}
  (filter gom:requires? ((compose .elements .ports gom:component) ast)) ",") 'extensions_over_empty_channels_is_undefined))}

SINGLETHREADED = true

channel transition_begin, transition_end

channel reorder_in,reorder_out : {# (map (lambda (x) (comma-join (map (lambda (y) (symbol-append (.name x) '. y)) (return-values-port x)))) (filter gom:provides? ((compose .elements .ports gom:component) ast)))}

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

#.component _#.behaviour.name _Component(IIG) = let
compress(x) = let
transparent sbisim
transparent diamond
within sbisim(diamond(x))
Exclude = {#
  (comma-join (list (map (lambda (x) (comma-join (map (lambda (y) (symbol-append (.name x) '. y)) (return-values-port x)))) (filter gom:provides? ((compose .elements .ports gom:component) ast))) (map-ports
#{#(comma-join (map (lambda (x) (list .port.name "." (.name x))) (filter gom:out? (gom:events port csp:import)))) #}
   (filter gom:provides? ((compose .elements .ports gom:component) ast)))
 (map-ports
#{#(comma-join (map (lambda (x) (list .port.name "." x)) (filter (lambda (x) (member x '(inevitable optional))) (port-events port)))) #}
   ((compose .elements .ports gom:component) ast) ",")))}
ClientCalls = {#
 (map-ports
#{#(comma-join (map (lambda (x) (list .port.name "." (.name x))) (filter gom:in? (gom:events port csp:import)))) #}
   (filter gom:provides? ((compose .elements .ports gom:component) ast)))}
UsedModeling = {#
 (map-ports
#{#(comma-join (map (lambda (x) (list .port.name "." x)) (filter (lambda (x) (member x '(inevitable optional))) (port-events port)))) #}
   (filter gom:requires? ((compose .elements .ports gom:component) ast)) ",")}
within compress((#.component _#.behaviour.name (IIG,true) [[x<-OUT.x|x<-extensions(OUT)]] [[x<-reorder_in.x|x<-extensions(reorder_in)]]
[|diff({|OUT,transition_begin,transition_end,reorder_in,#(comma-join (map .name ((compose .elements .ports gom:component) ast)))|},Exclude)|]
(((# (let ((required_processes (map-ports #{
#.interface.name _#.behaviour.name(true) [[#.interface.name .x<-#.port.name .x|x<-extensions(#.interface.name)]]
#} (filter gom:requires? ((compose .elements .ports gom:component) ast)) " ||| "))) (if (string-null? required_processes) 'STOP required_processes))) [[x<-IN.x|x<-extensions(IN)]]
[|union({|IN|},UsedModeling)|]
SEMANTICS(IN,OUT,ClientCalls,UsedModeling)))) [[reorder_out.x<-x|x<-extensions(reorder_out)]]\{transition_begin,transition_end})
