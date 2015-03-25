# Dezyne --- Dezyne command line tools
#
# Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

import dezyne.I

import runtime

class sugar:
    class Enum ():
        False, True = range (2)

    def __init__ (self, parent=None, name=''):
        self.parent = parent
        self.name = name
        self.handling = False
        self.deferred = None
        self.queue = []

        self.s = self.Enum.False

        self.i = dezyne.I (provides=('i', self))


        self.i.ins.e = lambda *args: runtime.call_in (self, lambda: self.i_e (*args), (self.i, 'e'))

    def i_e (self):
        if (self.s == self.Enum.False):
            if (self.s == self.Enum.False):
                self.i.outs.a ()
            else:
                t = {'value': self.Enum.False}
                if (t == self.Enum.True):
                    self.i.outs.a ()



