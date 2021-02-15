#ifndef CONTRAST_HH
#define CONTRAST_HH

struct Contrast: public skel::Contrast
{
  Contrast(const dzn::locator& l)
  : skel::Contrast(l)
  {}
  virtual ::IContrast::EContrast::type port_measure () {std::clog << "measure\n"; return ::IContrast::EContrast::Blurrier;}
};

#endif // CONTRAST_HH
