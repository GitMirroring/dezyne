# Dezyne --- Dezyne command line tools
#
# Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

import dezyne.I

import runtime

class expressions:

    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
        self.handling = False
        self.flushes = True
        self.deferred = None
        self.queue = []

        self.state = 3
        self.c = 0

        self.i = dezyne.I (provides=('i', self))


        self.i.ins.e = lambda *args: runtime.call_in (self, lambda: self.i_e (*args), (self.i, 'e'))

    def i_e (self):
        if (True):
            if (self.state == 0):
                self.state = 3
                self.i.outs.a ()
            else:
                self.state = self.state - 1
                if (self.c < self.state):
                    self.c = self.c + 1
                else:
                    if (self.c <= (self.state + 1)):
                        self.i.outs.lo ()
                    else:
                        if (self.c > self.state):
                            self.i.outs.hi ()



