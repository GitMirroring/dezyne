# Dezyne --- Dezyne command line tools
# Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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
import runtime

def a0():
    sys.stderr.write('a0()\n');

def a(i):
    sys.stderr.write('a(' + `i` + ')\n');

def aa(i, j):
    sys.stderr.write('aa(' + `i` + ',' + `j` + ')\n')
    assert(j == 123);

def a6(i0, i1, i2,i3, i4, i5):
    sys.stderr.write('a6(' + `i0` + ',' + `i1` + ',' + `i2` + ',' + `i3` + ',' + `i4` + ',' + `i5` + ')\n');
    assert(i0 == 0);
    assert(i1 == 1);
    assert(i2 == 2);
    assert(i3 == 3);
    assert(i4 == 4);
    assert(i5 == 5);

def main():
    rt = runtime.runtime ()
    d = dzn.Datasystem(rt, name='d');
    d.port.outs.name = 'port'
    d.port.outs.self = d

    d.port.outs.a0 = a0;
    d.port.outs.a = a;
    d.port.outs.aa = aa;
    d.port.outs.a6 = a6;

    assert(dzn.IDataparam().Status.Yes == d.port.ins.e0r());
    d.port.ins.e0();
    assert(dzn.IDataparam().Status.Yes == d.port.ins.er(123));
    d.port.ins.e(123);
    assert(dzn.IDataparam().Status.No == d.port.ins.eer(123,345));

    i = {'value':0};
    d.port.ins.eo(i);
    assert(i['value'] == 234);

    j = {'value':0};
    d.port.ins.eoo(i,j);
    assert(i['value'] == 123 and j['value'] == 456);

    d.port.ins.eio(i['value'],j);
    assert(i['value'] == 123 and j['value'] == i['value']);

    d.port.ins.eio2(i);
    assert(i['value'] == 246);


    assert(dzn.IDataparam().Status.Yes == d.port.ins.eor(i));
    assert(i['value'] == 234);

    assert(dzn.IDataparam().Status.Yes == d.port.ins.eoor(i,j));
    assert(i['value'] == 123 and j['value'] == 456);

    assert(dzn.IDataparam().Status.Yes == d.port.ins.eior(i['value'],j));
    assert(i['value'] == 123 and j['value'] == i['value']);

    assert(dzn.IDataparam().Status.Yes == d.port.ins.eio2r(i));
    assert(i['value'] == 246);


if __name__ == '__main__':
    main ()
