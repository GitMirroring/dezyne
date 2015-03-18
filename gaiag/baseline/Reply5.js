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

dezyne.Reply5 = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.dummy = false;
  this.reply_I_Status = null;
  this.reply_U_Status = null;

  this.i = new dezyne.I({provides: {name: 'i', component: this}, requires: {}});
  this.u = new dezyne.U({provides: {}, requires: {name: 'u', component: this}});

  this.i.in.done = function() {
    return runtime.call_in(this, function() {
      if(true) {
        var s = {value: this.u.in.what()};
        s.value = this.u.in.what();
        if(s.value === new dezyne.U().Status.Ok) {
          var s = {value: this.fun()};
          this.reply_I_Status = s.value;
        }
        else {
          var s = {value: this.fun_arg(new dezyne.I().Status.No)};
          this.reply_I_Status = s.value;
        }
      }
      return this.reply_I_Status;
    }.bind(this), [this.i, 'done', this.i.Status_to_string]);
  }.bind(this);
  this.fun = function () {
    return new dezyne.I().Status.Yes;
  }.bind(this);
  this.fun_arg = function (s) {
    return s;
  }.bind(this);

};
