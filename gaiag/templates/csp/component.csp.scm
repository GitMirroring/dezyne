;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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


CO_#.scope_model _plain(IIG,IG) = let
# (->string (map (lambda (x) (csp-transform model (ast-transform model x))) (om:functions model)))
#(behaviour-component->csp model)

within #.scope_model _(#(comma-space-join (map (lambda (x) (csp-expression->string model x '())) (om:member-values model))))

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

SINGLETHREADED = true

channel reorder_in, reorder_out : {|#(comma-join (map (lambda (x) (symbol-append x (string->symbol "_'"))) (map .name (om:provided model))))|}
channel queue_full

SEMANTICS(in',out',link',provided_in',provided_blocked',required_modeling',required_modeling_end',externals') = let

Q' = let

N' = #(csp-queue-size)

external chase

Cell = link'.in'?x' -> link'.out'!x' -> Cell

Back = in'?x' -> (link'.out'!x' -> Back [] in'?x' -> queue_full -> STOP)

Front = Cell[[link'.out' <- out']]

within
       if (N'==1) then (Back[[link'.out' <- out']])
       else if(N'==2) then chase(Back [link'.out' <-> link'.in'] Front  \ {|link'|})
       else chase((Back [link'.out' <-> link'.in'] ([link'.out'<->link'.in'] x : <1..N'-2> @ Cell)) [link'.out' <-> link'.in'] Front \ {|link'|})

R'(A') = ([] x' : A' @ x' -> R'(A'))
         []
         reorder_in?x' -> reorder_out!x' -> R'(A')
         []
         queue_full -> STOP

S'    = let

N' = #(csp-queue-size)

 -- component receives a stimulus
Idle() = transition_begin -> (([] x':provided_in' @ x' -> FillQ(0,false,false))
                              []
                              ([] x':required_modeling' @ x' -> FillQ(0,true,member(x',externals'))))

FillQ(c',rmod',external') =
   -- as a result of the stimulus it starts filling its queue
(c' <= N' & in'?x' -> FillQ(c'+1,rmod',external'))
[] -- component is done filling the queue or it turned out to be an empty required modeling event
([] x':required_modeling_end' @ x' -> (Busy(c',<>,rmod',false,extensions_over_empty_channels_is_undefined)
                                       [] ((c' == 0) or external' & (([] x' : provided_in' @ x' -> FillQ(c',false,external'))
                                                     []
                                                     ([] x' :required_modeling' @ x' -> FillQ(c',true,external'))))))
[] -- synchronous out event
([]x':{|#(comma-join (map (lambda (port) (symbol-append (.name port) (string->symbol "_''"))) (om:provided model)))|} @ x' -> FillQ(c',rmod',external'))
[] -- component replies on the stimulus
(reorder_in?x': diff(extensions(reorder_in),provided_blocked')  -> Busy(c',<x'>,rmod',false,extensions_over_empty_channels_is_undefined))
[] -- component blocks port
(reorder_in?x': provided_blocked' -> Busy(c',<>,rmod',false,extensions_over_empty_channels_is_undefined))

Busy(c',r',rmod',pout',end') =
-- if rmod' then asynchronous out event else synchronous out event
#((->join "\n[]\n") (map (lambda (port) (list "([]x':{|" (.name port) "_''|} @ x' -> Busy(c',r',rmod',true," (.name port) "_'''.modeling))")) (om:provided model)))
[] -- component is finished and outputs the void or reply event if present
(c' == 0 & transition_end -> if rmod' and pout' then end' -> End(r') else End(r'))
[]
(c' > 0 & transition_end -> transition_begin -> Busy(c',r',rmod',pout',end')) -- handling synchronous out events
[]
(c' <= N' & in'?x' -> Busy(c'+1,r',rmod',pout',end')) -- accepting synchronous out events
[]
(c' > 0 & out'?x' -> Busy(c'-1,r',rmod',pout',end')) -- handling queued out events
[]
(r' == <> & reorder_in?x' -> Busy(c',<x'>,false,pout',end')) -- reply to unblock port
[]
(r' != <> & reorder_in?x': diff(extensions(reorder_in),provided_blocked') -> illegal -> STOP) -- another reply is not allowed
[]
(r' != <> & reorder_in?x': provided_blocked' -> Busy(c',r',false,pout',end')) -- ignore blocked if reply already given
[]
queue_full -> STOP

End(r') = if r' == <> then Idle() else reorder_out!head(r') -> Idle()

within Idle()

within Q' [|{|in',out',queue_full|}|] if SINGLETHREADED then S' else R'(Union({{|in',out',transition_begin,transition_end|},provided_in',required_modeling'}))

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
end_required_modeling' = {#(comma-join (append-map (lambda (port)
                (list (->string (.name port) "_'''.modeling" ) (->string (.name port) "_'''.silent" )))
                                            (filter om:requires? ((compose .elements .ports) model))))}
externals' = {|#((->join ",") (map (lambda (x) (list (.name x) "_'''")) (filter .external (om:ports model))))|}
within compress((CO_#.scope_model _ (IIG,true) [[x<-OUT'.x|x<-extensions(OUT')]] [[x<-reorder_in.x|x<-extensions(reorder_in)]]
                 [|{|#(comma-join (list "OUT',transition_begin,transition_end,reorder_in" (comma-join (append-map (lambda (port) (list (.name port) (symbol-append (.name port) (string->symbol "_'")) (symbol-append (.name port) (string->symbol "_''")))) (om:provided model)))))|}|]
                 SEMANTICS(IN',OUT',LINK',provided_in',provided_blocked',begin_required_modeling',end_required_modeling',externals') \ {|OUT',transition_begin,transition_end,reorder_in|}
                 ) [[reorder_out.x<-x|x<-extensions(reorder_out)]]
                [|{|#(comma-join (apply append (list "IN'") (map (lambda (o) (list (.name o) (string-append (symbol->string (.name o)) "_'") (string-append (symbol->string (.name o)) "_'''"))) (om:required model))))|}|]
                (# (let ((required_processes ((->join "\n                 ||| ") (map (lambda (port)
(->string (list "IF_" ((om:scope-name) port) '_"(true,false) [["((om:scope-name) port) ".x<-" (.name port) ".x|x<-extensions("(.name port)")]][["((om:scope-name) port) "_'.x<-" (.name port) "_'.x|x<-extensions("(.name port)"_')]]" (if (not (null? (filter om:out? (om:events port)))) (list "[["((om:scope-name) port) "_''.x<-" (.name port) "_''.x|x<-extensions("(.name port)"_'')]]")) (list "[["((om:scope-name) port) "_'''.x<-" (.name port) "_'''.x|x<-extensions("(.name port)"_''')]]"))))
 (filter om:requires? ((compose .elements .ports) model)))))) (if (string-null? required_processes) 'STOP required_processes))
)[[x<-IN'.x|x<-extensions(IN')]])

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
