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

  static void log_in(String prefix, String event) {
    System.err.println(prefix + event);
    System.err.println(prefix + "return");
  }

  static void log_out(String prefix, String event) {
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

  static <R extends Enum<R>> R get_value(Class<R> E, String prefix) {
    String s;
    while ((s = main.reader.readLine()) != null) {
      R r = string_to_value(E, drop_prefix(s, prefix));
      if (r != null) {
        return r;
      }
    }
    System.exit(0);
    return null;
  }

  static <R extends Enum <R>> R log_valued(String prefix, String event, Class<R> E, String event_prefix) {
    System.err.println(prefix + event);
    R r = get_value(E, event_prefix);
    if (r != null) {
      System.err.println(prefix + r.getClass().getSimpleName() + "_" + E.getEnumConstants()[r.ordinal()]);
    }
    return r;
  }

  private static class EventMap extends HashMap<String, Action> {};
                        
  private static EventMap fillEventMap(final #.model  m) {
  final V<Integer> v = new V<Integer> (0);
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction .#event  = new #(action-type return-type parameter-types)() {public #return-type  action(#parameters) {#(string-if (eq? return-type 'void) #{log_#direction("#port .#direction .", "#event ");#}#{return log_valued("#port .#direction .", "#event ", #reply-type .#reply-name .class, "#port .#reply-name _");#})};};
#}) (filter (negate (gom:dir-matches? port))
       (gom:events port)))) (gom:ports model))     EventMap e = new EventMap();
#(map
    (lambda (port)
    (map (define-on model port #{
        e.put("#port .#event ", new Action() {public void action() {m.#port .#direction .#event .action(#((->join ", ") (map (lambda (p) (if (gom:out-or-inout? p) 'v 0)) parameter-objects)));}});
#}) (filter (gom:dir-matches? port)
       (gom:events port)))) (gom:ports model)) return e;
}

  public static void main(String[] args) throws IOException {
    Runtime runtime = new Runtime(new Action() {public void action() {System.err.println("illegal");System.exit(0);}});
    #.model  sut = new #.model(runtime, "sut");
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
