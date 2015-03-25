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

dezyne.ienum_collision = function(meta) {
  this.Retval1 = {
    OK: 0, NOK: 1
  };
  this.Retval1_to_string = {
    0: 'Retval1_OK', 1: 'Retval1_NOK'
  };
  this.Retval2 = {
    OK: 0, NOK: 1
  };
  this.Retval2_to_string = {
    0: 'Retval2_OK', 1: 'Retval2_NOK'
  };
  this.in = {
    foo : null,
    bar : null
  };
  this.out = {

  };
  this.meta = meta;
};
