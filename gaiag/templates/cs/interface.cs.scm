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

public class #.interface  : Interface<#.interface .In, #.interface .Out> {#
(->string (map (declare-enum model) (om:interface-enums model)))
  new public class In : Interface<#.model .In, #.model .Out>.In {
#((->join "\n") (map (declare-io model #{
    public #(lambda-type return-type formal-types)  #name ;#})
 (filter om:in? ((compose .elements .events) model)))
)
  }
  new public class Out : Interface<#.model .In, #.model .Out>.Out {
#((->join "\n") (map (declare-io model #{
    public #(lambda-type return-type formal-types)  #name;#})
 (filter om:out? ((compose .elements .events) model))))
  }
  public #.interface() {
    inport = new In();
    outport = new Out();
  }
  public static void connect(#.model  provided, #.model  required) {
   provided.outport = required.outport;
   required.inport = provided.inport;
  }
}
