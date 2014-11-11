// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Gaiag.
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

component.double_out_on_modeling = function() {
  this.State= {
    First: 0, Second: 1
  };
  this.state = this.State.First;

  this.p = new interface.I();
  this.r = new interface.I();

  this.p.in.start = function() {
    console.log('double_out_on_modeling.p_start');
    if(this.state === this.State.First) {
      {
        this.r.in.start();
        this.state = this.State.Second;
      }
    }
    else if(this.state === this.State.Second) {
      assert (false);
    }
  }.bind(this);
  this.r.out.foo = function() {
    console.log('double_out_on_modeling.r_foo');
    if(this.state === this.State.First) {
      assert (false);
    }
    else if(this.state === this.State.Second) {
      this.p.out.foo();
    }
  }.bind(this);
  this.r.out.bar = function() {
    console.log('double_out_on_modeling.r_bar');
    if(this.state === this.State.First) {
      assert (false);
    }
    else if(this.state === this.State.Second) {
      {
        this.p.out.bar();
        this.state = this.State.First;
      }
    }
  }.bind(this);

};
