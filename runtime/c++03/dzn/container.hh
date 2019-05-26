// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
// Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017, 2018, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
#include <dzn/sexp.hh>

#include <algorithm>
#include <functional>
#include <iostream>
#include <map>
#include <queue>
#include <string>

namespace dzn
{
    namespace sexp
    {
      sexp nil = {(sexp*)"()", 0};
      sexp dot = {(sexp*)".", 0};
      int (*read_char)() = getchar;
      int (*unread_char)(int) = ungetchar;
      char const* global_string;
      int global_pos;
    }

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
    boost::mutex mutex;
    boost::condition_variable condition;

    dzn::pump pump;

    container(bool flush, const dzn::locator& l = dzn::locator())
    : flush(flush)
    , meta("<external>","container",0)
    , dzn_locator(l.clone())
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
      //if(expect.empty()) condition.notify_one();
      return tmp;
    }
    void match(const std::string& actual)
    {
      std::string tmp = match_return();

      // if(actual != tmp)
      //   throw std::runtime_error("unmatched expectation: \"" + actual + "\" got: \"" + tmp + "\"");
    }
    void set_state (std::string str)
    {
      sexp::sexp* sexp = sexp::read_from_string(str.c_str ());
      std::list<sexp::sexp*> list = sexp::sexp_to_list(sexp);
      std::map<std::string,std::map<std::string,std::string>> state_alist;
      for(std::list<sexp::sexp*>::iterator it = list.begin(); it != list.end(); ++it)
        state_alist[sexp::sexp_to_string((*it)->car)] = sexp::sexp_to_alist((*it)->cdr);
      system.set_state(state_alist);
    };
    void operator()(const std::map<std::string, Function>& lookup, const std::set<std::string>& required_ports)
    {
      this->lookup = lookup;

      std::string port;
      std::string str;
      bool initial = true;

      while(std::getline (std::cin, str))
      {
        if (initial && str[0] == '(') set_state (str);
        initial = false;

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

          boost::unique_lock<boost::mutex> lock(mutex);
          condition.notify_one();
          expect.push(str);
        }
        else
        {
          pump(it->second);
          port.clear();
        }
      }
      // boost::unique_lock<boost::mutex> lock(mutex);
      // condition.wait(lock, [this]{return expect.empty();});
    }
  };
}

#endif //DZN_CONTAINER_HH
