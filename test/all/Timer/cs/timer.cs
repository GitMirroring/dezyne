// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
using dzn;

public class timer : Component {
  public itimer t;
  private static int g_id = 0;
  private int id;

  public timer(dzn.Locator locator, String name="", dzn.Meta parent=null) : base(locator, name, parent) {
    this.id = timer.g_id++;
    this.t = new itimer();
    this.t.dzn_meta.provides.name = "port";
    this.t.dzn_meta.provides.meta = this.dzn_meta;
    this.t.dzn_meta.provides.component = this;
    this.t.inport.create = (int ms) => {dzn.Runtime.callIn(this, () => {this.port_create(ms);}, this.t.dzn_meta, "create");};
    this.t.inport.cancel = () => {dzn.Runtime.callIn(this, () => {this.port_cancel();}, this.t.dzn_meta, "cancel");};
  }
  public void port_create(int ms) {
    this.dzn_locator.get<dzn.pump>().handle(id, ms, this.t.outport.timeout);
  }
  public void port_cancel() {
    this.dzn_locator.get<dzn.pump>().remove(id);
  }
}
