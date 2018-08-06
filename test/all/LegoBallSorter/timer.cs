// Dezyne --- Dezyne command line tools
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

public partial class timer : dzn.Component {
    static int s_id = 0;
    int id = 0;

    public void port_create(Integer ms) {
        if(id == 0) id = ++s_id;
        dzn_locator.get<dzn.pump>().handle(id, ms, ()=>port.outport.timeout());
    }
    public void port_cancel() {
        dzn_locator.get<dzn.pump>().remove(id);
    }
}
