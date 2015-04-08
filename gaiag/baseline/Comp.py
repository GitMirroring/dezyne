# Dezyne --- Dezyne command line tools
#
# Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
import dezyne.IComp
import dezyne.IDevice

import runtime

class Comp:
    class State ():
        Uninitialized, Initialized, Error = range (3)

    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
        self.handling = False
        self.flushes = True
        self.deferred = None
        self.queue = []

        self.s = self.State.Uninitialized
        self.reply_IComp_result_t = None
        self.reply_IDevice_result_t = None
        self.client = dezyne.IComp (provides=('client', self))
        self.device_A = dezyne.IDevice (requires=('device_A', self))

        self.client.ins.initialize = lambda *args: runtime.call_in (self, lambda: self.client_initialize (*args), (self.client, 'initialize', self.client.result_t_to_string))
        self.client.ins.recover = lambda *args: runtime.call_in (self, lambda: self.client_recover (*args), (self.client, 'recover', self.client.result_t_to_string))
        self.client.ins.perform_actions = lambda *args: runtime.call_in (self, lambda: self.client_perform_actions (*args), (self.client, 'perform_actions', self.client.result_t_to_string))

    def client_initialize (self):
        if (self.s == self.State.Uninitialized):
            res = {'value': self.device_A.ins.initialize ()}
            if (res['value'] == dezyne.IDevice.result_t.OK):
                res['value'] = self.device_A.ins.calibrate ()
            if (res['value'] == dezyne.IDevice.result_t.OK):
                self.s = self.State.Initialized
                self.reply_IDevice_result_t = dezyne.IDevice.result_t.OK
            else:
                self.s = self.State.Uninitialized
                self.reply_IDevice_result_t = dezyne.IDevice.result_t.NOK
        elif (self.s == self.State.Initialized):
            assert (False)
        elif (self.s == self.State.Error):
            assert (False)
        return self.reply_IComp_result_t

    def client_recover (self):
        if (self.s == self.State.Uninitialized):
            assert (False)
        elif (self.s == self.State.Initialized):
            assert (False)
        elif (self.s == self.State.Error):
            res = {'value': self.device_A.ins.calibrate ()}
            if (res['value'] == dezyne.IDevice.result_t.OK):
                self.s = self.State.Initialized
                self.reply_IDevice_result_t = dezyne.IDevice.result_t.OK
            else:
                self.s = self.State.Error
                self.reply_IDevice_result_t = dezyne.IDevice.result_t.NOK
        return self.reply_IComp_result_t

    def client_perform_actions (self):
        if (self.s == self.State.Uninitialized):
            assert (False)
        elif (self.s == self.State.Initialized):
            res = {'value': self.device_A.ins.perform_action1 ()}
            if (res['value'] == dezyne.IDevice.result_t.OK):
                res['value'] = self.device_A.ins.perform_action2 ()
            if (res['value'] == dezyne.IDevice.result_t.OK):
                self.s = self.State.Initialized
                self.reply_IDevice_result_t = dezyne.IDevice.result_t.OK
            else:
                self.s = self.State.Error
                self.reply_IDevice_result_t = dezyne.IDevice.result_t.NOK
        elif (self.s == self.State.Error):
            assert (False)
        return self.reply_IComp_result_t


