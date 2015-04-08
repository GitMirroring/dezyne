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

import sys
import dezyne.ITopon

import runtime

class Topon:

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
        self.c = False
        self.i = dezyne.ITopon (provides=('i', self))

        self.i.ins.e = lambda *args: runtime.call_in (self, lambda: self.i_e (*args), (self.i, 'e'))
        self.i.ins.t = lambda *args: runtime.call_in (self, lambda: self.i_t (*args), (self.i, 't'))

    def i_e (self):
        if (self.b and not (self.c)):
            self.i.outs.a ()
        elif (not (self.b) and not (self.c)):
            self.i.outs.a ()
        elif (not (self.c) and not (self.b)):
            self.i.outs.a ()


    def i_t (self):
        self.i.outs.a ()



