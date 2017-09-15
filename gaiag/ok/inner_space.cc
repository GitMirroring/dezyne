// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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
// Commentary:
//
// Code:

/*
templates/c++/source@root:0:expand */
/*
templates/c++/source@interface:0:expand */
/*
templates/c++/source@interface:0:expand */
/*
templates/c++/source@component:0:expand */
#include "inner_space.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

namespace inner {
  /*
  templates/c++/model-name:0:expand */
  space::/*
  templates/c++/model-name:0:expand */
  space(const dzn::locator& dzn_locator)
  : /*
  templates/c++/meta@component:0:expand */
  dzn_meta{"","/*
    templates/c++/model-name:0:expand */
    space",0,0,{/*
      templates/c++/ports-meta-list:0:expand */
    },{/*
      templates/c++/meta-child@component:0:expand */
      /*FIXME*/},{/*
      templates/c++/check-bindings-list:0:expand */
      [this]{inner.check_bindings();},[this]{fooi.check_bindings();}}}
  , dzn_rt(dzn_locator.get<dzn::runtime>())
  , dzn_locator(dzn_locator)
  /*
  templates/c++/variable-member-initializer@variable:0:expand */
  , inner_state(/*
  templates/c++/variable-expression@expression:0:expand */
  /*
  templates/c++/expression@literal:0:expand */
  ::inner::foo::I::Bool::t)
  /*
  templates/c++/variable-member-initializer@variable:0:expand */
  , foo_state(/*
  templates/c++/variable-expression@expression:0:expand */
  /*
  templates/c++/expression@literal:0:expand */
  ::foo::I::Bool::T)

  /*
  templates/c++/injected-member-initializer:0:expand */

  /*
  templates/c++/provided-member-initializer@port:0:expand */
  , inner({{"inner",this,&dzn_meta},{"",0,0}})
  /*
  templates/c++/provided-member-initializer@port:0:expand */
  , fooi({{"fooi",this,&dzn_meta},{"",0,0}})

  /*
  templates/c++/required-member-initializer:0:expand */

  /*
  templates/c++/async-member-initializer:0:expand */

  {
    dzn_rt.performs_flush(this) = true;
    dzn::pump* dzn_pump = dzn_locator.try_get<dzn::pump>();
    /*
    templates/c++/calls:0:expand */

    /*
    templates/c++/rcalls@trigger:0:expand */
    inner.in.e = [&](/*
    templates/c++/formals:0:expand */
    ){return dzn::call_in(this,[=/*
      templates/c++/out-arguments:0:expand */
      ]{ return inner_e(/*
        templates/c++/arguments:0:expand */
        );}, this->inner.meta, "e");};
    /*
    templates/c++/rcalls@trigger:0:expand */
    fooi.in.e = [&](/*
    templates/c++/formals:0:expand */
    ){return dzn::call_in(this,[=/*
      templates/c++/out-arguments:0:expand */
      ]{ return fooi_e(/*
        templates/c++/arguments:0:expand */
        );}, this->fooi.meta, "e");};

    /*
    templates/c++/reqs:0:expand */

    /*
    templates/c++/clrs:0:expand */

  }

  /*
  templates/c++/methods@on:0:expand */
  /*
  templates/c++/method@trigger:0:expand */
  /*
  templates/c++/return-type@type:0:expand */
  ::inner::foo::I::Bool::type /*
  templates/c++/model-name:0:expand */
  space::inner_e (/*
  templates/c++/formals:0:expand */
  )
  {
    /*
    templates/c++/on-statement@compound:0:expand */
    /*
    templates/c++/declarative-or-imperative@compound:0:expand */
    {
      /*
      templates/c++/statements@statement:0:expand */
      /*
      templates/c++/statement@action:0:expand */
      /*
      templates/c++/expression@action:0:expand */
      this->inner.out.a (/*
      templates/c++/arguments:0:expand */
      );
      /*
      templates/c++/statements@statement:0:expand */
      /*
      templates/c++/statement@reply:0:expand */
      /*
      templates/c++/assign-reply@reply:0:expand */
      this->reply_inner_foo_I_Bool = /*
      templates/c++/expression@var:0:expand */
      /*
      templates/c++/expression-expand@expression:0:expand */
      /*
      templates/c++/expression@variable:0:expand */
      /*
      templates/c++/variable-name@variable:0:expand */
      inner_state;
      /*
      templates/c++/port-release:0:expand */

    }


    /*
    templates/c++/return@type:0:expand */
    return /*
    templates/c++/non-void-reply@enum:0:expand */
    this->reply_inner_foo_I_Bool/*
    templates/c++/reply:0:expand */
    ;
  }
  /*
  templates/c++/methods@on:0:expand */
  /*
  templates/c++/method@trigger:0:expand */
  /*
  templates/c++/return-type@type:0:expand */
  ::foo::I::Bool::type /*
  templates/c++/model-name:0:expand */
  space::fooi_e (/*
  templates/c++/formals:0:expand */
  )
  {
    /*
    templates/c++/on-statement@compound:0:expand */
    /*
    templates/c++/declarative-or-imperative@compound:0:expand */
    {
      /*
      templates/c++/statements@statement:0:expand */
      /*
      templates/c++/statement@action:0:expand */
      /*
      templates/c++/expression@action:0:expand */
      this->fooi.out.a (/*
      templates/c++/arguments:0:expand */
      );
      /*
      templates/c++/statements@statement:0:expand */
      /*
      templates/c++/statement@reply:0:expand */
      /*
      templates/c++/assign-reply@reply:0:expand */
      this->reply_foo_I_Bool = /*
      templates/c++/expression@var:0:expand */
      /*
      templates/c++/expression-expand@expression:0:expand */
      /*
      templates/c++/expression@variable:0:expand */
      /*
      templates/c++/variable-name@variable:0:expand */
      foo_state;
      /*
      templates/c++/port-release:0:expand */

    }


    /*
    templates/c++/return@type:0:expand */
    return /*
    templates/c++/non-void-reply@enum:0:expand */
    this->reply_foo_I_Bool/*
    templates/c++/reply:0:expand */
    ;
  }

  /*
  templates/c++/functions:0:expand */

  void /*
  templates/c++/model-name:0:expand */
  space::check_bindings() const
  {
    dzn::check_bindings(&dzn_meta);
  }
  void /*
  templates/c++/model-name:0:expand */
  space::dump_tree(std::ostream& os) const
  {
    dzn::dump_tree(os, &dzn_meta);
  }
}

////////////////////////////////////////////////////////////////////////////////
/*
templates/c++/source@component:0:expand */
#include "inner_space.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

namespace bar {
  /*
  templates/c++/model-name:0:expand */
  c::/*
  templates/c++/model-name:0:expand */
  c(const dzn::locator& dzn_locator)
  : /*
  templates/c++/meta@component:0:expand */
  dzn_meta{"","/*
    templates/c++/model-name:0:expand */
    c",0,0,{/*
      templates/c++/ports-meta-list:0:expand */
    },{/*
      templates/c++/meta-child@component:0:expand */
      /*FIXME*/},{/*
      templates/c++/check-bindings-list:0:expand */
      [this]{i.check_bindings();}}}
  , dzn_rt(dzn_locator.get<dzn::runtime>())
  , dzn_locator(dzn_locator)
  /*
  templates/c++/variable-member-initializer@variable:0:expand */
  , state(/*
  templates/c++/variable-expression@expression:0:expand */
  /*
  templates/c++/expression@literal:0:expand */
  ::foo::I::Bool::T)

  /*
  templates/c++/injected-member-initializer:0:expand */

  /*
  templates/c++/provided-member-initializer@port:0:expand */
  , i({{"i",this,&dzn_meta},{"",0,0}})

  /*
  templates/c++/required-member-initializer:0:expand */

  /*
  templates/c++/async-member-initializer:0:expand */

  {
    dzn_rt.performs_flush(this) = true;
    dzn::pump* dzn_pump = dzn_locator.try_get<dzn::pump>();
    /*
    templates/c++/calls:0:expand */

    /*
    templates/c++/rcalls@trigger:0:expand */
    i.in.e = [&](/*
    templates/c++/formals:0:expand */
    ){return dzn::call_in(this,[=/*
      templates/c++/out-arguments:0:expand */
      ]{ return i_e(/*
        templates/c++/arguments:0:expand */
        );}, this->i.meta, "e");};

    /*
    templates/c++/reqs:0:expand */

    /*
    templates/c++/clrs:0:expand */

  }

  /*
  templates/c++/methods@on:0:expand */
  /*
  templates/c++/method@trigger:0:expand */
  /*
  templates/c++/return-type@type:0:expand */
  ::foo::I::Bool::type /*
  templates/c++/model-name:0:expand */
  c::i_e (/*
  templates/c++/formals:0:expand */
  )
  {
    /*
    templates/c++/on-statement@compound:0:expand */
    /*
    templates/c++/declarative-or-imperative@compound:0:expand */
    {
      /*
      templates/c++/statements@statement:0:expand */
      /*
      templates/c++/statement@action:0:expand */
      /*
      templates/c++/expression@action:0:expand */
      this->i.out.a (/*
      templates/c++/arguments:0:expand */
      );
      /*
      templates/c++/statements@statement:0:expand */
      /*
      templates/c++/statement@reply:0:expand */
      /*
      templates/c++/assign-reply@reply:0:expand */
      this->reply_foo_I_Bool = /*
      templates/c++/expression@var:0:expand */
      /*
      templates/c++/expression-expand@expression:0:expand */
      /*
      templates/c++/expression@variable:0:expand */
      /*
      templates/c++/variable-name@variable:0:expand */
      state;
      /*
      templates/c++/port-release:0:expand */

    }


    /*
    templates/c++/return@type:0:expand */
    return /*
    templates/c++/non-void-reply@enum:0:expand */
    this->reply_foo_I_Bool/*
    templates/c++/reply:0:expand */
    ;
  }

  /*
  templates/c++/functions:0:expand */

  void /*
  templates/c++/model-name:0:expand */
  c::check_bindings() const
  {
    dzn::check_bindings(&dzn_meta);
  }
  void /*
  templates/c++/model-name:0:expand */
  c::dump_tree(std::ostream& os) const
  {
    dzn::dump_tree(os, &dzn_meta);
  }
}

////////////////////////////////////////////////////////////////////////////////
