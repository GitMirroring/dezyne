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

import dezyne.IChoice

import runtime

class Choice:
    class State ():
        Off, Idle, Busy = range (3)

    def __init__ (self, parent=None, name=''):
        self.parent = parent
        self.name = name
        self.handling = False
        self.deferred = None
        self.queue = []

        self.s = self.State.Off

        self.c = dezyne.IChoice (provides=('c', self))


        self.c.ins.e = lambda *args: runtime.call_in (self, lambda: self.c_e (*args), (self.c, 'e'))

    def c_e (self):
        if (self.s == self.State.Off):
            self.s = self.State.Idle
            self.c.outs.a ()
        elif (self.s == self.State.Idle):
            self.s = self.State.Busy
            self.c.outs.a ()
        elif (self.s == self.State.Busy):
            self.s = self.State.Idle
            self.c.outs.a ()



