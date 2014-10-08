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

component.argument = function() {

  this.b = false;

  this.i = new interface.I();

  this.i.ins.e = function() {
    console.log('argument.i_e');
    if(true) {
      this.b = ! (this.b);
      c = this.g(this.b);
      this.b = this.g(c);
      if (c) {
        this.i.outs.f();
      }
    }
  }.bind(this);

  this.g = function (gc) {
    this.i.outs.f();
    return (gc || this.b);
  }.bind(this);

};
