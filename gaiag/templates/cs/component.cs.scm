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

public class #.scope_model  : Component {#
(->string (map (declare-enum model) (om:enums (.behaviour model))))#
(->string (map declare-integer (om:integers (.behaviour model))))
#
    (map (init-member model #{#'()
  #type  #name;#}) (om:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{#'()
  public #((om:scope-join) interface)  #name;#}) ((compose .elements .ports) model))

  public #.scope_model(Locator locator, String name="", dzn.Meta parent=null) : base(locator, name, parent) {
    this.flushes = true;#
(map (init-member model #{#'()
    #(string-if (eq? expression (if #f #f)) "" #{#name  = #expression ;#})#}) (om:variables model))#
(map (init-port #{#'()
    #name  = new #((om:scope-join) interface)();
    #name .dzn_meta.provides.name = "#name ";
    #name .dzn_meta.provides.meta = this.dzn_meta;
    #name .dzn_meta.provides.component = this;#})
    (filter om:provides? ((compose .elements .ports) model)))#
(map (init-port #{#'()
#(string-if injected?
#{
    #name  = locator.get<#((om:scope-join) interface) >();
#}
#{
    #name  = new #((om:scope-join) interface)();
    #name .dzn_meta.requires.name = "#name ";
    #name .dzn_meta.requires.component = this;
    #name .dzn_meta.requires.meta = this.dzn_meta;#})
#})
    (filter om:requires? ((compose .elements .ports) model)))#
(map
   (lambda (port)
     (map (define-on model port #{#'()
   #port .#direction port.#event  = (#formals) => {#(string-if (not (eq? return-type 'void)) #{return #})Runtime.call#(symbol-capitalize direction)#(string-if (not (eq? return-type 'void)) #{<#return-type >#})(this, () => {#(string-if (not (eq? return-type 'void)) #{return #})#port _#event(#arguments);}, this.#port .dzn_meta, "#event ");};
   #}) (filter (om:dir-matches? port) (om:events port))))
   (om:ports model))
  }#
(map
   (lambda (port)
     (map (define-on model port #{#'()
  public #return-type  #port _#event (#formals) {
  #statement #(if (not (eq? type 'void))
(list "return reply_" ((om:scope-join #f) reply-scope) "_" reply-name ";\n")) }
#}) (filter (om:dir-matches? port) (om:events port))))
   (om:ports model))#
(map (define-function model #{
   public #return-type  #name  (#formals) {
#statements }
#}) (om:functions model))
}
