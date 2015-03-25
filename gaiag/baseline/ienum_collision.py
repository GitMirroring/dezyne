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

class ienum_collision:
    class Retval1 ():
        OK, NOK = range (2)
    class Retval2 ():
        OK, NOK = range (2)
    Retval1_to_string = [ 'Retval1_OK', 'Retval1_NOK']
    Retval2_to_string = [ 'Retval2_OK', 'Retval2_NOK']
    def __init__ (self, provides=('', None), requires=('', None)):
        class Ins:
            def __init__ (self, name, c):
                self.name = name
                self.self = c
                self.foo = None
                self.bar = None
        self.ins = Ins (*provides)
        class Outs:
            def __init__ (self, name, c):
                self.name = name
                self.self = c
        self.outs = Outs (*requires)
