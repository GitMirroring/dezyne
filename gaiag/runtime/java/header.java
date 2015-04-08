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

// header
//package dezyne;

abstract class Action {
  public abstract void action();
}

abstract class ValuedAction<R> {
  public abstract R action();
}

@SuppressWarnings("unchecked")
abstract class Interface<I extends Interface.In, O extends Interface.Out> {
  interface In {
  }
  interface Out {
  }

  protected In in;
  protected Out out;

  public I getIn() {
    return (I) in;
  }

  public void setIn(I in) {
    this.in = in;
  }

  public O getOut() {
    return (O) out;
  }

  public void setOut(O out) {
    this.out = out;
  }

  @SuppressWarnings("rawtypes")
    public static void connect(Interface provided, Interface required) {
    provided.setOut(required.getOut());
    required.setIn(provided.getIn());
  };
}
// end header
