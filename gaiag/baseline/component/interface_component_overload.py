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
import interface.interface_component_overload


class interface_component_overload ():

    def __init__ (self):
        self.reply_interface_component_overload_R = None

        self.interface_component_overload = interface.interface_component_overload ()

        self.interface_component_overload.ins.e = self.interface_component_overload_e

    def interface_component_overload_e (self):
        sys.stderr.write ('interface_component_overload.interface_component_overload_e\n')
        self.reply_interface_component_overload_R = interface.interface_component_overload.R.V
        return self.reply_interface_component_overload_R


