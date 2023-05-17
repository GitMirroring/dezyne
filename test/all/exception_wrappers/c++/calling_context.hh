// dzn-examples -- Dezyne examples
//
// Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2021 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of dzn-examples.
//
// dzn-examples is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// dzn-examples is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with dzn-examples.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// This header provides a simplistic implementation of an
// "exception_context" struct for use with the C++ exception-wrapper
// code generator:
//
// dzn code --calling-context=exception_context --language=c++-exception-wrappers ...
//
// See also test/all/exception_wrapper.
//
// Code:

#include <iostream>
#include <queue>

struct exception_context
{
  std::queue<std::exception_ptr> qe;
  void operator () ()
  {
    if (qe.size ())
      std::rethrow_exception (qe.front ());
  }
  void extend (const std::exception_ptr e)
  {
    qe.push (e);
  }
  static void report (const std::exception &e)
  {
    std::clog << "exception." << e.what () << std::endl;
  }
};
