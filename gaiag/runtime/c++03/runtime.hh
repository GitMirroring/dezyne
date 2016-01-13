// Dezyne --- Dezyne command line tools
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "meta.hh"
#include "locator.hh"

#include <boost/tuple/tuple.hpp>

#include <algorithm>
#include <cassert>
#include <iostream>
#include <map>
#include <queue>

inline char const* to_string(bool b){return b ? "true" : "false";}
inline bool to__bool(std::string s){return s == "true";}

namespace dezyne
{
  void trace_in(std::ostream&, port::meta const&, const char*);
  void trace_out(std::ostream&, port::meta const&, const char*);

  inline void apply(const meta* m, const boost::function<void(const meta*)>& f)
  {
    f(m);
    for(std::vector<const meta*>::const_iterator c = m->children.begin(); c != m->children.end(); ++c)
    {
      apply(*c, f);
    }
  }

  inline void check_bindings_helper(const meta* m)
  {
    for(std::vector<boost::function<void()> >::const_iterator p = m->ports_connected.begin(); p != m->ports_connected.end(); ++p)
    {
      p->operator()();
    }
  }

  inline void check_bindings(const meta* m)
  {
    dezyne::apply(m, check_bindings_helper);
  }

  inline void dump_tree_helper(const meta* m)
  {
    std::clog << path(m) << ":" << m->type << std::endl;
  }

  inline void dump_tree(const meta* m)
  {
    dezyne::apply(m, dump_tree_helper);
  }

  struct runtime
  {
    std::map<void*, boost::tuple<bool, void*, std::queue<boost::function<void()> >, bool> > queues;

    bool external(void*);
    bool& handling(void*);
    void*& deferred(void*);
    std::queue<boost::function<void()> >& queue(void*);
    bool& performs_flush(void* scope);
    void flush(void*);
    void defer(void*, void*, const boost::function<void()>&);
    void handle(void*, const boost::function<void()>&); // trace_data const&);

    template <typename R>
    R valued_helper(void* scope, const boost::function<R()>& event)
    {
      bool& handle = handling(scope);
      if(handle) throw std::logic_error("a valued event cannot be deferred");
      R tmp;
      {
        runtime::scoped_value<bool> sv(handle, true);
        tmp = event();
      }
      flush(scope);
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

  template <typename T>
  boost::reference_wrapper<typename boost::remove_reference<T>::type> ref(T& t)
  {
    return boost::ref(t);
  }
  template <typename T>
  boost::reference_wrapper<typename boost::remove_reference<const T>::type> ref(const T& t)
  {
    return boost::cref(t);
  }
  template <typename C, typename P>
  void call_in(C* c, boost::function<void()> f, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, f);
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }
  template <typename C, typename P, typename A0>
  void call_in(C* c, boost::function<void(A0)> f, A0 a0, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, boost::bind(f, ref(a0)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }
  template <typename C, typename P, typename A0, typename A1>
  void call_in(C* c, boost::function<void(A0,A1)> f, A0 a0, A1 a1, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, boost::bind(f, ref(a0), ref(a1)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }
  template <typename C, typename P, typename A0, typename A1, typename A2>
  void call_in(C* c, boost::function<void(A0,A1,A2)> f, A0 a0, A1 a1, A2 a2, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, boost::bind(f, ref(a0), ref(a1), ref(a2)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }
  template <typename C, typename P, typename A0, typename A1, typename A2, typename A3>
  void call_in(C* c, boost::function<void(A0,A1,A2,A3)> f, A0 a0, A1 a1, A2 a2, A3 a3, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, boost::bind(f, ref(a0), ref(a1), ref(a2), ref(a3)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }
  template <typename C, typename P, typename A0, typename A1, typename A2, typename A3, typename A4>
  void call_in(C* c, boost::function<void(A0,A1,A2,A3,A4)> f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, boost::bind(f, ref(a0), ref(a1), ref(a2), ref(a3), ref(a4)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }
  template <typename C, typename P, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5>
  void call_in(C* c, boost::function<void(A0,A1,A2,A3,A4,A5)> f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, boost::bind(f, ref(a0), ref(a1), ref(a2), ref(a3), ref(a4), ref(a5)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }


  template <typename R, typename C, typename P>
  R rcall_in(C* c, boost::function<R()> f, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, f);
    trace_out(os, boost::get<0>(m)->meta, to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0>
  R rcall_in(C* c, boost::function<R(A0)> f, A0 a0, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, ref(a0))));
    trace_out(os, boost::get<0>(m)->meta, to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0, typename A1>
  R rcall_in(C* c, boost::function<R(A0,A1)> f, A0 a0, A1 a1, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, ref(a0), ref(a1))));
    trace_out(os, boost::get<0>(m)->meta, to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0, typename A1, typename A2>
  R rcall_in(C* c, boost::function<R(A0,A1,A2)> f, A0 a0, A1 a1, A2 a2, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, ref(a0), ref(a1), ref(a2))));
    trace_out(os, boost::get<0>(m)->meta, to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0, typename A1, typename A2, typename A3>
  R rcall_in(C* c, boost::function<R(A0,A1,A2,A3)> f, A0 a0, A1 a1, A2 a2, A3 a3, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, ref(a0), ref(a1), ref(a2), ref(a3))));
    trace_out(os, boost::get<0>(m)->meta, to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0, typename A1, typename A2, typename A3, typename A4>
  R rcall_in(C* c, boost::function<R(A0,A1,A2,A3,A4)> f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, ref(a0), ref(a1), ref(a2), ref(a3), ref(a4))));
    trace_out(os, boost::get<0>(m)->meta, to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5>
  R rcall_in(C* c, boost::function<R(A0,A1,A2,A3,A4,A5)> f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, ref(a0), ref(a1), ref(a2), ref(a3), ref(a4), ref(a5))));
    trace_out(os, boost::get<0>(m)->meta, to_string (r));
    return r;
  }


  template <typename C, typename P>
  void call_out(C* c, boost::function<void()> f, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_out(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.defer(boost::get<0>(m)->meta.provides.address, c, f);
  }
  template <typename C, typename P, typename A0>
  void call_out(C* c, boost::function<void(A0)> f, A0 a0, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_out(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.defer(boost::get<0>(m)->meta.provides.address, c, boost::bind(f, a0));
  }
  template <typename C, typename P, typename A0, typename A1>
  void call_out(C* c, boost::function<void(A0,A1)> f, A0 a0, A1 a1, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_out(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.defer(boost::get<0>(m)->meta.provides.address, c, boost::bind(f, a0, a1));
  }
  template <typename C, typename P, typename A0, typename A1, typename A2>
  void call_out(C* c, boost::function<void(A0,A1,A2)> f, A0 a0, A1 a1, A2 a2, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_out(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.defer(boost::get<0>(m)->meta.provides.address, c, boost::bind(f, a0, a1, a2));
  }
  template <typename C, typename P, typename A0, typename A1, typename A2, typename A3>
  void call_out(C* c, boost::function<void(A0,A1,A2,A3)> f, A0 a0, A1 a1, A2 a2, A3 a3, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_out(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.defer(boost::get<0>(m)->meta.provides.address, c, boost::bind(f, a0, a1, a2, a3));
  }
  template <typename C, typename P, typename A0, typename A1, typename A2, typename A3, typename A4>
  void call_out(C* c, boost::function<void(A0,A1,A2,A3,A4)> f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_out(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.defer(boost::get<0>(m)->meta.provides.address, c, boost::bind(f, a0, a1, a2, a3, a4));
  }
  template <typename C, typename P, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5>
  void call_out(C* c, boost::function<void(A0,A1,A2,A3,A4,A5)> f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_out(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.defer(boost::get<0>(m)->meta.provides.address, c, boost::bind(f, a0, a1, a2, a3, a4, a5));
  }
}
#endif
