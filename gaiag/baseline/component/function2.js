// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

component.function2 = function() {
  this.f = false;

  this.i = new interface.ifunction2();

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
        bb = this.vtoggle();
        this.f = bb;
        this.i.out.d();
      }
    }
  }.bind(this);
  this.vtoggle = function () {
    if(this.f) this.i.out.c();
    return ! (this.f);
  }.bind(this);

};
