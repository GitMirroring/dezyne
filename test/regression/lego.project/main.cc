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

#include "imotor.hh"
#include "ilight.hh"
#include "itouch.hh"
#include "itimer_impl.hh"
#include "timer.hh"

#include "LegoBallSorter.hh"

#include "runtime.hh"
#include "locator.hh"

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
  typedef std::map<std::string, std::function<void()>> event_map;


  void fill_event_map(LegoBallSorter& m, event_map& e)
  {
    int dzn_i = 0;
    m.ctrl.out.calibrated = [] () {std::clog << "ctrl.out.calibrated" << std::endl;};
    m.ctrl.out.finished = [] () {std::clog << "ctrl.out.finished" << std::endl;};
    m.brick1_aA.in.move = [] (uint8_t power, int32_t position) {std::clog << "brick1_aA.in.move" << std::endl;};
    m.brick1_aA.in.run = [] (uint8_t power, bool invert) {std::clog << "brick1_aA.in.run" << std::endl;};
    m.brick1_aA.in.stop = [] () {std::clog << "brick1_aA.in.stop" << std::endl;};
    m.brick1_aA.in.coast = [] () {std::clog << "brick1_aA.in.coast" << std::endl;};
    m.brick1_aA.in.zero = [] () {std::clog << "brick1_aA.in.zero" << std::endl;};
    m.brick1_aA.in.position = [] (int32_t& pos) {std::clog << "brick1_aA.in.position" << std::endl;};
    m.brick1_aA.in.at = [] (int32_t pos) {std::clog << "brick1_aA.in.at" << std::endl;return (imotor::result_t::type)0;};
    m.brick1_aB.in.move = [] (uint8_t power, int32_t position) {std::clog << "brick1_aB.in.move" << std::endl;};
    m.brick1_aB.in.run = [] (uint8_t power, bool invert) {std::clog << "brick1_aB.in.run" << std::endl;};
    m.brick1_aB.in.stop = [] () {std::clog << "brick1_aB.in.stop" << std::endl;};
    m.brick1_aB.in.coast = [] () {std::clog << "brick1_aB.in.coast" << std::endl;};
    m.brick1_aB.in.zero = [] () {std::clog << "brick1_aB.in.zero" << std::endl;};
    m.brick1_aB.in.position = [] (int32_t& pos) {std::clog << "brick1_aB.in.position" << std::endl;};
    m.brick1_aB.in.at = [] (int32_t pos) {std::clog << "brick1_aB.in.at" << std::endl;return (imotor::result_t::type)0;};
    m.brick1_aC.in.move = [] (uint8_t power, int32_t position) {std::clog << "brick1_aC.in.move" << std::endl;};
    m.brick1_aC.in.run = [] (uint8_t power, bool invert) {std::clog << "brick1_aC.in.run" << std::endl;};
    m.brick1_aC.in.stop = [] () {std::clog << "brick1_aC.in.stop" << std::endl;};
    m.brick1_aC.in.coast = [] () {std::clog << "brick1_aC.in.coast" << std::endl;};
    m.brick1_aC.in.zero = [] () {std::clog << "brick1_aC.in.zero" << std::endl;};
    m.brick1_aC.in.position = [] (int32_t& pos) {std::clog << "brick1_aC.in.position" << std::endl;};
    m.brick1_aC.in.at = [] (int32_t pos) {std::clog << "brick1_aC.in.at" << std::endl;return (imotor::result_t::type)0;};
    m.brick1_s1.in.detect = [] () {std::clog << "brick1_s1.in.detect" << std::endl;return (itouch::status::type)0;};
    m.brick1_s2.in.detect = [] () {std::clog << "brick1_s2.in.detect" << std::endl;return (itouch::status::type)0;};
    m.brick1_s3.in.detect = [] () {std::clog << "brick1_s3.in.detect" << std::endl;return (itouch::status::type)0;};
    m.brick1_s4.in.detect = [] () {std::clog << "brick1_s4.in.detect" << std::endl;return (itouch::status::type)0;};
    m.brick2_aA.in.move = [] (uint8_t power, int32_t position) {std::clog << "brick2_aA.in.move" << std::endl;};
    m.brick2_aA.in.run = [] (uint8_t power, bool invert) {std::clog << "brick2_aA.in.run" << std::endl;};
    m.brick2_aA.in.stop = [] () {std::clog << "brick2_aA.in.stop" << std::endl;};
    m.brick2_aA.in.coast = [] () {std::clog << "brick2_aA.in.coast" << std::endl;};
    m.brick2_aA.in.zero = [] () {std::clog << "brick2_aA.in.zero" << std::endl;};
    m.brick2_aA.in.position = [] (int32_t& pos) {std::clog << "brick2_aA.in.position" << std::endl;};
    m.brick2_aA.in.at = [] (int32_t pos) {std::clog << "brick2_aA.in.at" << std::endl;return (imotor::result_t::type)0;};
    m.brick2_aB.in.move = [] (uint8_t power, int32_t position) {std::clog << "brick2_aB.in.move" << std::endl;};
    m.brick2_aB.in.run = [] (uint8_t power, bool invert) {std::clog << "brick2_aB.in.run" << std::endl;};
    m.brick2_aB.in.stop = [] () {std::clog << "brick2_aB.in.stop" << std::endl;};
    m.brick2_aB.in.coast = [] () {std::clog << "brick2_aB.in.coast" << std::endl;};
    m.brick2_aB.in.zero = [] () {std::clog << "brick2_aB.in.zero" << std::endl;};
    m.brick2_aB.in.position = [] (int32_t& pos) {std::clog << "brick2_aB.in.position" << std::endl;};
    m.brick2_aB.in.at = [] (int32_t pos) {std::clog << "brick2_aB.in.at" << std::endl;return (imotor::result_t::type)0;};
    m.brick2_s2.in.detect = [] () {std::clog << "brick2_s2.in.detect" << std::endl;return (itouch::status::type)0;};
    m.brick2_s3.in.detect = [] () {std::clog << "brick2_s3.in.detect" << std::endl;return (itouch::status::type)0;};
    m.brick2_s4.in.detect = [] () {std::clog << "brick2_s4.in.detect" << std::endl;return (itouch::status::type)0;};
    m.brick3_aA.in.move = [] (uint8_t power, int32_t position) {std::clog << "brick3_aA.in.move" << std::endl;};
    m.brick3_aA.in.run = [] (uint8_t power, bool invert) {std::clog << "brick3_aA.in.run" << std::endl;};
    m.brick3_aA.in.stop = [] () {std::clog << "brick3_aA.in.stop" << std::endl;};
    m.brick3_aA.in.coast = [] () {std::clog << "brick3_aA.in.coast" << std::endl;};
    m.brick3_aA.in.zero = [] () {std::clog << "brick3_aA.in.zero" << std::endl;};
    m.brick3_aA.in.position = [] (int32_t& pos) {std::clog << "brick3_aA.in.position" << std::endl;};
    m.brick3_aA.in.at = [] (int32_t pos) {std::clog << "brick3_aA.in.at" << std::endl;return (imotor::result_t::type)0;};
    m.brick3_aC.in.move = [] (uint8_t power, int32_t position) {std::clog << "brick3_aC.in.move" << std::endl;};
    m.brick3_aC.in.run = [] (uint8_t power, bool invert) {std::clog << "brick3_aC.in.run" << std::endl;};
    m.brick3_aC.in.stop = [] () {std::clog << "brick3_aC.in.stop" << std::endl;};
    m.brick3_aC.in.coast = [] () {std::clog << "brick3_aC.in.coast" << std::endl;};
    m.brick3_aC.in.zero = [] () {std::clog << "brick3_aC.in.zero" << std::endl;};
    m.brick3_aC.in.position = [] (int32_t& pos) {std::clog << "brick3_aC.in.position" << std::endl;};
    m.brick3_aC.in.at = [] (int32_t pos) {std::clog << "brick3_aC.in.at" << std::endl;return (imotor::result_t::type)0;};
    m.brick3_s1.in.turnon = [] () {std::clog << "brick3_s1.in.turnon" << std::endl;};
    m.brick3_s1.in.turnoff = [] () {std::clog << "brick3_s1.in.turnoff" << std::endl;};
    m.brick3_s1.in.detect = [] () {std::clog << "brick3_s1.in.detect" << std::endl;return (ilight::status::type)0;};
    m.brick3_s2.in.detect = [] () {std::clog << "brick3_s2.in.detect" << std::endl;return (itouch::status::type)0;};
    m.brick3_s3.in.detect = [] () {std::clog << "brick3_s3.in.detect" << std::endl;return (itouch::status::type)0;};
    m.brick4_aA.in.move = [] (uint8_t power, int32_t position) {std::clog << "brick4_aA.in.move" << std::endl;};
    m.brick4_aA.in.run = [] (uint8_t power, bool invert) {std::clog << "brick4_aA.in.run" << std::endl;};
    m.brick4_aA.in.stop = [] () {std::clog << "brick4_aA.in.stop" << std::endl;};
    m.brick4_aA.in.coast = [] () {std::clog << "brick4_aA.in.coast" << std::endl;};
    m.brick4_aA.in.zero = [] () {std::clog << "brick4_aA.in.zero" << std::endl;};
    m.brick4_aA.in.position = [] (int32_t& pos) {std::clog << "brick4_aA.in.position" << std::endl;};
    m.brick4_aA.in.at = [] (int32_t pos) {std::clog << "brick4_aA.in.at" << std::endl;return (imotor::result_t::type)0;};
    m.brick4_aB.in.move = [] (uint8_t power, int32_t position) {std::clog << "brick4_aB.in.move" << std::endl;};
    m.brick4_aB.in.run = [] (uint8_t power, bool invert) {std::clog << "brick4_aB.in.run" << std::endl;};
    m.brick4_aB.in.stop = [] () {std::clog << "brick4_aB.in.stop" << std::endl;};
    m.brick4_aB.in.coast = [] () {std::clog << "brick4_aB.in.coast" << std::endl;};
    m.brick4_aB.in.zero = [] () {std::clog << "brick4_aB.in.zero" << std::endl;};
    m.brick4_aB.in.position = [] (int32_t& pos) {std::clog << "brick4_aB.in.position" << std::endl;};
    m.brick4_aB.in.at = [] (int32_t pos) {std::clog << "brick4_aB.in.at" << std::endl;return (imotor::result_t::type)0;};
    m.brick4_aC.in.move = [] (uint8_t power, int32_t position) {std::clog << "brick4_aC.in.move" << std::endl;};
    m.brick4_aC.in.run = [] (uint8_t power, bool invert) {std::clog << "brick4_aC.in.run" << std::endl;};
    m.brick4_aC.in.stop = [] () {std::clog << "brick4_aC.in.stop" << std::endl;};
    m.brick4_aC.in.coast = [] () {std::clog << "brick4_aC.in.coast" << std::endl;};
    m.brick4_aC.in.zero = [] () {std::clog << "brick4_aC.in.zero" << std::endl;};
    m.brick4_aC.in.position = [] (int32_t& pos) {std::clog << "brick4_aC.in.position" << std::endl;};
    m.brick4_aC.in.at = [] (int32_t pos) {std::clog << "brick4_aC.in.at" << std::endl;return (imotor::result_t::type)0;};
    m.brick4_s1.in.detect = [] () {std::clog << "brick4_s1.in.detect" << std::endl;return (itouch::status::type)0;};
    m.brick4_s2.in.detect = [] () {std::clog << "brick4_s2.in.detect" << std::endl;return (itouch::status::type)0;};
    m.brick4_s3.in.detect = [] () {std::clog << "brick4_s3.in.detect" << std::endl;return (itouch::status::type)0;};

    e["ctrl.calibrate"] = m.ctrl.in.calibrate;
    e["ctrl.stop"] = m.ctrl.in.stop; 
    e["ctrl.operate"] = m.ctrl.in.operate; 
  }
}

int main()
{
  dezyne::runtime rt;
  dezyne::locator l;
  l.set(rt);
  Lego lego;
  l.set(lego);

  std::function<std::shared_ptr<itimer_impl>(const dezyne::locator&)> create_timer_impl = [](const dezyne::locator& l){return std::make_shared<timer_impl>(l);};
  l.set(create_timer_impl);

  dezyne::event_map event_map;
  l.set(event_map, "event-map");

  dezyne::LegoBallSorter sut(l);
  sut.dzn_meta.name = "sut";

  dezyne::fill_event_map(sut, event_map);

  sut.check_bindings();
  sut.dump_tree();

#if 1
  std::string event;
  while(std::cin >> event)
    event_map[event]();
#else
  sut.ctrl.in.calibrate ();
  sut.ctrl.in.operate ();
#endif
}
