;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

assert #.interface.name _#.interface-behaviour(true) [[#.interface.name .x<-#.port.name .x|x<-extensions(#.interface.name)]] \ {#
(map-ports #{#
   (comma-join
       (map (lambda (x) (string-join (map ->string (list .port.name x)) ".")) (filter
         (lambda (x) (or (eq? x 'optional) (eq? x 'inevitable)))
         (port-events port)))) #} (filter gom:provides? ((compose .elements .ports gom:component) ast)))} [F= #.component _#.behaviour.name _Component(true) \ diff(Events,{|illegal,#.port.name |})
