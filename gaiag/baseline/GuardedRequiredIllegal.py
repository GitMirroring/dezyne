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

import dezyne.Top
import dezyne.Bottom

import runtime

class GuardedRequiredIllegal:

    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
        self.handling = False
        self.flushes = True
        self.deferred = None
        self.queue = []

        self.c = False

        self.t = dezyne.Top (provides=('t', self))

        self.b = dezyne.Bottom (requires=('b', self))

        self.t.ins.unguarded = lambda *args: runtime.call_in (self, lambda: self.t_unguarded (*args), (self.t, 'unguarded'))
        self.t.ins.e = lambda *args: runtime.call_in (self, lambda: self.t_e (*args), (self.t, 'e'))
        self.b.outs.f = lambda *args: runtime.call_out (self, lambda: self.b_f (*args), (self.b, 'f'))

    def t_unguarded (self):
        pass


    def t_e (self):
        if (not (self.c)):
            self.c = True
            self.b.ins.e ()
        elif (self.c):
            pass


    def b_f (self):
        if (not (self.c)):
            assert (False)
        elif (self.c):
            self.c = False



