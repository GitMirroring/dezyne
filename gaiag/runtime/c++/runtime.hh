// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "meta.hh"
#include "locator.hh"

//haX0r here
#include "pump.hh"  //TODO: put this include in every component which uses the blocking keyword in its behaviour.

#include <algorithm>
#include <cassert>
#include <iostream>
#include <map>
#include <queue>
#include <tuple>

namespace dezyne
{
void trace_in(std::ostream&, port::meta const&, const char*);
void trace_out(std::ostream&, port::meta const&, const char*);

inline void apply(const dezyne::meta* m, const std::function<void(const dezyne::meta*)>& f)
{
  f(m);
  for (auto c : m->children)
  {
    apply(c, f);
  }
}

inline void check_bindings(const dezyne::meta* c)
{
  apply(c, [](const dezyne::meta* m){
      std::for_each(m->ports_connected.begin(), m->ports_connected.end(), [](const std::function<void()>& p){p();});
    });
}

inline void dump_tree(std::ostream& os, const dezyne::meta* c)
{
  apply(c, [&](const dezyne::meta* m){
      os << path(m) << ":" << m->type << std::endl;
    });
}

struct runtime
{
  std::map<void*, std::tuple<bool, void*, std::queue<std::function<void()> >, bool> > queues;

  bool external(void*);
  bool& handling(void*);
  void*& deferred(void*);
  std::queue<std::function<void()> >& queue(void*);
  bool& performs_flush(void* scope);
  void flush(void*);
  void defer(void*, void*, const std::function<void()>&);
  void handle(void*, const std::function<void()>&); // trace_data const&);

  template <typename R>
  inline R valued_helper(void* scope, const std::function<R()>& event)
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

template <typename F, typename ... Args>
void shell(dezyne::pump& pump, F&& f, Args&& ...args)
{
  return pump.and_wait([&]{return f(std::forward<Args>(args)...);});
}

template <typename R, typename F, typename ... Args>
R valued_shell(dezyne::pump& pump, F&& f, Args&& ...args)
{
  return pump.and_wait<R>([&]{return f(std::forward<Args>(args)...);});
}

template <typename C, typename P>
void call_in(C* c, std::function<void()> f, std::tuple<P*, const char*, const char*> m)
{
  auto& os = c->dzn_locator.template get<typename std::ostream>();
  trace_in(os, std::get<0>(m)->meta, std::get<1>(m));
  c->dzn_rt.handle(c, f);
  trace_out(os, std::get<0>(m)->meta, std::get<2>(m) ? std::get<2>(m) : "return");
}

template <typename R, typename C, typename P>
R call_in(C* c, std::function<R()> f, std::tuple<P*, const char*, const char*> m)
{
  auto& os = c->dzn_locator.template get<typename std::ostream>();
  trace_in(os, std::get<0>(m)->meta, std::get<1>(m));
  auto r = c->dzn_rt.valued_helper(c, f);
  trace_out(os, std::get<0>(m)->meta, to_string (r));
  return r;
}

template <typename C, typename P>
void call_out(C* c, std::function<void()> f, std::tuple<P*, const char*, const char*> m)
{
  auto& os = c->dzn_locator.template get<typename std::ostream>();
  trace_out(os, std::get<0>(m)->meta, std::get<1>(m));
  c->dzn_rt.defer(std::get<0>(m)->meta.provides.address, c, f);
}
}
#endif
