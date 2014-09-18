// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

interface ienum_collision
{
  enum Retval1 {OK,NOK};
  in Retval1 foo;

  enum Retval2 {OK,NOK};
  in Retval2 bar;

  behaviour
  {
    on foo: reply(Retval1.OK);
    on bar: reply(Retval2.NOK);
  }
}

component enum_collision
{
  provides ienum_collision i;

  behaviour
  {
    on i.foo: reply(ienum_collision.Retval1.OK);
    on i.bar: reply(ienum_collision.Retval2.NOK);
  }
}
