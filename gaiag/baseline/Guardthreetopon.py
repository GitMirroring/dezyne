# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
import dezyne.IGuardthreetopon
import dezyne.RGuardthreetopon


class Guardthreetopon ():

    def __init__ (self):
        self.b = False

        self.i = dezyne.IGuardthreetopon ()
        self.r = dezyne.RGuardthreetopon ()

        self.i.ins.e = self.i_e
        self.i.ins.t = self.i_t
        self.i.ins.s = self.i_s
        self.r.outs.a = self.r_a

    def i_e (self):
        sys.stderr.write ('Guardthreetopon.i_e\n')
        if (True and self.b):
            self.i.outs.a ()
        elif (True and not (self.b)):
            c = True
            if (c):
                self.i.outs.a ()


    def i_t (self):
        sys.stderr.write ('Guardthreetopon.i_t\n')
        if (self.b):
            self.i.outs.a ()
        elif (not (self.b)):
            self.i.outs.a ()


    def i_s (self):
        sys.stderr.write ('Guardthreetopon.i_s\n')
        self.i.outs.a ()


    def r_a (self):
        sys.stderr.write ('Guardthreetopon.r_a\n')
        pass



