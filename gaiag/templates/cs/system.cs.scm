;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

class #.scope_model  : dzn.SystemComponent {
#(map (init-instance #{
    public #((om:scope-name) component)  #name;
#}) ((compose .elements .instances) model))#
(map (init-port #{
    public #((om:scope-join) interface)  #name;
#}) ((compose .elements .ports) model))

  public #.scope_model(dzn.Locator locator, String name="", dzn.Meta parent=null) : base(locator, name, parent) {
#(map (init-instance #{
    #name  = new #((om:scope-name) component)(locator, "#name ", this.dzn_meta);
#}) (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{
    locator = locator.clone()#
    (map (init-bind model #{.set(#instance);#}) (injected-bindings model))
#})#
(map (init-instance #{
    #name  = new #((om:scope-name) component)(locator, "#name ", this.dzn_meta);
#}) (non-injected-instances model))#
(map (init-bind model #{
    #port  = #instance;
#}) (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
# (map (connect-ports model #{
    #((om:scope-name '_) interface) .connect(#provided , #required);
#}) (filter (negate om:port-bind?) ((compose .elements .bindings) model)))}
}
