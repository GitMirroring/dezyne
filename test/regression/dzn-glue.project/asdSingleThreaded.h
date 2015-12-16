// Dezyne --- Dezyne command line tools
//
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

/*
 * This is confidential material the contents of which are the property of Verum Software Technologies BV.  
 * All reproduction and/or duplication in whole or in part without the written prior consent of 
 * Verum Software Technologies BV is strictly forbidden.  Modification of this code is strictly forbidden 
 * and may result in software runtime failure.
 *
 * Modification or removal of this notice in whole or in part is strictly forbidden.
 * Copyright 1998 - 2013 Verum Software Technologies BV
 */
#ifndef __ASD_SINGLETHREADED_H__
#define __ASD_SINGLETHREADED_H__

#include <string>
#include <vector>
#include <queue>
#include <set>
#include <algorithm>

#include <boost/bind.hpp>
#include <boost/noncopyable.hpp>
#include <boost/function.hpp>
#include <boost/numeric/conversion/converter.hpp>

#include "asdTransfer.h"
#include "asdInterfaces.h"

namespace asd_0
{
// /////////////////////////////////////////////////////////////////////////////
// SingleThreadedDpc
// /////////////////////////////////////////////////////////////////////////////

class SingleThreadedDpc
{
private:
  bool m_InUse;
  std::queue<boost::function<void()> > m_Queue;

public:
  SingleThreadedDpc() : m_InUse(false) {}

  void defer(const boost::function<void()>& f) {m_Queue.push(f);}
  bool isEmpty() {return m_Queue.empty();}
  void processEvents()
  {
    if (!m_InUse) {
      m_InUse = true;
      while(!m_Queue.empty())
      {
        boost::function<void()> f(m_Queue.front());
        m_Queue.pop();
        f();
      }
      m_InUse = false;
    }
  }
};

// /////////////////////////////////////////////////////////////////////////////
// SingleThreadedContextNoDpc
// /////////////////////////////////////////////////////////////////////////////

class SingleThreadedContextNoDpc
{
private:
  boost::function<void()> m_Transfer;

protected:
  boost::shared_ptr<asd::channels::ISingleThreaded> m_ISingleThreaded;

  bool m_Blocked;
  bool m_Released;

public:
  SingleThreadedContextNoDpc()
  : m_Blocked(false)
  , m_Released(false)
  {}

  asd::channels::ISingleThreaded& getISingleThreaded() const {return *m_ISingleThreaded;}
  void setISingleThreaded(const boost::shared_ptr<asd::channels::ISingleThreaded>& cb)
  {
    if(m_ISingleThreaded && cb)
    {
      ASD_ILLEGAL("SingleThreadedContext","Set","","ISingleThreaded already registered");
    }
    m_ISingleThreaded = cb;
  }

  void block()
  {
    if (m_Released || m_Blocked)
    {
      ASD_ILLEGAL("SingleThreadedContext","block","","api not released or not blocked");
    }
    m_Blocked = true;
  }

  void unblock()
  {
    if(m_Transfer)
    {
      m_Transfer();
      m_Transfer.clear();
    }
    m_Released = true;
  }
  void transfer(const boost::function<void()>& t)  {m_Transfer = t;}
  void awaitUnblock()
  {
    if (!m_Released)
    {
      ASD_ILLEGAL("SingleThreadedContext","awaitUnblock","","api not unblocked.");
    }
    m_Blocked = false;
    m_Released = false;
  }

private:
  SingleThreadedContextNoDpc& operator = (const SingleThreadedContextNoDpc& other);
};

// /////////////////////////////////////////////////////////////////////////////
// SingleThreadedContext
// /////////////////////////////////////////////////////////////////////////////

class SingleThreadedContext: public SingleThreadedContextNoDpc
{
  SingleThreadedDpc m_Dpc;

public:
  SingleThreadedContext() : m_Dpc() {}

  void defer(const boost::function<void()>& f)  {m_Dpc.defer(f);}
  void awaitUnblock()
  {
    m_Dpc.processEvents();
    if (!m_Released)
    {
      ASD_ILLEGAL("SingleThreadedContext","awaitUnblock","","api not unblocked.");
    }
    m_Blocked = false;
    m_Released = false;
  }

  void processSingleThreadedEvents()
  {
    if (!m_Blocked)
    {
      m_Dpc.processEvents();
      if (m_ISingleThreaded.get() != 0)
      {
        m_ISingleThreaded->processCBs();
      }
    }
  }
};

// /////////////////////////////////////////////////////////////////////////////
// SingleThreadedProxy
// /////////////////////////////////////////////////////////////////////////////

class SingleThreadedProxy: public asd::channels::ISingleThreaded
{
  SingleThreadedContext& context;
public:
  SingleThreadedProxy (SingleThreadedContext& cntxt) : context(cntxt) {}
  ~SingleThreadedProxy () {}
  void processCBs() {context.processSingleThreadedEvents();}
private:
  SingleThreadedProxy& operator = (const SingleThreadedProxy& other);
};

}
#endif

// /////////////////////////////////////////////////////////////////////////////
// -- end of file --
// /////////////////////////////////////////////////////////////////////////////
