// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Henk Katerberg <henk.katerberg@yahoo.com>
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

#include "LegoBallSorter.hh"

#include "runtime.hh"
#include "locator.hh"

#if __cplusplus >= 201103L
#include "pump.hh"

#include "lego_usb.hh"

#include <cstdlib>
#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>

constexpr std::uint8_t PORTA = 0;
constexpr std::uint8_t PORTB = 1;
constexpr std::uint8_t PORTC = 2;

constexpr std::uint8_t PORT1 = 0;
constexpr std::uint8_t PORT2 = 1;
constexpr std::uint8_t PORT3 = 2;
constexpr std::uint8_t PORT4 = 3;

void connect(imotor& m, lego::USB::Device* brick, std::uint8_t port);
void connect(itouch& t, lego::USB::Device* brick, std::uint8_t port);
void connect(ilight& l, lego::USB::Device* brick, std::uint8_t port);

struct timer_impl: public itimer_impl
{
  static size_t g_id;
  size_t id;
  itimer& port;
  dezyne::pump& p;

  timer_impl(const dezyne::locator& l)
  : id(g_id++)
  , port(l.get<itimer>())
  , p(l.get<dezyne::pump>())
  {}
  void create(int ms)
  {
    p.handle(id, ms, port.out.timeout);
  }
  void cancel()
  {
    p.remove(id);
  }
};
size_t timer_impl::g_id = 0;

lego::USB* usb_ptr = nullptr;

void signal_handler(int sig)
{
  if(usb_ptr)
  {
    for(auto& device: usb_ptr->devices)
    {
      for(auto i = 0; i <= 2; ++i) device.coast(i);
      for(auto i = 0; i <= 3; ++i) device.set_input_mode(i, 0, 0);
    }
  }
  signal(sig, SIG_DFL);
  std::abort();
}

int main(int argc, char* argv[])
{
  signal(SIGINT, signal_handler);
  signal(SIGABRT, signal_handler);
  signal(SIGSEGV, signal_handler);

  try
  {
    lego::USB lego_usb;
    usb_ptr = &lego_usb;

    // utility to name bricks
    for(int i = 1; i < argc; ++i)
    {
      std::cout << "naming BRICK #" << i << " " << argv[i] << std::endl;
      std::cout << "hit enter to continue or CTRL-C to stop" << std::endl;
      std::cin.get();
      lego_usb.devices.at(i-1).set_name(argv[i]);
    }
    if(argc > 1) return 0;

    // discover bricks by name
    std::map<std::string, lego::USB::Device*> bricks;
    for(auto& device: lego_usb.devices)
    {
      auto name = device.get_name();
      auto version = device.get_version();
      std::cout << "discovered: " << name << " at: " << &device
                << " protocol version: " << std::get<0>(version) << "." << std::get<1>(version)
                << " firmware version: " << std::get<2>(version) << "." << std::get<3>(version) << std::endl;
      bricks[name] = &device;
    }

    if (bricks.size () != 4)
      {
        std::cerr << "bricks found: " << bricks.size () << ", expected: 4" << std::endl;
        std::cerr << "exiting" << std::endl;
        exit (2);
      }

    // create dezyne system
    dezyne::runtime rt;
    dezyne::locator loc;
    loc.set(rt);

    std::unique_ptr<dezyne::pump> tmp1(new dezyne::pump);
    loc.set(*tmp1);

    std::function<std::shared_ptr<itimer_impl>(const dezyne::locator&)> create_timer_impl = [](const dezyne::locator& l){return std::make_shared<timer_impl>(l);};
    loc.set(create_timer_impl);

    LegoBallSorter sut(loc);

    std::unique_ptr<dezyne::pump> tmp2(std::move(tmp1)); //now the pump is destroyed before the sut is
    dezyne::pump& pump = *tmp2;

    sut.dzn_meta.name = "sut";
    sut.ctrl.meta.requires = {"ctrl",0};

    sut.ctrl.out.calibrated = []{std::cout << "LegoBallSorter.calibrated" << std::endl;};
    sut.ctrl.out.finished = []{std::cout << "LegoBallSorter.finished" << std::endl;};

    connect(sut.brick1_aA, bricks.at("INPUT"), PORTA);
    connect(sut.brick1_aB, bricks.at("INPUT"), PORTB);
    connect(sut.brick1_aC, bricks.at("INPUT"), PORTC);

    connect(sut.brick1_s1, bricks.at("INPUT"), PORT1);
    connect(sut.brick1_s2, bricks.at("INPUT"), PORT2);
    connect(sut.brick1_s3, bricks.at("INPUT"), PORT3);
    connect(sut.brick1_s4, bricks.at("INPUT"), PORT4);


    connect(sut.brick2_aA, bricks.at("OUTPUT"), PORTA);
    connect(sut.brick2_aB, bricks.at("OUTPUT"), PORTB);

    //connect(sut.brick2_s1, bricks.at("OUTPUT"), PORT1);
    connect(sut.brick2_s2, bricks.at("OUTPUT"), PORT2);
    connect(sut.brick2_s3, bricks.at("OUTPUT"), PORT3);
    connect(sut.brick2_s4, bricks.at("OUTPUT"), PORT4);


    connect(sut.brick3_aA, bricks.at("STAGE"), PORTA);
    connect(sut.brick3_aC, bricks.at("STAGE"), PORTC);

    connect(sut.brick3_s1, bricks.at("STAGE"), PORT1);
    connect(sut.brick3_s2, bricks.at("STAGE"), PORT2);
    connect(sut.brick3_s3, bricks.at("STAGE"), PORT3);


    connect(sut.brick4_aA, bricks.at("ROBOT"), PORTA);
    connect(sut.brick4_aB, bricks.at("ROBOT"), PORTB);
    connect(sut.brick4_aC, bricks.at("ROBOT"), PORTC);

    connect(sut.brick4_s1, bricks.at("ROBOT"), PORT1);
    connect(sut.brick4_s2, bricks.at("ROBOT"), PORT2);
    connect(sut.brick4_s3, bricks.at("ROBOT"), PORT3);

    sut.check_bindings();

    dezyne::apply(&sut.dzn_meta, [](const dezyne::meta* m){
        std::clog << m->parent << " " << m << " " << m->name << std::endl;
      });

    // run the event loop

    std::string s;
    bool stop = false;
    while(not stop && std::getline(std::cin, s)) {
      if(s.empty()) continue;
      if(s[0] == 'c') pump.and_wait(sut.ctrl.in.calibrate);
      if(s[0] == 'o') pump.and_wait(sut.ctrl.in.operate);
      if(s[0] == 's') pump.and_wait(sut.ctrl.in.stop);
      if(s[0] == 'q') stop = true;
    }
  }
  catch(const std::exception& e)
  {
    std::clog << "oops: " << e.what() << std::endl;
    return 1;
  }
}

void connect(imotor& m, lego::USB::Device* brick, std::uint8_t port)
{
  m.meta.provides = {"imotor",&m};

  m.in.move     = [=] (std::int8_t power, std::int32_t position) {
    std::int32_t delta = position - brick->get_position(port);
    auto sign = delta < 0 ? -1 : 1;
    brick->move(port, sign * power, true, std::abs(delta));
  };
  m.in.run      = [=] (std::int8_t power, bool invert) {
    brick->move(port, invert ? -power : power, false, 0);
  };
  m.in.stop     = [=] {brick->stop(port);};
  m.in.coast    = [=] {brick->coast(port);};
  m.in.zero     = [=] {brick->zero(port);};
  m.in.position = [=] (std::int32_t& position){position = brick->get_position(port);};
  m.in.at       = [=] (std::int32_t position){return brick->at(port, position) ?
                                              imotor::result_t::yes :
                                              imotor::result_t::no;};
}
void connect(ilight& l, lego::USB::Device* brick, std::uint8_t port)
{
  l.meta.provides = {"ilight",&l};

  l.in.turnon  = [=] {brick->set_input_mode(port, 0x05, 0x80);};
  l.in.turnoff = [=] {brick->set_input_mode(port, 0x06, 0x80);};
  l.in.detect  = [=] {return brick->get_input_values(port) < 42 ?
                      ilight::status::accept :
                      ilight::status::reject;};
}
void connect(itouch& t, lego::USB::Device* brick, std::uint8_t port)
{
  t.meta.provides = {"itouch",&t};

  brick->set_input_mode(port, 0x01, 0x20);
  t.in.detect  = [=] {return brick->get_input_values(port) == 1 ?
                      itouch::status::pressed :
                      itouch::status::released;};
}
#endif // __cplusplus >= 201103L
