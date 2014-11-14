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
import interface.IIf2


class If2 ():

    def __init__ (self):
        self.b = False
        self.r = interface.IIf2.result.value
        self.reply_IIf2_result = None

        self.i = interface.IIf2 ()

        self.i.ins.e = self.i_e

    def i_e (self):
        sys.stderr.write ('If2.i_e\n')
        if (self.b):
            v = self.i.outs.a ()
        else:
            v = self.i.outs.a ()
        self.b = not (self.b)


