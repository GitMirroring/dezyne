// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
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

class main {

  static void assert(bool b) {
    if (!b) {
      throw new dzn.RuntimeException("assertion failure");
    }
  }

  public static void Main(String[] args) {
    var locator = new dzn.Locator();
    var runtime = new dzn.Runtime();
    locator.set(runtime);

		var unbound_in_event = new hellochecksystembindings(locator, "unbound_in_event");
		unbound_in_event.p.outport.world = () => {};
		try
		{
			unbound_in_event.check_bindings();
		}
		catch(dzn.binding_error e)
		{
			string expected_event = "unbound_in_event.comp.r.inport.hello";
			assert(e.Message.Contains(expected_event));
		}

		var unbound_out_event = new hellochecksystembindings(locator, "unbound_out_event");
		unbound_out_event.r.inport.hello = () => {};
		try
		{
			unbound_out_event.check_bindings();
		}
		catch(dzn.binding_error e)
		{
			string expected_event = "unbound_out_event.comp.p.outport.world";
			assert(e.Message.Contains(expected_event));
		}

		var no_unbound_events = new hellochecksystembindings(locator, "no_unbound_events");
		no_unbound_events.p.outport.world = () => {};
		no_unbound_events.r.inport.hello = () => {};
		try
		{
			no_unbound_events.check_bindings();
		}
		catch(dzn.binding_error e)
		{
			assert(false);
		}
  }
}
