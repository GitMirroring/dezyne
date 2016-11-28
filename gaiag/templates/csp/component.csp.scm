;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
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

-- component.csp.scm

# (map (lambda (port)
         (->string "channel " (.name port) ": extensions(" ((om:scope-name) port) ")\n" ))
       (filter (lambda (port) (not (eq? ((om:scope-name) port) (.name port)))) (om:ports model)))
# (map (lambda (port)
         (->string "channel " (.name port) "_': extensions(" ((om:scope-name) port) "_')\n" ))
       (filter (lambda (port) (not (eq? ((om:scope-name) port) (.name port)))) (om:ports model)))
# (map (lambda (port)
         (->string "channel " (.name port) "_'': extensions(" ((om:scope-name) port) "_'')\n" ))
       (filter (lambda (port) (not (eq? ((om:scope-name) port) (.name port)))) (om:ports model)))
# (map (lambda (port)
         (->string "channel " (.name port) "_''': extensions(" ((om:scope-name) port) "_''')\n" ))
       (filter (lambda (port) (not (eq? ((om:scope-name) port) (.name port)))) (om:ports model)))

channel ill: {|
              #(comma-join (map .name (filter (lambda (port) (not (eq? ((om:scope-name) port) (.name port)))) (om:provided model)))) |}
  
CO_#.scope_model _plain(IIG,IG) = let
# (->string (map (lambda (x) (on->csp model (ast-transform model x))) (om:functions model)))
#(behaviour-component->csp model)

COMP = #.scope_model _(#(comma-space-join (map (lambda (x) (csp-expression->string model x '())) (om:member-values model))))
within if (IIG) then COMP[[ill.x <- x | x <- extensions(ill)]] else COMP[|{|ill|}|]STOP  

CO_#.scope_model _(IIG,IG) =

let APIBlock =
#((->list-join "[]\n")
  (map (lambda (port)
         (list
          (list port "?x -> " port "_'?x: diff(extensions(" port "_'), {blocked}) -> APIBlock" "\n")
          (list "[]\n")
          (list port "_'?x: diff(extensions(" port "_'), {blocked}) -> APIBlock" "\n")))
       (map .name(om:provided model))))

within CO_#.scope_model _plain(IIG,IG) [|diff({|#(comma-join (map (lambda (port) (list (.name port) "," (.name port) "_'")) (om:provided model))) |},{#
(comma-join (map (lambda (port) (list (.name port) "_'.blocked")) (om:provided model))) })|] APIBlock

channel IN',OUT' : {|#(comma-join (append (map (lambda (port) (list (.name port) "_''"))
                                  (filter (lambda (port) (not (null? (filter om:out? (om:events port))))) (om:required model)))
                                  (list 'extensions_over_empty_channels_is_undefined)))|}

channel LINK' : {|IN',OUT'|}

channel reorder_in, reorder_out : {|#(comma-join (map (lambda (x) (symbol-append x (string->symbol "_'"))) (map .name (om:provided model))))|}
channel queue_full

SEMANTICS(in',out',link',provided_in',provided_blocked',required_modeling',async_modeling',required_modeling_end',async_reqackclrs,in_internal') = let

async_reqs = set(< req | (req,ack,clr) <- async_reqackclrs >)
async_acks = set(< ack | (req,ack,clr) <- async_reqackclrs >)
async_clrs = set(< clr | (req,ack,clr) <- async_reqackclrs >)

ack2req(ack) = set(<req | (req,ack,clr) <- async_reqackclrs>)
clr2req(clr) = set(<req | (req,ack,clr) <- async_reqackclrs>)

Q' = let
N' = #(csp-queue-size)
external chase
Back = in'?x' -> (link'.out'!x' -> Back [] in'?x' -> queue_full -> STOP)
Cell = link'.in'?x' -> link'.out'!x' -> Cell
Front = Cell[[link'.out' <- out']]

within
       if (N'==1) then (Back[[link'.out' <- out']])
       else if(N'==2) then chase(Back [link'.out' <-> link'.in'] Front  \ {|link'|})
       else chase((Back [link'.out' <-> link'.in'] ([link'.out'<->link'.in'] x : <1..N'-2> @ Cell)) [link'.out' <-> link'.in'] Front \ {|link'|})

S'    = let
N' = #(csp-queue-size)
 -- component receives a stimulus
Idle(blocked', requested') = transition_begin -> Started(blocked', requested')

Started(blocked',requested') = 
(([] x':provided_in' @ x' -> FillQ(0,true,requested'))
[]
(empty(requested') & ([] x':required_modeling' @ x' -> FillQ(0,blocked',requested')))
[]
([] x':async_modeling' @ x' -> FillQ(0,blocked',requested'))
[]
(in'?x' -> Busy(1,<>,blocked',false,extensions_over_empty_channels_is_undefined,requested')))

FillQ(c',blocked',requested') =
   -- as a result of the stimulus it starts filling its queue
(c' <= N' & in'?x':in_internal' -> FillQ(c'+1,blocked',requested'))
[] -- component is done filling the queue or it turned out to be an empty required modeling event
([] x':required_modeling_end' @ x' -> 
(Busy(c',<>,blocked',false,extensions_over_empty_channels_is_undefined,requested') [] ((c' == 0) & Started(blocked',requested'))))
[] -- synchronous out event
([]x':{|#(comma-join (map (lambda (port) (symbol-append (.name port) (string->symbol "_''"))) (om:provided model)))|} @ x' -> FillQ(c',blocked',requested'))
[] -- component replies on the stimulus
(reorder_in?x': diff(extensions(reorder_in),provided_blocked')  -> Busy(c',<x'>,blocked',false,extensions_over_empty_channels_is_undefined,requested'))
[] -- component blocks port
(reorder_in?x': provided_blocked' -> Busy(c',<>,blocked',false,extensions_over_empty_channels_is_undefined,requested'))
[]
([]x':async_reqs @ x' -> FillQ(c',blocked',union(requested',{x'})))
[]
([]x':async_clrs @ x' -> FillQ(c',blocked',diff(requested',clr2req(x'))))

Busy(c',r',blocked',pout',end',requested') =
-- if blocked' then asynchronous out event else synchronous out event
#((->join "\n[]\n") (map (lambda (port) (list "([]x':{|" (.name port) "_''|} @ x' -> Busy(c',r',blocked',true," (.name port) "_'''.modeling,requested'))")) (om:provided model)))
[] -- component is finished and outputs the void or reply event if present
(c' == 0 & transition_end -> if (not blocked') and pout' then end' -> End(r',blocked',requested') else End(r',blocked',requested'))
[]
(c' > 0 & transition_end -> transition_begin -> Busy(c',r',blocked',pout',end',requested')) -- handling synchronous out events
[]
(c' <= N' & in'?x':in_internal' -> Busy(c'+1,r',blocked',pout',end',requested')) -- accepting synchronous out events
[]
(c' > 0 & out'?x' -> Busy(c'-1,r',blocked',pout',end',diff(requested',ack2req(x')))) -- handling queued out events
[]
(r' == <> & reorder_in?x' -> Busy(c',<x'>,true,pout',end',requested')) -- reply to unblock port
[]
(r' != <> & reorder_in?x': diff(extensions(reorder_in),provided_blocked') -> illegal -> STOP) -- another reply is not allowed
[]
(r' != <> & reorder_in?x': provided_blocked' -> Busy(c',r',true,pout',end',requested')) -- ignore blocked if reply already given
[]
queue_full -> STOP
[]
([]x':async_reqs @ x' -> Busy(c',r',blocked',pout',end',union(requested',{x'})))
[]
([]x':async_clrs @ x' -> Busy(c',r',blocked',pout',end',diff(requested',clr2req(x'))))

End(r',blocked',requested') = if r' == <> then Idle(blocked',requested') else reorder_out!head(r') -> Idle(false,requested')

within Idle(false,{})

within Q' [|{|in',out',queue_full|}|] S'
AS_#.scope_model _(IIG) = let
compress(x) = let
transparent sbisim
transparent diamond
within sbisim(diamond(x))
provided_in' = {#
 (comma-join (map (lambda (port) (comma-join (map (lambda (event) (list (.name port) "." (.name event))) (filter om:in? (om:events port))))) (om:provided model)))}
provided_blocked' = {#
 (comma-join (map (lambda (port) (list (.name port) "_'." "blocked")) (om:provided model)))}
begin_required_modeling' = {#(comma-join (required-modeling-events model))}
begin_async_modeling' = {#(comma-join (async-modeling-events model))}
end_required_modeling' = {#(comma-join (append-map (lambda (port) (list (->string (.name port) "_'''.modeling" ) (->string (.name port) "_'''.silent" )))
                                                   (filter om:requires? ((compose .elements .ports) model))))}
async_reqackclrs = <#(comma-join (async-reqackclrs model))>
in_internals' = inter(extensions(IN'), {|#((->join ",") (map (lambda (x) (list (.name x) "_''")) (filter (negate .external) (om:ports model))))|})
#(map (animate-pairs `((interface ,identity))
#{IFD_#interface _(IG,CS) = 
(IF_#interface _(IG,CS) [[x<-#interface _in''.x|x<-extensions(#interface _in'')]]) 
[|{|#interface _in'',#interface _out''|}|] 
IQ'(#interface _in'',#interface _out'',#interface _link'',#(csp-queue-size)) 
[[#interface _out''.x<-x|x<-extensions(#interface _out'')]] \ {|#interface _in''|}
#}) (delete-duplicates (map (compose om:name .type) (filter .external (om:ports model)))))
within compress((CO_#.scope_model _ (IIG,true) [[x<-OUT'.x|x<-extensions(OUT')]] [[x<-reorder_in.x|x<-extensions(reorder_in)]]
                 [|{|#(comma-join (list "OUT',transition_begin,transition_end,reorder_in" 
                                        (comma-join (append-map (lambda (name) (list (list name) (list name "_'") (list name "_''"))) (map .name (om:provided model))))
                                        (comma-join (async-reqclrs model))))|}|]
                 SEMANTICS(IN',OUT',LINK',provided_in',provided_blocked',begin_required_modeling',begin_async_modeling',end_required_modeling',async_reqackclrs,in_internals') \ {|OUT',transition_begin,transition_end,reorder_in|}
                 ) [[reorder_out.x<-x|x<-extensions(reorder_out)]]
                [|{|#(comma-join (apply append (list "IN'") (map (lambda (o) (list (.name o) (string-append (symbol->string (.name o)) "_'") (string-append (symbol->string (.name o)) "_'''"))) (om:required model))))|}|]
                # (let* ((required_processes ((->join "\n                 ||| ") 
                                               (map (lambda (port)
                                                      (->string (list (if (.external port) "IFD_" "IF_") ((om:scope-name) port) "_(true,false)"
                                                                      "[[" ((om:scope-name) port) ".x<-" (.name port) ".x|x<-extensions("(.name port)")]]\n"
                                                                      "[["((om:scope-name) port) "_'.x<-" (.name port) "_'.x|x<-extensions("(.name port)"_')]]\n"
                                                                      (if (not (null? (filter om:out? (om:events port))))
                                                                          (list "[["((om:scope-name) port) "_''.x<-" (.name port) "_''.x|x<-extensions("(.name port)"_'')]]\n"))
                                                                      (list "[["((om:scope-name) port) "_'''.x<-" (.name port) "_'''.x|x<-extensions("(.name port)"_''')]]\n"))))
                                                    (filter om:requires? ((compose .elements .ports) model)))))
                         (hide_channels (append-map (lambda (i) (list (list i " ") (list i "_'" ) (list "IN'." i "_''" ) (list i "_'''")))
                                                    (map .name (filter (compose dzn-async? .type) ((compose .elements .ports) model)))))
                          (hide (if (null? hide_channels) '() (list "\\{|" (comma-join hide_channels) "|}"))))
                     (list "(" (if (string-null? required_processes) 'STOP required_processes) ")" "[[x<-IN'.x|x<-extensions(IN')]]" hide)))
                                                                                                    
IF_SPEC = let

compress(x) = let
transparent sbisim
transparent diamond
within sbisim(diamond(x))

R2C = #((->list-join "\n      []\n      ") (append (map (lambda (port) (list (.name port) "?x -> " (.name port) "_'?x -> R2C")) (om:provided model))
                                                   (map (lambda (port) (list (.name port) "_'''?x -> " (.name port) "_'''?x -> R2C")) (om:provided model))))

IFS = #((->list-join "\n      |||\n      ") (map (lambda (port) (list "IF_" ((om:scope-name) port) "_(true,false)"
                                                                      (list "[[" ((om:scope-name) port) "<-" (.name port) "]]"
                                                                            "[[" ((om:scope-name) port) "_'" "<-" (.name port) "_'" "]]"
                                                                            "[[" ((om:scope-name) port) "_''" "<-" (.name port) "_''" "]]"
                                                                            "[[" ((om:scope-name) port) "_'''" "<-" (.name port) "_'''" "]]")))
                                                 (om:provided model)))

within compress(IFS [|{|#(comma-join (map (lambda (port) (list (.name port) "," (.name port) "_'" "," (.name port) "_'''")) (om:provided model)))|}|] R2C \ {|#
(comma-join (delete-duplicates (append-map (lambda (port) (list (list (.name port) "_'''.inevitable") (list (.name port) "_'''.optional") (list (.name port) "_'''.silent"))) (om:provided model))))|})


-- end of component.csp.scm
