// Dezyne --- Dezyne command line tools
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include <dzn/runtime.hh>
#include <dzn/locator.hh>

#if __cplusplus >= 201103L

#include <gtkmm.h>

#include <chrono>
#include <cstdlib>
#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <string>

namespace gui {
struct Motor: public Gtk::SpinButton
{
  dzn::meta meta;

  int home;
  int end;
  double velocity;
  int target;
  std::chrono::system_clock::time_point	last_update;

  static const int min = -10000.0;
  static const int max = 10000.0;

  Motor(const char* name, int home=0, int end=0)
  : Gtk::SpinButton(Gtk::Adjustment::create(0.0, min, max, 1.0, 0.0, 0.0))
  , meta{name,"NXT-Motor",0,{},{}}
  , home(home)
  , end(end)
  , velocity(0.5)
  , target()
  , last_update(std::chrono::system_clock::now())
  {}
  int sign(int i)
  {
    return i < 0 ? -1 : 1;
  }
  int get_value()
  {
    return Gtk::SpinButton::get_value();
  }
  void update(const std::function<void(int)>& f)
  {
    auto now = std::chrono::system_clock::now();
    int ms = std::chrono::duration_cast<std::chrono::milliseconds>(now - last_update).count();
    int position = sign (target) * std::min (std::abs (int(get_value() + sign(target) * velocity * ms)), std::abs (target));
    f(position);
    set_value(position);
    last_update = now;
  }
};

struct Sensor: public Gtk::CheckButton
{
  dzn::meta meta;

  Sensor(const char* name)
  : Gtk::CheckButton(name)
  , meta{name,"NXT-Sensor",0,{},{}}
  {}
};

class Lego : public Gtk::Window
{
public:
  Gtk::Box         box_lego;

  Gtk::Box         box_buttons;
  Gtk::Button      button_calibrate;
  Gtk::Button      button_operate;
  Gtk::Button      button_stop;

  Gtk::Box         box_input;
  Gtk::Box         box_output;
  Gtk::Box         box_stage;
  Gtk::Box         box_stage_x;
  Gtk::Box         box_stage_y;
  Gtk::Box         box_robot;
  Gtk::Box         box_truck;
  Gtk::Box         box_trolley;
  Gtk::Box         box_hoist;
  Gtk::Box         box_gripper;

  // input
  Gtk::Frame       frame_input;
  Motor            motor_input_feeder;
  Motor            motor_input_feedport;

  Sensor           sensor_input_feeder;
  Sensor           sensor_input_feedport;

  // output
  Gtk::Frame       frame_output;
  Motor            motor_output_reject_track;
  Motor            motor_output_accept_track;

  Sensor           sensor_output_reject;
  Sensor           sensor_output_accept;

  // light
  Sensor           light;

  // stage
  Gtk::Frame       frame_stage;
  Gtk::Frame       frame_stage_x;
  Motor            motor_stage_x;

  Sensor           sensor_stage_x_home;
  Sensor           sensor_stage_x_end;

  Gtk::Frame       frame_stage_y;
  Motor            motor_stage_y;

  Sensor           sensor_stage_y_home;
  Sensor           sensor_stage_y_end;

  // robot
  Gtk::Frame       frame_robot;
  // truck
  Gtk::Frame       frame_truck;
  Motor            motor_truck;    //robot x axis, moves trolley

  Sensor           sensor_truck_home;

  // trolley
  Gtk::Frame       frame_trolley;
  Motor            motor_trolley;  //robot y axis, moves hoist
  Sensor           sensor_trolley_end;

  // hoist
  Gtk::Frame       frame_hoist;
  Motor            motor_hoist;    //robot z axis, moves gripper up and down
  Sensor           sensor_hoist_end;

  // gripper
  Gtk::Frame       frame_gripper;
  Motor            motor_gripper;  //robot r axis, opens and closes gripper
  Sensor           sensor_gripper_end;

  Lego ()
    : box_lego (Gtk::ORIENTATION_HORIZONTAL, 2)
    , box_buttons (Gtk::ORIENTATION_VERTICAL, 1)
    , button_calibrate("calibrate")
    , button_operate("operate")
    , button_stop("stop")
    , box_input (Gtk::ORIENTATION_VERTICAL, 2)
    , box_output (Gtk::ORIENTATION_VERTICAL, 2)
    , box_stage (Gtk::ORIENTATION_VERTICAL, 2)
    , box_stage_x (Gtk::ORIENTATION_VERTICAL, 1)
    , box_stage_y (Gtk::ORIENTATION_VERTICAL, 1)
    , box_robot (Gtk::ORIENTATION_VERTICAL, 2)
    , box_truck (Gtk::ORIENTATION_VERTICAL, 1)
    , box_trolley (Gtk::ORIENTATION_VERTICAL, 1)
    , box_hoist (Gtk::ORIENTATION_VERTICAL, 1)
    , box_gripper (Gtk::ORIENTATION_VERTICAL, 1)
    , frame_input ("input")
    , motor_input_feeder("ext:input_feeder", 0, 400)
    , motor_input_feedport("ext:input_feedport")
    , sensor_input_feeder("ext:feeder")
    , sensor_input_feedport("ext:feedport")
    , frame_output("output")
    , motor_output_reject_track("ext:output_reject_track")
    , motor_output_accept_track("ext:output_accept_track")
    , sensor_output_reject("ext:reject")
    , sensor_output_accept("ext:accept")
    , light("ext:light")
    , frame_stage("stage")
    , frame_stage_x("x")
    , motor_stage_x("ext:stage_x",-100,500)
    , sensor_stage_x_home("ext:home")
    , sensor_stage_x_end("ext:end")
    , frame_stage_y("y")
    , motor_stage_y("ext:stage_y",-250, 250)
    , sensor_stage_y_home("ext:home")
    , sensor_stage_y_end("ext:end")
    , frame_robot("robot")
    , frame_truck("truck")
    , motor_truck("ext:truck",-200, 1000)
    , sensor_truck_home("ext:home")
    //    , sensor_truck_end("end")
    , frame_trolley("trolley")
    , motor_trolley("ext:trolley",0, 800)
    , sensor_trolley_end("ext:end")
    , frame_hoist("hoist")
    , motor_hoist("ext:hoist",0, 400)
    , sensor_hoist_end("ext:end")
    , frame_gripper("gripper")
    , motor_gripper("ext:gripper",0, -468)
    , sensor_gripper_end("ext:end")
  {
    light.set_sensitive(false);

    set_title ("Lego");
    set_border_width (10);

    add (box_lego);

    box_lego.pack_start(box_buttons);

    box_buttons.pack_start(button_calibrate);
    box_buttons.pack_start(button_operate);
    box_buttons.pack_start(button_stop);

    frame_input.add (box_input);
    frame_robot.add (box_robot);
    frame_stage.add (box_stage);
    frame_output.add (box_output);
    box_lego.pack_start(frame_input);
    box_lego.pack_start(frame_robot);
    box_lego.pack_start(frame_stage);
    box_lego.pack_start(frame_output);

    box_input.pack_start (motor_input_feeder);
    box_input.pack_start (sensor_input_feeder);
    box_input.pack_start (motor_input_feedport);
    box_input.pack_start (sensor_input_feedport);

    box_output.pack_start (motor_output_reject_track);
    box_output.pack_start (sensor_output_reject);
    box_output.pack_start (motor_output_accept_track);
    box_output.pack_start (sensor_output_accept);

    box_stage.pack_start (light);
    box_stage.pack_start (frame_stage_x);
    box_stage.pack_start (frame_stage_y);

    frame_stage_x.add (box_stage_x);
    box_stage_x.pack_start (motor_stage_x);
    box_stage_x.pack_start (sensor_stage_x_home);
    box_stage_x.pack_start (sensor_stage_x_end);

    frame_stage_y.add (box_stage_y);
    box_stage_y.pack_start (motor_stage_y);
    box_stage_y.pack_start (sensor_stage_y_home);
    box_stage_y.pack_start (sensor_stage_y_end);

    //box_robot.pack_start (frame_robot);
    box_robot.pack_start (frame_truck);
    box_robot.pack_start (frame_trolley);
    box_robot.pack_start (frame_hoist);
    box_robot.pack_start (frame_gripper);

    frame_truck.add (box_truck);
    box_truck.pack_start (motor_truck);
    box_truck.pack_start (sensor_truck_home);
    //box_truck.pack_start (sensor_truck_end);

    frame_trolley.add (box_trolley);
    box_trolley.pack_start (motor_trolley);
    box_trolley.pack_start (sensor_trolley_end);

    frame_hoist.add (box_hoist);
    box_hoist.pack_start (motor_hoist);
    box_hoist.pack_start (sensor_hoist_end);

    frame_gripper.add (box_gripper);
    box_gripper.pack_start (motor_gripper);
    box_gripper.pack_start (sensor_gripper_end);

    show_all_children ();
  }
  virtual ~Lego (){}
  void update()
  {
    motor_input_feeder.update([this](int position){
        sensor_input_feeder.set_active(position >= motor_input_feeder.end);
      });
    motor_input_feedport.update([](int position){});
    motor_output_reject_track.update([](int position){});
    motor_output_accept_track.update([](int position){});
    motor_stage_x.update([this](int position){
        sensor_stage_x_home.set_active(position <= motor_stage_x.home);
        sensor_stage_x_end.set_active(position >= motor_stage_x.end);
      });
    motor_stage_y.update([this](int position){
        sensor_stage_y_home.set_active(position <= motor_stage_y.home);
        sensor_stage_y_end.set_active(position >= motor_stage_y.end);
      });
    motor_truck.update([this](int position){
        sensor_truck_home.set_active(position <= motor_truck.home);
        //sensor_truck_end.set_active(position >= motor_truck.end);
      });
    motor_trolley.update([this](int position){
        sensor_trolley_end.set_active(position >= motor_trolley.end);
      });
    motor_hoist.update([this](int position){
        sensor_hoist_end.set_active(position >= motor_hoist.end);
      });
    motor_gripper.update([this](int position){
        sensor_gripper_end.set_active(position >= motor_gripper.end);
      });
  }
};

void connect(imotor&, gui::Motor&);
void connect(itouch& t, gui::Sensor &);
void connect(ilight& l, gui::Sensor &);

struct timer_impl: public itimer_impl
{
  sigc::connection connection;
  itimer& port;
  gui::Lego& lego;

  timer_impl(const dzn::locator& l)
  : port(l.get<itimer>())
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

}

int main(int argc, char* argv[])
{
  try
  {
    Glib::RefPtr<Gtk::Application> app
      = Gtk::Application::create (argc, argv,
                                  "org.gtkmm.examples.base");

    gui::Lego lego;

    // create dezyne system

    dzn::runtime rt;
    dzn::locator loc;
    loc.set(rt);
    loc.set(lego);

    std::function<std::shared_ptr<itimer_impl>(const dzn::locator&)> create_timer_impl = [](const dzn::locator& l){return std::make_shared<gui::timer_impl>(l);};
    loc.set(create_timer_impl);

    LegoBallSorter sut(loc);

    lego.button_calibrate.signal_clicked ().connect (sut.ctrl.in.calibrate);
    lego.button_operate.signal_clicked ().connect (sut.ctrl.in.operate);
    lego.button_stop.signal_clicked ().connect (sut.ctrl.in.stop);

    sut.dzn_meta.name = "sut";
    sut.ctrl.meta.requires = {"ctrl",&sut};

    sut.ctrl.out.calibrated = []{std::cout << "LegoBallSorter.calibrated" << std::endl;};
    sut.ctrl.out.finished = []{std::cout << "LegoBallSorter.finished" << std::endl;};

    connect(sut.brick1_aA, lego.motor_trolley);
    connect(sut.brick1_aB, lego.motor_input_feedport);
    connect(sut.brick1_aC, lego.motor_input_feeder);

    connect(sut.brick1_s1, lego.sensor_stage_x_end);
    connect(sut.brick1_s2, lego.sensor_input_feedport);
    connect(sut.brick1_s3, lego.sensor_truck_home);
    connect(sut.brick1_s4, lego.sensor_input_feeder);

    connect(sut.brick2_aA, lego.motor_output_reject_track);
    connect(sut.brick2_aB, lego.motor_output_accept_track);

    //connect(sut.brick2_s1, lego.sensor_truck_end);
    connect(sut.brick2_s2, lego.sensor_stage_x_home);
    connect(sut.brick2_s3, lego.sensor_output_reject);
    connect(sut.brick2_s4, lego.sensor_output_accept);

    connect(sut.brick3_aA, lego.motor_stage_x);
    connect(sut.brick3_aC, lego.motor_stage_y);

    connect(sut.brick3_s1, lego.light);
    connect(sut.brick3_s2, lego.sensor_stage_y_end);
    connect(sut.brick3_s3, lego.sensor_stage_y_home);

    connect(sut.brick4_aA, lego.motor_hoist);
    connect(sut.brick4_aB, lego.motor_gripper);
    connect(sut.brick4_aC, lego.motor_truck);

    connect(sut.brick4_s1, lego.sensor_gripper_end);
    connect(sut.brick4_s2, lego.sensor_trolley_end);
    connect(sut.brick4_s3, lego.sensor_hoist_end);

    sut.check_bindings();
    sut.dump_tree();

    return app->run (lego);
  }
  catch(const std::exception& e)
  {
    std::clog << "oops: " << e.what() << std::endl;
    return 1;
  }
}

namespace gui {
//#define SHORT_CIRCUIT 1

void connect(imotor& m, Motor& g)
{
  m.meta.provides = {"imotor",&g.meta};

  m.in.move     = [&] (std::int8_t power, std::int32_t position) {
#if !SHORT_CIRCUIT
    dzn::trace_in (std::clog, m.meta, "move");
    g.target = position;
    dzn::trace_out (std::clog, m.meta, "return");
#endif
  };
  m.in.run      = [&] (std::int8_t power, bool invert) {
    g.target = invert ? Motor::min : Motor::max;
  };
  m.in.stop     = [&] {g.target = g.get_value();};
  m.in.coast    = [&] {g.target = g.get_value();};
  m.in.zero     = [&] {int current = g.get_value(); g.home -= current; g.end -= current; g.target = 0; g.set_value(0);};
#if !SHORT_CIRCUIT
  m.in.position = [&] (std::int32_t& position){position =  g.get_value();};
  m.in.at       = [&] (std::int32_t position){ return abs(position - g.get_value()) <= 2 ? imotor::result_t::yes : imotor::result_t::no;};
#else
  m.in.position = [&] (std::int32_t& position){position = 0;};
  m.in.at       = [&] (std::int32_t position){return imotor::result_t::yes;};
#endif
}

void connect(itouch& t, Sensor& s)
{
  t.meta.provides = {"itouch",&s.meta};

#if !SHORT_CIRCUIT
  t.in.detect  = [&] {
    dzn::trace_in (std::clog, t.meta, "detect");
    auto r = s.get_active()
      ? itouch::status::pressed
      : itouch::status::released;
    dzn::trace_out (std::clog, t.meta, r == itouch::status::pressed ? "status_pressed" : "status_released");
    return r;
  };
#else
  t.in.detect  = [&] { return itouch::status::pressed; };
#endif
}

void connect(ilight& l, Sensor& s)
{
  l.meta.provides = {"ilight",&s.meta};
  l.in.turnon  = [&] {s.set_sensitive(true);};
  l.in.turnoff = [&] {s.set_sensitive(false);};
#if !SHORT_CIRCUIT
  l.in.detect  = [&] {return s.get_active()
                      ? ilight::status::accept
                      : ilight::status::reject;};
#else
  l.in.detect  = [&] {return ilight::status::accept;};
#endif
}
}
#endif //  __cplusplus >= 201103L
