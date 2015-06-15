// Dezyne --- Dezyne command line tools
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

/*
 * This is confidential material the contents of which are the property of Verum Software Technologies BV.  
 * All reproduction and/or duplication in whole or in part without the written prior consent of 
 * Verum Software Technologies BV is strictly forbidden.  Modification of this code is strictly forbidden 
 * and may result in software runtime failure.
 *
 * Modification or removal of this notice in whole or in part is strictly forbidden.
 * Copyright 1998 - 2013 Verum Software Technologies BV
 */
#ifndef __ASD_TRANSFER_H__
#define __ASD_TRANSFER_H__

#include <vector>
#include <algorithm>

#include <boost/function.hpp>

#include "asdDataVariable.h"

namespace asd_0
{
template <typename S, typename T>
class Assign
{
  S& lhs;
  const T& rhs;
public:
  Assign(S& l, const T& r)
  : lhs(l), rhs(r)
  {}
  void operator()() const
  {
    lhs = rhs.GetValue();
  }
private:
  Assign& operator = (const Assign& other);
};

class Transfer
{
  std::vector<boost::function<void()> > assignment;
public:
  template <typename S, typename T>
  Transfer(S& lhs, const T& rhs)
  {
    assignment.push_back(Assign<S,T>(lhs, rhs));
  }
  template <typename S, typename T>
  Transfer& operator()(S& lhs, const T& rhs)
  {
    assignment.push_back(Assign<S,T>(lhs, rhs));
    return *this;
  }
  void operator()() const
  {
    std::for_each(assignment.begin(), assignment.end(), &Transfer::execute);
  }
private:
  static void execute(const boost::function<void()>& f){ f(); }
};
} // asd_0

#endif
