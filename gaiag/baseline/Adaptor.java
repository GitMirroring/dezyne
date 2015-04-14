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

class Adaptor extends Component {
  enum State {
    Idle, Active, Terminating
  };

  State state;
  Integer count;

  IRun runner;
  IChoice choice;

  public Adaptor(Runtime runtime) {this(runtime, "");};

  public Adaptor(Runtime runtime, String name) {this(runtime, name, null);};

  public Adaptor(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    state = State.Idle;
    count = 0;
    runner = new IRun();
    runner.in.name = "runner";
    runner.in.self = this;
    state = State.Idle;
    count = 0;
    choice = new IChoice();
    choice.out.name = "choice";
    choice.out.self = this;
    runner.in.run = new Action() {public void action() {Runtime.callIn(Adaptor.this, new Action() {public void action() {runner_run();}}, new Meta(Adaptor.this.runner, "run"));};};

    choice.out.a = new Action() {public void action() {Runtime.callOut(Adaptor.this, new Action() {public void action() {choice_a();}}, new Meta(Adaptor.this.choice, "a"));};};

  };
  public void runner_run() {
    if (state == State.Idle && count < 2) {
      choice.in.e.action();
      state = State.Active;
    }
    else if (state == State.Idle && ! (count < 2)) { }
    else if (state == State.Active) {
      { }
    }
    else if (state == State.Terminating) { }
  };

  public void choice_a() {
    if (state == State.Idle) { }
    else if (state == State.Active) {
      {
        count = count + 1;
        choice.in.e.action();
        state = State.Terminating;
      }
    }
    else if (state == State.Terminating && count < 2) {
      choice.in.e.action();
      state = State.Active;
    }
    else if (state == State.Terminating && ! (count < 2)) state = State.Idle;
  };

}
