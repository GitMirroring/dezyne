;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
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
  public class In {
#((->join "\n") (map (declare-io model #{
    public #(lambda-type return-type formal-types)  #name ;#})
 (filter om:in? ((compose .elements .events) model)))
)
  }
  public class Out {
#((->join "\n") (map (declare-io model #{
    public #(lambda-type return-type formal-types)  #name;#})
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
  }
}
