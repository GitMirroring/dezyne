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
using System.Collections.Generic;

class EventMap : Dictionary<String, Action> {};

class main {
                        
  private static EventMap fillEventMap(#.model  m) {
  V<int> v = new V<int> (0);
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction port.#event  = (#parameters) => {System.Console.Error.WriteLine("#port .#direction .#event");#(string-if (not (eq? return-type 'void)) #{ return new (#return-type)();#})};
#}) (filter (negate (gom:dir-matches? port))
       (gom:events port)))) (gom:ports model))     EventMap e = new EventMap();
#(map
    (lambda (port)
    (map (define-on model port #{
        e.Add("#port .#event ", () => {m.#port .#direction port.#event(#((->join ", ") (map (lambda (p) (if (gom:out-or-inout? p) 'v 0)) parameter-objects)));});
#}) (filter (gom:dir-matches? port)
       (gom:events port)))) (gom:ports model)) return e;
}

  public static void Main(String[] args) {
    Runtime runtime = new Runtime();
    #.model  sut = new #.model(runtime, "sut");
    EventMap e = fillEventMap(sut);
    String line;
    while ((line = System.Console.ReadLine()) != null) {
      if (e.ContainsKey(line)) {
        e[line]();
      }
    }
  }
}
