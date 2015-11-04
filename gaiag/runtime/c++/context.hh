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

#ifndef CONTEXT_HH
#define CONTEXT_HH

#include <algorithm>
#include <condition_variable>
#include <functional>
#include <future>
#include <exception>
#include <iomanip>
#include <iostream>
#include <map>
#include <mutex>
#include <sstream>
#include <stdexcept>
#include <thread>

namespace dezyne
{
  struct thread_id_helper {
    thread_id_helper() {}

    friend std::ostream& operator << (std::ostream& os, const thread_id_helper&)
    {
      return os << std::setfill('0') << std::setw(6) << __gthread_self () - (__gthread_self () / 100000) * 100000 << ' ';
    }
  } _;

  class context;
  enum State {INITIAL, RELEASED, BLOCKED, FINAL};
  std::string to_string(State state)
  {
    switch(state)
    {
    case INITIAL: return "INITIAL";
    case RELEASED: return "RELEASED";
    case BLOCKED: return "BLOCKED";
    case FINAL: return "FINAL";
    }
    throw std::logic_error("UNKNOWN STATE");
  }

  class context
  {
    State state;
  public:
    std::function<void(std::function<void(context&)>&&)> work;
    std::function<void()> rel;
    std::unique_ptr<std::mutex> mutex;
    std::unique_ptr<std::condition_variable> condition;
    std::thread thread;
  public:
    context(bool thread_p=true)
    : state(INITIAL)
    , work()
    , mutex(std::make_unique<std::mutex>())
    , condition(std::make_unique<std::condition_variable>())
    , thread([&thread_p, this] {
        if(!thread_p) return;
        //std::clog << _ << "enter context" << std::endl;
        std::unique_lock<std::mutex> lock(*this->mutex);
        while(state != FINAL)
        {
          do_block(lock);
          if(state == FINAL) break;
          //std::clog << _ << "before work" << std::endl;
          if(!this->work) break;

          lock.unlock();
          this->work([this](context& c){ yield(c); });
          lock.lock();

          //std::clog << _ << "after work" << std::endl;
          if(state == FINAL) break;

          this->rel();
        }
        //std::clog << _ << "exit context" << std::endl;
      })
    {
      if(!thread_p) return;
      std::unique_lock<std::mutex> lock(*mutex);
      //std::clog << _ << "ctor waiting" << std::endl;
      while(state != BLOCKED) condition->wait(lock);
      //std::clog << _ << "ctor ready" << std::endl;
    }
    context(context&&) = delete;//default;
    context& operator=(context&&) = delete;//default;
    context(const context&) = delete;
    context& operator=(const context&) = delete;
    template <typename Work>
    context(Work&& work)
    : context()
    {
      this->work = std::move(work);
    }
    ~context()
    {
      if(!mutex) return;
      std::unique_lock<std::mutex> lock(*mutex);
      do_finish(lock);
    }
    std::thread::id get_id()
    {
      return thread.get_id();
    }
    void finish()
    {
      std::unique_lock<std::mutex> lock(*mutex);
      do_finish(lock);
    }
    void block()
    {
      std::unique_lock<std::mutex> lock(*mutex);
      do_block(lock);
    }
    void release()
    {
      std::unique_lock<std::mutex> lock(*mutex);
      do_release(lock);
    }
    void call(context& c)
    {
      std::unique_lock<std::mutex> lock(*mutex);
      this->rel = [&]{c.release();};
      do_release(lock);

      std::unique_lock<std::mutex> lock2(*c.mutex);
      c.state = BLOCKED;

      lock.unlock();

      do { c.condition->wait(lock2); } while(c.state == BLOCKED);
    }
    template <typename Work>
    void yield(Work&& work, context& c)
    {
      std::unique_lock<std::mutex> lock(*mutex);
      this->work = std::move(work);
      this->rel = [&]{c.release();};
      do_release(lock);

      std::unique_lock<std::mutex> lock2(*c.mutex);
      c.state = BLOCKED;

      lock.unlock();

      do { c.condition->wait(lock2); } while(c.state == BLOCKED);
    }
    void yield(context& to)
    {
      if(&to == this) return;
      std::unique_lock<std::mutex> lock(*mutex);
      to.release();
      do_block(lock);
    }
  private:
    void do_block(std::unique_lock<std::mutex>& lock)
    {
      //std::clog << _ << "enter block: " << to_string(state) << std::endl;
      state = BLOCKED;
      condition->notify_one();
      do { condition->wait(lock); } while(state == BLOCKED);
      //std::clog << _ << "exit block: " << to_string(state) << std::endl;
    }
    void do_release(std::unique_lock<std::mutex>&)
    {
      //std::clog << _ << "enter release: " << to_string(state) << std::endl;
      if(state != BLOCKED) throw std::runtime_error("not allowed to release a call which is " +
                                                    to_string(state));
      state = RELEASED;
      condition->notify_one();
      //std::clog << _ << "exit release: " << to_string(state) << std::endl;
    }
    void do_finish(std::unique_lock<std::mutex>& lock)
    {
      //std::clog << _ << "enter finish: " << to_string(state) << std::endl;
      state = FINAL;
      lock.unlock();
      condition->notify_all();
      thread.join();
      //std::clog << _ << "exit finish: " << to_string(state) << std::endl;
    }
  };
}

#endif //CONTEXT_HH
