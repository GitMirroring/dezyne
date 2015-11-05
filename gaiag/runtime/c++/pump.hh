// Dezyne --- Dezyne command line tools
//
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

#ifndef PUMP_HH
#define PUMP_HH

#include <cassert>
#include <condition_variable>
#include <functional>
#include <future>
#include <map>
#include <mutex>
#include <queue>

namespace dezyne
{
  struct pump
  {
    std::queue<std::function<void()>> queue;

    struct deadline
    {
      size_t id;
      std::chrono::steady_clock::time_point t;
      deadline(size_t id, size_t ms)
      : id(id)
      , t(std::chrono::steady_clock::now() + std::chrono::milliseconds(ms))
      {}
      bool expired() const
      {
        return t <= std::chrono::steady_clock::now();
      }
      bool operator < (const deadline& d) const
      {
        return t < d.t or (t == d.t and id < d.id);
      }
    };

    std::map<deadline, std::function<void()>> timers;

    std::function<void()> switch_context;
    std::function<void()> exit;

    std::thread::id thread_id;
    bool running;
    std::condition_variable condition;
    std::mutex mutex;
    std::future<void> task;
    pump();
    ~pump();
    void operator()();
    void block(void*);
    void release(void*);
    void operator()(const std::function<void()>&);
    void operator()(std::function<void()>&&);
    void and_wait(const std::function<void()>&);
    void handle(size_t id, size_t ms, const std::function<void()>&);
    void remove(size_t id);
  };
}

#endif
