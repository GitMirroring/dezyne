// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DEZYNE_RUNTIME_HH
#define DEZYNE_RUNTIME_HH

#include "meta.hh"
#include "locator.hh"

#include "pump.hh"

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
  template <typename L, typename = typename std::enable_if<std::is_void<typename std::result_of<L()>::type>::value>::type>
  void handle(void* scope, L&& l)
  {
    bool& handle = handling(scope);
    if(handle) throw std::logic_error("component already handling an event");
    {scoped_value<bool> sv(handle, true);
      l();}
    flush(scope);
  }
  template <typename L, typename = typename std::enable_if<!std::is_void<typename std::result_of<L()>::type>::value>::type>
  inline auto handle(void* scope, L&& l) -> decltype(l())
  {
    bool& handle = handling(scope);
    if(handle) throw std::logic_error("component already handling an event");
    decltype(l()) r;
    {scoped_value<bool> sv(handle, true);
      r = l();}
    flush(scope);
    return r;
  }
  runtime();
private:
  runtime(const runtime&);
  runtime& operator = (const runtime&);
};

template <typename F, typename ... Args>
auto shell(dezyne::pump& pump, F&& f, Args&& ...args) -> decltype(f())
{
  return pump.and_wait(std::bind(f,std::forward<Args>(args)...));
}

template <typename C>
struct call_helper
{
  C* c;
  std::ostream& os;
  const dezyne::port::meta& meta;
  const char* event;
  std::string reply;
  call_helper(C* c, const dezyne::port::meta& meta, const char* event)
  : c(c)
  , os(c->dzn_locator.template get<typename std::ostream>())
  , meta(meta)
  , event(event)
  , reply("return")
  {
    trace_in(os, meta, event);
    if(c->dzn_rt.handling(c))
    {
      c->dzn_locator.template get<dezyne::pump>().collateral_block();
    }
  }
  template <typename L, typename = typename std::enable_if<std::is_void<typename std::result_of<L()>::type>::value>::type>
  void operator()(L&& l)
  {
    c->dzn_rt.handle(c, l);
  }
  template <typename L, typename = typename std::enable_if<!std::is_void<typename std::result_of<L()>::type>::value>::type>
  auto operator()(L&& l) -> decltype(l())
  {
    auto r = c->dzn_rt.handle(c, l);
    reply = to_string(r);
    return r;
  }
#if BOOL_FOO
  template <typename L, typename = typename std::enable_if<std::is_integral<typename std::result_of<L()>>>
  auto operator()(L&& l) -> decltype(l())
  {
    auto r = c->dzn_rt.handle(c, l);
    reply = to_string(r);
    return r;
  }
#endif
  inline char const* to_string(bool b){return b ? "true" : "false";}
  inline bool to__bool(std::string s){return s == "true";}
  ~call_helper()
  {
    trace_out(os, meta, reply.c_str());
  }
};

template <typename C, typename L>
auto call_in(C* c, L&& l, const dezyne::port::meta& meta, const char* event) -> decltype(l())
{
  call_helper<C> helper(c, meta, event);
  return helper(l);
}

template <typename C, typename L>
void call_out(C* c, L&& l, const dezyne::port::meta& meta, const char* event)
{
  auto& os = c->dzn_locator.template get<typename std::ostream>();
  trace_out(os, meta, event);
  c->dzn_rt.defer(meta.provides.address, c, l);
}
}
#endif //DEZYNE_RUNTIME_HH
