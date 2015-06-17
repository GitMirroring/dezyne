// Dezyne --- Dezyne command line tools
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

#include "MachineConstants.hh"

#include "runtime.hh"
#include "locator.hh"

#include "LegoBallSorter.hh"

#include <iostream>

#include "itimer_impl.hh"
#include "timer.hh"

#include <gtkmm.h>

struct Lego
{
  void update() {}
};

struct timer_impl: public itimer_impl
{
  sigc::connection connection;
  dezyne::itimer& port;
  Lego& lego;

  timer_impl(const dezyne::locator& l)
  : port(l.get<dezyne::itimer>())
  , lego(l.get<Lego>())
  {}
  bool stupid_member(){lego.update(); port.out.timeout(); return false;}
  void create(int ms)
  {
    connection = Glib::signal_timeout().connect(sigc::mem_fun(this, &timer_impl::stupid_member), ms);
  }
  void cancel()
  {
    connection.disconnect();
  }
};

namespace dezyne
{
  bool relaxed = true;
  typedef std::map<std::string, std::function<void()>> event_map;

  std::string consume_synchronous_out_events(event_map& event_map)
  {
    std::string s;
    std::cin >> s;
    while (std::cin >> s)
    {
      if (event_map.find(s) == event_map.end()) break;
      event_map[s]();
    }
    return s;
  }

  void log_in(std::string prefix, std::string event, event_map& event_map)
  {
    std::clog << prefix << event << std::endl;
    if (relaxed) return;
    consume_synchronous_out_events(event_map);
    std::clog << prefix << "return" << std::endl;
  }

  void log_out(std::string prefix, std::string event, event_map& event_map)
  {
    std::clog << prefix << event << std::endl;
  }

  template <typename R>
  R log_valued(std::string prefix, std::string event, event_map& event_map, R (*string_to_value)(std::string), const char* (*value_to_string)(R))
  {
    std::clog << prefix << event << std::endl;
    if (relaxed) return (R)0;
    std::string s = consume_synchronous_out_events(event_map);

    R r = string_to_value(s.erase(std::min(s.size(), s.find(prefix)), prefix.size()));
    if (static_cast<int>(r) != -1)
    {
      std::clog << prefix << value_to_string(r) << std::endl;
      return r;
    }
    throw std::runtime_error("\"" + s + "\" is not a reply value");  
  }

  void fill_event_map(LegoBallSorter& m, event_map& e)
  {
    int dzn_i = 0;

    m.ctrl.out.calibrated = [&] () {log_out("ctrl.", "calibrated", e);};
    m.ctrl.out.finished = [&] () {log_out("ctrl.", "finished", e);};
    m.brick1_aA.in.move = [&] (Byte power, Integer position) {log_in("brick1_aA.", "move", e);};
    m.brick1_aA.in.run = [&] (Byte power, Boolean invert) {log_in("brick1_aA.", "run", e);};
    m.brick1_aA.in.stop = [&] () {log_in("brick1_aA.", "stop", e);};
    m.brick1_aA.in.coast = [&] () {log_in("brick1_aA.", "coast", e);};
    m.brick1_aA.in.zero = [&] () {log_in("brick1_aA.", "zero", e);};
    m.brick1_aA.in.position = [&] (Integer& pos) {log_in("brick1_aA.", "position", e);};
    m.brick1_aA.in.at = [&] (Integer pos) {return log_valued<imotor::result_t::type>("brick1_aA.", "at", e, to_imotor_result_t, static_cast<const char*(*)(imotor::result_t::type)>(to_string));};
    m.brick1_aB.in.move = [&] (Byte power, Integer position) {log_in("brick1_aB.", "move", e);};
    m.brick1_aB.in.run = [&] (Byte power, Boolean invert) {log_in("brick1_aB.", "run", e);};
    m.brick1_aB.in.stop = [&] () {log_in("brick1_aB.", "stop", e);};
    m.brick1_aB.in.coast = [&] () {log_in("brick1_aB.", "coast", e);};
    m.brick1_aB.in.zero = [&] () {log_in("brick1_aB.", "zero", e);};
    m.brick1_aB.in.position = [&] (Integer& pos) {log_in("brick1_aB.", "position", e);};
    m.brick1_aB.in.at = [&] (Integer pos) {return log_valued<imotor::result_t::type>("brick1_aB.", "at", e, to_imotor_result_t, static_cast<const char*(*)(imotor::result_t::type)>(to_string));};
    m.brick1_aC.in.move = [&] (Byte power, Integer position) {log_in("brick1_aC.", "move", e);};
    m.brick1_aC.in.run = [&] (Byte power, Boolean invert) {log_in("brick1_aC.", "run", e);};
    m.brick1_aC.in.stop = [&] () {log_in("brick1_aC.", "stop", e);};
    m.brick1_aC.in.coast = [&] () {log_in("brick1_aC.", "coast", e);};
    m.brick1_aC.in.zero = [&] () {log_in("brick1_aC.", "zero", e);};
    m.brick1_aC.in.position = [&] (Integer& pos) {log_in("brick1_aC.", "position", e);};
    m.brick1_aC.in.at = [&] (Integer pos) {return log_valued<imotor::result_t::type>("brick1_aC.", "at", e, to_imotor_result_t, static_cast<const char*(*)(imotor::result_t::type)>(to_string));};
    m.brick1_s1.in.detect = [&] () {return log_valued<itouch::status::type>("brick1_s1.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};
    m.brick1_s2.in.detect = [&] () {return log_valued<itouch::status::type>("brick1_s2.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};
    m.brick1_s3.in.detect = [&] () {return log_valued<itouch::status::type>("brick1_s3.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};
    m.brick1_s4.in.detect = [&] () {return log_valued<itouch::status::type>("brick1_s4.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};
    m.brick2_aA.in.move = [&] (Byte power, Integer position) {log_in("brick2_aA.", "move", e);};
    m.brick2_aA.in.run = [&] (Byte power, Boolean invert) {log_in("brick2_aA.", "run", e);};
    m.brick2_aA.in.stop = [&] () {log_in("brick2_aA.", "stop", e);};
    m.brick2_aA.in.coast = [&] () {log_in("brick2_aA.", "coast", e);};
    m.brick2_aA.in.zero = [&] () {log_in("brick2_aA.", "zero", e);};
    m.brick2_aA.in.position = [&] (Integer& pos) {log_in("brick2_aA.", "position", e);};
    m.brick2_aA.in.at = [&] (Integer pos) {return log_valued<imotor::result_t::type>("brick2_aA.", "at", e, to_imotor_result_t, static_cast<const char*(*)(imotor::result_t::type)>(to_string));};
    m.brick2_aB.in.move = [&] (Byte power, Integer position) {log_in("brick2_aB.", "move", e);};
    m.brick2_aB.in.run = [&] (Byte power, Boolean invert) {log_in("brick2_aB.", "run", e);};
    m.brick2_aB.in.stop = [&] () {log_in("brick2_aB.", "stop", e);};
    m.brick2_aB.in.coast = [&] () {log_in("brick2_aB.", "coast", e);};
    m.brick2_aB.in.zero = [&] () {log_in("brick2_aB.", "zero", e);};
    m.brick2_aB.in.position = [&] (Integer& pos) {log_in("brick2_aB.", "position", e);};
    m.brick2_aB.in.at = [&] (Integer pos) {return log_valued<imotor::result_t::type>("brick2_aB.", "at", e, to_imotor_result_t, static_cast<const char*(*)(imotor::result_t::type)>(to_string));};
    m.brick2_s2.in.detect = [&] () {return log_valued<itouch::status::type>("brick2_s2.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};
    m.brick2_s3.in.detect = [&] () {return log_valued<itouch::status::type>("brick2_s3.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};
    m.brick2_s4.in.detect = [&] () {return log_valued<itouch::status::type>("brick2_s4.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};
    m.brick3_aA.in.move = [&] (Byte power, Integer position) {log_in("brick3_aA.", "move", e);};
    m.brick3_aA.in.run = [&] (Byte power, Boolean invert) {log_in("brick3_aA.", "run", e);};
    m.brick3_aA.in.stop = [&] () {log_in("brick3_aA.", "stop", e);};
    m.brick3_aA.in.coast = [&] () {log_in("brick3_aA.", "coast", e);};
    m.brick3_aA.in.zero = [&] () {log_in("brick3_aA.", "zero", e);};
    m.brick3_aA.in.position = [&] (Integer& pos) {log_in("brick3_aA.", "position", e);};
    m.brick3_aA.in.at = [&] (Integer pos) {return log_valued<imotor::result_t::type>("brick3_aA.", "at", e, to_imotor_result_t, static_cast<const char*(*)(imotor::result_t::type)>(to_string));};
    m.brick3_aC.in.move = [&] (Byte power, Integer position) {log_in("brick3_aC.", "move", e);};
    m.brick3_aC.in.run = [&] (Byte power, Boolean invert) {log_in("brick3_aC.", "run", e);};
    m.brick3_aC.in.stop = [&] () {log_in("brick3_aC.", "stop", e);};
    m.brick3_aC.in.coast = [&] () {log_in("brick3_aC.", "coast", e);};
    m.brick3_aC.in.zero = [&] () {log_in("brick3_aC.", "zero", e);};
    m.brick3_aC.in.position = [&] (Integer& pos) {log_in("brick3_aC.", "position", e);};
    m.brick3_aC.in.at = [&] (Integer pos) {return log_valued<imotor::result_t::type>("brick3_aC.", "at", e, to_imotor_result_t, static_cast<const char*(*)(imotor::result_t::type)>(to_string));};
    m.brick3_s1.in.turnon = [&] () {log_in("brick3_s1.", "turnon", e);};
    m.brick3_s1.in.turnoff = [&] () {log_in("brick3_s1.", "turnoff", e);};
    m.brick3_s1.in.detect = [&] () {return log_valued<ilight::status::type>("brick3_s1.", "detect", e, to_ilight_status, static_cast<const char*(*)(ilight::status::type)>(to_string));};
    m.brick3_s2.in.detect = [&] () {return log_valued<itouch::status::type>("brick3_s2.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};
    m.brick3_s3.in.detect = [&] () {return log_valued<itouch::status::type>("brick3_s3.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};
    m.brick4_aA.in.move = [&] (Byte power, Integer position) {log_in("brick4_aA.", "move", e);};
    m.brick4_aA.in.run = [&] (Byte power, Boolean invert) {log_in("brick4_aA.", "run", e);};
    m.brick4_aA.in.stop = [&] () {log_in("brick4_aA.", "stop", e);};
    m.brick4_aA.in.coast = [&] () {log_in("brick4_aA.", "coast", e);};
    m.brick4_aA.in.zero = [&] () {log_in("brick4_aA.", "zero", e);};
    m.brick4_aA.in.position = [&] (Integer& pos) {log_in("brick4_aA.", "position", e);};
    m.brick4_aA.in.at = [&] (Integer pos) {return log_valued<imotor::result_t::type>("brick4_aA.", "at", e, to_imotor_result_t, static_cast<const char*(*)(imotor::result_t::type)>(to_string));};
    m.brick4_aB.in.move = [&] (Byte power, Integer position) {log_in("brick4_aB.", "move", e);};
    m.brick4_aB.in.run = [&] (Byte power, Boolean invert) {log_in("brick4_aB.", "run", e);};
    m.brick4_aB.in.stop = [&] () {log_in("brick4_aB.", "stop", e);};
    m.brick4_aB.in.coast = [&] () {log_in("brick4_aB.", "coast", e);};
    m.brick4_aB.in.zero = [&] () {log_in("brick4_aB.", "zero", e);};
    m.brick4_aB.in.position = [&] (Integer& pos) {log_in("brick4_aB.", "position", e);};
    m.brick4_aB.in.at = [&] (Integer pos) {return log_valued<imotor::result_t::type>("brick4_aB.", "at", e, to_imotor_result_t, static_cast<const char*(*)(imotor::result_t::type)>(to_string));};
    m.brick4_aC.in.move = [&] (Byte power, Integer position) {log_in("brick4_aC.", "move", e);};
    m.brick4_aC.in.run = [&] (Byte power, Boolean invert) {log_in("brick4_aC.", "run", e);};
    m.brick4_aC.in.stop = [&] () {log_in("brick4_aC.", "stop", e);};
    m.brick4_aC.in.coast = [&] () {log_in("brick4_aC.", "coast", e);};
    m.brick4_aC.in.zero = [&] () {log_in("brick4_aC.", "zero", e);};
    m.brick4_aC.in.position = [&] (Integer& pos) {log_in("brick4_aC.", "position", e);};
    m.brick4_aC.in.at = [&] (Integer pos) {return log_valued<imotor::result_t::type>("brick4_aC.", "at", e, to_imotor_result_t, static_cast<const char*(*)(imotor::result_t::type)>(to_string));};
    m.brick4_s1.in.detect = [&] () {return log_valued<itouch::status::type>("brick4_s1.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};
    m.brick4_s2.in.detect = [&] () {return log_valued<itouch::status::type>("brick4_s2.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};
    m.brick4_s3.in.detect = [&] () {return log_valued<itouch::status::type>("brick4_s3.", "detect", e, to_itouch_status, static_cast<const char*(*)(itouch::status::type)>(to_string));};

    e["ctrl.calibrate"] = m.ctrl.in.calibrate; 
    e["ctrl.stop"] = m.ctrl.in.stop; 
    e["ctrl.operate"] = m.ctrl.in.operate; 
  }
}

int main()
{
  dezyne::locator l;
  dezyne::runtime rt;
  l.set(rt);
  dezyne::illegal_handler ih;
  ih.illegal = [] {std::clog << "illegal" << std::endl; exit(0);};
  l.set(ih);

  Lego lego;
  l.set(lego);

  std::function<std::shared_ptr<itimer_impl>(const dezyne::locator&)> create_timer_impl = [](const dezyne::locator& l){return std::make_shared<timer_impl>(l);};
  l.set(create_timer_impl);

  dezyne::event_map event_map;
  dezyne::LegoBallSorter sut(l);
  sut.dzn_meta.name = "sut";

  dezyne::fill_event_map(sut, event_map);

  sut.check_bindings();
  sut.dump_tree();

  std::string event;
  while(std::cin >> event) {
    if (event_map.find(event) != event_map.end()) {
      event_map[event]();
    }
  }
}
