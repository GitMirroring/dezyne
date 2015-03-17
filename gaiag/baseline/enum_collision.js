// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

dezyne.enum_collision = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.reply_ienum_collision_Retval1 = null;
  this.reply_ienum_collision_Retval2 = null;

  this.i = new dezyne.ienum_collision({provides: {name: 'i', component: this}, requires: {}});

  this.i.in.foo = function() {
    return runtime.call_in(this, function() {
      this.reply_ienum_collision_Retval1 = ((typeof(new dezyne.ienum_collision().Retval1.OK) === 'object') ? new dezyne.ienum_collision().Retval1.OK.value : new dezyne.ienum_collision().Retval1.OK);
      return this.reply_ienum_collision_Retval1;
    }.bind(this), [this.i, 'foo', this.i.Retval1_to_string]);
  }.bind(this);
  this.i.in.bar = function() {
    return runtime.call_in(this, function() {
      this.reply_ienum_collision_Retval2 = ((typeof(new dezyne.ienum_collision().Retval2.NOK) === 'object') ? new dezyne.ienum_collision().Retval2.NOK.value : new dezyne.ienum_collision().Retval2.NOK);
      return this.reply_ienum_collision_Retval2;
    }.bind(this), [this.i, 'bar', this.i.Retval2_to_string]);
  }.bind(this);

};
