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

component.requires_twice = function() {


  this.p = new interface.irequires_twice();
  this.once = new interface.irequires_twice();
  this.twice = new interface.irequires_twice();

  this.p.ins.e = function() {
    console.log('requires_twice.p_e');
    {
      this.once.outs.a();
      this.twice.outs.a();
    }
  }.bind(this);

  this.once.outs.a = function() {
    console.log('requires_twice.once_a');
  }.bind(this);

  this.twice.outs.a = function() {
    console.log('requires_twice.twice_a');
  }.bind(this);


};
