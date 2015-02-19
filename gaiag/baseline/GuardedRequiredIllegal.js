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

dezyne.GuardedRequiredIllegal = function() {
  this.c = false;

  this.t = new dezyne.Top();
  this.b = new dezyne.Bottom();

  this.t.in.unguarded = function() {
    console.log('GuardedRequiredIllegal.t_unguarded');
    { }
  }.bind(this);
  this.t.in.e = function() {
    console.log('GuardedRequiredIllegal.t_e');
    if(! (this.c)) {
      this.c = true;
      this.b.in.e();
    }
    else if(this.c) { }
  }.bind(this);
  this.b.out.f = function() {
    console.log('GuardedRequiredIllegal.b_f');
    if(! (this.c)) console.assert (false);
    else if(this.c) {
      this.c = false;
    }
  }.bind(this);

};
