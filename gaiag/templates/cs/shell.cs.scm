;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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
#(map (init-instance model #{
    public #((om:scope-name) component)  #name;
#}) ((compose .elements .instances) model))#
(map (init-port #{
    public #((om:scope-join) interface)  #name;
#}) ((compose .elements .ports) model))
dzn.pump dzn_pump;

public #.scope_model(dzn.Locator locator, String name="", dzn.Meta parent=null) : base(locator.clone(), name, parent) {
  dzn_pump = new dzn.pump();
  dzn_locator.set(dzn_pump);
#(map (init-instance model #{
    #name  = new #((om:scope-name) component)(dzn_locator);
    #name .dzn_meta.parent = dzn_meta;

#}) ((compose .elements .instances) model))#
(map
  (lambda (port)
    (let* ((binding (om:port-bind model port))
          (instance-binding (om:instance-binding? binding))
          (instance-port (.name (.port instance-binding)))
          (instance (.name (om:instance model port)))
          (port (.name port)))
      (animate #{#instance .#instance-port .dzn_meta.requires.name = "#port ";
               #}
                 `((instance-port ,instance-port)
                   (instance ,instance)
                   (port ,port)))))
      (filter om:provides? (om:ports model)))#
(map
 (lambda (port)
   (let* ((binding (om:port-bind model port))
          (instance-binding (om:instance-binding? binding))
          (instance-port (.name (.port instance-binding)))
          (instance (.name (om:instance model port)))
          (port (.name port)))
     (animate #{#instance .#instance-port .dzn_meta.provides.name = "#port ";
              #}
                `((instance-port ,instance-port)
                  (instance ,instance)
                  (port ,port)))))
 (filter om:requires? (om:ports model)))#
(map (init-port #{#'()
    #name  = new #((om:scope-join) interface)();
    #name .dzn_meta.provides.name = "#name ";
    #name .dzn_meta.provides.meta = dzn_meta;
    #name .dzn_meta.provides.component = this;#})
    (filter om:provides? ((compose .elements .ports) model)))
#(map (init-port #{#'()
#(string-if injected?
#{
    #name  = locator.get<#((om:scope-join) interface) >();
#}
#{
    #name  = new #((om:scope-join) interface)();
    #name .dzn_meta.requires.name = "#name ";
    #name .dzn_meta.requires.component = this;
    #name .dzn_meta.requires.meta = dzn_meta;#})
#})
    (filter om:requires? ((compose .elements .ports) model)))#
(map (init-instance model #{
    #name  = new #((om:scope-name) component)(locator, "#name ", dzn_meta);
#}) (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{
    locator = locator.clone()#
    (map (init-bind model #{.set(#instance);#}) (injected-bindings model))
#})
#(map
 (lambda (port)
   (map (define-on model port #{
#port .#direction port.#event  = (#formals) => {#(string-if (not (eq? return-type 'void)) #{return #}) dzn_pump.blocking#(string-if (not (eq? return-type 'void)) #{<#return-type >#})(() => {#(string-if (not (eq? return-type 'void)) #{return #}) #instance .#instance-port .#direction port.#event(#arguments);});};
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
   (lambda (port)
     (map (define-on model port #{#'()
   #port .#direction port.#event  = (#formals) => {#(string-if (not (eq? return-type 'void)) #{return #})dzn_pump.execute(() => {#instance .#instance-port .#direction port.#event(#arguments);});};
   #}) (filter (om:dir-matches? port) (om:events port))))
   (filter om:requires? (om:ports model)))
#(map
 (lambda (port)
   (map (define-on model port #{
    #instance .#instance-port .outport.#event  = (#formals) => {#(string-if (not (eq? return-type 'void)) #{return #}) #port .outport.#event(#arguments);};
#}) (filter om:out? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
    (lambda (port)
      (map (define-on model port #{
    #instance .#instance-port .inport.#event  = (#formals) => {#(string-if (not (eq? return-type 'void)) #{return #}) #port .inport.#event(#arguments);};
#}) (filter om:in? (om:events port))))
      (filter om:requires? (om:ports model)))
#(map (connect-ports model #{
    #((om:scope-name '_) interface) .connect(#provided , #required);
#}) (filter (negate om:port-bind?) ((compose .elements .bindings) model)))
    }
}
