;;; Dezyne --- Dezyne command line tools
;;;
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

public class #.model  : Component {#
(->string (map (declare-enum model) (gom:enums (.behaviour model))))#
(->string (map declare-integer (gom:integers (.behaviour model))))
#
    (map (init-member model #{#'()
  #type  #name;#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{#'()
  public #interface  #name;#}) ((compose .elements .ports) model))

  public #.model(Locator locator, String name="", SystemComponent parent=null) : base(locator, name, parent) {
    this.flushes = true;#
(map (init-member model #{#'()
    #(string-if (eq? expression (if #f #f)) "" #{#name  = #expression ;#})#}) (gom:variables model))#
(map (init-port #{#'()
    #name  = new #interface();
    #name .inport.name = "#name ";
    #name .inport.self = this;#})
    (filter gom:provides? ((compose .elements .ports) model)))#
(map (init-port #{#'()
#(string-if injected?
#{
    #name  = locator.get<#interface >();
#}
#{
    #name  = new #interface();
    #name .outport.name = "#name ";
    #name .outport.self = this;#})
#})
    (filter gom:requires? ((compose .elements .ports) model)))#
(map
   (lambda (port)
     (map (define-on model port #{#'()
  #port .#direction port.#event  = (#parameters) => {#(string-if (not (eq? return-type 'void)) #{return #})Runtime.call#(symbol-capitalize direction)<#interface .In,#interface .Out#(string-if (not (eq? return-type 'void)) #{, #return-type#})>(this, () => {#(string-if (not (eq? return-type 'void)) #{return #})#port _#event(#arguments);}, new Meta<#interface .In,#interface .Out>(this.#port , "#event"));};
   #}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))
  }#
(map
   (lambda (port)
     (map (define-on model port #{#'()
  public #return-type  #port _#event (#parameters) {
  #statement #(if (not (eq? type 'void))
(list "return reply_" (*scope* reply-scope) "_" reply-name ";\n")) }
#}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))#
(map (define-function model #{
   public #return-type  #name  (#parameters) {
#statements }
#}) (gom:functions model))
}
