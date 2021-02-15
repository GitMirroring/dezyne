#ifndef MEMORY_HH
#define MEMORY_HH

struct Memory: public skel::Memory
{
  Memory(const dzn::locator& l)
  : skel::Memory(l)
  {}
  virtual void port_store () {std::clog << "store\n";}
};

#endif // MEMORY_HH
