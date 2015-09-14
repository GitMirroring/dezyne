// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#if __cplusplus >= 201103L

#include "pump.hh"

#include <algorithm>
#include <iostream>

namespace dezyne
{
  pump::pump()
  : running(true)
  , task(std::async(std::launch::async, std::ref(*this)))
  {}
  pump::~pump()
  {
    std::unique_lock<std::mutex> lock(mutex);
    running = false;
    lock.unlock();
    condition.notify_one();
    task.get();
  }
  void pump::operator()()
  {
    try
    {
      thread_id = std::this_thread::get_id();
      std::unique_lock<std::mutex> lock(mutex);
      while(running)
      {
        if(timers.empty())
        {
          condition.wait(lock, [this]{return queue.size() or not running;});
        }
        else
        {
          condition.wait_until(lock, timers.begin()->first.t, [this]{return queue.size() or not running;});
        }

        while(timers.size() && timers.begin()->first.expired())
        {
          auto t = *timers.begin();
          timers.erase(timers.begin());
          lock.unlock();
          t.second();
          lock.lock();
        }

        if(queue.size())
        {
          std::function<void()> f(queue.front());
          queue.pop();
          lock.unlock();
          f();
          lock.lock();
        }
      }
      assert(queue.empty());
    }
    catch(const std::exception& e)
    {
      std::clog << "oops: " << e.what() << std::endl;
      std::abort();
    }
  }
  void pump::handle(const std::function<void()>& e)
  {
    assert(e and std::this_thread::get_id() != thread_id);
    std::lock_guard<std::mutex> lock(mutex);
    queue.push(e);
    condition.notify_one();
  }
  void pump::handle(size_t id, size_t ms, const std::function<void()>& e)
  {
    assert(e and std::this_thread::get_id() == thread_id);
    assert(std::find_if(timers.begin(), timers.end(), [id](const std::pair<deadline, std::function<void()>>& p){ return p.first.id == id; }) == timers.end());
    timers.emplace(deadline(id, ms), e);
  }
  void pump::remove(size_t id)
  {
    assert(std::this_thread::get_id() == thread_id);
    auto it = std::find_if(timers.begin(), timers.end(), [id](const std::pair<deadline, std::function<void()>>& p){ return p.first.id == id; });
    if(it != timers.end()) timers.erase(it);
  }
}
#endif //  __cplusplus >= 201103L
