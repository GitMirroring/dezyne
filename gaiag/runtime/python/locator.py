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

import inspect

class Locator:
    def __init__ (self, services={}):
        self.services = services
    @staticmethod
    def key (type, key):
        type = type if inspect.isclass (type) else type.__class__
        return type.__name__ + key;
    def set (self, o, key=''):
        self.services[Locator.key (o, key)] = o
        return self
    def get (self, type, key=''):
        return self.services[Locator.key (type, key)]
    def clone (self):
        return Locator (self.services.copy ())

def main ():
    import sys
    loc = Locator ()
    i = 1
    s = 'foo'
    loc.set (i)
    loc.set (s)
    loc.set (loc)
    assert (loc.get (0) == i)
    assert (loc.get (int) == i)
    assert (loc.get ('') == s)
    assert (loc.get (str) == s)
    assert (loc.get (loc) == loc)
    assert (loc.get (Locator) == loc)
    assert (loc.get (Locator ()) == loc)
    assert (loc.clone().get (0) == i)

if __name__ == '__main__':
    main ()
