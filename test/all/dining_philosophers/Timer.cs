// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2025 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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

public partial class Timer
{
  public Timer (dzn.Locator locator)
    : base (locator)
  {}
  void t_deferred ()
  {
    dzn_locator.get<dzn.pump> ().handle (t.GetHashCode (), 0, ()=>{t.out_port.timeout ();});
  }
  void t_set ()
  {
    dzn_locator.get<dzn.pump> ().handle (t.GetHashCode (), 100, ()=>{t.out_port.timeout ();});
  }
  void t_cancel ()
  {
    dzn_locator.get<dzn.pump> ().remove (t.GetHashCode ());
  }
}
