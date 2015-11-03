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

#if 0 // __cplusplus >= 201402L
#define COROUTINE 1
#endif // __cplusplus >= 201402L

#if COROUTINE
#include <boost/coroutine/all.hpp>
#else // !COROUTINE
#include "context.hh"
#endif // !COROUTINE

#include <algorithm>
#include <iostream>
#include <list>

static void debug(const std::string& s)
{
#ifdef DEBUG
  std::cout << s << std::endl;
#endif
}

namespace dezyne
{
#if COROUTINE
  typedef boost::coroutines::symmetric_coroutine<void>::call_type context;
  typedef boost::coroutines::symmetric_coroutine<void>::yield_type yield;
#else
  typedef std::function<void(dezyne::context&)> yield;
#endif // !COROUTINE

  struct coroutine
  {
    dezyne::context context;
    dezyne::yield yield;
    void* port;
    bool finished;
    bool released;
    template <typename Worker>
    coroutine(std::list<coroutine>& coroutines, Worker&& worker)
      : context{[&coroutines, this, worker = std::move(worker)](auto&& yield){
        this->yield = std::move(yield);
        worker();
      }}
    , port(nullptr)
    , finished(false)
    , released(false)
    {}
    void call(dezyne::context& context)
    {
#if COROUTINE
      (void)context;
      this->context();
#else // !COROUTINE
      this->context.call(context);
#endif // !COROUTINE
    }
    void yield_to(dezyne::context& context)
    {
#if !COROUTINE
      this->yield(context);
#endif //!COROUTINE
    }
  };

  std::list<coroutine> coroutines;

  auto find_self = [] {
    auto self = std::find_if(coroutines.begin(), coroutines.end(), [](auto& c){return c.port == nullptr and not c.finished;});
    if(self == coroutines.end()) throw std::runtime_error("cannot find my self");
    return self;
  };

  auto find_blocked = [] (void* port) {
    auto self = std::find_if(coroutines.begin(), coroutines.end(), [port](auto& c){return c.port == port;});
    if(self == coroutines.end()) throw std::runtime_error("cannot find my blocked self");
    return self;
  };

  auto finish = [&](const char* name){
    auto self = find_self();

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
        }
      };

      context bogus;
#if !COROUTINE
      bogus.release();
#endif // !COROUTINE

      coroutines.emplace_back(coroutines, [&]{
          while(running or queue.size())
          {
            debug("main coroutine");
            worker();
          }
          finish("main");
          });

#if COROUTINE
      auto self = find_self();
      self->call(bogus);
#else // !COROUTINE
      coroutines.back().call(bogus);
#endif
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
    auto self = find_self();
    self->port = p;

    debug("block");
    coroutines.emplace_back(coroutines, [&]{
        auto self = find_self();
        while(not self->released)
        {
          debug("new coroutine");
          worker();
        }
        finish("new");
      });

    self = find_blocked(p);

    coroutines.back().call(self->context);
  }
  void pump::release(void* p)
  {
    auto self = find_self();
    auto blocked = find_blocked(p);

    debug("unblock");
    blocked->port = nullptr;
    self->released = true;
    self->yield_to(blocked->context);
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
