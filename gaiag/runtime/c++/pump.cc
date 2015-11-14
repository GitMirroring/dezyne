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
#include <list>

#include "coroutine.hh"

static void debug(const std::string& s)
{
#ifdef DEBUG
  std::cout << s << std::endl;
#endif
}

static void debug(const std::string& s, int id)
{
#ifdef DEBUG
  std::cout << '[' << id << "] " << s << std::endl;
#endif
}

namespace dezyne
{
  int coroutine::g_id = 0;

  std::list<coroutine> coroutines;

  auto find_self = [] {
    int count =0;
    for (auto& c: coroutines) {
      if (c.port == nullptr && !c.finished) count++;
    }
    auto self = std::find_if(coroutines.begin(), coroutines.end(), [](dezyne::coroutine& c){return c.port == nullptr && !c.finished;});
    if(self == coroutines.end()) throw std::runtime_error("cannot find my self");
    if (count !=1)throw std::runtime_error("too many coros");
    return self;
  };

  auto find_blocked = [] (void* port) {
    auto self = std::find_if(coroutines.begin(), coroutines.end(), [port](dezyne::coroutine& c){return c.port == port;});
    return self;
  };

  auto finish = [&](char const* name){
    auto self = find_self();
    self->finished = true;
    debug(std::string("exit ") + name + " coroutine", self->id);
  };

  static std::function<void()> worker;

  pump::pump()
  : switch_context([]{})
  , running(true)
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
        if(!lock) lock.lock();
        if(timers.empty())
        {
          condition.wait(lock, [this]{return queue.size() || !running;});
        }
        else
        {
          condition.wait_until(lock, timers.begin()->first.t, [this]{return queue.size() || !running;});
        }

        while(timers.size() && timers.begin()->first.expired())
        {
          auto t = *timers.begin();
          timers.erase(timers.begin());
          lock.unlock();
          t.second();
          if(!lock) lock.lock();
        }

        if(queue.size())
        {
          std::function<void()> f(std::move(queue.front()));
          queue.pop();
          lock.unlock();
          f();
        }
      };

      coroutine zero;

      exit = [&]{debug("enter exit"); zero.release();};

      if(!lock) lock.lock();
      while(running || queue.size())
      {
        do_one("main");
        coroutines.back().call(zero.context);
        debug("finish pump");
        coroutines.remove_if([](dezyne::coroutine& c){if(c.finished) debug("removing", c.id); return c.finished;});
      }
      assert(queue.empty());
    }
    catch(const std::exception& e)
    {
      std::clog << "oops: " << e.what() << std::endl;
      std::abort();
    }
  }
  void pump::do_one(char const* level)
  {
    coroutines.emplace_back([&]{
        auto self = find_self();
        debug(std::string(level) + " coroutine", self->id);
        while((running || queue.size()) && !self->released)
          {
            debug(level, self->id);
            worker();
          }
        finish(level);

        if(coroutines.size() != 1)
          {
            decltype(switch_context) tmp([]{});
            std::swap(switch_context, tmp);
            tmp();
          }
        else
          {
            exit();
          }
      });
  }
  void pump::block(void* p)
  {
    auto self = find_self();
    if(self->skip_block)
    {
      self->skip_block = false;
      return;
    }

    self->port = p;

    debug("block", self->id);
    do_one("new");
    self = find_blocked(p);

    self->yield_to(coroutines.back().context);
    debug("entered context", self->id);
    std::clog << "routines: ";
    for (auto& c: coroutines) {
      std::clog << c.id << " ";
    }
    std::clog << std::endl;
    coroutines.remove_if([](dezyne::coroutine& c){if(c.finished) debug("removing",c.id); return c.finished;});
  }
  void pump::release(void* p)
  {
    auto self = find_self();

    auto blocked = find_blocked(p);
    if(blocked == coroutines.end())
    {
      self->skip_block = true;
      return;
    }

    debug("unblock", blocked->id);
    debug("released", self->id);
    self->released = true;

    switch_context = [blocked,self] {
        blocked->port = nullptr;

        debug("switch from", self->id);
        debug("to", blocked->id);

        self->yield_to(blocked->context);
      };
  }
  void pump::operator()(const std::function<void()>& e)
  {
    assert(e);
    assert(std::this_thread::get_id() != thread_id);
    std::lock_guard<std::mutex> lock(mutex);
    queue.push(e);
    condition.notify_one();
  }
  void pump::operator()(std::function<void()>&& e)
  {
    assert(e);
    assert(std::this_thread::get_id() != thread_id);
    std::lock_guard<std::mutex> lock(mutex);
    queue.push(std::move(e));
    condition.notify_one();
  }
  void pump::and_wait(const std::function<void()>& e)
  {
    std::promise<void> p;

    assert(e);
    assert(std::this_thread::get_id() != thread_id);

    {std::lock_guard<std::mutex> lock(mutex);
    queue.push([&]{e(); p.set_value();});
    condition.notify_one();}

    p.get_future().get();
  }
  void pump::handle(size_t id, size_t ms, const std::function<void()>& e)
  {
    assert(e);
#if HAVE_BOOST_COROUTINE
    assert(std::this_thread::get_id() == thread_id);
#endif // HAVE_BOOST_COROUTINE
    assert(std::find_if(timers.begin(), timers.end(), [id](const std::pair<deadline, std::function<void()>>& p){ return p.first.id == id; }) == timers.end());
    timers.emplace(deadline(id, ms), e);
  }
  void pump::remove(size_t id)
  {
#if HAVE_BOOST_COROUTINE
    assert(std::this_thread::get_id() == thread_id);
#endif // HAVE_BOOST_COROUTINE
    auto it = std::find_if(timers.begin(), timers.end(), [id](const std::pair<deadline, std::function<void()>>& p){ return p.first.id == id; });
    if(it != timers.end()) timers.erase(it);
  }
}
