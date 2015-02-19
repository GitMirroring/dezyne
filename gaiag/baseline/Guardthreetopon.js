// Dezyne --- Dezyne command line tools
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

dezyne.Guardthreetopon = function() {
  this.b = false;

  this.i = new dezyne.IGuardthreetopon();
  this.r = new dezyne.RGuardthreetopon();

  this.i.in.e = function() {
    console.log('Guardthreetopon.i_e');
    if(true && this.b) {
      this.i.out.a.defer();
    }
    else if(true && ! (this.b)) {
      var c = true;
      if(c) this.i.out.a.defer();
    }
  }.bind(this);
  this.i.in.t = function() {
    console.log('Guardthreetopon.i_t');
    if(this.b) this.i.out.a.defer();
    else if(! (this.b)) this.i.out.a.defer();
  }.bind(this);
  this.i.in.s = function() {
    console.log('Guardthreetopon.i_s');
    this.i.out.a.defer();
  }.bind(this);
  this.r.out.a = function() {
    console.log('Guardthreetopon.r_a');
    { }
  }.bind(this);

};
