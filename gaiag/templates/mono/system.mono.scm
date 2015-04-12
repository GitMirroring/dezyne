;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

using System;

class #.model  : SystemComponent {
#(map (init-instance #{
    public #component  #name;
#}) ((compose .elements .instances) model))#
(map (init-port #{
    public #interface  #name;
#}) ((compose .elements .ports) model))

  public #.model(Runtime runtime, String name="", SystemComponent parent=null) : base(runtime, name, parent) {
#(map (init-instance #{
    #name  = new #component(runtime, "#name ", this);
#}) ((compose .elements .instances) model))#
(map (init-bind model #{
    #port  = #instance;
#}) (filter bind-port? ((compose .elements .bindings) model)))
# (map (connect-ports model #{
    #interface .connect(#provided , #required);
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))}
}
