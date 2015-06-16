##! /usr/bin/python

import sys
import os
sys.path.insert (0, os.path.dirname (sys.argv[0]))
##
import dezyne.#.model
import locator
import runtime

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
    consume_synchronous_out_events (event_map)
    sys.stderr.write (prefix + 'return' + '\n')

def log_out (prefix, event, event_map):
    sys.stderr.write (prefix + event + '\n')

def log_valued (prefix, event, event_map, string_to_value, value_to_string):
    sys.stderr.write (prefix + event + '\n')
    s = consume_synchronous_out_events (event_map)
    r = string_to_value(s)
    if (r != None):
        sys.stderr.write (prefix + value_to_string[r] + '\n')
        return r
    raise Exception ('"%s" is not a reply value' % s)

def #.model _fill_event_map (m):
    e = {
#(map
    (lambda (port)
    (map (define-on model port #{
        '#port .#event ': m.#port .#direction port.#event ,
#}) (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model))     }
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction port.#event  = lambda *args: #(string-if (eq? return-type 'void) #{log_#direction ('#port .', '#event ', e)#}#{log_valued ('#port .', '#event ', e, lambda s: dezyne.#interface .#reply-name .__dict__.get (drop_prefix(s, '#port .#reply-name _'), None), dezyne.#interface .#reply-name _to_string)#})
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))     return e
    return e

def main ():
    def illegal ():
        sys.stderr.write('illegal')
        sys.exit (0)
    loc = locator.Locator ()
    rt = runtime.Runtime (illegal)
    sut = dezyne.#.model  (loc.set (rt), name='sut')

    event_map = #.model _fill_event_map (sut)

    event = sys.stdin.readline ().strip ()
    while event:
        if event in event_map.keys ():
            event_map[event] ()
        event = sys.stdin.readline ().strip ()

if __name__ == '__main__':
    main ()
