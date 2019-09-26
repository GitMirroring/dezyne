// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2014, 2015, 2016, 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015, 2016, 2017, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

#include <dzn/runtime.hh>
#include <dzn/pump.hh>

#include <algorithm>
#include <iostream>

namespace dzn
{
  std::ostream debug(nullptr);

  runtime::runtime(){}

  void trace(std::ostream& os, port::meta const& m, const char* e)
  {
    os << path(m.requires.meta, m.requires.port) << "." << e << " -> "
       << path(m.provides.meta, m.provides.port) << "." << e << std::endl;
  }

  void trace_out(std::ostream& os, port::meta const& m, const char* e)
  {
    os << path(m.requires.meta, m.requires.port) << "." << e << " <- "
       << path(m.provides.meta, m.provides.port) << "." << e << std::endl;
  }

  void trace_qin(std::ostream& os, port::meta const& m, const char* e)
  {
    if (path(m.provides.meta) == "<external>")
      os << path(m.requires.meta, "<q>") << " <- "
         << path(m.provides.meta, m.provides.port) << "." << e << std::endl;
    else
      os <<  path(m.provides.meta, m.provides.port) << ".<q> <- "
         <<  path(m.requires.meta, m.requires.port) << "." << e << std::endl;
  }

  void trace_qout(std::ostream& os, port::meta const& m, const char* e)
  {
    os << path(m.requires.meta, m.requires.port) << "." << e << " <- "
       << path(m.requires.meta, "<q>") << std::endl;
  }

  bool runtime::external(void* scope) {
    return (queues.find(scope) == queues.end());
  }

  bool& runtime::handling(void* scope)
  {
    return std::get<0>(queues[scope]);
  }

  void*& runtime::deferred(void* scope)
  {
    return std::get<1>(queues[scope]);
  }

  std::queue<std::function<void()> >& runtime::queue(void* scope)
  {
    return std::get<2>(queues[scope]);
  }

  bool& runtime::performs_flush(void* scope)
  {
    return std::get<3>(queues[scope]);
  }

  bool& runtime::skip_block(void* port)
  {
    return skip_port[port];
  }

  void runtime::flush(void* scope)
  {
#ifdef DEBUG_RUNTIME
    std::cout << path(reinterpret_cast<dzn::meta*>(scope)) << " flush" << std::endl;
#endif
    if(!external(scope))
    {
      std::queue<std::function<void()> >& q = queue(scope);
      while(! q.empty())
      {
        std::function<void()> event = q.front();
        q.pop();
        handle(scope, event);
      }
      if (deferred(scope)) {
        void* tgt = deferred(scope);
        deferred(scope) = nullptr;
        if (!handling(tgt)) {
          runtime::flush(tgt);
        }
      }
    }
  }

  void runtime::defer(void* src, void* tgt, const std::function<void()>& event)
  {
#ifdef DEBUG_RUNTIME
    std::cout << path(reinterpret_cast<dzn::meta*>(tgt)) << " defer" << std::endl;
#endif

    if(!(src && performs_flush(src)) && !handling(tgt))
    {
      handle(tgt, event);
    }
    else
    {
      deferred(src) = tgt;
      queue(tgt).push(event);
    }
  }
}
