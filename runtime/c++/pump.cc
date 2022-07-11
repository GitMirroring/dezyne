// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2015, 2016, 2017, 2018, 2019, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2016 Rob Wieringa <rma.wieringa@gmail.com>
// Copyright © 2016 Henk Katerberg <hank@mudball.nl>
// Copyright © 2015, 2016, 2017, 2019, 2020, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include <dzn/locator.hh>
#include <dzn/pump.hh>
#include <dzn/runtime.hh>

#include <algorithm>
#include <cassert>
#include <iterator>

namespace dzn
{
  static std::list<coroutine>::iterator find_self(std::list<coroutine>& coroutines);
  void defer(const locator& l, void* c, std::function<bool()>&& p, std::function<void(size_t)>&& f)
  {
    l.get<dzn::pump>().defer(std::move(p),std::move(f));
  }
  void prune_deferred(const locator& l)
  {
    if (auto p = l.try_get<dzn::pump>())
      p->prune_deferred();
  }
  size_t coroutine_id(const locator& l)
  {
    auto ppump = l.try_get<dzn::pump>();
    return !ppump ? 1 : ppump->coroutine_id();
  }
  void port_block(const locator& l, void* c, void* p)
  {
    l.get<dzn::pump>().block(l.get<dzn::runtime>(), c, p);
  }
  void port_release(const locator& l, void* p)
  {
    l.get<dzn::pump>().release(l.get<dzn::runtime>(),p);
  }
  void collateral_block(void* c, const locator& l)
  {
    l.get<dzn::pump>().collateral_block(c, l.get<dzn::runtime>());
  }
  bool port_blocked_p(const locator& l, void *p)
  {
    dzn::pump* pump = l.try_get<dzn::pump>();
    if(pump)
      return pump->blocked_p(p);
    return false;
  }

  static std::list<coroutine>::iterator find_self(std::list<coroutine>& coroutines)
  {
    size_t count = std::count_if(coroutines.begin(), coroutines.end(), [](const coroutine& c){return c.port == nullptr && !c.finished;});
    assert(count != 0);
    assert(count != 2);
    assert(count < 3);
    assert(count == 1);
    auto self = std::find_if(coroutines.begin(), coroutines.end(), [](dzn::coroutine& c){return c.port == nullptr && !c.finished;});
    return self;
  }

  static std::list<coroutine>::iterator find_blocked(std::list<coroutine>& coroutines, void* port)
  {
    auto self = std::find_if(coroutines.begin(), coroutines.end(), [port](dzn::coroutine& c){return c.port == port;});
    return self;
  }

  static void remove_finished_coroutines(std::list<coroutine>& coroutines)
  {
    coroutines.remove_if([](dzn::coroutine& c){
        if(c.finished) debug.rdbuf() && debug << "[" << c.id << "] removing" << std::endl;
        return c.finished;
    });
  }


  pump::pump()
  : unblocked()
  , running(true)
  , paused(false)
  , id(0)
  , switch_context()
  , task(std::async(std::launch::async, std::ref(*this)))
  {}
  pump::~pump()
  {
    stop();
  }
  bool pump::blocked_p(void *p)
  {
    return find_blocked(coroutines, p) != coroutines.end();
  }
  void pump::stop()
  {
    debug.rdbuf() && debug << "pump::stop" << std::endl;
    std::unique_lock<std::mutex> lock(mutex);
    if(running)
    {
      running = false;
      condition.notify_one();
      lock.unlock();
      task.wait();
    }
  }
  void pump::wait()
  {
    debug.rdbuf() && debug << "pump::wait" << std::endl;
    std::unique_lock<std::mutex> lock(mutex);
    idle.wait(lock, [this]{return queue.empty() && deferred.empty();});
  }
  void pump::pause()
  {
    debug.rdbuf() && debug << "pump::pause" << std::endl;
    std::unique_lock<std::mutex> lock(mutex);
    paused = true;
  }
  void pump::resume()
  {
    debug.rdbuf() && debug << "pump::resume" << std::endl;
    std::unique_lock<std::mutex> lock(mutex);
    paused = false;
    condition.notify_one();
  }
  void pump::flush()
  {
    debug.rdbuf() && debug << "pump::flush" << std::endl;
    resume();
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    pause();
  }
  void pump::operator()()
  {
    try
    {
      worker = [&] {
        std::unique_lock<std::mutex> lock(mutex);
        if(queue.empty())
        {
          idle.notify_one();
        }
        if(timers.empty() && deferred.empty())
        {
          condition.wait(lock, [this]{return queue.size() || deferred.size() || !running;});
        }
        else
        {
          condition.wait_until(lock, timers.begin()->first.t, [this]{return queue.size() || deferred.size() || !running;});
        }

        if(queue.size())
        {
          std::function<void()> f(std::move(queue.front()));
          queue.pop();
          lock.unlock();
          f();
          lock.lock();
        }

        if(queue.empty() && deferred.size() && deferred.front().first())
        {
          auto p = deferred.front();
          deferred.erase(deferred.begin());
          lock.unlock();
          p.second(id);
          lock.lock();
        }

        while(timers_expired())
        {
          auto f(timers.begin()->second);
          timers.erase(timers.begin());
          lock.unlock();
          f();
          lock.lock();
        }
      };

      coroutine zero;
      debug.rdbuf() && debug << "coroutine zero: " << zero.id << std::endl;
      create_context();
      debug.rdbuf() && debug << "coroutine self: " << find_self(coroutines)->id << std::endl;

      exit = [&]{debug.rdbuf() && debug << "enter exit" << std::endl; zero.release();};

      std::unique_lock<std::mutex> lock(mutex);
      while(running || queue.size() || collateral_blocked.size())
      {
        condition.wait(lock, [this]{return !paused;});
        lock.unlock();
        assert(coroutines.size());
        coroutines.back().call(zero);
        lock.lock();
        remove_finished_coroutines(coroutines);
      }
      debug.rdbuf() && debug << "finish pump; #coroutines: " << coroutines.size()
            << " #collateral: " << collateral_blocked.size() << std::endl;

      for(auto& c: coroutines) debug.rdbuf() && debug << c.id << ":" << c.finished << std::endl;

      assert(queue.empty());
      assert(coroutines.size() != 0);
      assert(coroutines.size() != 2);
      assert(coroutines.size() < 3);
      assert(coroutines.size() == 1);
    }
    catch(const std::exception& e)
    {
      debug.rdbuf() && debug << "oops: " << e.what() << std::endl;
      std::terminate();
    }
  }
  bool pump::timers_expired() const
  {
    return timers.size() && timers.begin()->first.expired();
  }
  size_t pump::coroutine_id()
  {
    return find_self(coroutines)->id;
  }
  void pump::create_context()
  {
    coroutines.emplace_back(++id, [&]{
        try
        {
          auto self = find_self(coroutines);
          debug.rdbuf() && debug << "[" << self->id << "] create context" << std::endl;
          context_switch();
          while(running || queue.size() || timers_expired())
          {
            worker();
            if(unblocked.size()) collateral_release(self);
            context_switch();
          }
          exit();
        }
        catch(const forced_unwind&) { debug.rdbuf() && debug << "ignoring forced_unwind" << std::endl; }
        catch(const std::exception& e)
        {
          debug.rdbuf() && debug << "oops: " << e.what() << std::endl;
          std::terminate();
        }
      });
  }
  void pump::context_switch()
  {
    if (switch_context.size())
    {
      debug.rdbuf() && debug << "context_switch" << std::endl;
      auto context = std::move(switch_context.front());
      switch_context.erase(switch_context.begin());
      context();
    }
  }
  void pump::collateral_block(void* c, runtime& rt)
  {
    auto self = find_self(coroutines);
    debug.rdbuf() && debug << "[" << self->id << "] collateral_block" << std::endl;

    collateral_blocked.splice(collateral_blocked.end(), coroutines, self);

    self->component = c;
    size_t coroutine_id = rt.handling(c) | rt.blocked(c);
    auto it = find_if (coroutines.begin (), coroutines.end (),
                       [coroutine_id](coroutine& c) {return c.id == coroutine_id;});

    if (it == coroutines.end() || !it->port)
      throw std::runtime_error("blocking port not found");

    self->port = it->port;

    debug.rdbuf() && debug << "[" << self->id << "] collateral block on "
          << self->port << std::endl;

    create_context();
    self->yield_to(coroutines.back());

    debug.rdbuf() && debug << "[" << self->id << "] collateral_unblock" << std::endl;
  }
  void pump::collateral_release(std::list<coroutine>::iterator self)
  {
    debug.rdbuf() && debug << "[" << self->id << "] collateral_release" << std::endl;

    auto predicate = [this](const coroutine& c)
    {return std::find(unblocked.begin(),
                      unblocked.end(),
                      c.port) != unblocked.end();};

    auto it = collateral_blocked.end();
    do
    {
      it = std::find_if(collateral_blocked.begin(), collateral_blocked.end(), predicate);
      if(it != collateral_blocked.end())
      {
        debug.rdbuf() && debug << "collateral_unblocking: " << it->id
              << " for port: " << it->port << " " << std::endl;
        coroutines.splice(coroutines.end(), collateral_blocked, it);
        coroutines.back().port = nullptr;
        self->finished = true;
        self->yield_to(coroutines.back());
      }
    }
    while(it != collateral_blocked.end());

    if(collateral_blocked.end() == std::find_if(collateral_blocked.begin(), collateral_blocked.end(), predicate))
    {
      debug.rdbuf() && debug << "everything unblocked!!!" << std::endl;
      unblocked.clear();
    }
  }
  void pump::block(runtime& rt, void* c, void* p)
  {
    auto self = find_self (coroutines);
    rt.blocked(c) = self->id;
    rt.handling(c) = 0;
    rt.flush(c,self->id);
    if (rt.skip_block(p))
    {
      rt.skip_block(p) = false;
      return;
    }
    self->port = p;
    debug.rdbuf() && debug << "[" << self->id << "] block on " << p << std::endl;

    bool collateral_skip = collateral_release_skip_block (rt, c);
    if(!collateral_skip)
    {
      auto it = std::find_if(collateral_blocked.begin(),
                             collateral_blocked.end(),
                             [this](const coroutine& i)
                             {return std::find(unblocked.begin(),
                                               unblocked.end(),
                                               i.port) != unblocked.end();});
      if(it != collateral_blocked.end())
      {
        debug.rdbuf() && debug << "[" << it->id << "]" << " move from "
              << it->port << " to " << p << std::endl;
        it->port = p;
      }
      create_context();
    }

    assert(coroutines.back().port == nullptr);
    self->yield_to(coroutines.back());
    debug.rdbuf() && debug << "[" << self->id << "] entered context" << std::endl;
    if (debug.rdbuf())
    {
      debug.rdbuf() && debug << "routines: ";
      for (auto& c: coroutines) {
        debug.rdbuf() && debug << c.id << " ";
      }
      debug.rdbuf() && debug << std::endl;
    }
    remove_finished_coroutines(coroutines);
    rt.skip_block(p) = false;
    rt.blocked(c) = 0;
  }
  bool pump::collateral_release_skip_block(runtime& rt, void* c)
  {
    bool have_collateral = false;
    collateral_blocked.reverse();
    auto it = collateral_blocked.begin();
    while(it != collateral_blocked.end())
    {
      auto self = it++;
      if(std::find_if(unblocked.begin(), unblocked.end(),
                      [&](void* port) {return self->port == port;}) != unblocked.end()
         && self->component == c)
      {
        debug.rdbuf() && debug << "[" << self->id << "]" << " relay skip "
              << self->port << std::endl;
        have_collateral = true;
        self->component = nullptr;
        self->port = nullptr;
        coroutines.splice(coroutines.end(), collateral_blocked, self);
      }
    }
    collateral_blocked.reverse();
    return have_collateral;
  }
  void pump::release(runtime& rt, void* p)
  {
    rt.skip_block(p) = true;

    auto self = find_self(coroutines);
    debug.rdbuf() && debug << "[" << self->id << "] release of " << p << std::endl;

    auto blocked = find_blocked(coroutines, p);
    if(blocked == coroutines.end())
    {
      debug.rdbuf() && debug << "[" << self->id << "] skip block" << std::endl;
      return;
    }

    debug.rdbuf() && debug << "[" << blocked->id << "] unblock" << std::endl;

    switch_context.emplace_back([blocked,&rt,p,this] {
      auto self = find_self(coroutines);
      debug.rdbuf() && debug << "setting unblocked to port " << blocked->port << std::endl;
      unblocked.push_back(blocked->port);
      blocked->component = nullptr;
      blocked->port = nullptr;

      debug.rdbuf() && debug << "[" << self->id << "] switch from" << std::endl;
      debug.rdbuf() && debug << "[" << blocked->id << "] to" << std::endl;

      self->finished = true;
      self->yield_to(*blocked);
      assert(!"we must never return here!!!");
    });
  }
  void pump::operator()(const std::function<void()>& e)
  {
    assert(e);
    std::lock_guard<std::mutex> lock(mutex);
    queue.push(e);
    condition.notify_one();
  }
  void pump::operator()(std::function<void()>&& e)
  {
    assert(e);
    std::lock_guard<std::mutex> lock(mutex);
    queue.push(std::move(e));
    condition.notify_one();
  }
  void pump::defer(std::function<bool()>&& predicate, std::function<void(size_t)>&& e)
  {
    deferred.emplace_back(std::move(predicate), std::move(e));
  }
  void pump::prune_deferred()
  {
    deferred.erase(std::remove_if(deferred.begin(), deferred.end(),
                                  [](const std::pair<std::function<bool()>,std::function<void(size_t)>>& e){return !e.first();}),
                   deferred.end());
  }
  void pump::handle(size_t id, size_t ms, const std::function<void()>& e, size_t rank)
  {
    assert(e);
    assert(std::find_if(timers.begin(), timers.end(), [id](const std::pair<deadline, std::function<void()>>& p){ return p.first.id == id; }) == timers.end());
    timers.emplace(deadline(id, ms, rank), e);
  }
  void pump::remove(size_t id)
  {
    auto it = std::find_if(timers.begin(), timers.end(), [id](const std::pair<deadline, std::function<void()>>& p){ return p.first.id == id; });
    if(it != timers.end()) timers.erase(it);
  }
}
