// dzn-runtime -- Dezyne runtime library
// Copyright © 2015, 2016, 2017, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DZN_CONTAINER_HH
#define DZN_CONTAINER_HH

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

#include <algorithm>
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
    const bool flush;
    dzn::meta meta;
    dzn::locator dzn_locator;
    dzn::runtime dzn_rt;
    System system;

    std::map<std::string, Function> lookup;

    std::queue<std::string> expect;
    std::mutex mutex;
    std::condition_variable condition;

    dzn::pump pump;

    friend std::ostream& operator << (std::ostream& os, container<System,Function>&) {
      return os;
    }

    container(bool flush, dzn::locator&& l = dzn::locator{})
    : flush(flush)
    , meta{"<external>","container",0,0,{},{&system.dzn_meta},{[this]{system.check_bindings();}}}
    , dzn_locator(std::forward<dzn::locator>(l))
    , dzn_rt()
    , system(dzn_locator.set(dzn_rt).set(pump))
    , pump()
    {
      dzn_locator.get<illegal_handler>().illegal = []{std::clog << "illegal" << std::endl; std::exit(0);};
      dzn_rt.performs_flush(this) = flush;
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
      std::unique_lock<std::mutex> lock(mutex);
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
      if(expect.empty()) condition.notify_one();
      return tmp;
    }
    void match(const std::string& expected)
    {
      std::string actual = match_return();

      if(expected != actual)
        throw std::runtime_error("failure: expected: \"" + expected + "\" != actual: \"" + actual + "\"");
    }
    void operator()(std::map<std::string, Function>&& lookup, std::set<std::string>&& required_ports)
    {
      this->lookup = std::move(lookup);

      std::string port;
      std::string str;

      while(std::getline (std::cin, str))
      {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        auto it = this->lookup.find(str);
        if(it == this->lookup.end() || port.size())
        {
          std::string p = str.substr(0, str.find('.'));
          if(it == this->lookup.end() && required_ports.find(p) != required_ports.end())
          {
            if(port.empty() || port != p) port = p;
            else port.clear();
          }

          if(std::count(str.begin(), str.end(), '.') > 1) continue;

          std::unique_lock<std::mutex> lock(mutex);
          condition.notify_one();
          expect.push(str);
        }
        else
        {
          pump(it->second);
          port.clear();
        }
      }
      std::unique_lock<std::mutex> lock(mutex);
      condition.wait(lock, [this]{return expect.empty();});
    }
  };
}

#endif //DZN_CONTAINER_HH
