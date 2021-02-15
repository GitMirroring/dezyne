#ifndef CMOS_HH
#define CMOS_HH

struct CMOS: public skel::CMOS
{
  CMOS(const dzn::locator& l)
  : skel::CMOS(l)
  {}
  virtual void port_prepare () {std::clog << "sut.acquisition.sensor.port.prepare\n";};
  virtual void port_acquire () {std::clog << "sut.acquisition.sensor.port.acquire\n";};
  virtual void port_cancel ()  {std::clog << "sut.acquisition.sensor.port.cancel\n";};
};

#endif // CMOS_HH
