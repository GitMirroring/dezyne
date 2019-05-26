// Dezyne --- Dezyne command line tools
// Copyright © 2015, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
// Copyright © 2015, 2016, 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include <dzn/runtime.hh>
#include <dzn/pump.hh>

#include <algorithm>
#include <iostream>

namespace dzn {
  //std::ostream debug(std::clog.rdbuf());
  std::ostream debug(0);

  runtime::runtime(){}

  void trace_qin(std::ostream& os, port::meta const& m, const char* e)
  {
    os << path(m.requires.meta, "<q>") << " <- "
       << path(m.provides.meta, m.provides.port) << "." << e << std::endl;
  }
  void trace_qout(std::ostream& os, port::meta const& m, const char* e)
  {
    os << path(m.requires.meta, m.requires.port) << "." << e << " <- "
       << path(m.requires.meta, "<q>") << std::endl;
  }

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

  bool runtime::external(void* scope) {
    return (queues.find(scope) == queues.end());
  }

  bool& runtime::handling(void* scope)
  {
    return boost::get<0>(queues[scope]);
  }

  void*& runtime::deferred(void* scope)
  {
    return boost::get<1>(queues[scope]);
  }

  std::queue<boost::function<void()> >& runtime::queue(void* scope)
  {
    return boost::get<2>(queues[scope]);
  }

  bool& runtime::performs_flush(void* scope)
  {
    return boost::get<3>(queues[scope]);
  }

  void runtime::flush(void* scope)
  {
#ifdef DEBUG_RUNTIME
    std::cout << path(scope) << " flush" << std::endl;
#endif
    if(!external(scope))
    {
      std::queue<boost::function<void()> >& q = queue(scope);
      while(!q.empty())
      {
        boost::function<void()> event = q.front();
        q.pop();
        handle(scope, event);
      }
      if (deferred(scope)) {
        void* tgt = deferred(scope);
        deferred(scope) = NULL;
        if (!handling(tgt)) {
          runtime::flush(tgt);
        }
      }
    }
  }

  void runtime::defer(void* src, void* tgt, const boost::function<void()>& event)
  {
#ifdef DEBUG_RUNTIME
    std::cout << path(tgt) << " defer" << std::endl;
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

  void runtime::handle(void* scope, const boost::function<void()>& event)
  {
    bool& handle = handling(scope);

#ifdef DEBUG_RUNTIME
    std::cout << path(scope) << " handle " << std::boolalpha << handle << std::endl;
#endif

    if(!handle)
    {
      {
        scoped_value<bool> sv(handle, true);
        event();
      }
      flush(scope);
    }
    else
    {
      throw std::logic_error("component already handling an event");
    }
  }
}
