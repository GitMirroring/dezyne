;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2015 Henk Katerberg <henk.katerberg@yahoo.com>
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

class main {

  static String drop_prefix(String str, String prefix) {
    if (str.StartsWith(prefix)) {
      return str.Substring(prefix.Length);
    }
    return str;
  }

  static String consume_synchronous_out_events(EventMap event_map) {
    System.Console.ReadLine();
    String line;
    while ((line = System.Console.ReadLine()) != null) {
      if (!event_map.ContainsKey(line)) {
        break;
      }
      event_map[line]();
    }
    return line;
  }

  static void log_in(String prefix, String e, EventMap event_map) {
    System.Console.Error.WriteLine(prefix + e);
    consume_synchronous_out_events(event_map);
    System.Console.Error.WriteLine(prefix + "return");
  }

  static void log_out(String prefix, String e, EventMap event_map) {
    System.Console.Error.WriteLine(prefix + e);
  }

  static R? string_to_value<R>(String s) where R: struct, IComparable, IConvertible, IFormattable {
    foreach (R e in Enum.GetValues(typeof(R))) {
      if (e.ToString().Equals(s)) {
        return e;
      }
    }
    return null;
  }

  static R log_valued<R>(String prefix, String e, EventMap event_map, String event_prefix) where R: struct, IComparable, IConvertible, IFormattable {
    System.Console.Error.WriteLine(prefix + e);
    String s = consume_synchronous_out_events(event_map);
    R? r = string_to_value<R>(drop_prefix(s, event_prefix));
    if (r != null) {
      System.Console.Error.WriteLine(prefix + typeof(R).Name + "_" + r.ToString());
      return (R)r;
    }
    return default(R);
  }


  private class EventMap : Dictionary<String, Action> {};

  private static EventMap fillEventMap(#.model  m) {
  V<int> v = new V<int> (0);
  EventMap e = new EventMap();
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction port.#event  = (#formals) => {#(string-if (eq? return-type 'void) #{log_#direction("#port .", "#event ", e);#}#{return log_valued<#(if (eq? reply-scope '*global*) 'DznGlobal reply-scope).#reply-name >("#port .", "#event ", e, "#port .#reply-name _");#})};
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))
#(map
    (lambda (port)
    (map (define-on model port #{
        e.Add("#port .#event ", () => {m.#port .#direction port.#event(#((->join ", ") (map (lambda (p) (if (om:out-or-inout? p) 'v 0)) formal-objects)));});
#}) (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model)) return e;
}

  public static void Main(String[] args) {
    Locator locator = new Locator();
    Runtime runtime = new Runtime(() => {System.Console.Error.WriteLine("illegal"); Environment.Exit(0);});
    #.model  sut = new #.model(locator.set(runtime), "sut");
    EventMap e = fillEventMap(sut);
    String line;
    while ((line = System.Console.ReadLine()) != null) {
      if (e.ContainsKey(line)) {
        e[line]();
      }
    }
  }
}
