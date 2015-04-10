import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.HashMap;

class main {

  private static class EventMap extends HashMap<String, Action> {};
                        
  private static EventMap fillEventMap(#.model  m) {
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .get#(symbol-capitalize direction)().#event  = new Action() {public void action() {System.err.println("#port .#direction .#event");}};
#}) (filter (negate (gom:dir-matches? port))
       (gom:events port)))) (gom:ports model))     EventMap e = new EventMap();
#(map
    (lambda (port)
    (map (define-on model port #{
        e.put("#port .#event ", m.#port .get#(symbol-capitalize direction)().#event);
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
    #.model  sut = new #.model ();
    System.out.println("run");
    EventMap e = fillEventMap(sut);
    String line;
    while ((line = readLine()) != null) {
      System.out.println("line:" + line);
      Action a = e.get(line);
      if (a != null) {
         System.out.println("action!:" + line);
         a.action();
      }
    }
  }
}
