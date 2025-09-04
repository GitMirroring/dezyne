// Dezyne --- Dezyne command line tools
//
// Copyright © 2023 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

public partial class Watchdog
{
  void w_set ()
  {
    dzn_locator.get<dzn.pump> ().handle (this.GetHashCode (), 1000, () =>
    {
      System.Console.WriteLine("BEFORE TIMEOUT");
      this.w.out_port.timeout ();
      System.Console.WriteLine("AFTER TIMEOUT");
    });
    System.Console.WriteLine("TIMERSET");
  }
  void w_cancel ()
  {
    dzn_locator.get<dzn.pump> ().remove (this.GetHashCode ());
  }
};
