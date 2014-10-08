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

component.Reply4 = function() {
  this.Status= {
    Yes: 0, No: 1
  };

  this.dummy = false;
  this.reply_I_Status = nul;
  this.reply_U_Status = nul;

  this.i = new interface.I();
  this.u = new interface.U();

  this.i.ins.done = function() {
    console.log('Reply4.i_done');
    if(true) {
      {
        s = this.u.ins.what();
        this.s = this.u.ins.what();
        if (s === interface.U.Status.Ok) {
          v = this.fun();
          if (v === this.Status.Yes) this.reply_I_Status = interface.I.Status.Yes;
          else this.reply_I_Status = interface.I.Status.No;
        }
        else {
          v = this.fun_arg(this.Status.No);
          if (v === this.Status.Yes) this.reply_I_Status = interface.I.Status.Yes;
          else this.reply_I_Status = interface.I.Status.No;
        }
      }
    }
    return self.reply_I_Status;}.bind(this);

  this.fun = function () {
    return this.Status.Yes;
  }.bind(this);
  this.fun_arg = function (s) {
    return s;
  }.bind(this);

};
