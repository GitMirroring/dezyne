# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Gaiag.
#
# Gaiag is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Gaiag is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
# 
# Commentary:
# 
# Code:

import inspect
import sys
try:
    from enum import Enum
except:
    class Enum (): pass
#
import interface.I
import interface.U


class Reply5 ():

    def __init__ (self):
        self.dummy = False
        self.reply_I_Status = None
        self.reply_U_Status = None

        self.i = interface.I ()
        self.u = interface.U ()

        self.i.ins.done = self.i_done

    def i_done (self):
        sys.stderr.write ('Reply5.i_done\n')
        if (True):
            s =     self.u.ins.what ()
            self.s =             self.u.ins.what ()
            if (self.s == interface.U.Status.Ok):
                s = self.fun ()
                reply_I_Status = self.s
            else:
                s = self.fun_arg (interface.I.Status.No)
                reply_I_Status = self.s
        return reply_I_Status

    def fun (self):
        return interface.I.Status.Yes
    def fun_arg (self, s):
        return self.s

