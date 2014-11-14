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
import interface.I
import interface.U


class Reply ():

    def __init__ (self):
        self.dummy = False
        self.reply_I_Status = None
        self.reply_U_Status = None

        self.i = interface.I ()
        self.u = interface.U ()

        self.i.ins.done = self.i_done

    def i_done (self):
        sys.stderr.write ('Reply.i_done\n')
        if (True):
            s = self.u.ins.what ()
            if (s == interface.U.Status.Ok):
                self.reply_I_Status = interface.I.Status.Yes
            else:
                self.reply_I_Status = interface.I.Status.No
        return self.reply_I_Status


