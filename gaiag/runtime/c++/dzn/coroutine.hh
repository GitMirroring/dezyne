// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#if HAVE_BOOST_COROUTINE
#include <boost/coroutine/all.hpp>
#else
#include <dzn/context.hh>
#endif

#ifdef DEBUG_RUNTIME
#include <iostream>
#endif

namespace dzn
{
#if HAVE_BOOST_COROUTINE
  typedef boost::coroutines::symmetric_coroutine<void>::call_type context;
  typedef boost::coroutines::symmetric_coroutine<void>::yield_type yield;
#else
  typedef std::function<void(dzn::context&)> yield;
#endif

  struct coroutine
  {
    static int g_id;
    int id;

    dzn::context context;
    dzn::yield yield;
    void* port;
    bool finished;
    bool released;
    bool skip_block;
    template <typename Worker>
    coroutine(Worker&& worker)
    : id(g_id++)
    , context([this, worker](dzn::yield& yield){
        this->yield = std::move(yield);
        worker();
      })
    , port(nullptr)
    , finished(false)
    , released(false)
    , skip_block(false)
    {}
    ~coroutine()
    {
#ifdef DEBUG_RUNTIME
      std::cout << __FUNCTION__ << ": " << id << std::endl;
#endif
    }
    void yield_to(dzn::coroutine& c)
    {
      this->yield(c.context);
    }
#if HAVE_BOOST_COROUTINE
    coroutine() : id(-1), context() {}
    void call(dzn::coroutine&)
    {
      this->context();
    }
    void release(){}
#else // !HAVE_BOOST_COROUTINE
    coroutine() : id(-1), context(false) {}
    void call(dzn::coroutine& c)
    {
      this->context.call(c.context);
    }
    void release()
    {
      this->context.release();
    }
#endif // HAVE_BOOST_COROUTINE
  };
}
#endif //DZN_COROUTINE_HH
