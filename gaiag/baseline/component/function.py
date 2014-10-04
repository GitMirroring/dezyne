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

import sys
#
import interface.I


class function ():

    def __init__ (self):
        self.f = False

        self.i = interface.I ()

        self.i.ins.a = self.i_a
        self.i.ins.b = self.i_b

    def i_a (self):
        sys.stderr.write ('function.i_a\n')
        if (True):
            self.toggle ()

    def i_b (self):
        sys.stderr.write ('function.i_b\n')
        if (True):
            self.toggle ()
            self.toggle ()
            self.i.outs.d ()

    def toggle (self):
        if (self.f):
            self.i.outs.c ()
        self.f = not (self.f)

