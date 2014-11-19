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

dezyne.argument2 = function() {
  this.b = false;

  this.i = new dezyne.I();

  this.i.in.e = function() {
    console.log('argument2.i_e');
    if(true) this.b = ! (this.b);
    var c = this.g(this.b, this.b);
    this.b = this.g(c, c);
    if(c) {
      this.i.out.f.defer();
    }
  }.bind(this);
  this.g = function (ga, gb) {
    this.i.out.f.defer();
    return (ga || gb);
  }.bind(this);

};
