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

dezyne.requires_twice = function() {

  this.p = new dezyne.irequires_twice();
  this.once = new dezyne.irequires_twice();
  this.twice = new dezyne.irequires_twice();

  this.p.in.e = function() {
    console.log('requires_twice.p_e');
    {
      this.once.in.e.defer();
      this.twice.in.e.defer();
    }
  }.bind(this);
  this.once.out.a = function() {
    console.log('requires_twice.once_a');
    { }
  }.bind(this);
  this.twice.out.a = function() {
    console.log('requires_twice.twice_a');
    {
      this.p.out.a.defer();
    }
  }.bind(this);

};
