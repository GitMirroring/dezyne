// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022, 2023, 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
// Copyright © 2021, 2022, 2025 janneke Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2021, 2022, 2023, 2024, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
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

  int output = 0;
  std::map<std::string, std::function<void ()>> provide =
  {
    {"p.hello_void", sut.p.in.hello_void},
    {"p.hello_bool", sut.p.in.hello_bool},
    {"p.hello_int", sut.p.in.hello_int},
    {"p.hello_enum", std::bind (sut.p.in.hello_enum, 123, std::ref (output))},
  };

  std::map<std::string, std::function<void ()>> require =
  {
    {"r.world", std::bind (sut.r.out.world, 0)},
  };


  std::mutex mutex;

  size_t event = 0;
  std::vector<std::string> trace;

  sut.p.out.world = [&] (int)
  {
    std::lock_guard<std::mutex> lock (mutex);
    const std::string &next = trace[event++];
    assert (next == "p.world");
  };
  sut.r.in.hello_void = [&]
  {
    std::lock_guard<std::mutex> lock (mutex);
    const std::string &next = trace[event++];
    assert (next == "r.hello_void");
    const std::string &r = trace[event++];
    assert (r == "r.return");
  };
  sut.r.in.hello_bool = [&]
  {
    std::lock_guard<std::mutex> lock (mutex);
    const std::string &next = trace[event++];
    assert (next == "r.hello_bool");
    const std::string &tmp = trace[event++];
    const auto &result = tmp.substr (tmp.rfind ('.') + 1);
    return dzn::to_bool (result);
  };
  sut.r.in.hello_int = [&]
  {
    std::lock_guard<std::mutex> lock (mutex);
    const std::string &next = trace[event++];
    assert (next == "r.hello_int");
    const std::string &tmp = trace[event++];
    const auto &result = tmp.substr (tmp.rfind ('.') + 1);
    return dzn::to_int (result);
  };
  sut.r.in.hello_enum = [&] (int, int &)
  {
    std::lock_guard<std::mutex> lock (mutex);
    const std::string &next = trace[event++];
    assert (next == "r.hello_enum");
    const std::string &tmp = trace[event++];
    const auto &result = tmp.substr (tmp.rfind ('.') + 1);
    return dzn::to_Enum (result);
  };

  dzn::check_bindings (sut);

  std::queue<std::future<void>> sync;

  std::copy (std::istream_iterator<std::string> (std::cin),
             std::istream_iterator<std::string> (),
             std::back_inserter (trace));

  std::unique_lock<std::mutex> lock (mutex);
  while (event < trace.size ())
    {
      auto pit = provide.find (trace[event]);
      if (pit != provide.end ())
        {
          ++event;
          sync.push (std::async (std::launch::async, [&, pit]
          {
            pit->second ();
          }));
          lock.unlock ();
        }
      else
        {
          auto rit = require.find (trace[event]);
          if (rit != require.end ())
            {
              ++event;
              rit->second ();
            }
          else
            ++event;
          lock.unlock ();
        }
      std::this_thread::sleep_for (std::chrono::milliseconds (100));
      lock.lock ();
    }
  while (sync.size ())
    {
      sync.front ().wait ();
      sync.pop ();
    }
}
