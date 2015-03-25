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

import dezyne.dummy
import dezyne.imodeling

import runtime

class modeling:

    def __init__ (self, parent=None, name=''):
        self.parent = parent
        self.name = name
        self.handling = False
        self.deferred = None
        self.queue = []


        self.p = dezyne.dummy (provides=('p', self))

        self.r = dezyne.imodeling (requires=('r', self))

        self.p.ins.e = lambda *args: runtime.call_in (self, lambda: self.p_e (*args), (self.p, 'e'))
        self.r.outs.f = lambda *args: runtime.call_out (self, lambda: self.r_f (*args), (self.r, 'f'))

    def p_e (self):
        self.r.ins.e ()


    def r_f (self):
        pass



