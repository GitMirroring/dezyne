;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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
  static bool flush = false;
  static bool relaxed = false;

  static String drop_prefix(String str, String prefix) {
    if (str.StartsWith(prefix)) {
      return str.Substring(prefix.Length);
    }
    return str;
  }

  static String consume_synchronous_out_events(String e, String prefix, EventMap event_map) {
    String s;
    String match = e + prefix;
    while ((s = System.Console.ReadLine()) != null)
      if (s == match)
        break;
    while ((s = System.Console.ReadLine()) != null) {
      if (!event_map.ContainsKey(s)) {
        break;
      }
      event_map[s]();
    }
    return s;
  }

  static void log_in(String prefix, String e, EventMap event_map) {
    System.Console.Error.WriteLine(prefix + e);
    if (relaxed) return;
    consume_synchronous_out_events(prefix, e, event_map);
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
    if (relaxed) {
        R[] values = (R[])Enum.GetValues(typeof(R));
        return values[0];
    }
    String s = consume_synchronous_out_events(prefix, e, event_map);
    R? r = string_to_value<R>(drop_prefix(s, event_prefix));
    if (r != null) {
      System.Console.Error.WriteLine(prefix + typeof(R).Name + "_" + r.ToString());
      return (R)r;
    }
    return default(R);
  }


  private class EventMap : Dictionary<String, Action> {};

  private static EventMap fillEventMap(#.scope_model  m) {
  dzn.V<int> v = new dzn.V<int> (0);
  if (v.v == 0) {}
  dzn.Component c = new dzn.Component(m.dzn_locator);
  c.dzn_flushes = flush;
  c.dzn_meta.parent = null;
  c.dzn_meta.name = "<external>";
 EventMap e = new EventMap();
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction port.#event  = (#formals) => {#(string-if (eq? return-type 'void) #{log_#direction("#port .", "#event ", e);#}#{return log_valued<#(if (or (null? reply-scope) (om:outer-scope? model reply-scope)) 'dzn.Global reply-scope).#reply-name >("#port .", "#event ", e, "#port .#reply-name _");#})};
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))
#(map (init-port #{

    m.#name .dzn_meta.requires.name = "#name ";
    m.#name .dzn_meta.requires.component = c;
    m.#name .dzn_meta.requires.meta = c.dzn_meta;

    if (flush) {
      m.#name .dzn_meta.requires.component = c;
      m.#name .dzn_meta.requires.name = "<internal>.#name ";
    }
#}) (filter om:provides? (om:ports model)))
#(map (init-port #{

    m.#name .dzn_meta.provides.name = "#name ";
    m.#name .dzn_meta.provides.component = c;
    m.#name .dzn_meta.provides.meta = c.dzn_meta;

    if (flush) {
      m.#name .dzn_meta.provides.component = c;
      m.#name .dzn_meta.provides.name = "<internal>.#name ";
    }
    e.Add("#name .<flush>", () => {System.Console.Error.WriteLine("#name .<flush>"); dzn.Runtime.flush (m.#name .dzn_meta.provides.component);});
#}) (filter om:requires? (om:ports model)))
#(map
    (lambda (port)
    (map (define-on model port #{
        e.Add("#port .#event ", () => {m.#port .#direction port.#event(#((->join ", ") (map (lambda (p) (if (om:out-or-inout? p) 'v 0)) formal-objects)));});
#}) (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model))
 #(map (init-port #{
     m.#name .dzn_meta.provides.name = "#name ";
     m.#name .dzn_meta.requires.name = "#name ";
 #}) (om:ports model)) return e;
}

  public static void Main(String[] args) {
    flush = args.Length > 0 && args[0] == "--flush";
    relaxed = args.Length > 0 && args[0] == "--relaxed";
    dzn.Locator locator = new dzn.Locator();
    dzn.Runtime runtime = new dzn.Runtime(() => {System.Console.Error.WriteLine("illegal"); Environment.Exit(0);});
    #.scope_model  sut = new #.scope_model(locator.set(runtime), "sut");
    EventMap e = fillEventMap(sut);
    String s;
    while ((s = System.Console.ReadLine()) != null) {
      if (e.ContainsKey(s)) {
        e[s]();
      }
    }
  }
}
