#ifndef LIBRARY_FOREIGN_HH
#define LIBRARY_FOREIGN_HH

#include "hello.hh"

namespace library {

  struct foreign
  {
    dzn::meta dzn_meta;
    dzn::runtime& dzn_rt;
    dzn::locator const& dzn_locator;

    std::function<void ()> out_w;

    ::library::iworld w;



    foreign(const dzn::locator&);
    void check_bindings() const;
    void dump_tree(std::ostream& os) const;
    void set_state(std::map<std::string,std::map<std::string,std::string> > state_alist);
    void set_state(std::map<std::string,std::string> state_alist);
    friend std::ostream& operator << (std::ostream& os, const foreign& m)  {
      (void)m;
      return os << "[" << "]" ;
    }
    private:
    void w_world();

  };
};

#endif // LIBRARY_FOREIGN_HH
