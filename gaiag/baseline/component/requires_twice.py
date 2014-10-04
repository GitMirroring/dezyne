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
import interface.irequires_twice
import interface.irequires_twice
import interface.irequires_twice


class requires_twice ():

    def __init__ (self):

        self.p = interface.irequires_twice ()
        self.once = interface.irequires_twice ()
        self.twice = interface.irequires_twice ()

        self.p.ins.e = self.p_e
        self.once.outs.a = self.once_a
        self.twice.outs.a = self.twice_a

    def p_e (self):
        sys.stderr.write ('requires_twice.p_e\n')
        self.once.outs.a ()
        self.twice.outs.a ()

    def once_a (self):
        sys.stderr.write ('requires_twice.once_a\n')

    def twice_a (self):
        sys.stderr.write ('requires_twice.twice_a\n')


