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

component.enum_collision = function() {

  this.reply_ienum_collision_Retval1 = nul;
  this.reply_ienum_collision_Retval2 = nul;

  this.i = new interface.ienum_collision();

  this.i.ins.foo = function() {
    console.log('enum_collision.i_foo');
    this.reply_ienum_collision_Retval1 = interface.ienum_collision.Retval1.OK;
    return self.reply_ienum_collision_Retval1;}.bind(this);

  this.i.ins.bar = function() {
    console.log('enum_collision.i_bar');
    this.reply_ienum_collision_Retval2 = interface.ienum_collision.Retval2.NOK;
    return self.reply_ienum_collision_Retval2;}.bind(this);


};
