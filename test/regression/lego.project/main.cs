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

using System;
using System.Collections.Generic;

class config {
  public static int get(String s) {
    return 0;
  }
}

public class Byte
{ 
  int i = 0; 

  public Byte(int i=0) {this.i = i;}
  public Byte(Integer i) {this.i = (int)i;}   
  public static implicit operator Byte(int i) {return new Byte(i);}
  public static implicit operator int(Byte integer) {return integer.i;} 
  public static int operator +(Byte a, Byte b) {return a.i + b.i;} 
  public static Byte operator +(int a, Byte b) {return new Byte(a + b);} 
  public static int operator -(Byte a, Byte b) {return a.i - b.i;} 
  public static Byte operator -(int a, Byte b) {return new Byte(a - b);} 
}

public class Integer
{ 
  int i = 0;
  public Integer(int i=0) {this.i = i;}
  public Integer(Byte i) {this.i = (int)i;}
  public static implicit operator Integer(int i) {return new Integer(i);}
  public static implicit operator int(Integer integer) {return integer.i;} 
  public static int operator +(Integer a, Integer b) {return a.i + b.i;} 
  public static Integer operator +(int a, Integer b) {return new Integer(a + b);} 
  public static int operator -(Integer a, Integer b) {return a.i - b.i;} 
  public static Integer operator -(int a, Integer b) {return new Integer(a - b);} 
}

class main {
  static bool relaxed = true;

  static String drop_prefix(String str, String prefix) {
    if (str.StartsWith(prefix)) {
      return str.Substring(prefix.Length);
    }
    return str;
  }

  static String consume_synchronous_out_events(EventMap event_map) {
    System.Console.ReadLine();
    String line;
    while ((line = System.Console.ReadLine()) != null) {
      if (!event_map.ContainsKey(line)) {
        break;
      }
      event_map[line]();
    }
    return line;
  }

  static void log_in(String prefix, String e, EventMap event_map) {
    System.Console.Error.WriteLine(prefix + e);
    if (relaxed) return;
    consume_synchronous_out_events(event_map);
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
    String s = consume_synchronous_out_events(event_map);
    R? r = string_to_value<R>(drop_prefix(s, event_prefix));
    if (r != null) {
      System.Console.Error.WriteLine(prefix + typeof(R).Name + "_" + r.ToString());
      return (R)r;
    }
    return default(R);
  }


  private class EventMap : Dictionary<String, Action> {};

  private static EventMap fillEventMap(LegoBallSorter m) {
    V<int> v = new V<int> (0);
    EventMap e = new EventMap();
    m.ctrl.outport.calibrated = () => {log_out("ctrl.", "calibrated", e);};
    m.ctrl.outport.finished = () => {log_out("ctrl.", "finished", e);};
    m.brick1_aA.inport.move = (Byte power, Integer position) => {log_in("brick1_aA.", "move", e);};
    m.brick1_aA.inport.run = (Byte power, Boolean invert) => {log_in("brick1_aA.", "run", e);};
    m.brick1_aA.inport.stop = () => {log_in("brick1_aA.", "stop", e);};
    m.brick1_aA.inport.coast = () => {log_in("brick1_aA.", "coast", e);};
    m.brick1_aA.inport.zero = () => {log_in("brick1_aA.", "zero", e);};
    m.brick1_aA.inport.position = (V<Integer> pos) => {log_in("brick1_aA.", "position", e);};
    m.brick1_aA.inport.at = (Integer pos) => {return log_valued<imotor.result_t>("brick1_aA.", "at", e, "brick1_aA.result_t_");};
    m.brick1_aB.inport.move = (Byte power, Integer position) => {log_in("brick1_aB.", "move", e);};
    m.brick1_aB.inport.run = (Byte power, Boolean invert) => {log_in("brick1_aB.", "run", e);};
    m.brick1_aB.inport.stop = () => {log_in("brick1_aB.", "stop", e);};
    m.brick1_aB.inport.coast = () => {log_in("brick1_aB.", "coast", e);};
    m.brick1_aB.inport.zero = () => {log_in("brick1_aB.", "zero", e);};
    m.brick1_aB.inport.position = (V<Integer> pos) => {log_in("brick1_aB.", "position", e);};
    m.brick1_aB.inport.at = (Integer pos) => {return log_valued<imotor.result_t>("brick1_aB.", "at", e, "brick1_aB.result_t_");};
    m.brick1_aC.inport.move = (Byte power, Integer position) => {log_in("brick1_aC.", "move", e);};
    m.brick1_aC.inport.run = (Byte power, Boolean invert) => {log_in("brick1_aC.", "run", e);};
    m.brick1_aC.inport.stop = () => {log_in("brick1_aC.", "stop", e);};
    m.brick1_aC.inport.coast = () => {log_in("brick1_aC.", "coast", e);};
    m.brick1_aC.inport.zero = () => {log_in("brick1_aC.", "zero", e);};
    m.brick1_aC.inport.position = (V<Integer> pos) => {log_in("brick1_aC.", "position", e);};
    m.brick1_aC.inport.at = (Integer pos) => {return log_valued<imotor.result_t>("brick1_aC.", "at", e, "brick1_aC.result_t_");};
    m.brick1_s1.inport.detect = () => {return log_valued<itouch.status>("brick1_s1.", "detect", e, "brick1_s1.status_");};
    m.brick1_s2.inport.detect = () => {return log_valued<itouch.status>("brick1_s2.", "detect", e, "brick1_s2.status_");};
    m.brick1_s3.inport.detect = () => {return log_valued<itouch.status>("brick1_s3.", "detect", e, "brick1_s3.status_");};
    m.brick1_s4.inport.detect = () => {return log_valued<itouch.status>("brick1_s4.", "detect", e, "brick1_s4.status_");};
    m.brick2_aA.inport.move = (Byte power, Integer position) => {log_in("brick2_aA.", "move", e);};
    m.brick2_aA.inport.run = (Byte power, Boolean invert) => {log_in("brick2_aA.", "run", e);};
    m.brick2_aA.inport.stop = () => {log_in("brick2_aA.", "stop", e);};
    m.brick2_aA.inport.coast = () => {log_in("brick2_aA.", "coast", e);};
    m.brick2_aA.inport.zero = () => {log_in("brick2_aA.", "zero", e);};
    m.brick2_aA.inport.position = (V<Integer> pos) => {log_in("brick2_aA.", "position", e);};
    m.brick2_aA.inport.at = (Integer pos) => {return log_valued<imotor.result_t>("brick2_aA.", "at", e, "brick2_aA.result_t_");};
    m.brick2_aB.inport.move = (Byte power, Integer position) => {log_in("brick2_aB.", "move", e);};
    m.brick2_aB.inport.run = (Byte power, Boolean invert) => {log_in("brick2_aB.", "run", e);};
    m.brick2_aB.inport.stop = () => {log_in("brick2_aB.", "stop", e);};
    m.brick2_aB.inport.coast = () => {log_in("brick2_aB.", "coast", e);};
    m.brick2_aB.inport.zero = () => {log_in("brick2_aB.", "zero", e);};
    m.brick2_aB.inport.position = (V<Integer> pos) => {log_in("brick2_aB.", "position", e);};
    m.brick2_aB.inport.at = (Integer pos) => {return log_valued<imotor.result_t>("brick2_aB.", "at", e, "brick2_aB.result_t_");};
    m.brick2_s2.inport.detect = () => {return log_valued<itouch.status>("brick2_s2.", "detect", e, "brick2_s2.status_");};
    m.brick2_s3.inport.detect = () => {return log_valued<itouch.status>("brick2_s3.", "detect", e, "brick2_s3.status_");};
    m.brick2_s4.inport.detect = () => {return log_valued<itouch.status>("brick2_s4.", "detect", e, "brick2_s4.status_");};
    m.brick3_aA.inport.move = (Byte power, Integer position) => {log_in("brick3_aA.", "move", e);};
    m.brick3_aA.inport.run = (Byte power, Boolean invert) => {log_in("brick3_aA.", "run", e);};
    m.brick3_aA.inport.stop = () => {log_in("brick3_aA.", "stop", e);};
    m.brick3_aA.inport.coast = () => {log_in("brick3_aA.", "coast", e);};
    m.brick3_aA.inport.zero = () => {log_in("brick3_aA.", "zero", e);};
    m.brick3_aA.inport.position = (V<Integer> pos) => {log_in("brick3_aA.", "position", e);};
    m.brick3_aA.inport.at = (Integer pos) => {return log_valued<imotor.result_t>("brick3_aA.", "at", e, "brick3_aA.result_t_");};
    m.brick3_aC.inport.move = (Byte power, Integer position) => {log_in("brick3_aC.", "move", e);};
    m.brick3_aC.inport.run = (Byte power, Boolean invert) => {log_in("brick3_aC.", "run", e);};
    m.brick3_aC.inport.stop = () => {log_in("brick3_aC.", "stop", e);};
    m.brick3_aC.inport.coast = () => {log_in("brick3_aC.", "coast", e);};
    m.brick3_aC.inport.zero = () => {log_in("brick3_aC.", "zero", e);};
    m.brick3_aC.inport.position = (V<Integer> pos) => {log_in("brick3_aC.", "position", e);};
    m.brick3_aC.inport.at = (Integer pos) => {return log_valued<imotor.result_t>("brick3_aC.", "at", e, "brick3_aC.result_t_");};
    m.brick3_s1.inport.turnon = () => {log_in("brick3_s1.", "turnon", e);};
    m.brick3_s1.inport.turnoff = () => {log_in("brick3_s1.", "turnoff", e);};
    m.brick3_s1.inport.detect = () => {return log_valued<ilight.status>("brick3_s1.", "detect", e, "brick3_s1.status_");};
    m.brick3_s2.inport.detect = () => {return log_valued<itouch.status>("brick3_s2.", "detect", e, "brick3_s2.status_");};
    m.brick3_s3.inport.detect = () => {return log_valued<itouch.status>("brick3_s3.", "detect", e, "brick3_s3.status_");};
    m.brick4_aA.inport.move = (Byte power, Integer position) => {log_in("brick4_aA.", "move", e);};
    m.brick4_aA.inport.run = (Byte power, Boolean invert) => {log_in("brick4_aA.", "run", e);};
    m.brick4_aA.inport.stop = () => {log_in("brick4_aA.", "stop", e);};
    m.brick4_aA.inport.coast = () => {log_in("brick4_aA.", "coast", e);};
    m.brick4_aA.inport.zero = () => {log_in("brick4_aA.", "zero", e);};
    m.brick4_aA.inport.position = (V<Integer> pos) => {log_in("brick4_aA.", "position", e);};
    m.brick4_aA.inport.at = (Integer pos) => {return log_valued<imotor.result_t>("brick4_aA.", "at", e, "brick4_aA.result_t_");};
    m.brick4_aB.inport.move = (Byte power, Integer position) => {log_in("brick4_aB.", "move", e);};
    m.brick4_aB.inport.run = (Byte power, Boolean invert) => {log_in("brick4_aB.", "run", e);};
    m.brick4_aB.inport.stop = () => {log_in("brick4_aB.", "stop", e);};
    m.brick4_aB.inport.coast = () => {log_in("brick4_aB.", "coast", e);};
    m.brick4_aB.inport.zero = () => {log_in("brick4_aB.", "zero", e);};
    m.brick4_aB.inport.position = (V<Integer> pos) => {log_in("brick4_aB.", "position", e);};
    m.brick4_aB.inport.at = (Integer pos) => {return log_valued<imotor.result_t>("brick4_aB.", "at", e, "brick4_aB.result_t_");};
    m.brick4_aC.inport.move = (Byte power, Integer position) => {log_in("brick4_aC.", "move", e);};
    m.brick4_aC.inport.run = (Byte power, Boolean invert) => {log_in("brick4_aC.", "run", e);};
    m.brick4_aC.inport.stop = () => {log_in("brick4_aC.", "stop", e);};
    m.brick4_aC.inport.coast = () => {log_in("brick4_aC.", "coast", e);};
    m.brick4_aC.inport.zero = () => {log_in("brick4_aC.", "zero", e);};
    m.brick4_aC.inport.position = (V<Integer> pos) => {log_in("brick4_aC.", "position", e);};
    m.brick4_aC.inport.at = (Integer pos) => {return log_valued<imotor.result_t>("brick4_aC.", "at", e, "brick4_aC.result_t_");};
    m.brick4_s1.inport.detect = () => {return log_valued<itouch.status>("brick4_s1.", "detect", e, "brick4_s1.status_");};
    m.brick4_s2.inport.detect = () => {return log_valued<itouch.status>("brick4_s2.", "detect", e, "brick4_s2.status_");};
    m.brick4_s3.inport.detect = () => {return log_valued<itouch.status>("brick4_s3.", "detect", e, "brick4_s3.status_");};

    e.Add("ctrl.calibrate", () => {m.ctrl.inport.calibrate();});
    e.Add("ctrl.stop", () => {m.ctrl.inport.stop();});
    e.Add("ctrl.operate", () => {m.ctrl.inport.operate();});
    return e;
  }

  public static void Main(String[] args) {
    Locator locator = new Locator();
    Runtime runtime = new Runtime(() => {System.Console.Error.WriteLine("illegal"); Environment.Exit(0);});
    LegoBallSorter sut = new LegoBallSorter(locator.set(runtime), "sut");
    EventMap e = fillEventMap(sut);
    String line;
    while ((line = System.Console.ReadLine()) != null) {
      if (e.ContainsKey(line)) {
        e[line]();
      }
    }
  }
}
