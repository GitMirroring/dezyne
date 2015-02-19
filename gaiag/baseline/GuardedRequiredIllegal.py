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
import dezyne.Top
import dezyne.Bottom


class GuardedRequiredIllegal ():

    def __init__ (self):
        self.c = False

        self.t = dezyne.Top ()
        self.b = dezyne.Bottom ()

        self.t.ins.unguarded = self.t_unguarded
        self.t.ins.e = self.t_e
        self.b.outs.f = self.b_f

    def t_unguarded (self):
        sys.stderr.write ('GuardedRequiredIllegal.t_unguarded\n')
        pass


    def t_e (self):
        sys.stderr.write ('GuardedRequiredIllegal.t_e\n')
        if (not (self.c)):
            self.c = True
            self.b.ins.e ()
        elif (self.c):
            pass


    def b_f (self):
        sys.stderr.write ('GuardedRequiredIllegal.b_f\n')
        if (not (self.c)):
            assert (False)
        elif (self.c):
            self.c = False



