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

class IDevice:
    class result_t ():
        OK, NOK = range (2)
    result_t_to_string = [ 'result_t_OK', 'result_t_NOK']
    def __init__ (self, provides=('', None), requires=('', None)):
        class Ins:
            def __init__ (self, name, c):
                self.name = name
                self.self = c
                self.initialize = None
                self.calibrate = None
                self.perform_action1 = None
                self.perform_action2 = None
        self.ins = Ins (*provides)
        class Outs:
            def __init__ (self, name, c):
                self.name = name
                self.self = c
        self.outs = Outs (*requires)
