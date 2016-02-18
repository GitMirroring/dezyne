# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Gaiag.
#
# Gaiag is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Gaiag is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
# 
# Commentary:
# 
# Code:

#! /usr/bin/python

import sys
import os
sys.path.insert (0, os.path.dirname (sys.argv[0]))
#
import dzn.AlarmSystem
import locator
import runtime

def detected ():
    sys.stderr.write ('Console.detected\n')

def deactivated ():
    sys.stderr.write ('Console.deactivated\n')

def main ():
    loc = locator.Locator ()
    rt = runtime.Runtime ()
    sut = dzn.AlarmSystem (loc.set (rt), name='alarmsystem')
    sut.console.outport.name = 'console'
    sut.console.outport.self = sut

    sut.console.outport.detected = detected
    sut.console.outport.deactivated = deactivated

    sut.console.inport.arm ()
    sut.sensor.sensor.outport.triggered ()
    rt.flush (sut.sensor)
    sut.console.inport.disarm ()
    sut.sensor.sensor.outport.disabled ()
    rt.flush (sut.sensor)

if __name__ == '__main__':
    main ()
