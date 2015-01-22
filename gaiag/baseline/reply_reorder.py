# Dezyne --- Dezyne command line tools
#
# Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
import dezyne.Provides
import dezyne.Requires


class reply_reorder ():

    def __init__ (self):
        self.first = True

        self.p = dezyne.Provides ()
        self.r = dezyne.Requires ()

        self.p.ins.start = self.p_start
        self.r.outs.pong = self.r_pong

    def p_start (self):
        sys.stderr.write ('reply_reorder.p_start\n')
        self.r.ins.ping ()


    def r_pong (self):
        sys.stderr.write ('reply_reorder.r_pong\n')
        if (self.first):
            self.p.outs.busy ()
            self.first = not (self.first)
        elif (not (self.first)):
            self.p.outs.finish ()
            self.first = not (self.first)



