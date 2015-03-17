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

dezyne.expressions = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.state = 3;
  this.c = 0;

  this.i = new dezyne.I({provides: {name: 'i', component: this}, requires: {}});

  this.i.in.e = function() {
    runtime.call_in(this, function() {
      if(true) {
        if(this.state === 0) {
          this.state = 3;
          this.i.out.a();
        }
        else {
          this.state = this.state - 1;
          if(this.c < this.state) {
            this.c = this.c + 1;
          }
          else {
            if(this.c <= (this.state + 1)) {
              this.i.out.lo();
            }
            else {
              if(this.c > this.state) {
                this.i.out.hi();
              }
            }
          }
        }
      }
    }.bind(this), [this.i, 'e']);
  }.bind(this);

};
