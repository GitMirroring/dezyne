// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#ifndef RUNTIME_HH
#define RUNTIME_HH

#include <boost/bind.hpp>
#include <boost/bind/placeholders.hpp>
#include <boost/function.hpp>
#include <boost/function_types/function_type.hpp>
#include <boost/function_types/parameter_types.hpp>
#include <boost/function_types/function_arity.hpp>
#include <boost/preprocessor.hpp>

#include <map>
#include <queue>

namespace dezyne
{
  template <typename T>
  void trace(const T& t, const char* e)
  {
    std::clog << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << e << " -> " << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << e << std::endl;
  }

  template <typename T>
  void trace_return(const T& t, const char* e)
  {
    std::clog << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << e << " -> " << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << e << std::endl ;
  }

  struct component;

  struct meta
  {
    std::vector<const component*> children;
    const component* parent;
    const component* address;
    const char* name;
  };

  struct component
  {
    dezyne::meta meta;
  };

  template <typename T>
  void apply(const T* t, const std::function<void(const dezyne::meta&)>& f)
  {
    f(t->meta);
    for (auto c : t->meta.children)
    {
      apply(c, f);
    }
  }

  struct runtime
  {
    std::map<void*, std::pair<bool, std::queue<boost::function<void()> > > > queues;

    bool& handling(void*);
    void flush(void*);
    void defer(void*, const boost::function<void()>&);
    void handle_event(void*, const boost::function<void()>&);

    template <typename R, bool checked>
    inline R valued_helper(void* scope, const boost::function<R()>& event)
    {
      bool& handle = handling(scope);
      if(checked and handle) throw std::logic_error("a valued event cannot be deferred");

      runtime::scoped_value<bool> sv(handle, true);
      R tmp = event();
      if(not sv.initial)
      {
        flush(scope);
      }
      return tmp;
    }

    template <typename T>
    struct scoped_value
    {
      T& current;
      T initial;
      scoped_value(T& current, T value)
      : current(current)
      , initial(current)
      { current = value; }
      ~scoped_value()
      {
        current = initial;
      }
    };
    runtime();
  private:
    runtime(const runtime&);
    runtime& operator = (const runtime&);
  };

  using boost::ref;

  template <typename T>
  boost::reference_wrapper<T> dref(T& t)
  {
    return boost::ref(t);
  }
  template <typename T>
  boost::reference_wrapper<const T> dref(const T& t)
  {
    return boost::cref(t);
  }

  template <typename R>
  inline boost::function<R()> connect(runtime& rt, void* scope, const boost::function<R()>& event)
  {
    return boost::bind(&runtime::valued_helper<R,true>, &rt, scope, event);
  }
  template <>
  inline boost::function<void()> connect<void>(runtime& rt, void* scope, const boost::function<void()>& event)
  {
    return boost::bind(&runtime::handle_event, &rt, scope, event);
  }


#define DREF(N,i,a) dref(a ## i)
#define PLACE(N,i,a) BOOST_PP_CAT(a,BOOST_PP_ADD(i,1))

#define BOOST_PP_LOCAL_MACRO(N) \
  template <typename R BOOST_PP_ENUM_TRAILING_PARAMS(N,typename A)> \
    R handle_event_closure(runtime& rt, void* scope, const boost::function<R(BOOST_PP_ENUM_PARAMS(N,A))>& e BOOST_PP_ENUM_TRAILING_BINARY_PARAMS(N,A,a)) \
  { \
    return rt.valued_helper<R,false>(scope, boost::function<R()>(boost::bind(e BOOST_PP_ENUM_TRAILING(N,DREF,a)))); \
  } \
  template <typename R BOOST_PP_ENUM_TRAILING_PARAMS(N,typename A)>                       \
  boost::function<R(BOOST_PP_ENUM_PARAMS(N,A))> connect(runtime& rt, void* scope, const boost::function<R(BOOST_PP_ENUM_PARAMS(N,A))>& event) \
  { \
    return boost::bind(handle_event_closure<R BOOST_PP_ENUM_TRAILING_PARAMS(N,A)>, ref(rt), scope, event BOOST_PP_ENUM_TRAILING(N,PLACE,_)); \
  } \

#define BOOST_PP_LOCAL_LIMITS (1,6)
#include BOOST_PP_LOCAL_ITERATE()

#define BOOST_PP_LOCAL_MACRO(N) \
  template <BOOST_PP_ENUM_PARAMS(N,typename A)> \
  void handle_event_closure(runtime& rt, void* scope, const boost::function<void(BOOST_PP_ENUM_PARAMS(N,A))>& e BOOST_PP_ENUM_TRAILING_BINARY_PARAMS(N,A,a)) \
  { \
    rt.handle_event(scope, boost::function<void()>(boost::bind(e, BOOST_PP_ENUM(N,DREF,a)))); \
  } \
  template <BOOST_PP_ENUM_PARAMS(N,typename A)> \
  boost::function<void(BOOST_PP_ENUM_PARAMS(N,A))> connect(runtime& rt, void* scope, const boost::function<void(BOOST_PP_ENUM_PARAMS(N,A))>& event) \
  { \
    return boost::bind(handle_event_closure<BOOST_PP_ENUM_PARAMS(N,A)>, ref(rt), scope, event BOOST_PP_ENUM_TRAILING(N,PLACE,_)); \
  } \

#define BOOST_PP_LOCAL_LIMITS (1,6)
#include BOOST_PP_LOCAL_ITERATE()

#undef DREF
#undef PLACE
}
#endif
