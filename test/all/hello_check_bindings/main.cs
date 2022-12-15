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

using System;

class main
{
  static void assert (bool b)
  {
    if (!b) throw new dzn.RuntimeException ("assertion failure");
  }

  public static void Main (String[] args)
  {
    var locator = new dzn.Locator ();
    var runtime = new dzn.Runtime ();
    locator.set (runtime);

    var unbound_in_event = new hello_check_bindings (locator, "unbound_in_event");
    unbound_in_event.p.out_port.world = () => {};
    try
    {
      unbound_in_event.dzn_check_bindings ();
    }
    catch (dzn.binding_error e)
    {
      string expected_event = "unbound_in_event.r.in_port.hello";
      assert (e.Message.Contains (expected_event));
    }

    var unbound_out_event = new hello_check_bindings (locator, "unbound_out_event");
    unbound_out_event.r.in_port.hello = () => {};
    try
    {
      unbound_out_event.dzn_check_bindings ();
    }
    catch (dzn.binding_error e)
    {
      string expected_event = "unbound_out_event.p.out_port.world";
      assert (e.Message.Contains (expected_event));
    }

    var no_unbound_events = new hello_check_bindings (locator, "no_unbound_events");
    no_unbound_events.p.out_port.world = () => {};
    no_unbound_events.r.in_port.hello = () => {};
    try
    {
      no_unbound_events.dzn_check_bindings ();
    }
    catch (dzn.binding_error e)
    {
      assert (false);
    }
  }
}
