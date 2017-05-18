// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
// Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#ifndef DZN_PUMP_HH
#define DZN_PUMP_HH

#include <dzn/coroutine.hh>

#undef BOOST_THREAD_PROVIDES_FUTURE
#define BOOST_THREAD_PROVIDES_FUTURE 1

#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/thread.hpp>
#include <boost/thread/future.hpp>

#include <list>
#include <map>
#include <queue>
#include <set>

namespace dzn
{
  extern std::ostream debug;

  struct pump
  {
    boost::function <void()> collateral_block_lambda;
    boost::function<void()> worker;
    std::list<coroutine> coroutines;
    std::list<coroutine> collateral_blocked;
    std::set<void*> skip_block;
    std::queue<boost::function<void()> > queue;

    struct deadline
    {
      size_t id;
      boost::chrono::steady_clock::time_point t;
      size_t rank;
      deadline(size_t id, size_t ms, size_t rank)
      : id(id)
      , t(boost::chrono::steady_clock::now() + boost::chrono::milliseconds(ms))
      , rank(rank)
      {}
      bool expired() const {return t <= boost::chrono::steady_clock::now();}
      bool operator < (const deadline& d) const { return rank_less(d); }
    private:
      bool rank_less(const deadline& d) const {return rank < d.rank || (rank == d.rank && time_less(d));}
      bool time_less(const deadline& d) const {return t < d.t || (t == d.t && id < d.id);}
    };

    std::map<deadline, boost::function<void()> > timers;
    boost::function<void()> switch_context;
    boost::function<void()> exit;
    boost::thread::id thread_id;
    bool running;
    boost::condition_variable condition;
    boost::condition_variable idle;
    boost::mutex mutex;
    boost::future<void> task;
    pump();
    ~pump();
    void stop();
    void wait();
    void worker_helper();
    void operator()();

    void collateral_block();
    void collateral_release(std::list<coroutine>::iterator);

    void block(void*);
    void create_context_helper();
    void create_context();
    void release(void*);
    void operator()(const boost::function<void()>&);
    void handle(size_t id, size_t ms, const boost::function<void()>&, size_t rank = std::numeric_limits<size_t>::max());
    void remove(size_t id);
  private:
    void remove_finished_coroutines();
  };

  template <typename L>
  void blocking_helper(boost::promise<void>& p, const L& l)
  {
    l();
    p.set_value();
  }
  template <typename L>
  void blocking(dzn::pump& pump, const L& l)
  {
    boost::promise<void> p;
    pump(boost::function<void()>(boost::bind(&blocking_helper<L>, boost::ref(p), l)));
    return p.get_future().get();
  }
}

#endif //DZN_PUMP_HH
