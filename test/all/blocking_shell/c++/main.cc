// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include "blocking_shell.hh"

#include <future>
#include <iterator>
#include <map>
#include <mutex>
#include <queue>
#include <string>
#include <vector>

bool is_reply (const std::string &s)
{
  if (s.empty ()) return false;
  const std::string &v = s.substr (s.find ('.') + 1);
  return s.find (':') != std::string::npos
         || v == "return" || v == "true" || v == "false"
         || std::find_if (s.begin (), s.end (),
  [] (unsigned char c) { return !std::isdigit (c); }) == s.end ();
}

int main ()
{
  dzn::locator locator;
  dzn::runtime runtime;
  blocking_shell sut (locator.set (runtime));
  sut.dzn_meta.name = "sut";
  sut.p.dzn_meta.require.name = "p";
  sut.r.dzn_meta.provide.name = "r";

  int output = 0;
  std::map<std::string, std::function<void ()>> provides =
  {
    {"p.hello_void", sut.p.in.hello_void},
    {"p.hello_bool", sut.p.in.hello_bool},
    {"p.hello_int", sut.p.in.hello_int},
    {"p.hello_enum", std::bind (sut.p.in.hello_enum, 123, std::ref (output))},
  };

  std::map<std::string, std::function<void ()>> requires =
  {
    {"r.world", std::bind (sut.r.out.world, 0)},
  };


  std::mutex mutex;

  size_t event = 0;
  std::vector<std::string> trace;

  sut.p.out.world = [&] (int)
  {
    assert (trace[event] == "p.world");
    ++event;
  };
  sut.r.in.hello_void = [&]
  {
    std::lock_guard<std::mutex> lock (mutex);
    assert (trace[event] == "r.hello_void");
    ++event;
    ++event;
  };
  sut.r.in.hello_bool = [&]
  {
    std::cout << "hiero 2" << std::endl;
    std::lock_guard<std::mutex> lock (mutex);
    assert (trace[event] == "r.hello_bool");
    ++event;
    const std::string &tmp = trace[event];
    ++event;
    const auto &result = tmp.substr (tmp.rfind ('.') + 1);
    std::cout << "main reply " << result << std::endl;
    return dzn::to_bool (result);
  };
  sut.r.in.hello_int = [&]
  {
    std::lock_guard<std::mutex> lock (mutex);
    assert (trace[event] == "r.hello_int");
    ++event;
    const std::string &tmp = trace[event];
    ++event;
    const auto &result = tmp.substr (tmp.rfind ('.') + 1);
    return dzn::to_int (result);
  };
  sut.r.in.hello_enum = [&] (int, int &)
  {
    std::lock_guard<std::mutex> lock (mutex);
    assert (trace[event] == "r.hello_enum");
    ++event;
    const std::string &tmp = trace[event];
    ++event;
    const auto &result = tmp.substr (tmp.rfind ('.') + 1);
    return dzn::to_Enum (result);
  };

  std::queue<std::future<void>> sync;

  std::copy (std::istream_iterator<std::string> (std::cin),
             std::istream_iterator<std::string> (),
             std::back_inserter (trace));

  std::unique_lock<std::mutex> lock (mutex);

  while (event < trace.size ())
    {
      auto pit = provides.find (trace[event]);
      if (pit != provides.end ())
        {
          sync.push (std::async (std::launch::async, [ &, pit]
          {
            pit->second ();
            std::unique_lock<std::mutex> lock (mutex);
            ++event;
          }));
          ++event;
          lock.unlock ();
        }
      else
        {
          auto rit = requires.find (trace[event]);
          if (rit != requires.end ())
            {
              rit->second ();
              ++event;
            }
          lock.unlock ();
        }
      lock.lock ();
    }
  while (sync.size ())
    {
      sync.front ().wait ();
      sync.pop ();
    }
}
