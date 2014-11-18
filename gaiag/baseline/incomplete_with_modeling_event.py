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
import dezyne.iincomplete_with_modeling_event
import dezyne.iincomplete_with_modeling_event


class incomplete_with_modeling_event ():

    def __init__ (self):

        self.p = dezyne.iincomplete_with_modeling_event ()
        self.r = dezyne.iincomplete_with_modeling_event ()

        self.p.ins.e = self.p_e
        self.r.outs.a = self.r_a

    def p_e (self):
        sys.stderr.write ('incomplete_with_modeling_event.p_e\n')


    def r_a (self):
        sys.stderr.write ('incomplete_with_modeling_event.r_a\n')
        self.p.outs.a ()



