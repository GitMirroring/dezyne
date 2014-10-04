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
try:
    from enum import Enum
except:
    class Enum (): pass
#
import interface.I


class interface_port_overload ():

    def __init__ (self):
        self.reply_I_R = None

        self.I = interface.I ()

        self.I.ins.e = self.I_e

    def I_e (self):
        sys.stderr.write ('interface_port_overload.I_e\n')
        reply_I_R = interface.I.R.V
        return reply_I_R


