# Dezyne --- Dezyne command line tools
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
import dezyne.IDataparam

import runtime

class proxy:

    def __init__ (self, parent=None, name=''):
        self.parent = parent
        self.name = name
        self.handling = False
        self.deferred = None
        self.queue = []

        self.reply_IDataparam_Status = None

        self.top = dezyne.IDataparam (provides=('top', self))

        self.bottom = dezyne.IDataparam (requires=('bottom', self))

        self.top.ins.e0 = lambda *args: runtime.call_in (self, lambda: self.top_e0 (*args), (self.top, 'e0'))
        self.top.ins.e0r = lambda *args: runtime.call_in (self, lambda: self.top_e0r (*args), (self.top, 'e0r', self.top.Status_to_string))
        self.top.ins.e = lambda *args: runtime.call_in (self, lambda: self.top_e (*args), (self.top, 'e'))
        self.top.ins.er = lambda *args: runtime.call_in (self, lambda: self.top_er (*args), (self.top, 'er', self.top.Status_to_string))
        self.top.ins.eer = lambda *args: runtime.call_in (self, lambda: self.top_eer (*args), (self.top, 'eer', self.top.Status_to_string))
        self.top.ins.eo = lambda *args: runtime.call_in (self, lambda: self.top_eo (*args), (self.top, 'eo'))
        self.top.ins.eoo = lambda *args: runtime.call_in (self, lambda: self.top_eoo (*args), (self.top, 'eoo'))
        self.top.ins.eio = lambda *args: runtime.call_in (self, lambda: self.top_eio (*args), (self.top, 'eio'))
        self.top.ins.eio2 = lambda *args: runtime.call_in (self, lambda: self.top_eio2 (*args), (self.top, 'eio2'))
        self.top.ins.eor = lambda *args: runtime.call_in (self, lambda: self.top_eor (*args), (self.top, 'eor', self.top.Status_to_string))
        self.top.ins.eoor = lambda *args: runtime.call_in (self, lambda: self.top_eoor (*args), (self.top, 'eoor', self.top.Status_to_string))
        self.top.ins.eior = lambda *args: runtime.call_in (self, lambda: self.top_eior (*args), (self.top, 'eior', self.top.Status_to_string))
        self.top.ins.eio2r = lambda *args: runtime.call_in (self, lambda: self.top_eio2r (*args), (self.top, 'eio2r', self.top.Status_to_string))
        self.bottom.outs.a0 = lambda *args: runtime.call_out (self, lambda: self.bottom_a0 (*args), (self.bottom, 'a0'))
        self.bottom.outs.a = lambda *args: runtime.call_out (self, lambda: self.bottom_a (*args), (self.bottom, 'a'))
        self.bottom.outs.aa = lambda *args: runtime.call_out (self, lambda: self.bottom_aa (*args), (self.bottom, 'aa'))
        self.bottom.outs.a6 = lambda *args: runtime.call_out (self, lambda: self.bottom_a6 (*args), (self.bottom, 'a6'))

    def top_e0 (self):
        self.bottom.ins.e0 ()


    def top_e0r (self):
        r = {'value': self.bottom.ins.e0r ()}
        self.reply_IDataparam_Status = r['value']
        return self.reply_IDataparam_Status

    def top_e (self,pi):
        self.bottom.ins.e (pi)


    def top_er (self,pi):
        r = {'value': self.bottom.ins.er (pi)}
        self.reply_IDataparam_Status = r['value']
        return self.reply_IDataparam_Status

    def top_eer (self,i,j):
        r = {'value': self.bottom.ins.eer (i, j)}
        self.reply_IDataparam_Status = r['value']
        return self.reply_IDataparam_Status

    def top_eo (self,i):
        self.outfunc (i)


    def top_eoo (self,i,j):
        self.bottom.ins.eoo (i, j)


    def top_eio (self,i,j):
        self.bottom.ins.eio (i, j)


    def top_eio2 (self,i):
        self.bottom.ins.eio2 (i)


    def top_eor (self,i):
        s = {'value': self.bottom.ins.eor (i)}
        self.reply_IDataparam_Status = s['value']
        return self.reply_IDataparam_Status

    def top_eoor (self,i,j):
        s = {'value': self.bottom.ins.eoor (i, j)}
        self.reply_IDataparam_Status = s['value']
        return self.reply_IDataparam_Status

    def top_eior (self,i,j):
        s = {'value': self.bottom.ins.eior (i, j)}
        self.reply_IDataparam_Status = s['value']
        return self.reply_IDataparam_Status

    def top_eio2r (self,i):
        s = {'value': self.bottom.ins.eio2r (i)}
        self.reply_IDataparam_Status = s['value']
        return self.reply_IDataparam_Status

    def bottom_a0 (self):
        self.top.outs.a0 ()


    def bottom_a (self,i):
        self.deferfunc (i)


    def bottom_aa (self,i,j):
        self.top.outs.aa (i, j)


    def bottom_a6 (self,A0,A1,A2,A3,A4,A5):
        self.top.outs.a6 (A0, A1, A2, A3, A4, A5)


    def outfunc (self,i):
        j = {'value': i['value']}
        self.bottom.ins.eo (j)
        i['value'] = j['value']

    def deferfunc (self,i):
        self.top.outs.a (i)


