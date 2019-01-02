// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016, 2017, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
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

#include <dzn/meta.hh>
#include <dzn/locator.hh>

#include <boost/bind.hpp>
#include <boost/tuple/tuple.hpp>

#include <algorithm>
#include <cassert>
#include <iostream>
#include <map>
#include <queue>
#include <sstream>

inline std::string to_string(bool b){return b ? "true" : "false";}
inline std::string to_string(int i){std::stringstream ss; ss << i; return ss.str();}

namespace dzn
{
  class vector: public std::vector<const port::meta*>
  {
  public:
    vector& operator()(const port::meta* m)
    {
      push_back(m);
      return *this;
    }
  };

  class assign
  {
    std::vector<boost::function<void()> > _;
    template <typename LHS, typename RHS>
    static void helper(LHS& lhs, const RHS& rhs)
    {
      lhs = rhs;
    }
  public:
    template <typename LHS, typename RHS>
    assign& operator()(LHS& lhs, const RHS& rhs)
    {
      _.push_back(boost::bind(&assign::helper<LHS,RHS>, boost::ref(lhs), boost::cref(rhs)));
      return *this;
    }
    void operator()()
    {
      for(std::vector<boost::function<void()> >::const_iterator it = _.begin(); it != _.end(); ++it) (*it)();
    }
  };

  void trace_in(std::ostream&, port::meta const&, const std::string&);
  void trace_out(std::ostream&, port::meta const&, const std::string&);

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
    dzn::apply(m, check_bindings_helper);
  }

  inline void dump_tree_helper(std::ostream& os,  const meta* m)
  {
    os << path(m) << ":" << m->type << std::endl;
  }

  inline void dump_tree(std::ostream& os, const meta* m)
  {
    dzn::apply(m, boost::bind(dump_tree_helper, boost::ref(os), _1));
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

  void collateral_block(const locator&);
  void port_block(const locator&, void*);
  void port_release(const locator&, void*, boost::function<void()>&);

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
    c->dzn_rt.handle(c, boost::bind(f, boost::ref(a0)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }
  template <typename C, typename P, typename A0, typename A1>
  void call_in(C* c, boost::function<void(A0,A1)> f, A0 a0, A1 a1, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, boost::bind(f, boost::ref(a0), boost::ref(a1)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }
  template <typename C, typename P, typename A0, typename A1, typename A2>
  void call_in(C* c, boost::function<void(A0,A1,A2)> f, A0 a0, A1 a1, A2 a2, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, boost::bind(f, boost::ref(a0), boost::ref(a1), boost::ref(a2)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }
  template <typename C, typename P, typename A0, typename A1, typename A2, typename A3>
  void call_in(C* c, boost::function<void(A0,A1,A2,A3)> f, A0 a0, A1 a1, A2 a2, A3 a3, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, boost::bind(f, boost::ref(a0), boost::ref(a1), boost::ref(a2), boost::ref(a3)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }
  template <typename C, typename P, typename A0, typename A1, typename A2, typename A3, typename A4>
  void call_in(C* c, boost::function<void(A0,A1,A2,A3,A4)> f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, boost::bind(f, boost::ref(a0), boost::ref(a1), boost::ref(a2), boost::ref(a3), boost::ref(a4)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }
  template <typename C, typename P, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5>
  void call_in(C* c, boost::function<void(A0,A1,A2,A3,A4,A5)> f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    c->dzn_rt.handle(c, boost::bind(f, boost::ref(a0), boost::ref(a1), boost::ref(a2), boost::ref(a3), boost::ref(a4), boost::ref(a5)));
    trace_out(os, boost::get<0>(m)->meta, boost::get<2>(m) ? boost::get<2>(m) : "return");
  }


  template <typename R, typename C, typename P>
  R rcall_in(C* c, boost::function<R()> f, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, f);
    trace_out(os, boost::get<0>(m)->meta, ::to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0>
  R rcall_in(C* c, boost::function<R(A0)> f, A0 a0, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, boost::ref(a0))));
    trace_out(os, boost::get<0>(m)->meta, ::to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0, typename A1>
  R rcall_in(C* c, boost::function<R(A0,A1)> f, A0 a0, A1 a1, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, boost::ref(a0), boost::ref(a1))));
    trace_out(os, boost::get<0>(m)->meta, ::to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0, typename A1, typename A2>
  R rcall_in(C* c, boost::function<R(A0,A1,A2)> f, A0 a0, A1 a1, A2 a2, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, boost::ref(a0), boost::ref(a1), boost::ref(a2))));
    trace_out(os, boost::get<0>(m)->meta, ::to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0, typename A1, typename A2, typename A3>
  R rcall_in(C* c, boost::function<R(A0,A1,A2,A3)> f, A0 a0, A1 a1, A2 a2, A3 a3, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, boost::ref(a0), boost::ref(a1), boost::ref(a2), boost::ref(a3))));
    trace_out(os, boost::get<0>(m)->meta, ::to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0, typename A1, typename A2, typename A3, typename A4>
  R rcall_in(C* c, boost::function<R(A0,A1,A2,A3,A4)> f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, boost::ref(a0), boost::ref(a1), boost::ref(a2), boost::ref(a3), boost::ref(a4))));
    trace_out(os, boost::get<0>(m)->meta, ::to_string (r));
    return r;
  }
  template <typename R, typename C, typename P, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5>
  R rcall_in(C* c, boost::function<R(A0,A1,A2,A3,A4,A5)> f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, boost::tuple<P*, const char*, const char*> m)
  {
    std::ostream& os = c->dzn_locator.template get<typename std::ostream>();
    trace_in(os, boost::get<0>(m)->meta, boost::get<1>(m));
    R r = c->dzn_rt.valued_helper(c, boost::function<R()>(boost::bind(f, boost::ref(a0), boost::ref(a1), boost::ref(a2), boost::ref(a3), boost::ref(a4), boost::ref(a5))));
    trace_out(os, boost::get<0>(m)->meta, ::to_string (r));
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

  void call_async_helper(const locator&, const meta&, size_t, const boost::function<void()>& f, const boost::function<void()>& g);

  template <typename C>
  void call_async(C* c, void* id, const boost::function<void()>& f)
  {
    call_async_helper(c->dzn_locator, c->dzn_meta, reinterpret_cast<size_t>(id), boost::bind(f), boost::bind(&runtime::flush, &c->dzn_rt, c));
  }
  template <typename C, typename A0>
  void call_async(C* c, void* id, const boost::function<void(A0)>& f, A0 a0)
  {
    call_async_helper(c->dzn_locator, c->dzn_meta, reinterpret_cast<size_t>(id), boost::bind(f, a0), boost::bind(&runtime::flush, &c->dzn_rt, c));
  }
  template <typename C, typename A0, typename A1>
  void call_async(C* c, void* id, const boost::function<void(A0, A1)>& f, A0 a0, A1 a1)
  {
    call_async_helper(c->dzn_locator, c->dzn_meta, reinterpret_cast<size_t>(id), boost::bind(f, a0, a1), boost::bind(&runtime::flush, &c->dzn_rt, c));
  }
  template <typename C, typename A0, typename A1, typename A2>
  void call_async(C* c, void* id, const boost::function<void(A0, A1, A2)>& f, A0 a0, A1 a1, A2 a2)
  {
    call_async_helper(c->dzn_locator, c->dzn_meta, reinterpret_cast<size_t>(id), boost::bind(f, a0, a1, a2), boost::bind(&runtime::flush, &c->dzn_rt, c));
  }
  template <typename C, typename A0, typename A1, typename A2, typename A3>
  void call_async(C* c, void* id, const boost::function<void(A0, A1, A2, A3)>& f, A0 a0, A1 a1, A2 a2, A3 a3)
  {
    call_async_helper(c->dzn_locator, c->dzn_meta, reinterpret_cast<size_t>(id), boost::bind(f, a0, a1, a2, a3), boost::bind(&runtime::flush, &c->dzn_rt, c));
  }
  template <typename C, typename A0, typename A1, typename A2, typename A3, typename A4>
  void call_async(C* c, void* id, const boost::function<void(A0, A1, A2, A3, A4)>& f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4)
  {
    call_async_helper(c->dzn_locator, c->dzn_meta, reinterpret_cast<size_t>(id), boost::bind(f, a0, a1, a2, a3, a4), boost::bind(&runtime::flush, &c->dzn_rt, c));
  }
  template <typename C, typename A0, typename A1, typename A2, typename A3, typename A4, typename A5>
  void call_async(C* c, void* id, const boost::function<void(A0, A1, A2, A3, A4, A5)>& f, A0 a0, A1 a1, A2 a2, A3 a3, A4 a4, A5 a5)
  {
    call_async_helper(c->dzn_locator, c->dzn_meta, reinterpret_cast<size_t>(id), boost::bind(f, a0, a1, a2, a3, a4, a5), boost::bind(&runtime::flush, &c->dzn_rt, c));
  }
}
#endif
