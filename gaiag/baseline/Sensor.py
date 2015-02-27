# Dezyne --- Dezyne command line tools
#
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

import sys
#
import dezyne

class Sensor:
    def __init__ (self):
        self.sensor = dezyne.ISensor ()
        self.sensor.ins.enable = self.sensor_enable
        self.sensor.ins.disable = self.sensor_enable

    def sensor_enable (self):
        sys.stderr.write ('Sensor.enable\n')

    def sensor_disable (self):
        sys.stderr.write ('Sensor.disable\n')
