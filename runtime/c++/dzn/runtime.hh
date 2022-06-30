// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2017, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Rob Wieringa <rma.wieringa@gmail.com>
// Copyright © 2016 Henk Katerberg <hank@mudball.nl>
// Copyright © 2016, 2017, 2018, 2019, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
//
// This file is part of dzn-runtime.
//
// dzn-runtime is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// dzn-runtime is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with dzn-runtime.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#ifndef DZN_RUNTIME_HH
#define DZN_RUNTIME_HH

#include <dzn/meta.hh>
#include <dzn/locator.hh>
#include <dzn/coroutine.hh>
#include <algorithm>
#include <iostream>
#include <map>
#include <queue>
#include <tuple>
#include <vector>

// Set to 1 for tracing of internal async events
#ifndef DZN_ASYNC_TRACING
#define DZN_ASYNC_TRACING 0
#endif

// Set to 1 for experimental state tracing feature.
#ifndef DZN_STATE_TRACING
#define DZN_STATE_TRACING 0
#endif

inline std::string to_string(bool b){return b ? "true" : "false";}
inline std::string to_string(int i){return std::to_string(i);}

namespace dzn
{
  extern std::ostream debug;

  inline std::string component_to_string(void* c)
  {
    return c ? reinterpret_cast<component*>(c)->dzn_meta.name : "<external>";
  }

  void trace_qin(std::ostream&, port::meta const&, const char*);
  void trace_qout(std::ostream&, port::meta const&, const char*);

  void trace(std::ostream&, port::meta const&, const char*);
  void trace_out(std::ostream&, port::meta const&, const char*);

  inline void apply(const dzn::meta* m, const std::function<void(const dzn::meta*)>& f)
  {
    f(m);
    for (auto c : m->children)
    {
      apply(c, f);
    }
  }

  inline void check_bindings(const dzn::meta* c)
  {
    apply(c, [](const dzn::meta* m){
        std::for_each(m->ports_connected.begin(), m->ports_connected.end(), [](const std::function<void()>& p){p();});
      });
  }

  inline void dump_tree(std::ostream& os, const dzn::meta* c)
  {
    apply(c, [&](const dzn::meta* m){
        os << path(m) << ":" << m->type << std::endl;
      });
  }

  // implemented conditionally in pump.cc
  void collateral_block(void*, const locator&);
  bool port_blocked_p(const locator&, void* port);
  void port_block(const locator&, void* component, void* port);
  void port_release(const locator&, void*, std::function<void()>&);
  size_t coroutine_id(const locator&);

  struct runtime
  {
    runtime(const runtime&) = delete;
    runtime(runtime&&) = delete;
    struct state
    {
      size_t handling;
      bool performs_flush;
      void* deferred;
      std::queue<std::function<void()>> queue;
    };
    std::map<void*, state> states;
    std::map<void*, bool> skip_port;
    std::vector<void*> component_stack;
    std::map<size_t, std::vector<void*>> blocked_port_component_stack;
    bool& skip_block(void*);


    bool external(void*);
    size_t& handling(void*);
    void*& deferred(void*);
    std::queue<std::function<void()> >& queue(void*);
    bool& performs_flush(void* scope);
    template <typename T>
    void flush(T* t)
    {
      flush(t, coroutine_id(t->dzn_locator));
    }
    void flush(void*, size_t);
    void defer(void*, void*, const std::function<void()>&, size_t);
    template <typename F, typename = typename std::enable_if<std::is_void<typename std::result_of<F()>::type>::value>::type>
    void handle(void* scope, F&& f, size_t coroutine_id)
    {
      size_t& handle = handling(scope);
      if(handle) throw std::logic_error("component already handling an event");
      handle = coroutine_id;
      assert(handle != 0);
      f();
    }
    template <typename F, typename = typename std::enable_if<!std::is_void<typename std::result_of<F()>::type>::value>::type>
    inline auto handle(void* scope, F&& f, size_t coroutine_id) -> decltype(f())
    {
      size_t& handle = handling(scope);
      if(handle) throw std::logic_error("component already handling an event");
      handle = coroutine_id;
      return f();
    }
    runtime();
  };

  template <typename C, typename P>
  struct call_helper
  {
    C* c;
    std::ostream& os;
    const dzn::port::meta& meta;
    const char* event;
    std::string reply;
    call_helper(C* c, P& p, const char* event)
    : c(c)
    , os(c->dzn_locator.template get<typename std::ostream>())
    , meta(p.meta)
    , event(event)
    , reply("return")
    {
      if(c->dzn_rt.handling(c) || port_blocked_p(c->dzn_locator, &p))
        collateral_block(c, c->dzn_locator);
      c->dzn_rt.component_stack.push_back(c);
      trace(os, meta, event);
#if DZN_STATE_TRACING
      os << *c << std::endl;
#endif
    }
    template <typename L, typename = typename std::enable_if<std::is_void<typename std::result_of<L()>::type>::value>::type>
    void operator()(L&& l)
    {
      c->dzn_rt.handle(c, l, coroutine_id(c->dzn_locator));
    }
    template <typename L, typename = typename std::enable_if<!std::is_void<typename std::result_of<L()>::type>::value>::type>
    auto operator()(L&& l) -> decltype(l())
    {
      auto r = c->dzn_rt.handle(c, l, coroutine_id(c->dzn_locator));
      reply = ::to_string(r);
      return r;
    }
    ~call_helper()
    {
      trace_out(os, meta, reply.c_str());
#if DZN_STATE_TRACING
      os << *c << std::endl;
#endif
      assert(c->dzn_rt.component_stack.back() == c);
      c->dzn_rt.component_stack.pop_back();
      c->dzn_rt.handling(c) = 0;
    }
  };

  template <typename C, typename P, typename L>
  auto call_in(C* c, L&& l, P& p, const char* event) -> decltype(l())
  {
    call_helper<C,P> helper(c, p, event);
    return helper(l);
  }

  template <typename C, typename P, typename L>
  void call_out(C* c, L&& l, P& p, const char* e)
  {
    auto& os = c->dzn_locator.template get<typename std::ostream>();
#if !DZN_ASYNC_TRACING
    if (!dynamic_cast<async_base*> (&p))
      trace_qin(os, p.meta, e);
#else // DZN_ASYNC_TRACING
    trace_qin(os, p.meta, e);
#endif // DZN_ASYNC_TRACING
#if DZN_STATE_TRACING
    os << *c << std::endl;
#endif
    c->dzn_rt.defer(p.meta.provide.component, c, [&os,c,l,&p,e]{
      c->dzn_rt.component_stack.push_back(c);
#if !DZN_ASYNC_TRACING
      if (!dynamic_cast<async_base*> (&p))
        trace_qout(os, p.meta, e);
#else
      trace_qout(os, p.meta, e);
#endif
      l();
      assert(c->dzn_rt.component_stack.back() == c);
      c->dzn_rt.component_stack.pop_back();
    }, coroutine_id(c->dzn_locator));
  }
}
#endif //DZN_RUNTIME_HH
