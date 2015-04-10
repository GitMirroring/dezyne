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
                        
  private static EventMap fillEventMap(#.model  m) {
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction .#event  = new Action() {public void action() {System.err.println("#port .#direction .#event");}};
#}) (filter (negate (gom:dir-matches? port))
       (gom:events port)))) (gom:ports model))     EventMap e = new EventMap();
#(map
    (lambda (port)
    (map (define-on model port #{
        e.put("#port .#event ", m.#port .#direction .#event);
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
