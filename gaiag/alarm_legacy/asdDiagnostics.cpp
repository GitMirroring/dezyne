/*
 * This is confidential material the contents of which are the property of Verum Software Tools BV.  
 * All reproduction and/or duplication in whole or in part without the written prior consent of 
 * Verum Software Tools BV is strictly forbidden.  Modification of this code is strictly forbidden 
 * and may result in software runtime failure.
 *
 * Modification or removal of this notice in whole or in part is strictly forbidden.
 * Copyright 1998 - 2014 Verum Software Tools BV
 */
#include "asdDiagnostics.h"

#include <cstdlib>
#include <iostream>

namespace asd
{
  namespace diagnostics
  {
    info::info(type_t t,
               const char* const c, const char* const s,
               const char* const a, const char* const e, const char* m,
               const char* const f, const unsigned int l)
    : type(t)
    , component(c)
    , state(s)
    , channel(a)
    , stimulus(e)
    , member(m)
    , file(f)
    , line(l)
    {}

    static void default_handler(const info& i)
    {
      std::cout << (i.type == info::enter ? "-->" : i.type == info::exit ? "<--" : "illegal")
                << " " << i.component << " " << i.state << " " << i.channel << " " << i.stimulus << " "
                << i.member << " " << i.file << " " << i.line << std::endl;
    }

    static void default_exception_handler(const std::exception& e)
    {
      std::cout << "Exception: '"  << e.what() << std::endl;
    }


    static handler g_illegal_handler = default_handler;


    handler set_illegal(handler illegal_handler)
    {
      handler previous = g_illegal_handler;
      g_illegal_handler = illegal_handler;
      return previous;
    }

    void illegal(const info& i)
    {
      try{ g_illegal_handler(i); } catch(...){}
      std::abort();
    }

    static ehandler g_exception_handler = default_exception_handler;

    ehandler set_exception(ehandler exception_handler)
    {
      ehandler previous = g_exception_handler;
      g_exception_handler = exception_handler;
      return previous;
    }

    void exception(const std::exception& e)
    {
      try{ g_exception_handler(e); } catch(...){}
      std::abort();
    }

    static handler g_trace_handler = default_handler;

    handler set_trace(handler trace_handler)
    {
      handler previous = g_trace_handler;
      g_trace_handler = trace_handler;
      return previous;
    }
    void trace(const info& i)
    {
      g_trace_handler(i);
    }
  }
}
