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
import dezyne.U

import runtime

class Reply3:

    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
        self.handling = False
        self.flushes = True
        self.deferred = None
        self.queue = []

        self.dummy = False
        self.reply_I_Status = None
        self.reply_U_Status = None

        self.i = dezyne.I (provides=('i', self))

        self.u = dezyne.U (requires=('u', self))

        self.i.ins.done = lambda *args: runtime.call_in (self, lambda: self.i_done (*args), (self.i, 'done', self.i.Status_to_string))

    def i_done (self):
        if (True):
            s = {'value': self.u.ins.what ()}
            s['value'] = self.u.ins.what ()
            if (s['value'] == dezyne.U.Status.Ok):
                self.reply_fun ()
            else:
                self.reply_fun_arg (dezyne.I.Status.No)
        return self.reply_I_Status

    def reply_fun (self):
        self.reply_I_Status = dezyne.I.Status.Yes

    def reply_fun_arg (self,s):
        self.reply_I_Status = s


