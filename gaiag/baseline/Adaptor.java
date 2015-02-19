// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

class Adaptor{
  enum State {
    Idle, Active, Terminating
  };

  State state;
  Integer count;

  IRun runner;
  IChoice choice;

  public Adaptor() {
    state = State.Idle;
    count = 0;
    runner = new IRun();
    choice = new IChoice();
    runner.getIn().run = new Action() {
      public void action() {
        runner_run();
      }
    };
    choice.getOut().a = new Action() {
      public void action() {
        choice_a();
      }
    };
  };
  public void runner_run() {
    System.err.println("Adaptor.runner_run");
    if (state == State.Idle && count < 2) {
      choice.getIn().e.action();
      state = State.Active;
    }
    else if (state == State.Idle && ! (count < 2)) { }
    else if (state == State.Active) {
      { }
    }
    else if (state == State.Terminating) { }
  };

  public void choice_a() {
    System.err.println("Adaptor.choice_a");
    if (state == State.Idle) { }
    else if (state == State.Active) {
      {
        count = count + 1;
        choice.getIn().e.action();
        state = State.Terminating;
      }
    }
    else if (state == State.Terminating && count < 2) {
      choice.getIn().e.action();
      state = State.Active;
    }
    else if (state == State.Terminating && ! (count < 2)) state = State.Idle;
  };

}
