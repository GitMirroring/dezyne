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

dezyne.reply_reorder = function() {
  this.first = true;

  this.p = new dezyne.Provides();
  this.r = new dezyne.Requires();

  this.p.in.start = function() {
    console.log('reply_reorder.p_start');
    this.r.in.ping();
  }.bind(this);
  this.r.out.pong = function() {
    console.log('reply_reorder.r_pong');
    if(this.first) {
      this.p.out.busy.defer();
      this.first = ! (this.first);
    }
    if(! (this.first)) {
      this.p.out.finish.defer();
      this.first = ! (this.first);
    }
  }.bind(this);

};
