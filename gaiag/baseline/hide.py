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


class hide ():

    def __init__ (self):
        self.b = False
        self.c = True

        self.i = interface.I ()

        self.i.ins.e = self.i_e

    def i_e (self):
        sys.stderr.write ('hide.i_e\n')
        if (True):
            b = self.b
            c = self.g (self.b, self.c)
            if (self.c):
                self.i.outs.f ()


    def g (self, b, d):
        b = d
        d = self.c
        self.i.outs.f ()
        return (self.b or d)


