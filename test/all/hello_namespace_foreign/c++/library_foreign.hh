// Dezyne --- Dezyne command line tools
//
// Copyright © 2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
#ifndef LIBRARY_FOREIGN_HH
#define LIBRARY_FOREIGN_HH

#include "hello.hh"

namespace library {

  struct foreign: public dzn::component
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
