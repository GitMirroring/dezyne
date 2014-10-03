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

import inspect
import sys
#
import component

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

def connect (provided, required):
    provided.outs = required.outs
    required.ins = provided.ins

class AlarmSystem ():
    def __init__ (self):
        self.alarm = component.Alarm ()
        self.sensor = component.Sensor ()
        self.siren = component.Siren ()
        self.console = self.alarm.console
        connect (self.sensor.sensor, self.alarm.sensor)
        connect (self.siren.siren, self.alarm.siren)
