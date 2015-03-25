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

import dezyne.ifunction2

import runtime

class function2:

    def __init__ (self, parent=None, name=''):
        self.parent = parent
        self.name = name
        self.handling = False
        self.deferred = None
        self.queue = []

        self.f = False

        self.i = dezyne.ifunction2 (provides=('i', self))


        self.i.ins.a = lambda *args: runtime.call_in (self, lambda: self.i_a (*args), (self.i, 'a'))
        self.i.ins.b = lambda *args: runtime.call_in (self, lambda: self.i_b (*args), (self.i, 'b'))

    def i_a (self):
        if (True):
            self.f = self.vtoggle ()


    def i_b (self):
        if (True):
            self.f = self.vtoggle ()
            bb = {'value': self.vtoggle ()}
            self.f = bb['value']
            self.i.outs.d ()


    def vtoggle (self):
        if (self.f):
            self.i.outs.c ()
        return not (self.f)


