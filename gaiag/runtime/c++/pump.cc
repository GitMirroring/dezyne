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

static void debug(const std::string& s)
{
#ifdef DEBUG_RUNTIME
  std::cout << s << std::endl;
#endif
}

static void debug(const std::string& s, int id)
{
#ifdef DEBUG_RUNTIME
  std::cout << '[' << id << "] " << s << std::endl;
#endif
}

namespace dezyne
{
int coroutine::g_id = 0;

auto find_self = [] (std::list<coroutine>& coroutines){
  int count =0;
  for (auto& c: coroutines) {
    if (c.port == nullptr && !c.finished) count++;
  }
  auto self = std::find_if(coroutines.begin(), coroutines.end(), [](dezyne::coroutine& c){return c.port == nullptr && !c.finished;});
  if(self == coroutines.end()) throw std::runtime_error("cannot find my self");
  if (count !=1)throw std::runtime_error("too many coros");
  return self;
};

auto find_blocked = [] (std::list<coroutine>& coroutines, void* port) {
  auto self = std::find_if(coroutines.begin(), coroutines.end(), [port](dezyne::coroutine& c){return c.port == port;});
  return self;
};

auto finish = [&](std::list<coroutine>& coroutines){
  auto self = find_self(coroutines);
  self->finished = true;
  debug("finish coroutine", self->id);
};

pump::pump()
: switch_context()
, running(true)
, task(std::async(std::launch::async, std::ref(*this)))
{}
pump::~pump()
{
  std::unique_lock<std::mutex> lock(mutex);
  running = false;
  condition.notify_one();
  if (lock) lock.unlock();
  task.get();
}
void pump::operator()()
{
  try
  {
    thread_id = std::this_thread::get_id();

    worker = [&] {
      std::unique_lock<std::mutex> lock(mutex);
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
        if (lock) lock.unlock();
        t.second();
      }

      if(queue.size())
      {
        std::function<void()> f(std::move(queue.front()));
        queue.pop();
        if (lock) lock.unlock();
        f();
      }
    };

    coroutine zero;
    create_context();

    exit = [&]{debug("enter exit"); zero.release();};

    std::unique_lock<std::mutex> lock(mutex);
    while(running || queue.size() || collateral_blocked.size())
    {
      assert(coroutines.size());
      if (lock) lock.unlock();
      coroutines.back().call(zero.context);
      lock.lock();
      coroutines.remove_if([](dezyne::coroutine& c){if(c.finished) debug("removing", c.id); return c.finished;});
    }
    debug("finish pump");
    assert(queue.empty());
  }
  catch(const std::exception& e)
  {
    std::cout << "oops: " << e.what() << std::endl;
    std::terminate();
  }
}
void pump::create_context()
{
  coroutines.emplace_back([&]{
      try
      {
        auto self = find_self(coroutines);
        debug("create context", self->id);
        while((running || queue.size()) && !self->released)
        {
          worker();
          if(!self->released)
          {
            collateral_release(self);
          }
        }

        if(self->released) finish(coroutines);

        if(switch_context) decltype(switch_context)(std::move(switch_context))();

        if(!self->released) collateral_release(self);

        exit();
      }
#if HAVE_BOOST_COROUTINE
      catch(const boost::coroutines::detail::forced_unwind&) {throw;}
#else
      catch(const context::unwind&) {}
#endif
      catch(const std::exception& e)
      {
        std::cout << "oops: " << e.what() << std::endl;
        std::terminate();
      }
    });
}
void pump::collateral_block()
{
  auto self = find_self(coroutines);
  debug("collateral_block", self->id);

  collateral_blocked.splice(collateral_blocked.end(), coroutines, self);
  create_context();
  self->yield_to(coroutines.back().context);

  debug("collateral_unblock", self->id);
}
void pump::collateral_release(std::list<coroutine>::iterator self)
{
  if(collateral_blocked.size()) finish(coroutines);
  while(collateral_blocked.size())
  {
    coroutines.splice(coroutines.end(), collateral_blocked, collateral_blocked.begin());
    self->yield_to(coroutines.back().context);
  }
}
void pump::block(void* p)
{
  auto it = skip_block.find(p);
  if(it != skip_block.end())
  {
    skip_block.erase(it);
    return;
  }

  auto self = find_self(coroutines);
  if(self->skip_block)
  {
    self->skip_block = false;
    return;
  }

  self->port = p;

  debug("block", self->id);
  create_context();

  self->yield_to(coroutines.back().context);
  debug("entered context", self->id);
#ifdef DEBUG_RUNTIME
  std::cout << "routines: ";
  for (auto& c: coroutines) {
    std::clog << c.id << " ";
  }
  std::cout << std::endl;
#endif
  coroutines.remove_if([](dezyne::coroutine& c){if(c.finished) debug("removing",c.id); return c.finished;});
}
void pump::release(void* p)
{
  auto self = find_self(coroutines);

  auto blocked = find_blocked(coroutines, p);
  if(blocked == coroutines.end())
  {
    skip_block.insert(p);
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
void pump::and_wait(const std::function<void()>& e)
{
  if (std::this_thread::get_id() == thread_id)
    return operator()(e);
  return and_wait_(e);
}
void pump::and_wait_(const std::function<void()>& e)
{
  std::promise<void> p;

  assert(e);
  {std::lock_guard<std::mutex> lock(mutex);
    queue.push([&]{e(); p.set_value();});}
  condition.notify_one();
  p.get_future().get();
}
void pump::handle(size_t id, size_t ms, const std::function<void()>& e)
{
  assert(e);
  assert(std::find_if(timers.begin(), timers.end(), [id](const std::pair<deadline, std::function<void()>>& p){ return p.first.id == id; }) == timers.end());
  timers.emplace(deadline(id, ms), e);
}
void pump::remove(size_t id)
{
  auto it = std::find_if(timers.begin(), timers.end(), [id](const std::pair<deadline, std::function<void()>>& p){ return p.first.id == id; });
  if(it != timers.end()) timers.erase(it);
}
}
