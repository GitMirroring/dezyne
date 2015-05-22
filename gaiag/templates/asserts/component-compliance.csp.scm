;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

assert IF_#((compose .type om:port) model) _#((compose .name .behaviour om:import .type om:port) model)(true,false) [[#((compose .type om:port) model) .x<-#((compose .name om:port) model) .x|x<-extensions(#((compose .name om:port) model))]][[#((compose .type om:port) model)_'.x<-#((compose .name om:port) model)_'.x|x<-extensions(#((compose .name om:port) model)_')]]#
(->string (if (not (null? (filter om:out? (om:events (om:port model))))) (list "[["((compose .type om:port) model) "_''.x<-" ((compose .name om:port) model) "_''.x|x<-extensions("((compose .name om:port) model) "_'')]]"))) \ {#
   (comma-join
       (append (list (->string (list (.type (om:port model)) "_'''.modeling"))) (map (lambda (x) (map ->string (list ((compose .name om:port) model) "." x))) (filter
         (lambda (x) (or (eq? x 'optional) (eq? x 'inevitable)))
         (port-events (om:port model))))))} [F= AS_#(.name model) _#((compose .name .behaviour) model) (true) \ diff(Events,{|illegal,#((compose .name om:port)model),#((compose .name om:port)model)_'#
(->string (if (not (null? (filter om:out? (om:events (om:port model))))) (list "," ((compose .name om:port) model) "_''")))|})
