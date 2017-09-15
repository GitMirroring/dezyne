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
templates/c++/header@root:0:expand */
/*
templates/c++/header-data:0:expand */

#ifndef inner_space_HH
#define inner_space_HH
/*
templates/c++/header-@interface:0:expand */
/*
templates/c++/include-guard:0:expand */


#include <dzn/meta.hh>

#include <map>
namespace inner { namespace foo {

    /*
    templates/c++/global-enum-definer:0:expand */

    struct /*
    templates/c++/model-name:0:expand */
    I
    {
      /*
      templates/c++/enum-definer@enum:0:expand */
#ifndef ENUM_inner_foo_I_Bool
#define ENUM_inner_foo_I_Bool 1
      struct Bool
      {
        enum type
        {
          /*
          templates/c++/asd-voidreply:0:expand */
          /*
          templates/c++/enum-field-definer@enum-field:0:expand */
          f,/*
          templates/c++/enum-field-definer@enum-field:0:expand */
          t
        };
      };
#endif // ENUM_inner_foo_I_Bool

      struct
      {
        /*
        templates/c++/in-event-definer@event:0:expand */
        std::function<::inner::foo::I::Bool::type(/*
        templates/c++/formals:0:expand */
        )> e;
      } in;

      struct
      {
        /*
        templates/c++/out-event-definer@event:0:expand */
        std::function<void(/*
        templates/c++/formals:0:expand */
        )> a;
      } out;

      dzn::port::meta meta;
      inline /*
      templates/c++/model-name:0:expand */
      I(const dzn::port::meta& m) : meta(m) {}

      void check_bindings() const
      {
        /*
        templates/c++/check-in-binding@event:0:expand */
        if (! in.e) throw dzn::binding_error(meta, "in.e");

        /*
        templates/c++/check-out-binding@event:0:expand */
        if (! out.a) throw dzn::binding_error(meta, "out.a");

      }
    };

    inline void connect (/*
    templates/c++/model-name:0:expand */
    I& provided, /*
    templates/c++/model-name:0:expand */
    I& required)
    {
      provided.out = required.out;
      required.in = provided.in;
      provided.meta.requires = required.meta.requires;
      required.meta.provides = provided.meta.provides;
    }

  }
}


/*
templates/c++/interface-enum-to-string@enum:0:expand */
#ifndef ENUM_TO_STRING_inner_foo_I_Bool
#define ENUM_TO_STRING_inner_foo_I_Bool 1
inline std::string to_string(::inner::foo::I::Bool::type v)
{
  switch(v)
  {
    /*
    templates/c++/enum-field-to-string@enum-field:0:expand */
    case ::inner::foo::I::Bool::f: return "Bool_f";
    /*
    templates/c++/enum-field-to-string@enum-field:0:expand */
    case ::inner::foo::I::Bool::t: return "Bool_t";

  }
  return "";
}
#endif // ENUM_TO_STRING_inner_foo_I_Bool

/*
templates/c++/interface-string-to-enum@enum:0:expand */
#ifndef STRING_TO_ENUM_inner_foo_I_Bool
#define STRING_TO_ENUM_inner_foo_I_Bool 1
inline ::inner::foo::I::Bool::type to_inner_foo_I_Bool(std::string s)
{
  static std::map<std::string, ::inner::foo::I::Bool::type> m = {
    /*
    templates/c++/string-to-enum@enum-field:0:expand */
    {"Bool_f", ::inner::foo::I::Bool::f},
    /*
    templates/c++/string-to-enum@enum-field:0:expand */
    {"Bool_t", ::inner::foo::I::Bool::t},
  };
  return m.at(s);
}
#endif // STRING_TO_ENUM_inner_foo_I_Bool


/*
templates/c++/endif:0:expand */
/*
templates/c++/header-@interface:0:expand */
/*
templates/c++/include-guard:0:expand */


#include <dzn/meta.hh>

#include <map>
namespace foo {

  /*
  templates/c++/global-enum-definer:0:expand */

  struct /*
  templates/c++/model-name:0:expand */
  I
  {
    /*
    templates/c++/enum-definer@enum:0:expand */
#ifndef ENUM_foo_I_Bool
#define ENUM_foo_I_Bool 1
    struct Bool
    {
      enum type
      {
        /*
        templates/c++/asd-voidreply:0:expand */
        /*
        templates/c++/enum-field-definer@enum-field:0:expand */
        F,/*
        templates/c++/enum-field-definer@enum-field:0:expand */
        T
      };
    };
#endif // ENUM_foo_I_Bool

    struct
    {
      /*
      templates/c++/in-event-definer@event:0:expand */
      std::function<::foo::I::Bool::type(/*
      templates/c++/formals:0:expand */
      )> e;
    } in;

    struct
    {
      /*
      templates/c++/out-event-definer@event:0:expand */
      std::function<void(/*
      templates/c++/formals:0:expand */
      )> a;
    } out;

    dzn::port::meta meta;
    inline /*
    templates/c++/model-name:0:expand */
    I(const dzn::port::meta& m) : meta(m) {}

    void check_bindings() const
    {
      /*
      templates/c++/check-in-binding@event:0:expand */
      if (! in.e) throw dzn::binding_error(meta, "in.e");

      /*
      templates/c++/check-out-binding@event:0:expand */
      if (! out.a) throw dzn::binding_error(meta, "out.a");

    }
  };

  inline void connect (/*
  templates/c++/model-name:0:expand */
  I& provided, /*
  templates/c++/model-name:0:expand */
  I& required)
  {
    provided.out = required.out;
    required.in = provided.in;
    provided.meta.requires = required.meta.requires;
    required.meta.provides = provided.meta.provides;
  }

}


/*
templates/c++/interface-enum-to-string@enum:0:expand */
#ifndef ENUM_TO_STRING_foo_I_Bool
#define ENUM_TO_STRING_foo_I_Bool 1
inline std::string to_string(::foo::I::Bool::type v)
{
  switch(v)
  {
    /*
    templates/c++/enum-field-to-string@enum-field:0:expand */
    case ::foo::I::Bool::F: return "Bool_F";
    /*
    templates/c++/enum-field-to-string@enum-field:0:expand */
    case ::foo::I::Bool::T: return "Bool_T";

  }
  return "";
}
#endif // ENUM_TO_STRING_foo_I_Bool

/*
templates/c++/interface-string-to-enum@enum:0:expand */
#ifndef STRING_TO_ENUM_foo_I_Bool
#define STRING_TO_ENUM_foo_I_Bool 1
inline ::foo::I::Bool::type to_foo_I_Bool(std::string s)
{
  static std::map<std::string, ::foo::I::Bool::type> m = {
    /*
    templates/c++/string-to-enum@enum-field:0:expand */
    {"Bool_F", ::foo::I::Bool::F},
    /*
    templates/c++/string-to-enum@enum-field:0:expand */
    {"Bool_T", ::foo::I::Bool::T},
  };
  return m.at(s);
}
#endif // STRING_TO_ENUM_foo_I_Bool


/*
templates/c++/endif:0:expand */

#ifndef INTERFACE_ONLY
////////////////////////////////////////////////////////////////////////////////
/*
templates/c++/header@component:0:expand */
// #ifndef /*
templates/c++/upcase-model-name:0:expand */
INNER_SPACE_HH
// #define /*
templates/c++/upcase-model-name:0:expand */
INNER_SPACE_HH

#include <iostream>

/*
templates/c++/interface-include@file-name:0:expand */
#include "inner_space.hh"
/*
templates/c++/interface-include@file-name:0:expand */
#include "inner_space.hh"


namespace dzn {
  struct locator;
  struct runtime;
}

namespace inner {
  struct /*
  templates/c++/model-name:0:expand */
  space
  {
    dzn::meta dzn_meta;
    dzn::runtime& dzn_rt;
    dzn::locator const& dzn_locator;
    /*
    templates/c++/enum-definer@enum:0:expand */
#ifndef ENUM_inner_foo_I_Bool
#define ENUM_inner_foo_I_Bool 1
    struct Bool
    {
      enum type
      {
        /*
        templates/c++/asd-voidreply:0:expand */
        /*
        templates/c++/enum-field-definer@enum-field:0:expand */
        f,/*
        templates/c++/enum-field-definer@enum-field:0:expand */
        t
      };
    };
#endif // ENUM_inner_foo_I_Bool
    /*
    templates/c++/enum-definer@enum:0:expand */
#ifndef ENUM_foo_I_Bool
#define ENUM_foo_I_Bool 1
    struct Bool
    {
      enum type
      {
        /*
        templates/c++/asd-voidreply:0:expand */
        /*
        templates/c++/enum-field-definer@enum-field:0:expand */
        F,/*
        templates/c++/enum-field-definer@enum-field:0:expand */
        T
      };
    };
#endif // ENUM_foo_I_Bool

    /*
    templates/c++/variable-member-declare@variable:0:expand */
    ::inner::foo::I::Bool::type inner_state;
    /*
    templates/c++/variable-member-declare@variable:0:expand */
    ::foo::I::Bool::type foo_state;

    /*
    templates/c++/reply-member-declare@enum:0:expand */
    ::inner::foo::I::Bool::type reply_inner_foo_I_Bool;
    /*
    templates/c++/reply-member-declare@enum:0:expand */
    ::foo::I::Bool::type reply_foo_I_Bool;

    /*
    templates/c++/out-binding-lambda@port:0:expand */
    std::function<void ()> out_inner;
    /*
    templates/c++/out-binding-lambda@port:0:expand */
    std::function<void ()> out_fooi;

    /*
    templates/c++/provided-port-declare@port:0:expand */
    ::inner::foo::I inner;
    /*
    templates/c++/provided-port-declare@port:0:expand */
    ::foo::I fooi;

    /*
    templates/c++/required-port-declare:0:expand */

    /*
    templates/c++/async-port-declare:0:expand */

    /*
    templates/c++/model-name:0:expand */
    space(const dzn::locator&);
    void check_bindings() const;
    void dump_tree(std::ostream& os) const;
    friend std::ostream& operator << (std::ostream& os, const /*
    templates/c++/model-name:0:expand */
    space& m)  {
      (void)m;
      return os << "[" << /*
      templates/c++/stream-member@variable:0:expand */
      m.inner_state <<", " << /*
      templates/c++/stream-member@variable:0:expand */
      m.foo_state <<"]" ;
    }
    private:
    /*
    templates/c++/method-declare@on:0:expand */
    /*
    templates/c++/declare-method@trigger:0:expand */
    /*
    templates/c++/return-type@type:0:expand */
    ::inner::foo::I::Bool::type inner_e (/*
    templates/c++/formals:0:expand */
    );
    /*
    templates/c++/method-declare@on:0:expand */
    /*
    templates/c++/declare-method@trigger:0:expand */
    /*
    templates/c++/return-type@type:0:expand */
    ::foo::I::Bool::type fooi_e (/*
    templates/c++/formals:0:expand */
    );

    /*
    templates/c++/function-declare:0:expand */
  };
}

// #endif // /*
templates/c++/upcase-model-name:0:expand */
INNER_SPACE_HH
////////////////////////////////////////////////////////////////////////////////
/*
templates/c++/header@component:0:expand */
// #ifndef /*
templates/c++/upcase-model-name:0:expand */
BAR_C_HH
// #define /*
templates/c++/upcase-model-name:0:expand */
BAR_C_HH

#include <iostream>

/*
templates/c++/interface-include@file-name:0:expand */
#include "inner_space.hh"


namespace dzn {
  struct locator;
  struct runtime;
}

namespace bar {
  struct /*
  templates/c++/model-name:0:expand */
  c
  {
    dzn::meta dzn_meta;
    dzn::runtime& dzn_rt;
    dzn::locator const& dzn_locator;
    /*
    templates/c++/enum-definer@enum:0:expand */
#ifndef ENUM_foo_I_Bool
#define ENUM_foo_I_Bool 1
    struct Bool
    {
      enum type
      {
        /*
        templates/c++/asd-voidreply:0:expand */
        /*
        templates/c++/enum-field-definer@enum-field:0:expand */
        F,/*
        templates/c++/enum-field-definer@enum-field:0:expand */
        T
      };
    };
#endif // ENUM_foo_I_Bool

    /*
    templates/c++/variable-member-declare@variable:0:expand */
    ::foo::I::Bool::type state;

    /*
    templates/c++/reply-member-declare@enum:0:expand */
    ::foo::I::Bool::type reply_foo_I_Bool;

    /*
    templates/c++/out-binding-lambda@port:0:expand */
    std::function<void ()> out_i;

    /*
    templates/c++/provided-port-declare@port:0:expand */
    ::foo::I i;

    /*
    templates/c++/required-port-declare:0:expand */

    /*
    templates/c++/async-port-declare:0:expand */

    /*
    templates/c++/model-name:0:expand */
    c(const dzn::locator&);
    void check_bindings() const;
    void dump_tree(std::ostream& os) const;
    friend std::ostream& operator << (std::ostream& os, const /*
    templates/c++/model-name:0:expand */
    c& m)  {
      (void)m;
      return os << "[" << /*
      templates/c++/stream-member@variable:0:expand */
      m.state <<"]" ;
    }
    private:
    /*
    templates/c++/method-declare@on:0:expand */
    /*
    templates/c++/declare-method@trigger:0:expand */
    /*
    templates/c++/return-type@type:0:expand */
    ::foo::I::Bool::type i_e (/*
    templates/c++/formals:0:expand */
    );

    /*
    templates/c++/function-declare:0:expand */
  };
}

// #endif // /*
templates/c++/upcase-model-name:0:expand */
BAR_C_HH
////////////////////////////////////////////////////////////////////////////////

#endif // INTERFACE_ONLY
#endif // inner_space_HH
