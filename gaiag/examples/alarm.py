# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
import dezyne.AlarmSystem
import runtime

def detected ():
   sys.stderr.write ('Console.detected\n')

def deactivated ():
   sys.stderr.write ('Console.deactivated\n')

def main ():
    alarm_system = dezyne.AlarmSystem (name='alarmsystem')
    alarm_system.console.outs.name = 'console'
    alarm_system.console.outs.self = alarm_system

    alarm_system.console.outs.detected = detected
    alarm_system.console.outs.deactivated = deactivated

    alarm_system.console.ins.arm ()
    alarm_system.sensor.sensor.outs.triggered ()
    runtime.flush(alarm_system.sensor)
    alarm_system.console.ins.disarm ()
    alarm_system.sensor.sensor.outs.disabled ()
    runtime.flush(alarm_system.sensor)

if __name__ == '__main__':
    main ()
