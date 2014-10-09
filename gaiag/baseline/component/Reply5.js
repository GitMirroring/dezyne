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

component.Reply5 = function() {

  this.dummy = false;
  this.reply_I_Status = nul;
  this.reply_U_Status = nul;

  this.i = new interface.I();
  this.u = new interface.U();

  this.i.ins.done = function() {
    console.log('Reply5.i_done');
    if(true) {
      {
        s = this.u.ins.what();
        this.s = this.u.ins.what();
        if(s === interface.U.Status.Ok) {
          s = this.fun();
          this.reply_I_Status = s;
        }
        else {
          s = this.fun_arg(interface.I.Status.No);
          this.reply_I_Status = s;
        }
      }
    }
    return self.reply_I_Status;
  }.bind(this);
  this.fun = function () {
    return interface.I.Status.Yes;
  }.bind(this);
  this.fun_arg = function (s) {
    return s;
  }.bind(this);

};
