# Dezyne --- Dezyne command line tools
#
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

import dezyne.IDataparam

import runtime

class Dataparam:

    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
        self.handling = False
        self.flushes = True
        self.deferred = None
        self.queue = []

        self.mi = 0
        self.s = dezyne.IDataparam.Status.Yes
        self.reply_IDataparam_Status = None

        self.port = dezyne.IDataparam (provides=('port', self))


        self.port.ins.e0 = lambda *args: runtime.call_in (self, lambda: self.port_e0 (*args), (self.port, 'e0'))
        self.port.ins.e0r = lambda *args: runtime.call_in (self, lambda: self.port_e0r (*args), (self.port, 'e0r', self.port.Status_to_string))
        self.port.ins.e = lambda *args: runtime.call_in (self, lambda: self.port_e (*args), (self.port, 'e'))
        self.port.ins.er = lambda *args: runtime.call_in (self, lambda: self.port_er (*args), (self.port, 'er', self.port.Status_to_string))
        self.port.ins.eer = lambda *args: runtime.call_in (self, lambda: self.port_eer (*args), (self.port, 'eer', self.port.Status_to_string))
        self.port.ins.eo = lambda *args: runtime.call_in (self, lambda: self.port_eo (*args), (self.port, 'eo'))
        self.port.ins.eoo = lambda *args: runtime.call_in (self, lambda: self.port_eoo (*args), (self.port, 'eoo'))
        self.port.ins.eio = lambda *args: runtime.call_in (self, lambda: self.port_eio (*args), (self.port, 'eio'))
        self.port.ins.eio2 = lambda *args: runtime.call_in (self, lambda: self.port_eio2 (*args), (self.port, 'eio2'))
        self.port.ins.eor = lambda *args: runtime.call_in (self, lambda: self.port_eor (*args), (self.port, 'eor', self.port.Status_to_string))
        self.port.ins.eoor = lambda *args: runtime.call_in (self, lambda: self.port_eoor (*args), (self.port, 'eoor', self.port.Status_to_string))
        self.port.ins.eior = lambda *args: runtime.call_in (self, lambda: self.port_eior (*args), (self.port, 'eior', self.port.Status_to_string))
        self.port.ins.eio2r = lambda *args: runtime.call_in (self, lambda: self.port_eio2r (*args), (self.port, 'eio2r', self.port.Status_to_string))

    def port_e0 (self):
        self.port.outs.a6 (0, 1, 2, 3, 4, 5)


    def port_e0r (self):
        self.port.outs.a0 ()
        self.reply_IDataparam_Status = dezyne.IDataparam.Status.Yes
        return self.reply_IDataparam_Status

    def port_e (self,i):
        pi = {'value': i}
        s = {'value': self.funx (pi['value'])}
        s['value'] = s['value']
        self.mi = pi['value']
        self.mi = self.xfunx (pi['value'], pi['value'])
        self.port.outs.a (self.mi)
        self.port.outs.aa (self.mi, pi['value'])


    def port_er (self,i):
        pi = {'value': i}
        s = {'value': dezyne.IDataparam.Status.No}
        self.mi = pi['value']
        self.port.outs.a (self.mi)
        self.port.outs.aa (self.mi, pi['value'])
        if (True):
            self.reply_IDataparam_Status = dezyne.IDataparam.Status.Yes
        else:
            self.reply_IDataparam_Status = s['value']
        return self.reply_IDataparam_Status

    def port_eer (self,i,j):
        s = {'value': dezyne.IDataparam.Status.No}
        self.port.outs.a (j)
        self.port.outs.aa (j, i)
        self.reply_IDataparam_Status = s['value']
        return self.reply_IDataparam_Status

    def port_eo (self,i):
        i['value'] = 234


    def port_eoo (self,i,j):
        i['value'] = 123
        j['value'] = 456


    def port_eio (self,i,j):
        j['value'] = i


    def port_eio2 (self,i):
        t = {'value': i['value']}
        i['value'] = 123 + 123


    def port_eor (self,i):
        i['value'] = 234
        self.reply_IDataparam_Status = dezyne.IDataparam.Status.Yes
        return self.reply_IDataparam_Status

    def port_eoor (self,i,j):
        i['value'] = 123
        j['value'] = 456
        self.reply_IDataparam_Status = dezyne.IDataparam.Status.Yes
        return self.reply_IDataparam_Status

    def port_eior (self,i,j):
        j['value'] = i
        self.reply_IDataparam_Status = dezyne.IDataparam.Status.Yes
        return self.reply_IDataparam_Status

    def port_eio2r (self,i):
        t = {'value': i['value']}
        i['value'] = 123 + 123
        self.reply_IDataparam_Status = dezyne.IDataparam.Status.Yes
        return self.reply_IDataparam_Status

    def fun (self):
        return dezyne.IDataparam.Status.Yes

    def funx (self,xi):
        xi = xi
        return dezyne.IDataparam.Status.Yes

    def xfunx (self,xi, xj):
        return (xi + xj) / 2


