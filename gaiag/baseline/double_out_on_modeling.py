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
import interface.I
import interface.I


class double_out_on_modeling ():
    class State ():
        First, Second = range (2)

    def __init__ (self):
        self.state = self.State.First

        self.p = interface.I ()
        self.r = interface.I ()

        self.p.ins.start = self.p_start
        self.r.outs.foo = self.r_foo
        self.r.outs.bar = self.r_bar

    def p_start (self):
        sys.stderr.write ('double_out_on_modeling.p_start\n')
        if (self.state == self.State.First):
            self.r.ins.start ()
            self.state = self.State.Second
        elif (self.state == self.State.Second):
            assert (False)


    def r_foo (self):
        sys.stderr.write ('double_out_on_modeling.r_foo\n')
        if (self.state == self.State.First):
            assert (False)
        elif (self.state == self.State.Second):
            self.p.outs.foo ()


    def r_bar (self):
        sys.stderr.write ('double_out_on_modeling.r_bar\n')
        if (self.state == self.State.First):
            assert (False)
        elif (self.state == self.State.Second):
            self.p.outs.bar ()
            self.state = self.State.First



