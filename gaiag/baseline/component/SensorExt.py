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

import sys
#
import interface

class SensorExt:
    def __init__ (self):
        self.sensor = interface.Sensor ()
        self.sensor.ins.enable = self.sensor_enable
        self.sensor.ins.disable = self.sensor_enable

    def sensor_enable (self):
        sys.stderr.write ('SensorExt.enable\n')

    def sensor_disable (self):
        sys.stderr.write ('SensorExt.disable\n')

