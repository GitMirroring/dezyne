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

import dezyne.irequires_twice
import dezyne.irequires_twice
import dezyne.irequires_twice

import runtime

class requires_twice:

    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
        self.handling = False
        self.flushes = True
        self.deferred = None
        self.queue = []


        self.p = dezyne.irequires_twice (provides=('p', self))

        self.once = dezyne.irequires_twice (requires=('once', self))
        self.twice = dezyne.irequires_twice (requires=('twice', self))

        self.p.ins.e = lambda *args: runtime.call_in (self, lambda: self.p_e (*args), (self.p, 'e'))
        self.once.outs.a = lambda *args: runtime.call_out (self, lambda: self.once_a (*args), (self.once, 'a'))
        self.twice.outs.a = lambda *args: runtime.call_out (self, lambda: self.twice_a (*args), (self.twice, 'a'))

    def p_e (self):
        self.once.ins.e ()
        self.twice.ins.e ()


    def once_a (self):
        pass


    def twice_a (self):
        self.p.outs.a ()



