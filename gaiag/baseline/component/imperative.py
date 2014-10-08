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
import interface.iimperative


class imperative ():
    class States ():
        I, II, III, IV = range (4)

    def __init__ (self):
        self.state = self.States.I

        self.i = interface.iimperative ()

        self.i.ins.e = self.i_e

    def i_e (self):
        sys.stderr.write ('imperative.i_e\n')
        if (self.state == self.States.I):
            self.i.outs.f ()
            self.i.outs.g ()
            self.i.outs.h ()
            self.state = self.States.II
        elif (self.state == self.States.II):
            self.state = self.States.III
        elif (self.state == self.States.III):
            self.i.outs.f ()
            self.i.outs.g ()
            self.i.outs.g ()
            self.i.outs.f ()
            self.state = self.States.IV
        elif (self.state == self.States.IV):
            self.i.outs.h ()
            self.state = self.States.I



