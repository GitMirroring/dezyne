# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

import collections
import inspect
import sys

def __info__ (depth=1):
    return inspect.stack ()[depth]

def __file_name__ (depth=1):
    return __info__ (depth + 1)[1]

def __line__ (depth=1):
    return __info__ (depth + 1)[2]

def __function__ (depth=1):
    return __info__ (depth + 1)[3]

def object_bind (object, function):
    return lambda *args: function (object, *args)

class Console ():
    def __init__ (self):
        self._in = collections.namedtuple ('arm', 'disarm')
        self._out = collections.namedtuple ('detected', 'deactivated')

class Sensor ():
    def __init__ (self):
        self._in = collections.namedtuple ('enable', 'disable')
        self._out = collections.namedtuple ('triggered', 'disabled')

class Siren ():
    def __init__ (self):
        class In ():
            self.turnon = None
            self.turnoff = None
        self._in = In ()
        self._out = None

class Alarm ():
    def __init__ (self):
        self.state = 'disarmed'
        self.sounding = False
        self.po_console = Console ()
        self.po_sensor = Sensor ()
        self.po_siren = Siren ()

        #self.po_console._in.arm = object_bind (self, self.po_console_arm)
        self.po_console._in.arm = self.po_console_arm
        self.po_console._in.disarm = self.po_console_disarm
        self.po_sensor._out.triggered = self.po_sensor_triggered
        self.po_sensor._out.disabled = self.po_sensor_disabled

    def po_console_arm (self):
        sys.stderr.write (self.__class__.__name__ + '.' + __function__ () + '\n')

    def po_console_disarm (self):
        sys.stderr.write (self.__class__.__name__ + '.' + __function__ () + '\n')

    def po_sensor_triggered (self):
        sys.stderr.write (self.__class__.__name__ + '.' + __function__ () + '\n')

    def po_sensor_disabled (self):
        sys.stderr.write (self.__class__.__name__ + '.' + __function__ () + '\n')

class AlarmSystem ():
    def __init__ (self):
        self.is_alarm = Alarm ()
        self.is_sensor = Sensor ()
        self.is_siren = Siren ()
        self.po_console = self.is_alarm.po_console
        self.is_sensor.po_sensor = self.is_alarm.po_sensor
        self.is_siren.po_siren = self.is_alarm.po_siren

def detected ():
   sys.stderr.write ('Console.detected\n')

def deactivated ():
   sys.stderr.write ('Console.deactivated\n')

def main ():
    alarm_system = AlarmSystem ()
    alarm_system.po_console._out.detected = detected
    alarm_system.po_console._out.deactivated = deactivated

    alarm_system.po_console._in.arm ()
    alarm_system.is_sensor.po_sensor._out.triggered ()
    alarm_system.po_console._in.disarm ()
    alarm_system.is_sensor.po_sensor._out.disabled ()
    print alarm_system

if __name__ == '__main__':
    main ()
