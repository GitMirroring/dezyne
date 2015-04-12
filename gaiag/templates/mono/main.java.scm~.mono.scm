;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
