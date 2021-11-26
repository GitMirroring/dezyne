#ifndef FOREIGN_HH
#define FOREIGN_HH

struct foreign: public skel::foreign
{
  foreign (const dzn::locator& locator)
  : skel::foreign (locator)
  {}
  void p_hello ()
  {
    p.out.world ();
  }
};

#endif
