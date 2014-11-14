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

dezyne.imperative = function() {
  this.States= {
    I: 0, II: 1, III: 2, IV: 3
  };
  this.state = this.States.I;

  this.i = new dezyne.iimperative();

  this.i.in.e = function() {
    console.log('imperative.i_e');
    if(this.state === this.States.I) {
      {
        this.i.out.f.defer();
        this.i.out.g.defer();
        this.i.out.h.defer();
        this.state = this.States.II;
      }
    }
    else if(this.state === this.States.II) {
      {
        this.state = this.States.III;
      }
    }
    else if(this.state === this.States.III) {
      {
        this.i.out.f.defer();
        this.i.out.g.defer();
        this.i.out.g.defer();
        this.i.out.f.defer();
        this.state = this.States.IV;
      }
    }
    else if(this.state === this.States.IV) {
      {
        this.i.out.h.defer();
        this.state = this.States.I;
      }
    }
  }.bind(this);

};
