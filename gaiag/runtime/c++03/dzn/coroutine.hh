// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
// Copyright © 2015, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#ifndef DZN_COROUTINE_HH
#define DZN_COROUTINE_HH

#include <boost/coroutine/all.hpp>

namespace dzn
{
  typedef boost::coroutines::symmetric_coroutine<void>::call_type context;
  typedef boost::coroutines::symmetric_coroutine<void>::yield_type yield;
  typedef boost::coroutines::detail::forced_unwind forced_unwind;

  struct coroutine
  {
    static size_t g_id;
    size_t id;
    dzn::context context;
    dzn::yield* yield;
    void* port;
    bool finished;
    bool released;
    bool skip_block;
    coroutine() {} //HAX0R
    template <typename Worker>
    coroutine(Worker worker)
    : id(++g_id)
    , context(boost::bind(&coroutine::call_worker<Worker>, this, worker, _1))
    , port(0)
    , finished(false)
    , released(false)
    , skip_block(false)
    {}
    template <typename Worker>
    void call_worker(const Worker&  worker, dzn::yield& yield)
    {
      this->yield = &yield;
      worker();
    }
    void yield_to(dzn::coroutine& c)
    {
      (*this->yield)(c.context);
    }
    void call(dzn::coroutine&)
    {
      this->context();
    }
    void release(){}
  };
}
#endif //DZN_COROUTINE_HH
