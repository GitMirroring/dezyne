// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "pump.hh"

#include <algorithm>
#include <iostream>

#include <boost/coroutine/all.hpp>

static void debug(const std::string& s)
{
#ifdef DEBUG
  std::cout << s << std::endl;
#endif
}

namespace dezyne
{
  struct coroutine
  {
    typedef boost::coroutines::symmetric_coroutine<void>::call_type call_type;
    typedef boost::coroutines::symmetric_coroutine<void>::yield_type yield_type;
    call_type call;
    yield_type yield;
    void* port;
    bool finished;
    bool released;
    template <typename Worker>
    coroutine(std::vector<coroutine>& coroutines, Worker&& worker)
    : call{[&coroutines, worker = std::move(worker)](auto&& yield){
        auto& self = coroutines.back();
        self.yield = std::move(yield);
        worker();
      }}
    , yield()
    , port(nullptr)
    , finished(false)
    , released(false)
    {}
  };

  std::vector<coroutine> coroutines;

  auto schedule = [&]{
    while(true)
    {
      auto it = std::find_if(coroutines.rbegin(), coroutines.rend(), [](auto& c){return c.port == nullptr and not c.finished;});
      if(it != coroutines.rend())
      {
        debug("schedule");
        it->call();
      }
      else break;
      coroutines.erase(std::remove_if(coroutines.begin(), coroutines.end(), [](auto& c){return c.finished;}), coroutines.end());
    }
    debug("schedule exit");
  };

  auto finish = [&](const char* name){
    auto self = std::find_if(coroutines.rbegin(), coroutines.rend(), [](auto& c){return c.port == nullptr and not c.finished;});
    self->finished = true;
    debug(std::string("exit ") + name + " coroutine");
  };

  static std::function<void()> worker;

  pump::pump()
  : running(true)
  , task(std::async(std::launch::async, std::ref(*this)))
  {}
  pump::~pump()
  {
    std::unique_lock<std::mutex> lock(mutex);
    running = false;
    condition.notify_one();
    lock.unlock();
    task.get();
  }
  void pump::operator()()
  {
    try
    {
      thread_id = std::this_thread::get_id();
      std::unique_lock<std::mutex> lock(mutex, std::defer_lock);

      worker = [&] {
        if(not lock) lock.lock();
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
          if(not lock) lock.lock();
        }

        if(queue.size())
        {
          std::function<void()> f(std::move(queue.front()));
          queue.pop();
          lock.unlock();
          f();
          if(not lock) lock.lock();
        }
      };

      coroutines.emplace_back(coroutines, [&]{
          while(running or queue.size())
          {
            debug("main coroutine");
            worker();
          }
          finish("main");
        });

      schedule();
      assert(queue.empty());
    }
    catch(const std::exception& e)
    {
      std::clog << "oops: " << e.what() << std::endl;
      std::abort();
    }
  }
  void pump::block(void* p)
  {
    auto self = std::find_if(coroutines.begin(), coroutines.end(), [](auto& c){return c.port == nullptr and not c.finished;});
    self->port = p;

    coroutines.emplace_back(coroutines, [&]{
        auto self = std::find_if(coroutines.begin(), coroutines.end(), [](auto& c){return c.port == nullptr and not c.finished;});
        while(not self->released)
        {
          debug("new coroutine");
          worker();
        }
        finish("new");
      });
    debug("block");
    self = std::find_if(coroutines.begin(), coroutines.end(), [p](auto& c){return c.port == p;});
    self->yield();
  }
  void pump::release(void* p)
  {
    auto self = std::find_if(coroutines.begin(), coroutines.end(), [p](auto& c){return c.port == nullptr and not c.finished;});
    auto blocked = std::find_if(coroutines.begin(), coroutines.end(), [p](auto& c){return c.port == p;});
    debug("unblock");
    blocked->port = nullptr;
    self->released = true;
  }
  void pump::operator()(const std::function<void()>& e)
  {
    assert(e and std::this_thread::get_id() != thread_id);
    std::lock_guard<std::mutex> lock(mutex);
    queue.push(e);
    condition.notify_one();
  }
  void pump::operator()(std::function<void()>&& e)
  {
    assert(e and std::this_thread::get_id() != thread_id);
    std::lock_guard<std::mutex> lock(mutex);
    queue.push(std::move(e));
    condition.notify_one();
  }
  void pump::and_wait(const std::function<void()>& e)
  {
    std::promise<void> p;

    assert(e and std::this_thread::get_id() != thread_id);

    {std::lock_guard<std::mutex> lock(mutex);
    queue.push([&]{e(); p.set_value();});
    condition.notify_one();}

    p.get_future().get();
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
