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
import interface.ifunction2


class function2 ():

    def __init__ (self):
        self.f = False

        self.i = interface.ifunction2 ()

        self.i.ins.a = self.i_a
        self.i.ins.b = self.i_b

    def i_a (self):
        sys.stderr.write ('function2.i_a\n')
        if (True):
            self.f = self.vtoggle ()


    def i_b (self):
        sys.stderr.write ('function2.i_b\n')
        if (True):
            self.f = self.vtoggle ()
            bb = self.vtoggle ()
            self.f = bb
            self.i.outs.d ()


    def vtoggle (self):
        if (self.f):
            self.i.outs.c ()
        return not (self.f)


