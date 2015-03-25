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

import dezyne.iincomplete_with_modeling_event
import dezyne.iincomplete_with_modeling_event

import runtime

class incomplete_with_modeling_event:

    def __init__ (self, parent=None, name=''):
        self.parent = parent
        self.name = name
        self.handling = False
        self.deferred = None
        self.queue = []


        self.p = dezyne.iincomplete_with_modeling_event (provides=('p', self))

        self.r = dezyne.iincomplete_with_modeling_event (requires=('r', self))

        self.p.ins.e = lambda *args: runtime.call_in (self, lambda: self.p_e (*args), (self.p, 'e'))
        self.r.outs.a = lambda *args: runtime.call_out (self, lambda: self.r_a (*args), (self.r, 'a'))

    def p_e (self):
        pass


    def r_a (self):
        self.p.outs.a ()



