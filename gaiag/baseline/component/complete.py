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
import interface.icomplete
import interface.icomplete


class complete ():

    def __init__ (self):

        self.p = interface.icomplete ()
        self.r = interface.icomplete ()

        self.p.ins.e = self.p_e
        self.r.outs.a = self.r_a

    def p_e (self):
        sys.stderr.write ('complete.p_e\n')
        self.r.ins.e ()


    def r_a (self):
        sys.stderr.write ('complete.r_a\n')
        self.p.outs.a ()



