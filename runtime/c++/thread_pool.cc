// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2020 Rutger van Beusekom <rutger@dezyne.org>
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

#include <cassert>
#include <condition_variable>
#include <functional>
#include <future>
#include <mutex>
#include <queue>
#include <vector>

namespace dzn
{
namespace thread
{
class task;
class pool
{
  class task;
  friend class task;
  std::vector<std::shared_ptr<const task> > tasks_;
  std::queue<task *> idle_tasks_;
  std::condition_variable con_;
  std::mutex mut_;
public:
  pool () {}
  ~pool ()
  {
    std::unique_lock<std::mutex> lock (mut_);
    while (! (idle_tasks_.size () == tasks_.size ()))
      {
        con_.wait (lock);
      }
  }
  std::future<void> defer (const std::function<void ()> &work)
  {
    std::unique_lock<std::mutex> lock (mut_);
    if (idle_tasks_.empty ())
      {
        task *pt = new task (*this);
        tasks_.push_back (std::shared_ptr<const task> (pt));
        return pt->assign (work);
      }
    else
      {
        std::future<void> fut = idle_tasks_.front ()->assign (work);
        idle_tasks_.pop ();
        return fut;
      }
  }
  size_t capacity () const
  {
    return tasks_.size ();
  }
private:
  pool &operator = (const pool &);
  pool (const pool &);

  void idle (task *t)
  {
    std::unique_lock<std::mutex> lock (mut_);
    idle_tasks_.push (t);
    if (idle_tasks_.size () == tasks_.size ()) { con_.notify_one (); };
  }
  class task
  {
    pool &pool_;
    bool running_;
    std::function<void ()> work_;
    std::promise<void> promise_;
    std::mutex mut_;
    std::condition_variable con_;
    std::thread thread_;
  public:
    task (pool &p)
      : pool_ (p)
      , running_ (true)
      , work_ ()
      , mut_ ()
      , con_ ()
      , thread_ (std::bind (&task::worker, self ()))
    {}
    ~task ()
    {
      std::unique_lock<std::mutex> lock (mut_);
      running_ = false;
      con_.notify_one ();
      lock.unlock ();
      thread_.join ();
    }
    task *self () { return this; }
    std::future<void> assign (std::function<void ()> work)
    {
      std::unique_lock<std::mutex> lock (mut_);
      assert (!work_);
      work_.swap (work);
      promise_ = std::promise<void> ();
      con_.notify_one ();
      return promise_.get_future ();
    }
    void worker ()
    {
      std::unique_lock<std::mutex> lock (mut_);
      do
        {
          while (running_ && !work_)
            {
              con_.wait (lock);
            }
          if (work_)
            {
              std::function<void ()> work;
              work_.swap (work);
              lock.unlock ();
              work ();
              promise_.set_value ();
              pool_.idle (this);
              lock.lock ();
            }
        }
      while (running_);
    }
  private:
    task (const task &);
    task &operator = (const task &);
  };
};

std::future<void> defer (const std::function<void ()> &work)
{
  static thread::pool tp;
  return tp.defer (work);
}
}
}
