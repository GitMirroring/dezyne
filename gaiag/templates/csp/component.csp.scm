;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
         (->string "channel " (.name port) ": extensions(" (.type port) ")\n" ))
       (filter (lambda (port) (not (eq? (.type port) (.name port)))) ((compose .elements .ports) model)))
# (map (lambda (port)
         (->string "channel " (.name port) "_': extensions(" (.type port) "_')\n" ))
       (filter (lambda (port) (not (eq? (.type port) (.name port)))) ((compose .elements .ports) model)))
# (map (lambda (port)
         (and-let* ((events (null-is-#f (port-events port gom:out?))))
                   (->string "channel " (.name port) "_'': extensions(" (.type port) "_'')\n" )))
       (filter (lambda (port) (not (eq? (.type port) (.name port)))) ((compose .elements .ports) model)))
# (map (lambda (port)
         (->string "channel " (.name port) "_''': extensions(" (.type port) "_''')\n" ))
       (filter (lambda (port) (not (eq? (.type port) (.name port)))) ((compose .elements .ports) model)))


CO_#(.name model) _#((compose .name .behaviour) model) (IIG,IG) = let
# (->string (map (lambda (x) (csp-transform model (ast-transform model x))) (gom:functions (.behaviour model))))
#(.name model) _#((compose .name .behaviour) model) ((#(->csp model (make <context> :members ((compose gom:member-names) model))))) = transition_begin -> (
#(behaviour->csp model)
)

within #(.name model) _#((compose .name .behaviour) model) ((#(->csp model (make <context> :members ((compose gom:member-values) model) :locals '(<>)))))

channel extensions_over_empty_channels_is_undefined
channel IN',OUT' : {#
 (comma-join (list (comma-join
                    (map (lambda (port)
                           (comma-join (map (lambda (event) (list (.name port) "_''." (.name event))) (filter gom:out? ((compose .elements .events gom:import .type) port)))))
                           (filter gom:requires? ((compose .elements .ports) model)))) 'extensions_over_empty_channels_is_undefined))}

channel LINK' : {|IN',OUT'|}

SINGLETHREADED = true

channel reorder_in  : {# (comma-join (map (lambda (x) (symbol-append (.type (gom:port model)) (string->symbol "_'.") x)) (return-values-port (gom:port model))))}
channel reorder_out : {# (comma-join (map (lambda (x) (symbol-append (.name (gom:port model)) (string->symbol "_'.") x)) (return-values-port (gom:port model))))}
channel queue_full'

SEMANTICS(in',out',link',client',modeling',end') = let

Q' = let

N' = #(csp-queue-size)

external chase

Cell = link'.in'?x' -> link'.out'!x' -> Cell

Back = in'?x' -> (link'.out'!x' -> Back [] in'?x' -> queue_full' -> illegal -> STOP)

Front = Cell[[link'.out' <- out']]

within
       if (N'==1) then (Back[[link'.out' <- out']])
       else if(N'==2) then chase(Back [link'.out' <-> link'.in'] Front  \ {|link'|})
       else chase((Back [link'.out' <-> link'.in'] ([link'.out'<->link'.in'] x : <1..N'-2> @ Cell)) [link'.out' <-> link'.in'] Front \ {|link'|})

R'(A') = ([] x' : A' @ x' -> R'(A'))
       []
       reorder_in?#(.type (gom:port model))_'.x' -> reorder_out!#(.name (gom:port model))_'.x' -> R'(A')

S'    = let

N' = #(csp-queue-size)


Idle(c') = transition_begin -> ([] x' : union(client',modeling') @ x' -> FillQ(c',<>))

FillQ(c',r') = (c' <= N' & in'?x' -> FillQ(c'+1,r'))
            []
            ([] x':end' @ x' ->  Busy(c',r'))
            []
            (r' == <> & reorder_in?#(.type (gom:port model))_'.x' -> Busy(c',<x'>))

Busy(c',r') = (c' == 0 & transition_end -> (if r' == <> then Idle(0) else reorder_out!#(.name (gom:port model))_'.head(r') -> Idle(0)))
              []
              (c' > 0 & transition_end -> transition_begin -> Busy(c',r'))
              []
              (c' <= N' & in'?x' -> Busy(c'+1,r'))
              []
              (c' > 0 & out'?x' -> Busy(c'-1,r'))
              []
              (r' != <> & reorder_in?#(.type (gom:port model))_'.x' -> illegal -> STOP)

within Idle(0)

within Q' [|{|in',out'|}|] if SINGLETHREADED then S' else R'(Union({{|in',out',transition_begin,transition_end|},client',modeling'}))

AS_#(.name model) _#((compose .name .behaviour) model) (IIG) = let
compress(x) = let
transparent sbisim
transparent diamond
within sbisim(diamond(x))

ClientCalls = {#
 (comma-join (map (lambda (event) (list (.name (gom:port model)) "." (.name event))) (filter gom:in? (gom:events (gom:port model)))))}
UsedModeling = {#
                (comma-join
                 (map (lambda (port)
                        (comma-join (map (lambda (event) (list (.name port) "." event)) (filter (lambda (event) (member event '(inevitable optional))) (port-events port)))))
                        (filter gom:requires? ((compose .elements .ports) model))))}
TheEnd = {|#(comma-join (map (lambda (port)
                 (->string (.name port) "_'''" ))
               (filter gom:requires? ((compose .elements .ports) model))))|}
within compress((CO_#(.name model) _#((compose .name .behaviour) model) (IIG,true) [[x<-OUT'.x|x<-extensions(OUT')]] [[x<-reorder_in.x|x<-extensions(reorder_in)]]
                 [|{|#(comma-join (append (list "OUT',transition_begin,transition_end,reorder_in") (let ((port (gom:port model))) (list (.name port) (string-append (symbol->string (.name port)) "_'")))))|}|]
                 SEMANTICS(IN',OUT',LINK',ClientCalls,UsedModeling,TheEnd) \ {|OUT',transition_begin,transition_end,reorder_in|}
                 ) [[reorder_out.x<-x|x<-extensions(reorder_out)]]
                [|{|#(comma-join (apply append (list "IN'") (map (lambda (o) (list (.name o) (string-append (symbol->string (.name o)) "_'") (string-append (symbol->string (.name o)) "_'''"))) (filter gom:requires? ((compose .elements .ports) model)))))|}|]
                (# (let ((required_processes ((->join "\n                 ||| ") (map (lambda (port)
(->string (list "IF_" (.type port) '_ ((compose .name .behaviour gom:import .type) port) "(true,false) [["(.type port) ".x<-" (.name port) ".x|x<-extensions("(.name port)")]][["(.type port) "_'.x<-" (.name port) "_'.x|x<-extensions("(.name port)"_')]]" (if (not (null? (filter gom:out? (gom:events port)))) (list "[["(.type port) "_''.x<-" (.name port) "_''.x|x<-extensions("(.name port)"_'')]]")) (list "[["(.type port) "_'''.x<-" (.name port) "_'''.x|x<-extensions("(.name port)"_''')]]"))))
 (filter gom:requires? ((compose .elements .ports) model)))))) (if (string-null? required_processes) 'STOP required_processes))
)[[x<-IN'.x|x<-extensions(IN')]])

-- end of component.csp.scm
