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
  static boolean relaxed = false;

  static Reader reader;

  static String drop_prefix(String string, String prefix) {
    if (string.startsWith(prefix)) {
      return string.substring(prefix.length());
    }
    return string;
  }

  static String consume_synchronous_out_events(String prefix, String event, EventMap event_map) {
    String s;
    String match = prefix + event;
    while ((s = main.reader.readLine()) != null)
      if (s.equals(match))
        break;
    while ((s = main.reader.readLine()) != null) {
      Action a = event_map.get(s);
      if (a == null) {
        break;
      }
      a.action();
    }
    return s;
  }

  static void log_in(String prefix, String event, EventMap event_map) {
    System.err.println(prefix + event);
    if (relaxed) return;
    consume_synchronous_out_events(prefix, event, event_map);
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
    String s = consume_synchronous_out_events(prefix, event, event_map);
    R r = string_to_value(E, drop_prefix(s, event_prefix));
    if (r != null) {
      System.err.println(prefix + r.getClass().getSimpleName() + "_" + E.getEnumConstants()[r.ordinal()]);
    }
    return r;
  }

  private static class EventMap extends HashMap<String, Action> {};

  private static EventMap fillEventMap(final #.scope_model  m) {
  final V<Integer> v = new V<Integer> (0);
  Component c = new Component(m.locator);
  final EventMap e = new EventMap();
  c.flushes = true;
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction .#event  = new #(action-type model (.type signature) (.formals signature))() {public #return-type  action(#formals) {#(string-if (eq? return-type 'void) #{log_#direction("#port .", "#event ", e);#}#{return log_valued("#port .", "#event ", e, "#port .#reply-name _", #(if (or (null? reply-scope) (om:outer-scope? model reply-scope)) 'DznGlobal reply-scope).#reply-name .class);#})};};
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))
#(map (init-port #{
    m.#name .in.self = c;
    m.#name .in.name = "<internal>";
    e.put("#name .<flush>", new Action(){public void action() {System.err.println("#name .<flush>"); m.runtime.flush (m.#name .in.self);}});
#}) (filter om:requires? (om:ports model)))
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
    #.scope_model  sut = new #.scope_model(locator.set(runtime), "sut");
    EventMap e = fillEventMap(sut);
    main.reader = new Reader();
    String s;
    while ((s = main.reader.readLine()) != null) {
      Action a = e.get(s);
      if (a != null) {
        a.action();
      }
    }
  }
}
