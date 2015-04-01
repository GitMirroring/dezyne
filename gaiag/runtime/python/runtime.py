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

import sys

def external (c):
    return False

def flush (c):
    if (external (c)):
        return
    while (c.queue):
        handle (c, c.queue.pop ())
    if (c.deferred):
        t = c.deferred
        c.deferred = None;
        if (not t.handling):
            flush (t)

def defer (i, o, f):
    if (not i.flushes and not o.handling):
        handle (o, f)
    else:
        i.deferred = o
        o.queue.insert (0, f)

def handle (c, f):
    if (not c.handling):
        c.handling = True
        f ()
        c.handling = False
        flush (c)
    else:
        throw ('component already handling an event')

def call_in (c, f, m):
    trace_in (m[0], m[1])
    handle = c.handling
    c.handling = True
    r = f ()
    if (handle):
        throw ('a valued event cannot be deferred')
    c.handling = False
    flush (c)
    trace_out (m[0], 'return' if r == None else m[2][r])
    return r

def call_out (c, f, m):
    trace_out (m[0], m[1])
    defer (m[0].ins.self, c, f)

def path (m, p=''):
    if (not m):
        return 'null.' + p;
    if (m.__dict__.has_key ('self')):
        return path (m.self, m.name + ('.' + p if p else p))
    if (m.__dict__.has_key ('parent') and m.parent):
        return path (m.parent, m.name + ('.' + p if p else p))
    return m.name + ('.' + p if p else p)

def trace_in (i, e):
    sys.stderr.write (path (i.outs) + '.' + e + ' -> '
                      + path (i.ins) + '.' + e + '\n')

def trace_out (i, e):
    sys.stderr.write (path(i.ins) + '.' + e + ' -> '
                      + path(i.outs) + '.' + e + '\n')

