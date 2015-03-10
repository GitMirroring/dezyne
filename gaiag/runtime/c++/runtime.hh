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

#include <functional>
#include <map>
#include <queue>
#include <tuple>

namespace dezyne
{
  void trace_in(port::meta const& m, const char* e);
  void trace_out(port::meta const& m, const char* e);

  struct component;

  struct meta
  {
    const char* name;
    const component* address;
    const component* parent;
    std::vector<const component*> children;
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
    std::map<void*, std::pair<bool, std::queue<std::function<void()> > > > queues;

    bool& handling(void*);
    void flush(void*);
    void defer(void*, const std::function<void()>&);
    void handle(void*, const std::function<void()>&); // trace_data const&);

    template <typename R, bool checked = true>
    inline R valued_helper(void* scope, const std::function<R()>& event)
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

  template <typename C, typename P>
  void call_in(C* c, std::function<void()> f, std::tuple<P*, const char*, const char*> m)
  {
    trace_in(std::get<0>(m)->meta, std::get<1>(m));
    c->rt.handle(c, f);
    trace_out(std::get<0>(m)->meta, std::get<2>(m) ? std::get<2>(m) : "return");
  }

  template <typename R, typename C, typename P>
  R call_in(C* c, std::function<R()> f, std::tuple<P*, const char*, const char*> m)
  {
    trace_in(std::get<0>(m)->meta, std::get<1>(m));
    auto r = c->rt.valued_helper(c, f);
    trace_out(std::get<0>(m)->meta, to_string (r));
    return r;
  }

  template <typename C, typename P>
  void call_out(C* c, std::function<void()> f, std::tuple<P*, const char*, const char*> m)
  {
    trace_out(std::get<0>(m)->meta, std::get<1>(m));
    c->rt.defer(std::get<0>(m)->meta.provides.address, [=]{c->rt.handle(c, f);});
  }
}
#endif
