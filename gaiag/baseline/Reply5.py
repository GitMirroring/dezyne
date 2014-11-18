# Dezyne --- Dezyne command line tools
#
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
#
import dezyne.I
import dezyne.U


class Reply5 ():

    def __init__ (self):
        self.dummy = False
        self.reply_I_Status = None
        self.reply_U_Status = None

        self.i = dezyne.I ()
        self.u = dezyne.U ()

        self.i.ins.done = self.i_done

    def i_done (self):
        sys.stderr.write ('Reply5.i_done\n')
        if (True):
            s = self.u.ins.what ()
            s = self.u.ins.what ()
            if (s == U.Status.Ok):
                s = self.fun ()
                self.reply_I_Status = s
            else:
                s = self.fun_arg (I.Status.No)
                self.reply_I_Status = s
        return self.reply_I_Status

    def fun (self):
        return I.Status.Yes

    def fun_arg (self, s):
        return s


