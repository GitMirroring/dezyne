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
#
import dzn.Datasystem
import locator
import runtime
from runtime import V

def a0 ():
    sys.stderr.write ('a0()\n')

def a (i):
    sys.stderr.write ('a(' + `i` + ')\n')

def aa (i, j):
    sys.stderr.write ('aa(' + `i` + ',' + `j` + ')\n')
    assert (j == 123)

def a6 (i0, i1, i2,i3, i4, i5):
    sys.stderr.write('a6(' + `i0` + ',' + `i1` + ',' + `i2` + ',' + `i3` + ',' + `i4` + ',' + `i5` + ')\n')
    assert (i0 == 0)
    assert (i1 == 1)
    assert (i2 == 2)
    assert (i3 == 3)
    assert (i4 == 4)
    assert (i5 == 5)

def main ():
    loc = locator.Locator ()
    rt = runtime.Runtime ()
    d = dzn.Datasystem (loc.set (rt), name='d')
    d.port.outport.name = 'port'
    d.port.outport.self = None

    d.port.outport.a0 = a0
    d.port.outport.a = a
    d.port.outport.aa = aa
    d.port.outport.a6 = a6

    assert (dzn.IDataparam.Status.Yes == d.port.inport.e0r ())
    d.port.inport.e0 ()
    assert (dzn.IDataparam.Status.Yes == d.port.inport.er (123))
    d.port.inport.e (123)
    assert (dzn.IDataparam.Status.No == d.port.inport.eer (123,345))

    i = V (0)
    d.port.inport.eo (i)
    assert (i.v == 234)

    j = V (0)
    d.port.inport.eoo (i,j)
    assert (i.v == 123 and j.v == 456)

    d.port.inport.eio (i.v,j)
    assert (i.v == 123 and j.v == i.v)

    d.port.inport.eio2 (i)
    assert (i.v == 246)


    assert (dzn.IDataparam.Status.Yes == d.port.inport.eor (i))
    assert (i.v == 234)

    assert (dzn.IDataparam.Status.Yes == d.port.inport.eoor (i,j))
    assert (i.v == 123 and j.v == 456)

    assert (dzn.IDataparam.Status.Yes == d.port.inport.eior (i.v,j))
    assert (i.v == 123 and j.v == i.v)

    assert (dzn.IDataparam.Status.Yes == d.port.inport.eio2r (i))
    assert (i.v == 246)


if __name__ == '__main__':
    main ()
