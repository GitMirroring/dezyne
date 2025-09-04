// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2017, 2023 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Henk Katerberg <hank@mudball.nl>
// Copyright © 2015-2018, 2022, 2034 Rutger van Beusekom <rutger@dezyne.org>
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

#include <dzn/config.hh>

#if HAVE_BOOST_COROUTINE
#include <boost/coroutine/all.hpp>
namespace dzn
{
typedef boost::coroutines::symmetric_coroutine<void>::call_type context;
typedef boost::coroutines::symmetric_coroutine<void>::yield_type yield;
typedef boost::coroutines::detail::forced_unwind forced_unwind;
}
#else
#include <dzn/context.hh>
namespace dzn
{
typedef context::forced_unwind forced_unwind;
typedef std::function<void (context &)> yield;
}
#endif

namespace dzn
{
struct coroutine
{
  size_t id;
  dzn::context context;
  dzn::yield yield;
  void *component;
  void *port;
  bool finished;
  bool skip_block;
  coroutine ();
  coroutine (size_t id, std::function<void()> &&worker);
  void yield_to (dzn::coroutine &that);
  void call (coroutine &that);
  void release ();
};
}
#endif //DZN_COROUTINE_HH
