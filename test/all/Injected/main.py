# Dezyne --- Dezyne command line tools
# Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#! /usr/bin/python

import sys
import os
sys.path.insert (0, os.path.dirname (sys.argv[0]))
##
import dzn.Injected
import runtime
import locator

def f ():
    sys.stderr.write ('f\n')

def main ():
    loc = locator.Locator ()
    rt = runtime.Runtime ()

    sut = dzn.Injected (loc.set (rt), 'sut')
    sut.t.outport.f = f;

    #sut.check_bindings ()
    #sut.dump_tree ()

    sut.t.inport.e ()

if __name__ == '__main__':
    main ()
