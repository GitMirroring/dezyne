#include "library_foreign.hh"

namespace library {

  foreign::foreign(const dzn::locator& dzn_locator)
  : dzn_meta{"","foreign",0,0,{},{},{[this]{w.check_bindings();}}}
  , dzn_rt(dzn_locator.get<dzn::runtime>())
  , dzn_locator(dzn_locator)


  , w({{"w",this,&dzn_meta},{"",0,0}})



  {
    w.in.world = [&](){return dzn::call_in(this,[=]{ dzn_locator.get<dzn::runtime>().skip_block(&this->w) = false; return w_world();}, this->w.meta, "world");};

  }

  void foreign::w_world()
  {
  }

  void foreign::check_bindings() const
  {
    dzn::check_bindings(&dzn_meta);
  }
  void foreign::dump_tree(std::ostream& os) const
  {
    dzn::dump_tree(os, &dzn_meta);
  }
  void foreign::set_state(std::map<std::string,std::map<std::string,std::string> > state_alist)
  {
    set_state(state_alist["foreign."]);
  }
  void foreign::set_state(std::map<std::string,std::string> state_alist)
  {

  }
};
