// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2015, 2016, 2017, 2018, 2019, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2016 Rob Wieringa <rma.wieringa@gmail.com>
// Copyright © 2016 Henk Katerberg <hank@mudball.nl>
// Copyright © 2015, 2016, 2017, 2019, 2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
  size_t coroutine_id(const locator& l)
  {
    auto ppump = l.try_get<dzn::pump>();
    return !ppump ? 1 : ppump->coroutine_id();
  }
  static std::list<coroutine>::iterator find_self(std::list<coroutine>& coroutines);
  void port_block(const locator& l, void* c, void* p)
  {
    auto& rt = l.get<dzn::runtime>();
    rt.handling(c) = 0;
    rt.flush(c,coroutine_id(l));
    if(rt.skip_block(p)) return;
    auto& pump = l.get<dzn::pump>();
    auto self = find_self (pump.coroutines);
    assert(rt.blocked_port_component_stack[self->id].empty());
    rt.blocked_port_component_stack[self->id] = rt.component_stack;
    rt.component_stack.clear();
    pump.block(rt, c, p);
  }
  void port_release(const locator& l, void* p, std::function<void()>& out_binding)
  {
    if(out_binding) out_binding();
    out_binding = nullptr;
    auto& rt = l.get<dzn::runtime>();
    rt.skip_block(p) = true;
    l.get<dzn::pump>().release(rt,p);
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
    //debug << "#runnable coroutines: " << count << std::endl;
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
    idle.wait(lock, [this]{return queue.empty();});
  }
  void pump::operator()()
  {
    //debug << "operator(): " << coroutine::get_id() << std::endl;

    try
    {
      worker = [&] {
        debug << "worker self: " << find_self(coroutines)->id << std::endl;

        std::unique_lock<std::mutex> lock(mutex);
        if(queue.empty())
        {
          idle.notify_one();
        }
        if(timers.empty())
        {
          condition.wait(lock, [this]{return queue.size() || !running;});
        }
        else
        {
          condition.wait_until(lock, timers.begin()->first.t, [this]{return queue.size() || !running;});
        }

        if(queue.size())
        {
          std::function<void()> f(std::move(queue.front()));
          queue.pop();
          lock.unlock();
          f();
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

    assert(1 == std::count_if(rt.blocked_port_component_stack.begin(),
                              rt.blocked_port_component_stack.end(),
                              [c](const std::pair<size_t, std::vector<void*>>& o)
                              {
                                return std::find(o.second.begin(),
                                                 o.second.end(),
                                                 c)
                                  != o.second.end();
                              }));

    auto it = std::find_if(rt.blocked_port_component_stack.begin(),
                           rt.blocked_port_component_stack.end(),
                           [c](const std::pair<size_t, std::vector<void*>>& o)
                           {
                             return std::find(o.second.begin(),
                                              o.second.end()
                                              ,c)
                               != o.second.end();
                           });

    assert(it != rt.blocked_port_component_stack.end());

    self->component = c;
    auto itc = find_if (coroutines.begin (), coroutines.end (),
                        [it](coroutine& c) {return c.id == it->first;});
    self->port = itc->port;
    assert(rt.blocked_port_component_stack[self->id].empty());
    rt.blocked_port_component_stack[self->id] = rt.component_stack;
    rt.component_stack.clear ();

    debug.rdbuf() && debug << "[" << self->id << "] collateral block on "
          << self->port << std::endl;

    create_context();
    self->yield_to(coroutines.back());

    debug.rdbuf() && debug << "[" << self->id << "] collateral_unblock" << std::endl;
    auto& v = rt.blocked_port_component_stack[self->id];
    rt.component_stack.insert(rt.component_stack.end(), v.begin(), v.end());
    rt.blocked_port_component_stack[self->id].clear ();
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
    auto self = find_self(coroutines);
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
        std::swap(rt.component_stack,rt.blocked_port_component_stack.at(self->id));
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
    auto self = find_self(coroutines);
    debug.rdbuf() && debug << "[" << self->id << "] release of " << p << std::endl;

    auto blocked = find_blocked(coroutines, p);
    if(blocked == coroutines.end())
    {
      debug.rdbuf() && debug << "[" << self->id << "] skip block" << std::endl;
      return;
    }

    debug.rdbuf() && debug << "[" << blocked->id << "] unblock" << std::endl;

    switch_context.emplace_back([blocked,self,&rt,p,this] {
      auto self = find_self(coroutines);
      debug.rdbuf() && debug << "setting unblocked to port " << blocked->port << std::endl;
      unblocked.push_back(blocked->port);
      blocked->component = nullptr;
      blocked->port = nullptr;

      debug.rdbuf() && debug << "[" << self->id << "] switch from" << std::endl;
      debug.rdbuf() && debug << "[" << blocked->id << "] to" << std::endl;

      assert(rt.component_stack.empty());
      std::swap(rt.component_stack,rt.blocked_port_component_stack.at(blocked->id));

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
