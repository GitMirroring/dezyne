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

interface I
{
  in void start;
  out void foo;
  out void bar;
  behaviour
  {
    enum State {First, Second};
    State state = State.First;
    [state.First]
    {
      on start: state = State.Second;
    }
    [state.Second]
    {
      on start: illegal;
      on inevitable: { foo; bar; state = State.First;}
    }
  }
}

component double_out_on_modeling
{
  provides I p;
  requires I r;

  behaviour
  {
    enum State {First, Second};
    State state = State.First;
    [state.First]
    {
      on p.start: {r.start; state = State.Second;}
      on r.foo: illegal;
      on r.bar: illegal;
    }
    [state.Second]
    {
      on p.start: illegal;
      on r.foo: p.foo;
      on r.bar: {p.bar; state = State.First;}
    }
  }
}
