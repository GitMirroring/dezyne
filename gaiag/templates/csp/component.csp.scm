;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
;;; Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

-- component.csp.scm

# (map (lambda (port)
         (->string "channel " (.name port) ": extensions(" ((om:scope-name) port) ")\n" ))
       (filter (lambda (port) (not (eq? ((om:scope-name) port) (.name port)))) ((compose .elements .ports) model)))
# (map (lambda (port)
         (->string "channel " (.name port) "_': extensions(" ((om:scope-name) port) "_')\n" ))
       (filter (lambda (port) (not (eq? ((om:scope-name) port) (.name port)))) ((compose .elements .ports) model)))
# (map (lambda (port)
         (and-let* ((events (null-is-#f (port-events port om:out?))))
                   (->string "channel " (.name port) "_'': extensions(" ((om:scope-name) port) "_'')\n" )))
       (filter (lambda (port) (not (eq? ((om:scope-name) port) (.name port)))) ((compose .elements .ports) model)))
# (map (lambda (port)
         (->string "channel " (.name port) "_''': extensions(" ((om:scope-name) port) "_''')\n" ))
       (filter (lambda (port) (not (eq? ((om:scope-name) port) (.name port)))) ((compose .elements .ports) model)))


CO_#.scope_model _#((compose .name .behaviour) model) (IIG,IG) = let
# (->string (map (lambda (x) (csp-transform model (ast-transform model x))) (om:functions model)))
#(behaviour-component->csp model)

within #.scope_model _#((compose .name .behaviour) model)(#(comma-space-join (map (lambda (x) (csp-expression->string model x '())) (om:member-values model))))

channel extensions_over_empty_channels_is_undefined
channel IN',OUT' : {#
 (comma-join (list (comma-join
                    (map (lambda (port)
                           (comma-join (map (lambda (event) (list (.name port) "_''." (.name event))) (filter om:out? ((compose .elements .events om:import .type) port)))))
                           (filter om:requires? ((compose .elements .ports) model)))) 'extensions_over_empty_channels_is_undefined))}

channel LINK' : {|IN',OUT'|}

SINGLETHREADED = true

channel reorder_in  : {# (comma-join (map (lambda (x) (symbol-append ((om:scope-name) (om:port model)) (string->symbol "_'.") x)) (return-values-port (om:port model))))}
channel reorder_out : {# (comma-join (map (lambda (x) (symbol-append (.name (om:port model)) (string->symbol "_'.") x)) (return-values-port (om:port model))))}
channel queue_full

SEMANTICS(in',out',link',client',modeling',end') = let

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
       reorder_in?#((om:scope-name) (om:port model))_'.x' -> reorder_out!#(.name (om:port model))_'.x' -> R'(A')

S'    = let

N' = #(csp-queue-size)


Idle(c') = transition_begin -> ([] x' : union(client',modeling') @ x' -> FillQ(c',<>))

FillQ(c',r') = (c' <= N' & in'?x' -> FillQ(c'+1,r'))
            []
            ([] x':end' @ x' ->  (Busy(c',r') [] c' == 0 & ([] x' : union(client',modeling') @ x' -> FillQ(c',<>))))
            []
            (r' == <> & reorder_in?#((om:scope-name) (om:port model))_'.x' -> Busy(c',<x'>))

Busy(c',r') = (c' == 0 & transition_end -> (if r' == <> then Idle(0) else reorder_out!#(.name (om:port model))_'.head(r') -> Idle(0)))
              []
              (c' > 0 & transition_end -> transition_begin -> Busy(c',r'))
              []
              (c' <= N' & in'?x' -> Busy(c'+1,r'))
              []
              (c' > 0 & out'?x' -> Busy(c'-1,r'))
              []
              (r' != <> & reorder_in?#((om:scope-name) (om:port model))_'.x' -> illegal -> STOP)

within Idle(0)

within Q' [|{|in',out'|}|] if SINGLETHREADED then S' else R'(Union({{|in',out',transition_begin,transition_end|},client',modeling'}))

AS_#.scope_model _#((compose .name .behaviour) model) (IIG) = let
compress(x) = let
transparent sbisim
transparent diamond
within sbisim(diamond(x))

ClientCalls = {#
 (comma-join (map (lambda (event) (list (.name (om:port model)) "." (.name event))) (filter om:in? (om:events (om:port model)))))}
UsedModeling = {#
                (comma-join
                 (map (lambda (port)
                        (comma-join (map (lambda (event) (list (.name port) "." event)) (filter (lambda (event) (member event '(inevitable optional))) (port-events port)))))
                        (filter om:requires? ((compose .elements .ports) model))))}
TheEnd = {|#(comma-join (map (lambda (port)
                 (->string (.name port) "_'''" ))
               (filter om:requires? ((compose .elements .ports) model))))|}
within compress((CO_#.scope_model _#((compose .name .behaviour) model) (IIG,true) [[x<-OUT'.x|x<-extensions(OUT')]] [[x<-reorder_in.x|x<-extensions(reorder_in)]]
                 [|{|#(comma-join (append (list "OUT',transition_begin,transition_end,reorder_in") (let ((port (om:port model))) (list (.name port) (string-append (symbol->string (.name port)) "_'")))))|}|]
                 SEMANTICS(IN',OUT',LINK',ClientCalls,UsedModeling,TheEnd) \ {|OUT',transition_begin,transition_end,reorder_in|}
                 ) [[reorder_out.x<-x|x<-extensions(reorder_out)]]
                [|{|#(comma-join (apply append (list "IN'") (map (lambda (o) (list (.name o) (string-append (symbol->string (.name o)) "_'") (string-append (symbol->string (.name o)) "_'''"))) (filter om:requires? ((compose .elements .ports) model)))))|}|]
                (# (let ((required_processes ((->join "\n                 ||| ") (map (lambda (port)
(->string (list "IF_" ((om:scope-name) port) '_ ((compose .name .behaviour om:import .type) port) "(true,false) [["((om:scope-name) port) ".x<-" (.name port) ".x|x<-extensions("(.name port)")]][["((om:scope-name) port) "_'.x<-" (.name port) "_'.x|x<-extensions("(.name port)"_')]]" (if (not (null? (filter om:out? (om:events port)))) (list "[["((om:scope-name) port) "_''.x<-" (.name port) "_''.x|x<-extensions("(.name port)"_'')]]")) (list "[["((om:scope-name) port) "_'''.x<-" (.name port) "_'''.x|x<-extensions("(.name port)"_''')]]"))))
 (filter om:requires? ((compose .elements .ports) model)))))) (if (string-null? required_processes) 'STOP required_processes))
)[[x<-IN'.x|x<-extensions(IN')]])

-- end of component.csp.scm
