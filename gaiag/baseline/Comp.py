# Dezyne --- Dezyne command line tools
#
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
import interface.IComp
import interface.IDevice


class Comp ():
    class State ():
        Uninitialized, Initialized, Error = range (3)

    def __init__ (self):
        self.s = self.State.Uninitialized
        self.reply_IComp_result_t = None
        self.reply_IDevice_result_t = None

        self.client = interface.IComp ()
        self.device_A = interface.IDevice ()

        self.client.ins.initialize = self.client_initialize
        self.client.ins.recover = self.client_recover
        self.client.ins.perform_actions = self.client_perform_actions

    def client_initialize (self):
        sys.stderr.write ('Comp.client_initialize\n')
        if (self.s == self.State.Uninitialized):
            res = self.device_A.ins.initialize ()
            if (res == interface.IDevice.result_t.OK):
                self.res = self.device_A.ins.calibrate ()
            if (res == interface.IDevice.result_t.OK):
                self.s = self.State.Initialized
                self.reply_IDevice_result_t = interface.IDevice.result_t.OK
            else:
                self.s = self.State.Uninitialized
                self.reply_IDevice_result_t = interface.IDevice.result_t.NOK
        elif (self.s == self.State.Initialized):
            assert (False)
        elif (self.s == self.State.Error):
            assert (False)
        return self.reply_IComp_result_t

    def client_recover (self):
        sys.stderr.write ('Comp.client_recover\n')
        if (self.s == self.State.Uninitialized):
            assert (False)
        elif (self.s == self.State.Initialized):
            assert (False)
        elif (self.s == self.State.Error):
            res = self.device_A.ins.calibrate ()
            if (res == interface.IDevice.result_t.OK):
                self.s = self.State.Initialized
                self.reply_IDevice_result_t = interface.IDevice.result_t.OK
            else:
                self.s = self.State.Error
                self.reply_IDevice_result_t = interface.IDevice.result_t.NOK
        return self.reply_IComp_result_t

    def client_perform_actions (self):
        sys.stderr.write ('Comp.client_perform_actions\n')
        if (self.s == self.State.Uninitialized):
            assert (False)
        elif (self.s == self.State.Initialized):
            res = self.device_A.ins.perform_action1 ()
            if (res == interface.IDevice.result_t.OK):
                self.res = self.device_A.ins.perform_action2 ()
            if (res == interface.IDevice.result_t.OK):
                self.s = self.State.Initialized
                self.reply_IDevice_result_t = interface.IDevice.result_t.OK
            else:
                self.s = self.State.Error
                self.reply_IDevice_result_t = interface.IDevice.result_t.NOK
        elif (self.s == self.State.Error):
            assert (False)
        return self.reply_IComp_result_t


