import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.HashMap;

class Reader {
  BufferedReader reader;
  String readLine() throws IOException {
    if (System.console() != null) {
      return System.console().readLine();
    }
    if (reader == null) {
      reader = new BufferedReader(new InputStreamReader(System.in));
    }
    return reader.readLine();
  }
}  

class main {

  private static class EventMap extends HashMap<String, Action> {};
                        
  private static EventMap fillEventMap(final #.model  m) {
  final V<Integer> v = new V<Integer> (0);
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction .#event  = new #(action-type return-type parameter-types)() {public #return-type  action(#parameters) {System.err.println("#port .#direction .#event");#(string-if (not (eq? return-type 'void)) #{ return (#return-type)null;#})}};
#}) (filter (negate (gom:dir-matches? port))
       (gom:events port)))) (gom:ports model))     EventMap e = new EventMap();
#(map
    (lambda (port)
    (map (define-on model port #{
        e.put("#port .#event ", new Action() {public void action() {m.#port .#direction .#event .action(#((->join ", ") (map (lambda (p) (if (gom:out-or-inout? p) 'v 0)) parameter-objects)));}});
#}) (filter (gom:dir-matches? port)
       (gom:events port)))) (gom:ports model)) return e;
}

  private static String readLine() throws IOException {
    if (System.console() != null) {
      return System.console().readLine();
    }
    BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
    return reader.readLine();
  }

  public static void main(String[] args) throws IOException {
    Runtime runtime = new Runtime();
    #.model  sut = new #.model(runtime, "sut");
    EventMap e = fillEventMap(sut);
    Reader reader = new Reader();
    String line;
    while ((line = reader.readLine()) != null) {
      Action a = e.get(line);
      if (a != null) {
        a.action();
      }
    }
  }
}
