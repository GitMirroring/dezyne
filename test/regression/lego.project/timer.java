// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

class timer extends Component {


  itimer port;

  public timer(Locator locator) {this(locator, "");};

  public timer(Locator locator, String name) {this(locator, name, null);};

  public timer(Locator locator, String name, SystemComponent parent) {
    super(locator, name, parent);
    this.flushes = true;
    port = new itimer();
    port.in.name = "port";
    port.in.self = this;
    port.in.create = new Action1<Integer>() {public void action(final Byte ms) {Runtime.callIn(timer.this, new Action() {public void action() {port_create(ms);}}, new Meta(timer.this.port, "create"));};};

    port.in.cancel = new Action() {public void action() {Runtime.callIn(timer.this, new Action() {public void action() {port_cancel();}}, new Meta(timer.this.port, "cancel"));};};

  };
  public void port_create(final Byte ms) {
    { }
  };

  public void port_cancel() {
    { }
  };

}
