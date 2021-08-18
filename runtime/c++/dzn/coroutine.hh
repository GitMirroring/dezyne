// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Henk Katerberg <hank@mudball.nl>
// Copyright © 2015, 2016, 2017, 2018 Rutger van Beusekom <rutger@dezyne.org>
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

#ifndef DZN_COROUTINE_HH
#define DZN_COROUTINE_HH

#include <dzn/context.hh>

namespace dzn
{
  typedef context::forced_unwind forced_unwind;
  typedef std::function<void(dzn::context&)> yield;

  struct coroutine
  {
    size_t id;
    dzn::context context;
    dzn::yield yield;
    void* port;
    bool finished;
    bool released;
    bool skip_block;
    template <typename Worker>
    coroutine(Worker&& worker)
    : id()
    , context([this, worker](dzn::yield& yield){
        this->id = context::get_id();
        this->yield = std::move(yield);
        worker();
      })
    , port()
    , finished()
    , released()
    , skip_block()
    {}
    coroutine()
    : id(context::get_id())
    , context()
    , port()
    , finished()
    , released()
    , skip_block()
    {}
    void yield_to(dzn::coroutine& c)
    {
      this->yield(c.context);
    }
    void call(dzn::coroutine& c)
    {
      this->context.call(c.context);
    }
    void release()
    {
      this->context.release();
    }
    static size_t get_id()
    {
      return context::get_id();
    }
  };
}
#endif //DZN_COROUTINE_HH
