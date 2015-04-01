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

import dezyne.IReply7
import dezyne.IReply7

import runtime

class Reply7:

    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
        self.handling = False
        self.flushes = True
        self.deferred = None
        self.queue = []

        self.reply_IReply7_E = None

        self.p = dezyne.IReply7 (provides=('p', self))

        self.r = dezyne.IReply7 (requires=('r', self))

        self.p.ins.foo = lambda *args: runtime.call_in (self, lambda: self.p_foo (*args), (self.p, 'foo', self.p.E_to_string))

    def p_foo (self):
        self.f ()
        return self.reply_IReply7_E

    def f (self):
        v = {'value': self.r.ins.foo ()}
        self.reply_IReply7_E = v['value']


