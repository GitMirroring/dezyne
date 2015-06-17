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

#! /usr/bin/python

import sys
import os
sys.path.insert (0, os.path.dirname (sys.argv[0]))
#

def config_get (x):
    return 0

config = {'get': config_get}
              
try:
     builtins = sys.modules['__builtin__'].__dict__
except KeyError:
    builtins = sys.modules['builtins'].__dict__
builtins['config'] = config

import dezyne.LegoBallSorter
import locator
import runtime

relaxed = True;

def drop_prefix (string, prefix):
    if string.startswith (prefix):
        return string[len(prefix):]
    return string

def consume_synchronous_out_events (event_map):
    sys.stdin.readline ()
    event = sys.stdin.readline ().strip ()
    while event:
        if event not in event_map.keys ():
            break
        event_map[event] ()
        event = sys.stdin.readline ().strip ()
    return event

def log_in (prefix, event, event_map):
    sys.stderr.write (prefix + event + '\n')
    if relaxed: return
    consume_synchronous_out_events (event_map)
    sys.stderr.write (prefix + 'return' + '\n')

def log_out (prefix, event, event_map):
    sys.stderr.write (prefix + event + '\n')

def log_valued (prefix, event, event_map, string_to_value, value_to_string):
    sys.stderr.write (prefix + event + '\n')
    if relaxed: return 0
    s = consume_synchronous_out_events (event_map)
    r = string_to_value(s)
    if (r != None):
        sys.stderr.write (prefix + value_to_string[r] + '\n')
        return r
    raise Exception ('"%s" is not a reply value' % s)

def LegoBallSorter_fill_event_map (m):
    e = {
        'ctrl.calibrate': m.ctrl.inport.calibrate,
        'ctrl.stop': m.ctrl.inport.stop,
        'ctrl.operate': m.ctrl.inport.operate,
    }
    m.ctrl.outport.calibrated = lambda *args: log_out('ctrl.', 'calibrated', e)
    m.ctrl.outport.finished = lambda *args: log_out('ctrl.', 'finished', e)
    m.brick1_aA.inport.move = lambda *args: log_in('brick1_aA.', 'move', e)
    m.brick1_aA.inport.run = lambda *args: log_in('brick1_aA.', 'run', e)
    m.brick1_aA.inport.stop = lambda *args: log_in('brick1_aA.', 'stop', e)
    m.brick1_aA.inport.coast = lambda *args: log_in('brick1_aA.', 'coast', e)
    m.brick1_aA.inport.zero = lambda *args: log_in('brick1_aA.', 'zero', e)
    m.brick1_aA.inport.position = lambda *args: log_in('brick1_aA.', 'position', e)
    m.brick1_aA.inport.at = lambda *args: log_valued ('brick1_aA.', 'at', e, lambda s: dezyne.imotor.result_t.__dict__.get (drop_prefix(s, 'brick1_aA.result_t_'), None), dezyne.imotor.result_t_to_string)
    m.brick1_aB.inport.move = lambda *args: log_in('brick1_aB.', 'move', e)
    m.brick1_aB.inport.run = lambda *args: log_in('brick1_aB.', 'run', e)
    m.brick1_aB.inport.stop = lambda *args: log_in('brick1_aB.', 'stop', e)
    m.brick1_aB.inport.coast = lambda *args: log_in('brick1_aB.', 'coast', e)
    m.brick1_aB.inport.zero = lambda *args: log_in('brick1_aB.', 'zero', e)
    m.brick1_aB.inport.position = lambda *args: log_in('brick1_aB.', 'position', e)
    m.brick1_aB.inport.at = lambda *args: log_valued ('brick1_aB.', 'at', e, lambda s: dezyne.imotor.result_t.__dict__.get (drop_prefix(s, 'brick1_aB.result_t_'), None), dezyne.imotor.result_t_to_string)
    m.brick1_aC.inport.move = lambda *args: log_in('brick1_aC.', 'move', e)
    m.brick1_aC.inport.run = lambda *args: log_in('brick1_aC.', 'run', e)
    m.brick1_aC.inport.stop = lambda *args: log_in('brick1_aC.', 'stop', e)
    m.brick1_aC.inport.coast = lambda *args: log_in('brick1_aC.', 'coast', e)
    m.brick1_aC.inport.zero = lambda *args: log_in('brick1_aC.', 'zero', e)
    m.brick1_aC.inport.position = lambda *args: log_in('brick1_aC.', 'position', e)
    m.brick1_aC.inport.at = lambda *args: log_valued ('brick1_aC.', 'at', e, lambda s: dezyne.imotor.result_t.__dict__.get (drop_prefix(s, 'brick1_aC.result_t_'), None), dezyne.imotor.result_t_to_string)
    m.brick1_s1.inport.detect = lambda *args: log_valued ('brick1_s1.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick1_s1.status_'), None), dezyne.itouch.status_to_string)
    m.brick1_s2.inport.detect = lambda *args: log_valued ('brick1_s2.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick1_s2.status_'), None), dezyne.itouch.status_to_string)
    m.brick1_s3.inport.detect = lambda *args: log_valued ('brick1_s3.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick1_s3.status_'), None), dezyne.itouch.status_to_string)
    m.brick1_s4.inport.detect = lambda *args: log_valued ('brick1_s4.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick1_s4.status_'), None), dezyne.itouch.status_to_string)
    m.brick2_aA.inport.move = lambda *args: log_in('brick2_aA.', 'move', e)
    m.brick2_aA.inport.run = lambda *args: log_in('brick2_aA.', 'run', e)
    m.brick2_aA.inport.stop = lambda *args: log_in('brick2_aA.', 'stop', e)
    m.brick2_aA.inport.coast = lambda *args: log_in('brick2_aA.', 'coast', e)
    m.brick2_aA.inport.zero = lambda *args: log_in('brick2_aA.', 'zero', e)
    m.brick2_aA.inport.position = lambda *args: log_in('brick2_aA.', 'position', e)
    m.brick2_aA.inport.at = lambda *args: log_valued ('brick2_aA.', 'at', e, lambda s: dezyne.imotor.result_t.__dict__.get (drop_prefix(s, 'brick2_aA.result_t_'), None), dezyne.imotor.result_t_to_string)
    m.brick2_aB.inport.move = lambda *args: log_in('brick2_aB.', 'move', e)
    m.brick2_aB.inport.run = lambda *args: log_in('brick2_aB.', 'run', e)
    m.brick2_aB.inport.stop = lambda *args: log_in('brick2_aB.', 'stop', e)
    m.brick2_aB.inport.coast = lambda *args: log_in('brick2_aB.', 'coast', e)
    m.brick2_aB.inport.zero = lambda *args: log_in('brick2_aB.', 'zero', e)
    m.brick2_aB.inport.position = lambda *args: log_in('brick2_aB.', 'position', e)
    m.brick2_aB.inport.at = lambda *args: log_valued ('brick2_aB.', 'at', e, lambda s: dezyne.imotor.result_t.__dict__.get (drop_prefix(s, 'brick2_aB.result_t_'), None), dezyne.imotor.result_t_to_string)
    m.brick2_s2.inport.detect = lambda *args: log_valued ('brick2_s2.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick2_s2.status_'), None), dezyne.itouch.status_to_string)
    m.brick2_s3.inport.detect = lambda *args: log_valued ('brick2_s3.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick2_s3.status_'), None), dezyne.itouch.status_to_string)
    m.brick2_s4.inport.detect = lambda *args: log_valued ('brick2_s4.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick2_s4.status_'), None), dezyne.itouch.status_to_string)
    m.brick3_aA.inport.move = lambda *args: log_in('brick3_aA.', 'move', e)
    m.brick3_aA.inport.run = lambda *args: log_in('brick3_aA.', 'run', e)
    m.brick3_aA.inport.stop = lambda *args: log_in('brick3_aA.', 'stop', e)
    m.brick3_aA.inport.coast = lambda *args: log_in('brick3_aA.', 'coast', e)
    m.brick3_aA.inport.zero = lambda *args: log_in('brick3_aA.', 'zero', e)
    m.brick3_aA.inport.position = lambda *args: log_in('brick3_aA.', 'position', e)
    m.brick3_aA.inport.at = lambda *args: log_valued ('brick3_aA.', 'at', e, lambda s: dezyne.imotor.result_t.__dict__.get (drop_prefix(s, 'brick3_aA.result_t_'), None), dezyne.imotor.result_t_to_string)
    m.brick3_aC.inport.move = lambda *args: log_in('brick3_aC.', 'move', e)
    m.brick3_aC.inport.run = lambda *args: log_in('brick3_aC.', 'run', e)
    m.brick3_aC.inport.stop = lambda *args: log_in('brick3_aC.', 'stop', e)
    m.brick3_aC.inport.coast = lambda *args: log_in('brick3_aC.', 'coast', e)
    m.brick3_aC.inport.zero = lambda *args: log_in('brick3_aC.', 'zero', e)
    m.brick3_aC.inport.position = lambda *args: log_in('brick3_aC.', 'position', e)
    m.brick3_aC.inport.at = lambda *args: log_valued ('brick3_aC.', 'at', e, lambda s: dezyne.imotor.result_t.__dict__.get (drop_prefix(s, 'brick3_aC.result_t_'), None), dezyne.imotor.result_t_to_string)
    m.brick3_s1.inport.turnon = lambda *args: log_in('brick3_s1.', 'turnon', e)
    m.brick3_s1.inport.turnoff = lambda *args: log_in('brick3_s1.', 'turnoff', e)
    m.brick3_s1.inport.detect = lambda *args: log_valued ('brick3_s1.', 'detect', e, lambda s: dezyne.ilight.status.__dict__.get (drop_prefix(s, 'brick3_s1.status_'), None), dezyne.ilight.status_to_string)
    m.brick3_s2.inport.detect = lambda *args: log_valued ('brick3_s2.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick3_s2.status_'), None), dezyne.itouch.status_to_string)
    m.brick3_s3.inport.detect = lambda *args: log_valued ('brick3_s3.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick3_s3.status_'), None), dezyne.itouch.status_to_string)
    m.brick4_aA.inport.move = lambda *args: log_in('brick4_aA.', 'move', e)
    m.brick4_aA.inport.run = lambda *args: log_in('brick4_aA.', 'run', e)
    m.brick4_aA.inport.stop = lambda *args: log_in('brick4_aA.', 'stop', e)
    m.brick4_aA.inport.coast = lambda *args: log_in('brick4_aA.', 'coast', e)
    m.brick4_aA.inport.zero = lambda *args: log_in('brick4_aA.', 'zero', e)
    m.brick4_aA.inport.position = lambda *args: log_in('brick4_aA.', 'position', e)
    m.brick4_aA.inport.at = lambda *args: log_valued ('brick4_aA.', 'at', e, lambda s: dezyne.imotor.result_t.__dict__.get (drop_prefix(s, 'brick4_aA.result_t_'), None), dezyne.imotor.result_t_to_string)
    m.brick4_aB.inport.move = lambda *args: log_in('brick4_aB.', 'move', e)
    m.brick4_aB.inport.run = lambda *args: log_in('brick4_aB.', 'run', e)
    m.brick4_aB.inport.stop = lambda *args: log_in('brick4_aB.', 'stop', e)
    m.brick4_aB.inport.coast = lambda *args: log_in('brick4_aB.', 'coast', e)
    m.brick4_aB.inport.zero = lambda *args: log_in('brick4_aB.', 'zero', e)
    m.brick4_aB.inport.position = lambda *args: log_in('brick4_aB.', 'position', e)
    m.brick4_aB.inport.at = lambda *args: log_valued ('brick4_aB.', 'at', e, lambda s: dezyne.imotor.result_t.__dict__.get (drop_prefix(s, 'brick4_aB.result_t_'), None), dezyne.imotor.result_t_to_string)
    m.brick4_aC.inport.move = lambda *args: log_in('brick4_aC.', 'move', e)
    m.brick4_aC.inport.run = lambda *args: log_in('brick4_aC.', 'run', e)
    m.brick4_aC.inport.stop = lambda *args: log_in('brick4_aC.', 'stop', e)
    m.brick4_aC.inport.coast = lambda *args: log_in('brick4_aC.', 'coast', e)
    m.brick4_aC.inport.zero = lambda *args: log_in('brick4_aC.', 'zero', e)
    m.brick4_aC.inport.position = lambda *args: log_in('brick4_aC.', 'position', e)
    m.brick4_aC.inport.at = lambda *args: log_valued ('brick4_aC.', 'at', e, lambda s: dezyne.imotor.result_t.__dict__.get (drop_prefix(s, 'brick4_aC.result_t_'), None), dezyne.imotor.result_t_to_string)
    m.brick4_s1.inport.detect = lambda *args: log_valued ('brick4_s1.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick4_s1.status_'), None), dezyne.itouch.status_to_string)
    m.brick4_s2.inport.detect = lambda *args: log_valued ('brick4_s2.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick4_s2.status_'), None), dezyne.itouch.status_to_string)
    m.brick4_s3.inport.detect = lambda *args: log_valued ('brick4_s3.', 'detect', e, lambda s: dezyne.itouch.status.__dict__.get (drop_prefix(s, 'brick4_s3.status_'), None), dezyne.itouch.status_to_string)
    return e

def main ():
    def illegal ():
        sys.stderr.write('illegal')
        sys.exit (0)
    loc = locator.Locator ()
    rt = runtime.Runtime (illegal)
    sut = dezyne.LegoBallSorter (loc.set (rt), name='sut')

    event_map = LegoBallSorter_fill_event_map (sut)

    event = sys.stdin.readline ().strip ()
    while event:
        if event in event_map.keys ():
            event_map[event] ()
        event = sys.stdin.readline ().strip ()

if __name__ == '__main__':
    main ()
