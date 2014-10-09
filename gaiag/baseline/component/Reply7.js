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

component.Reply7 = function() {

  this.reply_IReply7_E = nul;

  this.p = new interface.IReply7();
  this.r = new interface.IReply7();

  this.p.ins.foo = function() {
    console.log('Reply7.p_foo');
    this.f();
    return self.reply_IReply7_E;
  }.bind(this);
  this.f = function () {
    v = this.r.ins.foo();
    this.reply_IReply7_E = v;
  }.bind(this);

};
