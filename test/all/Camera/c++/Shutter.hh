#ifndef SHUTTER_HH
#define SHUTTER_HH

struct Shutter: public skel::Shutter
{
  Shutter(const dzn::locator& l)
  : skel::Shutter(l)
  {}
  virtual void port_expose () {std::clog << "sut.optics.focus.sensor.port.measure\n";}
};

#endif // SHUTTER_HH
