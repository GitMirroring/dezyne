;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
;;; Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
;;; Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
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

public class #.scope_model {#
 (->string (map (declare-enum model) (om:interface-enums model)))
 public static string to_string(bool b) {return b ? "true" : "false";}
  public class In {
#(map (declare-io model #{
    public #(lambda-type model type formals)  #name ;
    #})
 (filter om:in? ((compose .elements .events) model)))

  }
  public class Out {
#((->join "\n") (map (declare-io model #{
    public #(lambda-type model type formals)  #name;#})
 (filter om:out? ((compose .elements .events) model))))
  }
  public dzn.port.Meta dzn_meta;
  public In inport;
  public Out outport;
  public #.scope_model() {
    dzn_meta = new dzn.port.Meta ();
    inport = new In();
    outport = new Out();
  }
  public static void connect(#.scope_model  provided, #.scope_model  required) {
   provided.outport = required.outport;
   required.inport = provided.inport;
   provided.dzn_meta.requires = required.dzn_meta.requires;
   required.dzn_meta.provides = provided.dzn_meta.provides;
  }
  public void check_bindings()
  {
  #(map (declare-io model #{
      if (inport.#name	== null) throw new dzn.binding_error(dzn_meta, "inport.#name ");
  #}) (filter om:in? ((compose .elements .events) model)))
  #(map (declare-io model #{
      if (outport.#name	 == null) throw new dzn.binding_error(dzn_meta, "outport.#name ");
  #}) (filter om:out? ((compose .elements .events) model)))
  }
}
