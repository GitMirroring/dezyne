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
import interface.IReply7
import interface.IReply7


class Reply7 ():

    def __init__ (self):
        self.reply_IReply7_E = None

        self.p = interface.IReply7 ()
        self.r = interface.IReply7 ()

        self.p.ins.foo = self.p_foo

    def p_foo (self):
        sys.stderr.write ('Reply7.p_foo\n')
        self.f ()
        return self.reply_IReply7_E

    def f (self):
        v = self.r.ins.foo ()
        self.reply_IReply7_E = v


