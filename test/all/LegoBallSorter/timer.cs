// Dezyne --- Dezyne command line tools
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

public class timer : Component {


  public itimer port;

  public timer(dzn.Locator locator, String name="", dzn.Meta parent=null) : base(locator, name, parent) {
    this.port = new itimer();
    this.port.dzn_meta.provides.name = "port";
    this.port.dzn_meta.provides.meta = this.dzn_meta;
    this.port.dzn_meta.provides.component = this;
    this.port.inport.create = (Integer ms) => {dzn.Runtime.callIn(this, () => {port_create(ms);}, this.dzn_meta, "create");};

    port.inport.cancel = () => {dzn.Runtime.callIn(this, () => {port_cancel();}, this.dzn_meta, "cancel");};

  }
  public void port_create(Integer ms) {
    { }
  }

  public void port_cancel() {
    { }
  }

}
