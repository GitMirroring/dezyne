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
import dezyne.ienum_collision


class enum_collision ():

    def __init__ (self):
        self.reply_ienum_collision_Retval1 = None
        self.reply_ienum_collision_Retval2 = None

        self.i = dezyne.ienum_collision ()

        self.i.ins.foo = self.i_foo
        self.i.ins.bar = self.i_bar

    def i_foo (self):
        sys.stderr.write ('enum_collision.i_foo\n')
        self.reply_ienum_collision_Retval1 = ienum_collision.Retval1.OK
        return self.reply_ienum_collision_Retval1

    def i_bar (self):
        sys.stderr.write ('enum_collision.i_bar\n')
        self.reply_ienum_collision_Retval2 = ienum_collision.Retval2.NOK
        return self.reply_ienum_collision_Retval2


