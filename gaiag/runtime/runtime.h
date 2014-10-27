// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#ifndef RUNTIME_H
#define RUNTIME_H

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
  using boost::bind;
  using boost::function;

  struct runtime
  {
    std::map<void*, std::pair<bool, std::queue<function<void()> > > > queues;

    bool& handling(void*);
    void flush(void*);
    void defer(void*, const function<void()>&);
    void handle_event(void*, const function<void()>&);

    template <typename R, bool checked>
    inline R valued_helper(void* scope, const function<R()>& event)
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
  inline function<R()> connect(runtime& rt, void* scope, const function<R()>& event)
  {
    return bind(&runtime::valued_helper<R,true>, &rt, scope, event);
  }
  template <>
  inline function<void()> connect<void>(runtime& rt, void* scope, const function<void()>& event)
  {
    return bind(&runtime::handle_event, &rt, scope, event);
  }


#define DREF(N,i,a) dref(a ## i)
#define PLACE(N,i,a) BOOST_PP_CAT(a,BOOST_PP_ADD(i,1))

#define BOOST_PP_LOCAL_MACRO(N) \
  template <typename R BOOST_PP_ENUM_TRAILING_PARAMS(N,typename A)> \
    R handle_event_closure(runtime& rt, void* scope, const function<R(BOOST_PP_ENUM_PARAMS(N,A))>& e BOOST_PP_ENUM_TRAILING_BINARY_PARAMS(N,A,a)) \
  { \
    return rt.valued_helper<R,false>(scope, function<R()>(bind(e BOOST_PP_ENUM_TRAILING(N,DREF,a)))); \
  } \
  template <typename R BOOST_PP_ENUM_TRAILING_PARAMS(N,typename A)>                       \
  function<R(BOOST_PP_ENUM_PARAMS(N,A))> connect(runtime& rt, void* scope, const function<R(BOOST_PP_ENUM_PARAMS(N,A))>& event) \
  { \
    return bind(handle_event_closure<R BOOST_PP_ENUM_TRAILING_PARAMS(N,A)>, ref(rt), scope, event BOOST_PP_ENUM_TRAILING(N,PLACE,_)); \
  } \

#define BOOST_PP_LOCAL_LIMITS (1,6)
#include BOOST_PP_LOCAL_ITERATE()

#define BOOST_PP_LOCAL_MACRO(N) \
  template <BOOST_PP_ENUM_PARAMS(N,typename A)> \
  void handle_event_closure(runtime& rt, void* scope, const function<void(BOOST_PP_ENUM_PARAMS(N,A))>& e BOOST_PP_ENUM_TRAILING_BINARY_PARAMS(N,A,a)) \
  { \
    rt.handle_event(scope, function<void()>(bind(e, BOOST_PP_ENUM(N,DREF,a)))); \
  } \
  template <BOOST_PP_ENUM_PARAMS(N,typename A)> \
  function<void(BOOST_PP_ENUM_PARAMS(N,A))> connect(runtime& rt, void* scope, const function<void(BOOST_PP_ENUM_PARAMS(N,A))>& event) \
  { \
    return bind(handle_event_closure<BOOST_PP_ENUM_PARAMS(N,A)>, ref(rt), scope, event BOOST_PP_ENUM_TRAILING(N,PLACE,_)); \
  } \

#define BOOST_PP_LOCAL_LIMITS (1,6)
#include BOOST_PP_LOCAL_ITERATE()

#undef DREF
#undef PLACE
}
#endif
