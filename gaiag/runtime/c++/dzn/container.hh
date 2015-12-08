// Dezyne --- Dezyne command line tools
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
  template <typename System>
  struct container
  {
    dzn::meta meta;
    dzn::locator locator;
    dzn::runtime runtime;
    System system;

    std::queue<std::string> expect;
    std::mutex mutex;
    std::condition_variable condition;

    dzn::pump pump;

    container(bool flush, dzn::locator&& l = dzn::locator{})
    : meta{"<internal>","container",0,{&system.dzn_meta},{[this]{system.check_bindings();}}}
    , locator(std::forward<dzn::locator>(l))
    , runtime()
    , system(locator.set(runtime).set(pump))
    , pump()
    {
      runtime.performs_flush(this) = flush;
      system.dzn_meta.name = "sut";
    }
    std::string match_return()
    {
      std::unique_lock<std::mutex> lock(mutex);
      condition.wait(lock, [this]{return not expect.empty();});
      std::string tmp = expect.front();
      expect.pop();
      return tmp;
    }
    void match(const std::string& actual)
    {
      std::unique_lock<std::mutex> lock(mutex);
      condition.wait(lock, [this]{return not expect.empty();});

      if(actual != expect.front())
        throw std::runtime_error("unmatched expectation: \"" + expect.front() + "\" got: \"" + actual + "\"");

      expect.pop();
    }
    void operator()(const std::map<std::string, std::function<void()>>& lookup)
    {
      std::string str;
      while(std::cin >> str)
      {
        auto it = lookup.find(str);
        if(it == lookup.end())
        {
          std::unique_lock<std::mutex> lock(mutex);
          condition.notify_one();
          expect.push(str);
        }
        else
        {
          pump(it->second);
        }
      }
    }
  };
}

#endif //DZN_CONTAINER_HH
