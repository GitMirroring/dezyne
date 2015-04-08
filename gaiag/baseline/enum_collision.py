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

import sys
import dezyne.ienum_collision

import runtime

class enum_collision:

    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
        self.handling = False
        self.flushes = True
        self.deferred = None
        self.queue = []

        self.reply_ienum_collision_Retval1 = None
        self.reply_ienum_collision_Retval2 = None
        self.i = dezyne.ienum_collision (provides=('i', self))

        self.i.ins.foo = lambda *args: runtime.call_in (self, lambda: self.i_foo (*args), (self.i, 'foo', self.i.Retval1_to_string))
        self.i.ins.bar = lambda *args: runtime.call_in (self, lambda: self.i_bar (*args), (self.i, 'bar', self.i.Retval2_to_string))

    def i_foo (self):
        self.reply_ienum_collision_Retval1 = dezyne.ienum_collision.Retval1.OK
        return self.reply_ienum_collision_Retval1

    def i_bar (self):
        self.reply_ienum_collision_Retval2 = dezyne.ienum_collision.Retval2.NOK
        return self.reply_ienum_collision_Retval2


