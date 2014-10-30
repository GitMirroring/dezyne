# Gaiag --- Guile in Asd In Asd in Guile.
#
# This file is part of Gaiag.
#
# Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
import interface.dummy
import interface.imodeling


class modeling ():

    def __init__ (self):

        self.p = interface.dummy ()
        self.r = interface.imodeling ()

        self.p.ins.e = self.p_e
        self.r.outs.f = self.r_f

    def p_e (self):
        sys.stderr.write ('modeling.p_e\n')
        if (True):
            self.r.ins.e ()
        elif (True):
            pass


    def r_f (self):
        sys.stderr.write ('modeling.r_f\n')
        if (True):
            pass
        elif (True):
            pass



