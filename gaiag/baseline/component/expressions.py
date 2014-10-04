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


class expressions ():

    def __init__ (self):
        self.state = 3
        self.c = 0

        self.i = interface.I ()

        self.i.ins.e = self.i_e

    def i_e (self):
        sys.stderr.write ('expressions.i_e\n')
        if (True):
            if (self.state == 0):
                self.state = 3
                self.i.outs.a ()
            else:
                self.state = self.state - 1
                if (self.c < self.state):
                    self.c = self.c + 1
                else:
                    if (self.c <= (self.state + 1)):
                        self.i.outs.lo ()
                    else:
                        if (self.c > self.state):
                            self.i.outs.hi ()


