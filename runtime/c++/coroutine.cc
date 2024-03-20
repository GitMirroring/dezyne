// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2024 Rutger van Beusekom <rutger@dezyne.org>
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

#include <dzn/coroutine.hh>

namespace dzn
{
coroutine::coroutine (size_t id, std::function<void()>&& worker)
  : id (id)
  , context ([this, worker] (dzn::yield &yield)
  {
    this->yield = std::move (yield);
    worker ();
  })
  , port ()
  , finished ()
  , skip_block ()
{}
coroutine::coroutine ()
  : id (0)
  , context ()
  , port ()
  , finished ()
  , skip_block ()
{}
void coroutine::yield_to (dzn::coroutine &that)
{
  this->yield (that.context);
}
#if HAVE_BOOST_COROUTINE
void coroutine::call (dzn::coroutine &)
{
  this->context ();
}
void coroutine::release () {}
#else //!HAVE_BOOST_COROUTINE
void coroutine::call (dzn::coroutine &that)
{
  this->context.call (that.context);
}
void coroutine::release ()
{
  this->context.release ();
}
#endif // !HAVE_BOOST_COROUTINE
}
