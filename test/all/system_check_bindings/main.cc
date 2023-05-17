// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
// Copyright © 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include "system_check_bindings.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

#include <cassert>

int main ()
{
  dzn::locator l;
  dzn::runtime rt;
  l.set (rt);

  system_check_bindings unbound_in_event (l);
  unbound_in_event.dzn_meta.name = "unbound_in_event";
  unbound_in_event.p.out.world = [] { };
  try
    {
      dzn::check_bindings (unbound_in_event);
    }
  catch (dzn::binding_error const& e)
    {
      std::string expected_event = "unbound_in_event.comp.r.in.hello";
      std::string actual_error (e.what ());
      assert (actual_error.find (expected_event) != std::string::npos);
    }

  system_check_bindings unbound_out_event (l);
  unbound_out_event.dzn_meta.name = "unbound_out_event";
  unbound_out_event.r.in.hello = [] { };
  try
    {
      dzn::check_bindings (unbound_out_event);
    }
  catch (dzn::binding_error const& e)
    {
      std::string expected_event = "unbound_out_event.comp.p.out.world";
      std::string actual_error (e.what ());
      assert (actual_error.find (expected_event) != std::string::npos);
    }

  system_check_bindings no_unbound_events (l);
  no_unbound_events.dzn_meta.name = "no_unbound_events";
  no_unbound_events.p.out.world = [] { };
  no_unbound_events.r.in.hello = [] { };
  try
    {
      dzn::check_bindings (no_unbound_events);
    }
  catch (dzn::binding_error const& e)
    {
      assert (false);
    }
}
