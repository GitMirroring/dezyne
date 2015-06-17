// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Dezyne.
//
// Dezyne is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Dezyne is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.HashMap;

class Reader {
  BufferedReader reader;
  String readLine() {
    try {
      if (System.console() != null) {
        return System.console().readLine();
      }
      if (reader == null) {
        reader = new BufferedReader(new InputStreamReader(System.in));
      }
      return reader.readLine();
    }
    catch (IOException e) {
      return null;
    }
  }
}

class main<R> {
  static Reader reader;

  static String drop_prefix(String string, String prefix) {
    if (string.startsWith(prefix)) {
      return string.substring(prefix.length());
    }
    return string;
  }

  static String consume_synchronous_out_events(EventMap event_map) {
    main.reader.readLine();
    String line;
    while ((line = main.reader.readLine()) != null) {
      Action a = event_map.get(line);
      if (a == null) {
        break;
      }
      a.action();
    }
    return line;
  }

  static void log_in(String prefix, String event, EventMap event_map) {
    System.err.println(prefix + "in." + event);
  }

  static void log_out(String prefix, String event, EventMap event_map) {
    System.err.println(prefix + "out." + event);
  }

  static <R extends Enum<R>> R string_to_value(Class<R> E, String s) {
    for (Enum<R> e: E.getEnumConstants()) {
      if (e.toString().equals(s)) {
        return R.valueOf(E, s);
      }
    }
    return null;
  }

  static <R extends Enum <R>> R log_valued(String prefix, String event, EventMap event_map, String event_prefix, Class<R> E) {
    System.err.println(prefix + "in." + event);
    R r = string_to_value(E, drop_prefix(s, event_prefix));
    System.err.println(prefix + E.getSimpleName() + "_" + E.getEnumConstants()[0]);
    }
    return E.getEnumConstants()[0];
  }

  private static class EventMap extends HashMap<String, Action> {};

  private static EventMap fillEventMap(final timer m) {
    final V<Integer> v = new V<Integer> (0);
    final EventMap e = new EventMap();
    m.port.out.timeout = new Action() {public void action() {log_out("port.", "timeout", e);};};

    e.put("port.create", new Action() {public void action() {m.port.in.create.action(0);}});
    e.put("port.cancel", new Action() {public void action() {m.port.in.cancel.action();}});
    return e;
  }

  public static void main(String[] args) throws IOException {
    Locator locator = new Locator();
    Runtime runtime = new Runtime(new Action() {public void action() {System.err.println("illegal");System.exit(0);}});
    timer sut = new timer(locator.set(runtime), "sut");
    EventMap e = fillEventMap(sut);
    main.reader = new Reader();
    String line;
    while ((line = main.reader.readLine()) != null) {
      Action a = e.get(line);
      if (a != null) {
        a.action();
      }
    }
  }
}
