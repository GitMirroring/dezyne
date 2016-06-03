// Dezyne --- Dezyne command line tools
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

// figure this out: byte cannot be converted to int
class config<R> {
  public static <R> R get(String s) {
    return null;
  }
}

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
  static boolean relaxed = true;

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
    System.err.println(prefix + event);
    if (relaxed) return;
    consume_synchronous_out_events(event_map);
    System.err.println(prefix + "return");
  }

  static void log_out(String prefix, String event, EventMap event_map) {
    System.err.println(prefix + event);
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
    System.err.println(prefix + event);
    if (relaxed) return E.getEnumConstants()[0];
    String s = consume_synchronous_out_events(event_map);
    R r = string_to_value(E, drop_prefix(s, event_prefix));
    if (r != null) {
      System.err.println(prefix + r.getClass().getSimpleName() + "_" + E.getEnumConstants()[r.ordinal()]);
    }
    return r;
  }

  private static class EventMap extends HashMap<String, Action> {};

  private static EventMap fillEventMap(final LegoBallSorter m) {
    final V<Integer> v = new V<Integer> (0);
    final EventMap e = new EventMap();
    m.ctrl.out.calibrated = new Action() {public void action() {log_out("ctrl.", "calibrated", e);};};
    m.ctrl.out.finished = new Action() {public void action() {log_out("ctrl.", "finished", e);};};
    m.brick1_aA.in.move = new Action2<Byte, Integer>() {public void action(final Byte power, final Integer position) {log_in("brick1_aA.", "move", e);};};
    m.brick1_aA.in.run = new Action2<Byte, Boolean>() {public void action(final Byte power, final Boolean invert) {log_in("brick1_aA.", "run", e);};};
    m.brick1_aA.in.stop = new Action() {public void action() {log_in("brick1_aA.", "stop", e);};};
    m.brick1_aA.in.coast = new Action() {public void action() {log_in("brick1_aA.", "coast", e);};};
    m.brick1_aA.in.zero = new Action() {public void action() {log_in("brick1_aA.", "zero", e);};};
    m.brick1_aA.in.position = new Action1<V<Integer>>() {public void action(final V<Integer> pos) {log_in("brick1_aA.", "position", e);};};
    m.brick1_aA.in.at = new ValuedAction1<imotor.result_t, Integer>() {public imotor.result_t action(final Integer pos) {return log_valued("brick1_aA.", "at", e, "brick1_aA.result_t_", imotor.result_t.class);};};
    m.brick1_aB.in.move = new Action2<Byte, Integer>() {public void action(final Byte power, final Integer position) {log_in("brick1_aB.", "move", e);};};
    m.brick1_aB.in.run = new Action2<Byte, Boolean>() {public void action(final Byte power, final Boolean invert) {log_in("brick1_aB.", "run", e);};};
    m.brick1_aB.in.stop = new Action() {public void action() {log_in("brick1_aB.", "stop", e);};};
    m.brick1_aB.in.coast = new Action() {public void action() {log_in("brick1_aB.", "coast", e);};};
    m.brick1_aB.in.zero = new Action() {public void action() {log_in("brick1_aB.", "zero", e);};};
    m.brick1_aB.in.position = new Action1<V<Integer>>() {public void action(final V<Integer> pos) {log_in("brick1_aB.", "position", e);};};
    m.brick1_aB.in.at = new ValuedAction1<imotor.result_t, Integer>() {public imotor.result_t action(final Integer pos) {return log_valued("brick1_aB.", "at", e, "brick1_aB.result_t_", imotor.result_t.class);};};
    m.brick1_aC.in.move = new Action2<Byte, Integer>() {public void action(final Byte power, final Integer position) {log_in("brick1_aC.", "move", e);};};
    m.brick1_aC.in.run = new Action2<Byte, Boolean>() {public void action(final Byte power, final Boolean invert) {log_in("brick1_aC.", "run", e);};};
    m.brick1_aC.in.stop = new Action() {public void action() {log_in("brick1_aC.", "stop", e);};};
    m.brick1_aC.in.coast = new Action() {public void action() {log_in("brick1_aC.", "coast", e);};};
    m.brick1_aC.in.zero = new Action() {public void action() {log_in("brick1_aC.", "zero", e);};};
    m.brick1_aC.in.position = new Action1<V<Integer>>() {public void action(final V<Integer> pos) {log_in("brick1_aC.", "position", e);};};
    m.brick1_aC.in.at = new ValuedAction1<imotor.result_t, Integer>() {public imotor.result_t action(final Integer pos) {return log_valued("brick1_aC.", "at", e, "brick1_aC.result_t_", imotor.result_t.class);};};
    m.brick1_s1.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick1_s1.", "detect", e, "brick1_s1.status_", itouch.status.class);};};
    m.brick1_s2.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick1_s2.", "detect", e, "brick1_s2.status_", itouch.status.class);};};
    m.brick1_s3.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick1_s3.", "detect", e, "brick1_s3.status_", itouch.status.class);};};
    m.brick1_s4.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick1_s4.", "detect", e, "brick1_s4.status_", itouch.status.class);};};
    m.brick2_aA.in.move = new Action2<Byte, Integer>() {public void action(final Byte power, final Integer position) {log_in("brick2_aA.", "move", e);};};
    m.brick2_aA.in.run = new Action2<Byte, Boolean>() {public void action(final Byte power, final Boolean invert) {log_in("brick2_aA.", "run", e);};};
    m.brick2_aA.in.stop = new Action() {public void action() {log_in("brick2_aA.", "stop", e);};};
    m.brick2_aA.in.coast = new Action() {public void action() {log_in("brick2_aA.", "coast", e);};};
    m.brick2_aA.in.zero = new Action() {public void action() {log_in("brick2_aA.", "zero", e);};};
    m.brick2_aA.in.position = new Action1<V<Integer>>() {public void action(final V<Integer> pos) {log_in("brick2_aA.", "position", e);};};
    m.brick2_aA.in.at = new ValuedAction1<imotor.result_t, Integer>() {public imotor.result_t action(final Integer pos) {return log_valued("brick2_aA.", "at", e, "brick2_aA.result_t_", imotor.result_t.class);};};
    m.brick2_aB.in.move = new Action2<Byte, Integer>() {public void action(final Byte power, final Integer position) {log_in("brick2_aB.", "move", e);};};
    m.brick2_aB.in.run = new Action2<Byte, Boolean>() {public void action(final Byte power, final Boolean invert) {log_in("brick2_aB.", "run", e);};};
    m.brick2_aB.in.stop = new Action() {public void action() {log_in("brick2_aB.", "stop", e);};};
    m.brick2_aB.in.coast = new Action() {public void action() {log_in("brick2_aB.", "coast", e);};};
    m.brick2_aB.in.zero = new Action() {public void action() {log_in("brick2_aB.", "zero", e);};};
    m.brick2_aB.in.position = new Action1<V<Integer>>() {public void action(final V<Integer> pos) {log_in("brick2_aB.", "position", e);};};
    m.brick2_aB.in.at = new ValuedAction1<imotor.result_t, Integer>() {public imotor.result_t action(final Integer pos) {return log_valued("brick2_aB.", "at", e, "brick2_aB.result_t_", imotor.result_t.class);};};
    m.brick2_s2.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick2_s2.", "detect", e, "brick2_s2.status_", itouch.status.class);};};
    m.brick2_s3.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick2_s3.", "detect", e, "brick2_s3.status_", itouch.status.class);};};
    m.brick2_s4.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick2_s4.", "detect", e, "brick2_s4.status_", itouch.status.class);};};
    m.brick3_aA.in.move = new Action2<Byte, Integer>() {public void action(final Byte power, final Integer position) {log_in("brick3_aA.", "move", e);};};
    m.brick3_aA.in.run = new Action2<Byte, Boolean>() {public void action(final Byte power, final Boolean invert) {log_in("brick3_aA.", "run", e);};};
    m.brick3_aA.in.stop = new Action() {public void action() {log_in("brick3_aA.", "stop", e);};};
    m.brick3_aA.in.coast = new Action() {public void action() {log_in("brick3_aA.", "coast", e);};};
    m.brick3_aA.in.zero = new Action() {public void action() {log_in("brick3_aA.", "zero", e);};};
    m.brick3_aA.in.position = new Action1<V<Integer>>() {public void action(final V<Integer> pos) {log_in("brick3_aA.", "position", e);};};
    m.brick3_aA.in.at = new ValuedAction1<imotor.result_t, Integer>() {public imotor.result_t action(final Integer pos) {return log_valued("brick3_aA.", "at", e, "brick3_aA.result_t_", imotor.result_t.class);};};
    m.brick3_aC.in.move = new Action2<Byte, Integer>() {public void action(final Byte power, final Integer position) {log_in("brick3_aC.", "move", e);};};
    m.brick3_aC.in.run = new Action2<Byte, Boolean>() {public void action(final Byte power, final Boolean invert) {log_in("brick3_aC.", "run", e);};};
    m.brick3_aC.in.stop = new Action() {public void action() {log_in("brick3_aC.", "stop", e);};};
    m.brick3_aC.in.coast = new Action() {public void action() {log_in("brick3_aC.", "coast", e);};};
    m.brick3_aC.in.zero = new Action() {public void action() {log_in("brick3_aC.", "zero", e);};};
    m.brick3_aC.in.position = new Action1<V<Integer>>() {public void action(final V<Integer> pos) {log_in("brick3_aC.", "position", e);};};
    m.brick3_aC.in.at = new ValuedAction1<imotor.result_t, Integer>() {public imotor.result_t action(final Integer pos) {return log_valued("brick3_aC.", "at", e, "brick3_aC.result_t_", imotor.result_t.class);};};
    m.brick3_s1.in.turnon = new Action() {public void action() {log_in("brick3_s1.", "turnon", e);};};
    m.brick3_s1.in.turnoff = new Action() {public void action() {log_in("brick3_s1.", "turnoff", e);};};
    m.brick3_s1.in.detect = new ValuedAction<ilight.status>() {public ilight.status action() {return log_valued("brick3_s1.", "detect", e, "brick3_s1.status_", ilight.status.class);};};
    m.brick3_s2.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick3_s2.", "detect", e, "brick3_s2.status_", itouch.status.class);};};
    m.brick3_s3.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick3_s3.", "detect", e, "brick3_s3.status_", itouch.status.class);};};
    m.brick4_aA.in.move = new Action2<Byte, Integer>() {public void action(final Byte power, final Integer position) {log_in("brick4_aA.", "move", e);};};
    m.brick4_aA.in.run = new Action2<Byte, Boolean>() {public void action(final Byte power, final Boolean invert) {log_in("brick4_aA.", "run", e);};};
    m.brick4_aA.in.stop = new Action() {public void action() {log_in("brick4_aA.", "stop", e);};};
    m.brick4_aA.in.coast = new Action() {public void action() {log_in("brick4_aA.", "coast", e);};};
    m.brick4_aA.in.zero = new Action() {public void action() {log_in("brick4_aA.", "zero", e);};};
    m.brick4_aA.in.position = new Action1<V<Integer>>() {public void action(final V<Integer> pos) {log_in("brick4_aA.", "position", e);};};
    m.brick4_aA.in.at = new ValuedAction1<imotor.result_t, Integer>() {public imotor.result_t action(final Integer pos) {return log_valued("brick4_aA.", "at", e, "brick4_aA.result_t_", imotor.result_t.class);};};
    m.brick4_aB.in.move = new Action2<Byte, Integer>() {public void action(final Byte power, final Integer position) {log_in("brick4_aB.", "move", e);};};
    m.brick4_aB.in.run = new Action2<Byte, Boolean>() {public void action(final Byte power, final Boolean invert) {log_in("brick4_aB.", "run", e);};};
    m.brick4_aB.in.stop = new Action() {public void action() {log_in("brick4_aB.", "stop", e);};};
    m.brick4_aB.in.coast = new Action() {public void action() {log_in("brick4_aB.", "coast", e);};};
    m.brick4_aB.in.zero = new Action() {public void action() {log_in("brick4_aB.", "zero", e);};};
    m.brick4_aB.in.position = new Action1<V<Integer>>() {public void action(final V<Integer> pos) {log_in("brick4_aB.", "position", e);};};
    m.brick4_aB.in.at = new ValuedAction1<imotor.result_t, Integer>() {public imotor.result_t action(final Integer pos) {return log_valued("brick4_aB.", "at", e, "brick4_aB.result_t_", imotor.result_t.class);};};
    m.brick4_aC.in.move = new Action2<Byte, Integer>() {public void action(final Byte power, final Integer position) {log_in("brick4_aC.", "move", e);};};
    m.brick4_aC.in.run = new Action2<Byte, Boolean>() {public void action(final Byte power, final Boolean invert) {log_in("brick4_aC.", "run", e);};};
    m.brick4_aC.in.stop = new Action() {public void action() {log_in("brick4_aC.", "stop", e);};};
    m.brick4_aC.in.coast = new Action() {public void action() {log_in("brick4_aC.", "coast", e);};};
    m.brick4_aC.in.zero = new Action() {public void action() {log_in("brick4_aC.", "zero", e);};};
    m.brick4_aC.in.position = new Action1<V<Integer>>() {public void action(final V<Integer> pos) {log_in("brick4_aC.", "position", e);};};
    m.brick4_aC.in.at = new ValuedAction1<imotor.result_t, Integer>() {public imotor.result_t action(final Integer pos) {return log_valued("brick4_aC.", "at", e, "brick4_aC.result_t_", imotor.result_t.class);};};
    m.brick4_s1.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick4_s1.", "detect", e, "brick4_s1.status_", itouch.status.class);};};
    m.brick4_s2.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick4_s2.", "detect", e, "brick4_s2.status_", itouch.status.class);};};
    m.brick4_s3.in.detect = new ValuedAction<itouch.status>() {public itouch.status action() {return log_valued("brick4_s3.", "detect", e, "brick4_s3.status_", itouch.status.class);};};

    e.put("ctrl.calibrate", new Action() {public void action() {m.ctrl.in.calibrate.action();}});
    e.put("ctrl.stop", new Action() {public void action() {m.ctrl.in.stop.action();}});
    e.put("ctrl.operate", new Action() {public void action() {m.ctrl.in.operate.action();}});
    return e;
  }

  public static void main(String[] args) throws IOException {
    Locator locator = new Locator();
    Runtime runtime = new Runtime(new Action() {public void action() {System.err.println("illegal");System.exit(0);}});
    LegoBallSorter sut = new LegoBallSorter(locator.set(runtime), "sut");
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
