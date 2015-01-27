# Dezyne --- Dezyne command line tools
#
# Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
#
# This file is part of Dezyne.
#
# Dezyne is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Dezyne is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
# 
# Commentary:
# 
# Code:

import sys
#
import dezyne.IRun
import dezyne.IChoice


class Adaptor ():
    class State ():
        Idle, Active, Terminating = range (3)

    def __init__ (self):
        self.state = self.State.Idle
        self.count = 0

        self.runner = dezyne.IRun ()
        self.choice = dezyne.IChoice ()

        self.runner.ins.run = self.runner_run
        self.choice.outs.a = self.choice_a

    def runner_run (self):
        sys.stderr.write ('Adaptor.runner_run\n')
        if (self.state == self.State.Idle):
            if (self.count < 2):
                self.choice.ins.e ()
                self.state = self.State.Active
            else:
                pass
        elif (self.state == self.State.Active):
            pass
        elif (self.state == self.State.Terminating):
            pass


    def choice_a (self):
        sys.stderr.write ('Adaptor.choice_a\n')
        if (self.state == self.State.Idle):
            pass
        elif (self.state == self.State.Active):
            self.count = self.count + 1
            self.choice.ins.e ()
            self.state = self.State.Terminating
        elif (self.state == self.State.Terminating):
            if (self.count < 2):
                self.choice.ins.e ()
                self.state = self.State.Active
            else:
                self.state = self.State.Idle



