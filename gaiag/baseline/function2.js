// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

dezyne.function2 = function() {
  this.f = false;

  this.i = new dezyne.ifunction2();

  this.i.in.a = function() {
    console.log('function2.i_a');
    if(true) {
      {
        this.f = this.vtoggle();
      }
    }
  }.bind(this);
  this.i.in.b = function() {
    console.log('function2.i_b');
    if(true) {
      {
        this.f = this.vtoggle();
        var bb = this.vtoggle();
        this.f = bb;
        this.i.out.d.defer();
      }
    }
  }.bind(this);
  this.vtoggle = function () {
    if(this.f) this.i.out.c.defer();
    return ! (this.f);
  }.bind(this);

};
