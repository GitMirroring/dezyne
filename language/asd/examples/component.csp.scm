;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Gaiag.
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

datatype event_alphabet 
= %(pipe-join (unique (sort (append (event-names (component-ports (component ast))) '(arm return)) symbol<)))

% (map-ports 
"channel %(*interface*),%(*port*): {%(comma-join (append (map port-name (port-events *port-def*)) '(return)))}
" (component-ports (component ast)))

%(*component*)_%(behaviour-name (component-behaviour (component ast))) (IIG,IG) = let
%(*component*)_%(behaviour-name (component-behaviour (component ast)))(% (comma-join (map variable-name (behaviour-variables (component-behaviour (component ast)))))) = 

% (map-guards
" (% (list (cadr (guard-expression *guard-def*)) '== (caddr (guard-expression *guard-def*)))) & transition_begin -> (
" (statements-guard (behaviour-statements (component-behaviour (component ast)))))

