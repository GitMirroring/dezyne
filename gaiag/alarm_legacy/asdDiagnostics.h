// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

/*
 * This is confidential material the contents of which are the property of Verum Software Tools BV.  
 * All reproduction and/or duplication in whole or in part without the written prior consent of 
 * Verum Software Tools BV is strictly forbidden.  Modification of this code is strictly forbidden 
 * and may result in software runtime failure.
 *
 * Modification or removal of this notice in whole or in part is strictly forbidden.
 * Copyright 1998 - 2014 Verum Software Tools BV
 */
#ifndef __ASD_DIAGNOSTICS_H__
#define __ASD_DIAGNOSTICS_H__

#include <exception>

#ifdef ASD_HAVE_CONFIG_H
  #include "asdConfig.h"
#else
  #include "asdDefConfig.h"
#endif

#ifdef ASD_ENABLE_DEBUG
  #ifdef ASD_ENABLE_DEPRECATED_ASDRUNTIME_TRACE
    #include "trace.h"
    #include <cstdlib>
    
    #define ASD_TRACE_ENTER(component, state, api, event) ASD_TRACE("-->")
    #define ASD_TRACE_EXIT(component, state, api, event) ASD_TRACE("<--")
    #define ASD_ILLEGAL(component, state, api, event) ASD_TRACE("ILLEGAL"); std::abort();
  #else
    #if defined(__GNUC__) || defined(_MSC_VER)
      #define ASD_TRACE_ENTER(component, state, api, event)\
        asd::diagnostics::trace(asd::diagnostics::info(asd::diagnostics::info::enter, \
                              component, state, api, event, __FUNCTION__, __FILE__, __LINE__));
      #define ASD_TRACE_EXIT(component, state, api, event)                    \
        asd::diagnostics::trace(asd::diagnostics::info(asd::diagnostics::info::exit, \
                              component, state, api, event, __FUNCTION__, __FILE__, __LINE__));
      #define ASD_ILLEGAL(component, state, api, event)                       \
        asd::diagnostics::illegal(asd::diagnostics::info(asd::diagnostics::info::illegal, \
                              component, state, api, event, __FUNCTION__, __FILE__, __LINE__));
    #else
      #define ASD_TRACE_ENTER(component, state, api, event)                   \
        asd::diagnostics::trace(asd::diagnostics::info(asd::diagnostics::info::enter, \
                              component, state, api, event, "", __FILE__, __LINE__));
      #define ASD_TRACE_EXIT(component, state, api, event)                    \
        asd::diagnostics::trace(asd::diagnostics::info(asd::diagnostics::info::exit, \
                              component, state, api, event, "", __FILE__, __LINE__));
      #define ASD_ILLEGAL(component, state, api, event)                       \
        asd::diagnostics::illegal(asd::diagnostics::info(asd::diagnostics::info::illegal, \
                               component, state, api, event, "", __FILE__, __LINE__)); 
    #endif
  #endif
#else
  #define ASD_TRACE_ENTER(component, state, api, event) do {} while (0)
  #define ASD_TRACE_EXIT(component, state, api, event) do {} while (0)
  #define ASD_ILLEGAL(component, state, api, event)                       \
    asd::diagnostics::illegal(\
        asd::diagnostics::info(asd::diagnostics::info::illegal, "", "", "", "", "", "", __LINE__)); 
#endif

namespace asd
{
  namespace diagnostics
  {
    struct info
    {
      enum type_t{enter, exit, illegal};
      type_t type;
      const char* const component;
      const char* const state;
      const char* const channel;
      const char* const stimulus;
      const char* const member;
      const char* const file;
      const unsigned int line;
      
      info(type_t type,
           const char* const component,
           const char* const state,
           const char* const channel,
           const char* const stimulus,
           const char* const member,
           const char* const file,
           const unsigned int line);
    private:
      info& operator = (const info& other);
    };

    typedef void (*handler)(const info&);

    handler set_illegal(handler);
    void illegal(const info&);

    handler set_trace(handler);
    void trace(const info&);

    typedef void (*ehandler) (const std::exception&);
    ehandler set_exception(ehandler);
    void exception(const std::exception&);
  }
}

#endif // __ASDRUNTIME_DIAGNOSTICS_H__
