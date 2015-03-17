// Dezyne --- Dezyne command line tools
//
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

dezyne.IDataparam = function(meta) {
  this.Status = {
    Yes: 0, No: 1
  };
  this.Status_to_string = {
    0: 'Status_Yes', 1: 'Status_No'
  };
  this.in = {
    e0 : null,
    e0r : null,
    e : null,
    er : null,
    eer : null,
    eo : null,
    eoo : null,
    eio : null,
    eio2 : null,
    eor : null,
    eoor : null,
    eior : null,
    eio2r : null
  };
  this.out = {
    a0 : null,
    a : null,
    aa : null,
    a6 : null
  };
  this.meta = meta;
};
