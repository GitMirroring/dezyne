// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
// Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#ifndef DZN_CONTAINER_HH
#define DZN_CONTAINER_HH

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

#include <functional>
#include <iostream>
#include <map>
#include <queue>
#include <string>

namespace dzn
{
  template <typename System, typename Function>
  struct container
  {
    dzn::meta meta;
    dzn::locator locator;
    dzn::runtime runtime;
    System system;

    std::map<std::string, Function> lookup;

    std::queue<std::string> expect;
    boost::mutex mutex;
    boost::condition_variable condition;

    dzn::pump pump;

    container(bool flush, const dzn::locator& l = dzn::locator())
    : meta("<internal>","container",0)
    , locator(l.clone())
    , runtime()
    , system(locator.set(runtime).set(pump))
    , pump()
    {
      runtime.performs_flush(this) = flush;
      system.dzn_meta.name = "sut";
    }
    ~container()
    {
      dzn::pump* p = system.dzn_locator.template try_get<dzn::pump>(); //only shells have a pump
      //resolve the race condition between the shell pump dtor and the container pump dtor
      if(p && p != &pump) pump([p] {p->stop();});
    }
    std::string match_return()
    {
      boost::unique_lock<boost::mutex> lock(mutex);
      condition.wait(lock, [this]{return not expect.empty();});
      std::string tmp = expect.front(); expect.pop();
      auto it = lookup.find(tmp);
      while(it != lookup.end())
      {
        it->second();
        condition.wait(lock, [this]{return not expect.empty();});
        tmp = expect.front(); expect.pop();
        it = lookup.find(tmp);
      }
      return tmp;
    }
    void match(const std::string& actual)
    {
      std::string tmp = match_return();

      if(actual != tmp)
        throw std::runtime_error("unmatched expectation: \"" + actual + "\" got: \"" + tmp + "\"");
    }
    void operator()(const std::map<std::string, Function>& lookup, const std::set<std::string>& required_ports)
    {
      this->lookup = lookup;

      std::string port;
      std::string str;

      while(std::cin >> str)
      {
        auto it = this->lookup.find(str);
        if(it == this->lookup.end() || port.size())
        {
          std::string p = str.substr(0, str.find('.'));
          if(it == this->lookup.end() && required_ports.find(p) != required_ports.end())
          {
            if(port.empty() || port != p) port = p;
            else port.clear();
          }
          boost::unique_lock<boost::mutex> lock(mutex);
          condition.notify_one();
          expect.push(str);
        }
        else
        {
          pump(it->second);
          port.clear();
        }
        boost::this_thread::sleep_for(boost::chrono::milliseconds(100));
      }
    }
  };
}

#endif //DZN_CONTAINER_HH
