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

  inline std::string component_to_string(dzn::component* c)
  {
    return c ? reinterpret_cast<component_meta*>(c)->dzn_meta.name : "<external>";
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
  void collateral_block(const locator&, dzn::component*);
  bool port_blocked_p(const locator&, void*);
  void port_block(const locator&, dzn::component*, void*);
  void port_release(const locator&, dzn::component*, void*);
  size_t coroutine_id(const locator&);
  void defer(const locator&, std::function<bool()>&&, std::function<void(size_t)>&&);
  void prune_deferred(const locator&);

  struct runtime
  {
    runtime(const runtime&) = delete;
    runtime(runtime&&) = delete;
    struct state
    {
      size_t handling;
      size_t blocked;
      void* skip;
      bool performs_flush;
      dzn::component* deferred;
      std::queue<std::function<void()>> queue;
    };
    std::map<dzn::component*, state> states;
    bool skip_block(dzn::component*, void*);
    void set_skip_block(dzn::component*, void*);
    void reset_skip_block(dzn::component*);

    bool external(dzn::component*);
    size_t& handling(dzn::component*);
    size_t& blocked(dzn::component*);
    dzn::component*& deferred(dzn::component*);
    std::queue<std::function<void()> >& queue(dzn::component*);
    bool& performs_flush(dzn::component*);
    template <typename T>
    void flush(T* t)
    {
      flush(t, coroutine_id(t->dzn_locator));
    }
    void flush(dzn::component*, size_t);
    void enqueue(dzn::component*, dzn::component*, const std::function<void()>&, size_t);
    template <typename F, typename = typename std::enable_if<std::is_void<typename std::result_of<F()>::type>::value>::type>
    void handle(dzn::component* component, F&& f, size_t coroutine_id)
    {
      size_t& handle = handling(component);
      if(handle) throw std::logic_error("component already handling an event");
      handle = coroutine_id;
      assert(handle != 0);
      f();
    }
    template <typename F, typename = typename std::enable_if<!std::is_void<typename std::result_of<F()>::type>::value>::type>
    inline auto handle(dzn::component* component, F&& f, size_t coroutine_id) -> decltype(f())
    {
      size_t& handle = handling(component);
      if(handle) throw std::logic_error("component already handling an event");
      handle = coroutine_id;
      return f();
    }
    runtime();
  };

  template <typename C, typename P>
  struct call_helper
  {
    C* component;
    std::ostream& os;
    const dzn::port::meta& meta;
    const char* event;
    std::string reply;
    call_helper(C* c, P& port, const char* event)
    : component(c)
    , os(c->dzn_locator.template get<typename std::ostream>())
    , meta(port.meta)
    , event(event)
    , reply("return")
    {
      if(component->dzn_rt.handling(component) ||
         port_blocked_p(component->dzn_locator, &port))
        collateral_block(component->dzn_locator, component);

      component->dzn_rt.reset_skip_block(component);
      trace(os, meta, event);
#if DZN_STATE_TRACING
      os << *component << std::endl;
#endif
    }
    template <typename L, typename = typename std::enable_if<std::is_void<typename std::result_of<L()>::type>::value>::type>
    void operator()(L&& event)
    {
      component->dzn_rt.handle(component, event, coroutine_id(component->dzn_locator));
    }
    template <typename L, typename = typename std::enable_if<!std::is_void<typename std::result_of<L()>::type>::value>::type>
    auto operator()(L&& event) -> decltype(event())
    {
      auto value = component->dzn_rt.handle(component, event, coroutine_id(component->dzn_locator));
      reply = ::to_string(value);
      return value;
    }
    ~call_helper()
    {
      trace_out(os, meta, reply.c_str());
#if DZN_STATE_TRACING
      os << *c << std::endl;
#endif
      prune_deferred(component->dzn_locator);
      component->dzn_rt.handling(component) = 0;
    }
  };

  template <typename C, typename P, typename L>
  auto call_in(C* component, L&& event, P& port, const char* event_name) -> decltype(event())
  {
    call_helper<C,P> helper(component, port, event_name);
    return helper(event);
  }

  template <typename C, typename P, typename L>
  void call_out(C* component, L&& event, P& port, const char* event_name)
  {
    auto& os = component->dzn_locator.template get<typename std::ostream>();
#if !DZN_ASYNC_TRACING
    if (!dynamic_cast<async_base*> (&port))
      trace_qin(os, port.meta, event_name);
#else // DZN_ASYNC_TRACING
    trace_qin(os, port.meta, event_name);
#endif // DZN_ASYNC_TRACING
#if DZN_STATE_TRACING
    os << *component << std::endl;
#endif
    component->dzn_rt.enqueue(port.meta.provide.component, component,
                              [&os,component,event,&port,event_name]{
#if !DZN_ASYNC_TRACING
      if (!dynamic_cast<async_base*> (&port))
        trace_qout(os, port.meta, event_name);
#else
      trace_qout(os, port.meta, event_name);
#endif
      event();
    }, coroutine_id(component->dzn_locator));
    prune_deferred(component->dzn_locator);
  }
  template <typename C, typename P, typename E>
  void defer(C* component, P&& predicate, E&& event)
  {
    defer(component->dzn_locator, std::function<bool()>(predicate),
          std::function<void(size_t)>([=](size_t coroutine_id){
            component->dzn_rt.handling(component) = coroutine_id;
            event();
            component->dzn_rt.flush(component);
          }));
  }
}
#endif //DZN_RUNTIME_HH
