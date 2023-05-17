#include "hello_foreign.hh"

foreign::foreign (const dzn::locator &locator)
  : skel::foreign (locator)
{}

void foreign::p_hello ()
{
  p.out.world ();
}
