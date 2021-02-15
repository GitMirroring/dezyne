#ifndef LENS_HH
#define LENS_HH

struct Lens: public skel::Lens
{
  Lens(const dzn::locator& l)
  : skel::Lens(l)
  {}
  virtual void port_forward () {std::clog << "sut.optics.focus.lens.port.forward\n";}
  virtual void port_backward () {std::clog << "sut.optics.focus.lens.port.backward\n";}
  virtual void port_stop () {std::clog << "sut.optics.focus.lens.port.stop\n";}
};

#endif // LENS_HH
