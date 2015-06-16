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
    System.err.println(prefix + event);
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
    String s = consume_synchronous_out_events(event_map);
    R r = string_to_value(E, drop_prefix(s, event_prefix));
    if (r != null) {
      System.err.println(prefix + r.getClass().getSimpleName() + "_" + E.getEnumConstants()[r.ordinal()]);
    }
    return r;
  }

  private static class EventMap extends HashMap<String, Action> {};

  private static EventMap fillEventMap(final #.model  m) {
  final V<Integer> v = new V<Integer> (0);
  final EventMap e = new EventMap();
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction .#event  = new #(action-type return-type formal-types)() {public #return-type  action(#formals) {#(string-if (eq? return-type 'void) #{log_#direction("#port .", "#event ", e);#}#{return log_valued("#port .", "#event ", e, "#port .#reply-name _", #(if (eq? reply-scope '*global*) 'DznGlobal reply-scope).#reply-name .class);#})};};
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))
#(map
    (lambda (port)
    (map (define-on model port #{
        e.put("#port .#event ", new Action() {public void action() {m.#port .#direction .#event .action(#((->join ", ") (map (lambda (p) (if (om:out-or-inout? p) 'v 0)) formal-objects)));}});
#}) (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model)) return e;
}

  public static void main(String[] args) throws IOException {
    Locator locator = new Locator();
    Runtime runtime = new Runtime(new Action() {public void action() {System.err.println("illegal");System.exit(0);}});
    #.model  sut = new #.model(locator.set(runtime), "sut");
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
