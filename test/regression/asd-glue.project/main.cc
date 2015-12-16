// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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


#include "runtime.hh"
#include "locator.hh"

#include "AlarmSystemComp.hh"

#include <iostream>

namespace dezyne
{
  static bool flush = false;
  static bool relaxed = false;
  typedef std::map<std::string, std::function<void()>> event_map;

  bool prefix_p(std::string s, std::string prefix) {
    return std::equal(prefix.begin(), prefix.end(), s.begin());
  }

  void match_event(std::string match, int line=__LINE__)
  {
    std::string s;
    std::cin >> s;
    if (s==match) return;
    throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(line) + ": invalid event; expected: `" + match + "', found: `" + s + "'");
  }

  std::string get_return(std::string prefix, std::string event, event_map& event_map, bool value=false)
  {
    std::string s;
    std::string match = prefix + event;
    while(std::cin >> s) {
      if (s == match
      || (value
      && event_map.find(s) == event_map.end()
      && prefix_p(s, prefix)))
      return s;
      if (event_map.find(s) == event_map.end()
      && !relaxed)
      throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": no such event: `" + s + "'");
      if (!prefix_p(s, prefix))
      throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": wrong port; found: `" + s + ", expected: " + prefix);
      event_map[s]();
    }
    throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": invalid event; expected: `" + match + "', found: `" + s + "'");
  }

  void call_in(std::string prefix, std::string event, event_map& event_map)
  {
    std::clog << prefix << event << std::endl;
    if (relaxed) return;
    match_event(prefix + event, __LINE__);
    get_return(prefix, "return", event_map);
    std::clog << prefix << "return" << std::endl;
  }

  template <typename R>
  R call_valued(std::string prefix, std::string event, event_map& event_map, R (*string_to_value)(std::string), const char* (*value_to_string)(R))
  {
    std::clog << prefix << event << std::endl;
    if (relaxed) return (R)0;
    match_event(prefix + event, __LINE__);
    std::string s = get_return(prefix, "", event_map, true);
    R r = string_to_value(s.erase(std::min(s.size(), s.find(prefix)), prefix.size()));
    if (static_cast<int>(r) != -1)
    {
      std::clog << prefix << value_to_string(r) << std::endl;
      return r;
    }
    throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": not a reply value: `" + s + "', expected: `" + prefix + "*'");
  }

  void call_out(std::string prefix, std::string event, event_map& event_map)
  {
    std::clog << prefix << event << std::endl;
    if (relaxed) return;
    match_event(prefix + event, __LINE__);
  }

  struct component
  {
    meta dzn_meta;
    runtime& dzn_rt;
    component(runtime& rt) : dzn_rt(rt)
    {
      rt.performs_flush(this) = flush;
    }
  };

  void fill_event_map(component* c, AlarmSystemComp& m, event_map& e)
  {
    static int dzn_i = 0;
    (void)dzn_i;

    m.console.out.Tripped = [&] () {call_out("console.", "Tripped", e);};
    m.console.out.SwitchedOff = [&] () {call_out("console.", "SwitchedOff", e);};
    m.sensor.in.Activate = [&] () {call_in("sensor.", "Activate", e);};
    m.sensor.in.Deactivate = [&] () {call_in("sensor.", "Deactivate", e);};
    m.siren.in.TurnOn = [&] () {call_in("siren.", "TurnOn", e);};
    m.siren.in.TurnOff = [&] () {call_in("siren.", "TurnOff", e);};


#if 0
    // actions
    e["console.Tripped"] = nullptr;
    e["console.SwitchedOff"] = nullptr;
    e["sensor.Activate"] = nullptr;
    e["sensor.Deactivate"] = nullptr;
    e["siren.TurnOn"] = nullptr;
    e["siren.TurnOff"] = nullptr;

    e["console.return"] = nullptr;
    e["sensor.return"] = nullptr;
    e["siren.return"] = nullptr;

#endif

    if (flush) {
      m.sensor.meta.provides.address = c;
      m.sensor.meta.provides.meta = &c->dzn_meta;
    }
    e["sensor.<flush>"] = [&] { std::clog << "sensor.<flush>" << std::endl; m.dzn_rt.flush(m.sensor.meta.provides.address); };
    if (flush) {
      m.siren.meta.provides.address = c;
      m.siren.meta.provides.meta = &c->dzn_meta;
    }
    e["siren.<flush>"] = [&] { std::clog << "siren.<flush>" << std::endl; m.dzn_rt.flush(m.siren.meta.provides.address); };

    e["console.SwitchOn"] = m.console.in.SwitchOn;

    e["console.SwitchOff"] = m.console.in.SwitchOff;


    e["sensor.DetectedMovement"] = m.sensor.out.DetectedMovement;
    e["sensor.Deactivated"] = m.sensor.out.Deactivated;

    m.console.meta.provides.port = "console";
    m.console.meta.requires.port = "console";
    m.sensor.meta.provides.port = "sensor";
    m.sensor.meta.requires.port = "sensor";
    m.siren.meta.provides.port = "siren";
    m.siren.meta.requires.port = "siren";
  }
}

int main(int argc, char const* argv[])
{
  dezyne::flush = argc > 1 && argv[1] == std::string("--flush");
  dezyne::relaxed = argc > 1 && argv[1] == std::string("--relaxed");

#if BLOCKING
  bool main_p = true;
  std::mutex mutex;
#endif //BLOCKING

  dezyne::locator l;
  dezyne::runtime rt;
  l.set(rt);
  std::unique_ptr<dezyne::pump> tmp1(new dezyne::pump);
  l.set(*tmp1);
  dezyne::illegal_handler ih;
  ih.illegal = [] {std::clog << "illegal" << std::endl; exit(0);};
  l.set(ih);

  dezyne::event_map event_map;
  AlarmSystemComp sut(l);
  sut.dzn_meta.name = "sut";

  dezyne::component c(rt);
  c.dzn_meta.parent = 0;
  c.dzn_meta.name = "<internal>";

  dezyne::fill_event_map(&c, sut, event_map);

#if BLOCKING
  std::unique_ptr<dezyne::pump> tmp2(std::move(tmp1)); //now the pump is destroyed before the sut is
  dezyne::pump& pump = *tmp2;

  pump.next_event = [&] {
    pump([&]{
      std::unique_lock<std::mutex> lock(mutex);
      std::string s;
      while(!main_p && std::cin >> s && event_map.find(s) != event_map.end())
      {
        lock.unlock();
        event_map[s]();
        lock.lock();
      }
    });
  };
#endif

  sut.check_bindings();
  sut.dump_tree();

  std::string s;
  while(std::cin >> s) {
    if (event_map.find(s) == event_map.end()
    && !dezyne::relaxed)
    //throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": no such event: `" + s + "'");
    continue; // valued/vs return thinko
#if BLOCKING
    std::unique_lock<std::mutex> lock(mutex);
    main_p = false;
    lock.unlock();
    pump.and_wait(event_map[s]);
    lock.lock();
    main_p = true;
#else //!BLOCKING
    event_map[s]();
#endif //!BLOCKING
  }
}
