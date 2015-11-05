// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef COROUTINE_HH
#define COROUTINE_HH

#include <iostream>

#if HAVE_BOOST_COROUTINE
#warning using boost coroutine
#include <boost/coroutine/all.hpp>
#else // !HAVE_BOOST_COROUTINE
#warning using threads
#include "context.hh"
#endif // !HAVE_BOOST_COROUTINE

namespace dezyne
{
#if HAVE_BOOST_COROUTINE
  typedef boost::coroutines::symmetric_coroutine<void>::call_type context;
  typedef boost::coroutines::symmetric_coroutine<void>::yield_type yield;
#else // !HAVE_BOOST_COROUTINE
  typedef std::function<void(dezyne::context&)> yield;
#endif // !HAVE_BOOST_COROUTINE

  struct coroutine
  {
    static int g_id;
    int id;

    dezyne::context context;
    dezyne::yield yield;
    void* port;
    bool finished;
    bool released;
    bool skip_block;
    template <typename Worker>
    coroutine(Worker&& worker)
    : id(g_id++)
      //, context{[this, worker](std::function<void(dezyne::context&)> yield){
    , context{[this, worker](dezyne::yield&& yield){

        this->yield = std::move(yield);
        worker();
      }}
    , port(nullptr)
    , finished(false)
    , released(false)
    , skip_block(false)
    {}
    ~coroutine()
    {
#ifdef DEBUG
      std::clog << __FUNCTION__ << ": " << id << std::endl;
#endif
    }
    void yield_to(dezyne::context& context)
    {
      this->yield(context);
    }
#if HAVE_BOOST_COROUTINE
    coroutine() : id(-1), context() {}
    void call(dezyne::context& context)
    {
      this->context();
    }
    void release(){}
#else // !HAVE_BOOST_COROUTINE
    coroutine() : id(-1), context(false) {}
    void call(dezyne::context& context)
    {
      this->context.call(context);
    }
    void release()
    {
      this->context.release();
    }
#endif // !HAVE_BOOST_COROUTINE
  };
}
#endif //COROUTINE_HH
