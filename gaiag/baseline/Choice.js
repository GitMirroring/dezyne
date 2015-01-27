// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

dezyne.Choice = function() {
  this.State = {
    Off: 0, Idle: 1, Busy: 2
  };
  this.s = this.State.Off;

  this.c = new dezyne.IChoice();

  this.c.in.e = function() {
    console.log('Choice.c_e');
    if(this.s === this.State.Off) {
      this.s = this.State.Idle;
      this.c.out.a.defer();
    }
    else if(this.s === this.State.Idle) {
      this.s = this.State.Busy;
      this.c.out.a.defer();
    }
    else if(this.s === this.State.Busy) {
      this.s = this.State.Idle;
      this.c.out.a.defer();
    }
  }.bind(this);

};
