# Dezyne --- Dezyne command line tools
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

import dezyne.IGuardthreetopon
import dezyne.RGuardthreetopon

import runtime

class Guardthreetopon:

    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
        self.handling = False
        self.flushes = True
        self.deferred = None
        self.queue = []

        self.b = False

        self.i = dezyne.IGuardthreetopon (provides=('i', self))

        self.r = dezyne.RGuardthreetopon (requires=('r', self))

        self.i.ins.e = lambda *args: runtime.call_in (self, lambda: self.i_e (*args), (self.i, 'e'))
        self.i.ins.t = lambda *args: runtime.call_in (self, lambda: self.i_t (*args), (self.i, 't'))
        self.i.ins.s = lambda *args: runtime.call_in (self, lambda: self.i_s (*args), (self.i, 's'))
        self.r.outs.a = lambda *args: runtime.call_out (self, lambda: self.r_a (*args), (self.r, 'a'))

    def i_e (self):
        if (True and self.b):
            self.i.outs.a ()
        elif (True and not (self.b)):
            c = {'value': True}
            if (c['value']):
                self.i.outs.a ()


    def i_t (self):
        if (self.b):
            self.i.outs.a ()
        elif (not (self.b)):
            self.i.outs.a ()


    def i_s (self):
        self.i.outs.a ()


    def r_a (self):
        pass



