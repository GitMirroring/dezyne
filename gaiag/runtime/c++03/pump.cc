// Dezyne --- Dezyne command line tools
//
// Copyright © 2015, 2016, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include <dzn/locator.hh>
#include <dzn/meta.hh>
#include <dzn/pump.hh>

#include <algorithm>
#include <cassert>
#include <new>

#ifdef DEBUG_RUNTIME
#include <iostream>
#endif

namespace dzn
{
  size_t coroutine::g_id = 0;

  void port_block(const locator& l, void* p)
  {
    l.get<dzn::pump>().block(p);
  }
  void port_release(const locator& l, void* p, boost::function<void()>& out_binding)
  {
    if(out_binding) out_binding();
    out_binding = 0;
    l.get<dzn::pump>().release(p);
  }
  void collateral_block(const locator& l)
  {
    l.get<dzn::pump>().collateral_block_lambda();
  }
  inline void compose_sequence(const boost::function<void()>& f, const boost::function<void()>& g) {f(); g();}
  void call_async_helper(const locator& l, const meta& m, size_t id, const boost::function<void()>& f, const boost::function<void()>& g)
  {
    l.get<dzn::pump>().handle(id, 0, boost::bind(compose_sequence,f,g), m.rank);
  }

  inline bool unblocked_p(const coroutine& c)
  {
    return c.port == 0 && !c.finished;
  }

  static std::list<coroutine>::iterator find_self(std::list<coroutine>& coroutines)
  {
    assert(1 == std::count_if(coroutines.begin(), coroutines.end(), unblocked_p));
    std::list<coroutine>::iterator self = std::find_if(coroutines.begin(), coroutines.end(), unblocked_p);
    return self;
  }

  inline bool blocked_p(void* port, const coroutine& c)
  {
    return port == c.port;
  }

  static std::list<coroutine>::iterator find_blocked(std::list<coroutine>& coroutines, void* port)
  {
    std::list<coroutine>::iterator self = std::find_if(coroutines.begin(), coroutines.end(), boost::bind<bool>(blocked_p, port, _1));
    return self;
  }

  static void finish(std::list<coroutine>& coroutines)
  {
    std::list<coroutine>::iterator self = find_self(coroutines);
    self->finished = true;
    debug << "[" << self->id << "] finish coroutine" << std::endl;
  }

  pump::pump()
  : collateral_block_lambda(boost::bind(&pump::collateral_block, this))
  , switch_context()
  , running(true)
  , task(boost::async(boost::launch::async, boost::function<void()>(boost::ref(*this))))
  {}
  pump::~pump()
  {
    stop();
  }
  void pump::stop()
  {
    boost::unique_lock<boost::mutex> lock(mutex);
    if(running)
    {
      running = false;
      condition.notify_one();
      if (lock) lock.unlock();
      task.wait();
    }
  }
  void pump::wait()
  {
    boost::unique_lock<boost::mutex> lock(mutex);
    while(queue.empty()) {
      idle.wait(lock);
    }
  }
  void pump::worker_helper()
  {
    boost::unique_lock<boost::mutex> lock(mutex);
    if(queue.empty())
    {
      idle.notify_one();
    }
    if(timers.empty())
    {
      while(queue.empty() && running)
        condition.wait(lock);
    }
    else
    {
      while(queue.empty() && running)
        condition.wait_until(lock, timers.begin()->first.t);
    }

    if(queue.size())
    {
      boost::function<void()> f;
      std::swap(queue.front(), f);
      queue.pop();
      lock.unlock();
      f();
      lock.lock();
    }

    while(timers.size() && timers.begin()->first.expired())
    {
      boost::function<void()> f(timers.begin()->second);
      timers.erase(timers.begin());
      lock.unlock();
      f();
      lock.lock();
    }
  }
  void pump::operator()()
  {
    try
    {
      thread_id = boost::this_thread::get_id();

      worker = boost::bind(&pump::worker_helper, this);

      coroutine zero;
      create_context();

      exit = boost::bind(&coroutine::release, &zero);

      boost::unique_lock<boost::mutex> lock(mutex);
      while(running || queue.size() || collateral_blocked.size())
      {
        assert(coroutines.size());

        lock.unlock();

        coroutines.back().call(zero);

        lock.lock();

        remove_finished_coroutines();
      }
      debug << "finish pump" << std::endl;
      assert(queue.empty());
    }
    catch(const std::exception& e)
    {
      debug << __FILE__ << ":" << __LINE__ << ": oops: " << e.what() << std::endl;
      std::terminate();
    }
  }
  void pump::create_context_helper()
  {
    try
    {
      std::list<coroutine>::iterator self = find_self(coroutines);
      debug << "[" << self->id << "] create context" << std::endl;
      while(!self->released && (running ||
                                queue.size() ||
                                coroutines.size() > 1))
      {
        worker();
        if(!self->released) collateral_release(self);
      }
      if(self->released) finish(coroutines);

      if(switch_context) {
        boost::function<void()> tmp;
        std::swap(tmp, switch_context);
        tmp();
      }

      if(!self->released) collateral_release(self);

      exit();
    }
    catch(const forced_unwind&) {throw;}
    catch(const std::exception& e)
    {
      debug << __FILE__ << ":" << __LINE__ << ": oops: " << e.what() << std::endl;
      std::terminate();
    }
  }
  void pump::create_context()
  {
    coroutines.push_back(coroutine());
    coroutines.back().~coroutine();
    new (&coroutines.back()) dzn::coroutine(boost::function<void()>(boost::bind(&pump::create_context_helper, this)));
  }
  void pump::collateral_block()
  {
    std::list<coroutine>::iterator self = find_self(coroutines);
    debug << "[" << self->id << "] collateral_block" << std::endl;

    collateral_blocked.splice(collateral_blocked.end(), coroutines, self);
    create_context();
    self->yield_to(coroutines.back());

    debug << "[" << self->id << "] collateral_unblock" << std::endl;
  }
  void pump::collateral_release(std::list<coroutine>::iterator self)
  {
    if(collateral_blocked.size()) finish(coroutines);
    while(collateral_blocked.size())
    {
      coroutines.splice(coroutines.end(), collateral_blocked, collateral_blocked.begin());
      self->yield_to(coroutines.back());
    }
  }
  void pump::block(void* p)
  {
    std::set<void*>::iterator it = skip_block.find(p);
    if(it != skip_block.end())
    {
      skip_block.erase(it);
      return;
    }

    std::list<coroutine>::iterator self = find_self(coroutines);

    self->port = p;

    debug << "[" << self->id << "] block" << std::endl;

    create_context();

    self->yield_to(coroutines.back());
    debug << "[" << self->id << "] entered context" << std::endl;
    if (debug.rdbuf())
    {
      debug << "routines: ";
      for (std::list<coroutine>::iterator it = coroutines.begin(); it != coroutines.end(); ++it) {
        debug << it->id << " ";
      }
      debug << std::endl;
    }
    remove_finished_coroutines();
  }
  inline void switch_context_helper(std::list<coroutine>::iterator blocked, std::list<coroutine>::iterator self)
  {
    blocked->port = 0;

    debug << "[" << self->id << "] switch from" << std::endl;
    debug << "[" << blocked->id << "] to" << std::endl;

    self->yield_to(*blocked);
  }
  void pump::release(void* p)
  {
    std::list<coroutine>::iterator self = find_self(coroutines);

    std::list<coroutine>::iterator blocked = find_blocked(coroutines, p);
    if(blocked == coroutines.end())
    {
    debug << "[" << self->id << "] skip block" << std::endl;
      skip_block.insert(p);
      return;
    }

    debug << "[" << blocked->id << "] unblock" << std::endl;
    debug << "[" << self->id << "] released" << std::endl;
    self->released = true;

    switch_context = boost::bind(&switch_context_helper,blocked,self);
  }
  void pump::operator()(const boost::function<void()>& e)
  {
    assert(e);
    boost::lock_guard<boost::mutex> lock(mutex);
    queue.push(e);
    condition.notify_one();
  }
  inline bool timer_p(size_t id, const std::pair<pump::deadline, boost::function<void()> >& p)
  {
    return p.first.id == id;
  }
  void pump::handle(size_t id, size_t ms, const boost::function<void()>& e, size_t rank)
  {
    assert(e);
    assert(std::find_if(timers.begin(), timers.end(), boost::bind<bool>(&timer_p, id, _1)) == timers.end());
    timers.insert(std::make_pair(deadline(id, ms, rank), e));
  }
  void pump::remove(size_t id)
  {
    std::map<deadline, boost::function<void()> >::iterator it = std::find_if(timers.begin(), timers.end(), boost::bind<bool>(&timer_p, id, _1));
    if(it != timers.end()) timers.erase(it);
  }

  inline bool finished_p(const coroutine& c){if(c.finished) debug << "[" << c.id << "] removing" << std::endl; return c.finished;}

  void pump::remove_finished_coroutines()
  {
    coroutines.remove_if(finished_p);
  }
}
