# Dezyne --- Dezyne command line tools
#
# Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

import dezyne.IRun
import dezyne.IChoice

import runtime

class Adaptor:
    class State ():
        Idle, Active, Terminating = range (3)

    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
        self.handling = False
        self.flushes = True
        self.deferred = None
        self.queue = []

        self.state = self.State.Idle
        self.count = 0

        self.runner = dezyne.IRun (provides=('runner', self))

        self.choice = dezyne.IChoice (requires=('choice', self))

        self.runner.ins.run = lambda *args: runtime.call_in (self, lambda: self.runner_run (*args), (self.runner, 'run'))
        self.choice.outs.a = lambda *args: runtime.call_out (self, lambda: self.choice_a (*args), (self.choice, 'a'))

    def runner_run (self):
        if (self.state == self.State.Idle and self.count < 2):
            self.choice.ins.e ()
            self.state = self.State.Active
        elif (self.state == self.State.Idle and not (self.count < 2)):
            pass
        elif (self.state == self.State.Active):
            pass
        elif (self.state == self.State.Terminating):
            pass


    def choice_a (self):
        if (self.state == self.State.Idle):
            pass
        elif (self.state == self.State.Active):
            self.count = self.count + 1
            self.choice.ins.e ()
            self.state = self.State.Terminating
        elif (self.state == self.State.Terminating and self.count < 2):
            self.choice.ins.e ()
            self.state = self.State.Active
        elif (self.state == self.State.Terminating and not (self.count < 2)):
            self.state = self.State.Idle



