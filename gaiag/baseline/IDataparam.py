# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

class IDataparam:
    class Status ():
        Yes, No = range (2)
    Status_to_string = [ 'Status_Yes', 'Status_No']
    def __init__ (self, provides=('', None), requires=('', None)):
        class Ins:
            def __init__ (self, name, c):
                self.name = name
                self.self = c
                self.e0 = None
                self.e0r = None
                self.e = None
                self.er = None
                self.eer = None
                self.eo = None
                self.eoo = None
                self.eio = None
                self.eio2 = None
                self.eor = None
                self.eoor = None
                self.eior = None
                self.eio2r = None
        self.ins = Ins (*provides)
        class Outs:
            def __init__ (self, name, c):
                self.name = name
                self.self = c
                self.a0 = None
                self.a = None
                self.aa = None
                self.a6 = None
        self.outs = Outs (*requires)
