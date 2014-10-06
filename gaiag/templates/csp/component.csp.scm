;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
         (->string "channel " (.name port) ":{" (comma-join (append (port-events port) (return-values-port port))) "}\n" ))
       (filter (lambda (port) (not (eq? (.type port) (.name port)))) ((compose .elements .ports) model)))

CO_#(.name model) _#((compose .name .behaviour) model) (IIG,IG) = let
# (->string (map (lambda (x) (csp-transform model (ast-transform model x))) (gom:functions (.behaviour model))))
#(.name model) _#((compose .name .behaviour) model) ((#(->csp model (make <context> :members ((compose gom:member-names) model))))) = transition_begin -> (
#(behaviour->csp model
 (->string (list (.name model) "_" ((compose .name .behaviour) model) "((" (->csp model (make <context> :members ((compose gom:member-names) model))) "))" )))
)

within #(.name model) _#((compose .name .behaviour) model) ((#(->csp model (make <context> :members ((compose gom:member-values) model) :locals '(<>)))))

channel extensions_over_empty_channels_is_undefined
channel IN,OUT : {#
 (comma-join (list (comma-join
                    (map (lambda (port)
                           (comma-join (map (lambda (event) (list (.name port) "." (.name event))) (filter gom:out? ((compose .elements .events gom:import .type) port)))))
                           (filter gom:requires? ((compose .elements .ports) model)))) 'extensions_over_empty_channels_is_undefined))}

SINGLETHREADED = true

channel reorder_in  : {# (comma-join (map (lambda (x) (symbol-append (.type (gom:port model)) '. x)) (return-values-port (gom:port model))))}
channel reorder_out : {# (comma-join (map (lambda (x) (symbol-append (.name (gom:port model)) '. x)) (return-values-port (gom:port model))))}

SEMANTICS(in',out',client',modeling') = let
Q'(s') = length(s') < card({|in'|}) & in'?x' -> Q'(s'^<x'>)
       []
       length(s') > 0 & out'!head(s') -> Q'(tail(s'))
       []
       length(s') == card({|in'|}) & in'?x' -> illegal -> STOP

R'(A') = ([] x' : A' @ x' -> R'(A'))
       []
       reorder_in?#(.type (gom:port model)).x' -> reorder_out!#(.name (gom:port model)).x' -> R'(A')

S'    = let

Idle(c') = transition_begin -> ([] x' : union(client',modeling') @ x' -> Busy(c',<>))

Busy(c',r') = c' == 0 & transition_end -> (if r' == <> then Idle(0) else reorder_out!#(.name (gom:port model)).head(r') -> Idle(0))
            []
            c' > 0 & transition_end -> transition_begin -> Busy(c',r')
            []
            c' < card({|in'|}) & ([] x' : {|in'|} @ x' -> Busy(c'+1,r'))
            []
            c' > 0 & ([] x' : {|out'|} @ x' -> Busy(c'-1,r'))
            []
            r' == <> & reorder_in?#(.type (gom:port model)).x' -> Busy(c',<x'>)
            []
            r' != <> & reorder_in?#(.type (gom:port model)).x' -> illegal -> STOP

within Idle(0)

within Q'(<>) [|{|in',out'|}|] if SINGLETHREADED then S' else R'(Union({{|in',out',transition_begin,transition_end|},client',modeling'}))

AS_#(.name model) _#((compose .name .behaviour) model) (IIG) = let
compress(x) = let
transparent sbisim
transparent diamond
within sbisim(diamond(x))
Exclude = {#
  (comma-join
   (list (comma-join (map (lambda (x) (symbol-append (.name (gom:port model)) '. x)) (return-values-port (gom:port model))))
         (comma-join (map (lambda (event) (list (.name (gom:port model)) "." (.name event))) (filter gom:out? (gom:events (gom:port model)))))
         (comma-join
          (map (lambda (port)
                 (->string (comma-join (map (lambda (event) (list (.name port) "." event)) (filter (lambda (x) (member x '(inevitable optional))) (port-events port))))))
               ((compose .elements .ports) model)))))}
ClientCalls = {#
 (comma-join (map (lambda (event) (list (.name (gom:port model)) "." (.name event))) (filter gom:in? (gom:events (gom:port model)))))}
UsedModeling = {#
                (comma-join
                 (map (lambda (port)
                        (comma-join (map (lambda (event) (list (.name port) "." event)) (filter (lambda (event) (member event '(inevitable optional))) (port-events port)))))
                        (filter gom:requires? ((compose .elements .ports) model))))}
within compress((CO_#(.name model) _#((compose .name .behaviour) model) (IIG,true) [[x<-OUT.x|x<-extensions(OUT)]] [[x<-reorder_in.x|x<-extensions(reorder_in)]]
[|diff({|OUT,transition_begin,transition_end,reorder_in,#(comma-join (map (lambda (o) (.name o)) ((compose .elements .ports) model)))|},Exclude)|]
(((# (let ((required_processes ((->join "\n ||| ") (map (lambda (port)
(->string (list "IF_" (.type port) '_ ((compose .name .behaviour gom:import .type) port) "(true) [["(.type port) ".x<-" (.name port) ".x|x<-extensions("(.name port)")]]")))
 (filter gom:requires? ((compose .elements .ports) model)))))) (if (string-null? required_processes) 'STOP required_processes))
) [[x<-IN.x|x<-extensions(IN)]]
[|union({|IN|},UsedModeling)|]
SEMANTICS(IN,OUT,ClientCalls,UsedModeling)))) [[reorder_out.x<-x|x<-extensions(reorder_out)]]\{transition_begin,transition_end})

-- end of component.csp.scm
