# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
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

class V:
    def __init__ (self, v):
        self.v = v

def illegal ():
    raise RuntimeError ('illegal')

class Runtime:
    def __init__ (self, illegal=illegal):
        self.components = []
        self.illegal = illegal
        self.info = {}
    def flushes (self, c):
        self.components += [c]
        self.info[c] = self.info.get (c, Info ())
        self.info[c].flushes = True
    def external_p (self, c):
        return c not in self.components
    def flush (self, c):
        if (self.external_p (c)):
            return
        while (self.info[c].q):
            self.handle (c, self.info[c].q.pop ())
        if (self.info[c].deferred):
            t = self.info[c].deferred
            self.info[c].deferred = None;
            if (not self.info[t].handling):
                self.flush (t)
    def defer (self, i, o, f):
        if (not i or (not self.info[i].flushes and not self.info[o].handling)):
            self.handle (o, f)
        else:
            self.info[i].deferred = o
            self.info[o].q.insert (0, f)
    def valued_helper (self, c, f, m):
        handle = self.info[c].handling
        self.info[c].handling = True
        r = f ()
        if (handle and r != None):
            throw ('a valued event cannot be deferred')
        self.info[c].handling = False
        self.flush (c)
        return r
    def handle (self, c, f):
        if (not self.info[c].handling):
            self.info[c].handling = True
            f ()
            self.info[c].handling = False
            self.flush (c)
        else:
            throw ('component already handling an event')

class Port:
    def __init__ (self, name='', component=None):
        self.name = name
        self.component = component

class Component:
    def __init__ (self, loc, name='', parent=None):
        self.loc = loc
        self.rt = loc.get (Runtime)
        self.name = name
        self.parent = parent

class Info:
    def __init__ (self):
        self.handling = False
        self.deferred = None
        self.flushes = False
        self.q = []

def call_in (c, f, m):
    trace_in (m[0], m[1])
    r = c.rt.valued_helper (c, f, m)
    trace_out (m[0], 'return' if r == None else m[2][r])
    return r

def call_out (c, f, m):
    trace_out (m[0], m[1])
    c.rt.defer (m[0].inport.component, c, f)

def path (m, p=''):
    if (not m):
        return '<external>.' + p;
    if ('component' in m.__dict__.keys ()):
        return path (m.component, m.name + ('.' + p if p else p))
    if ('parent' in m.__dict__.keys () and m.parent):
        return path (m.parent, m.name + ('.' + p if p else p))
    return m.name + ('.' + p if p else p)

def trace_in (i, e):
    sys.stderr.write (path (i.outport) + '.' + e + ' -> '
                      + path (i.inport) + '.' + e + '\n')

def trace_out (i, e):
    sys.stderr.write (path(i.inport) + '.' + e + ' -> '
                      + path(i.outport) + '.' + e + '\n')
