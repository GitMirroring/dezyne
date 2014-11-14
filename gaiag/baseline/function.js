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

dezyne.function = function() {
  this.f = false;

  this.i = new dezyne.I();

  this.i.in.a = function() {
    console.log('function.i_a');
    if(true) {
      {
        this.toggle();
      }
    }
  }.bind(this);
  this.i.in.b = function() {
    console.log('function.i_b');
    if(true) {
      {
        this.toggle();
        this.toggle();
        this.i.out.d.defer();
      }
    }
  }.bind(this);
  this.toggle = function () {
    if(this.f) {
      this.i.out.c.defer();
    }
    this.f = ! (this.f);
  }.bind(this);

};
