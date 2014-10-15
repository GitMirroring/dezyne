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

component.hide = function() {

  this.b = false;
  this.c = true;

  this.i = new interface.I();

  this.i.in.e = function() {
    console.log('hide.i_e');
    if(true) {
      b = this.b;
      c = this.g(this.b, this.c);
      if(this.c) {
        this.i.out.f();
      }
    }
  }.bind(this);
  this.g = function (b, d) {
    b = d;
    d = this.c;
    this.i.out.f();
    return (this.b || d);
  }.bind(this);

};
