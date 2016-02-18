##! /usr/bin/python

import sys
import os
sys.path.insert (0, os.path.dirname (sys.argv[0]))
##
import dzn.#.scope_model
import locator
import runtime

relaxed = False;

def drop_prefix (string, prefix):
    if string.startswith (prefix):
        return string[len(prefix):]
    return string

def consume_synchronous_out_events (prefix, event, event_map):
    s = sys.stdin.readline ().strip ()
    while s:
        if s == prefix + event:
            break
        s = sys.stdin.readline ().strip ()
    s = sys.stdin.readline ().strip ()
    while s:
        if s not in event_map.keys ():
            break
        event_map[s] ()
        s = sys.stdin.readline ().strip ()
    return s

def log_in (prefix, event, event_map):
    sys.stderr.write (prefix + event + '\n')
    if relaxed: return
    consume_synchronous_out_events (prefix, event, event_map)
    sys.stderr.write (prefix + 'return' + '\n')

def log_out (prefix, event, event_map):
    sys.stderr.write (prefix + event + '\n')

def log_valued (prefix, event, event_map, string_to_value, value_to_string):
    sys.stderr.write (prefix + event + '\n')
    if relaxed: return 0
    s = consume_synchronous_out_events (prefix, event, event_map)
    r = string_to_value(s)
    if (r != None):
        sys.stderr.write (prefix + value_to_string[r] + '\n')
        return r
    raise Exception ('"%s" is not a reply value' % s)

def #.scope_model _fill_event_map (m):
    c = runtime.Component (m.loc)
    m.loc.get (runtime.Runtime).flushes (c)
    e = {
#(map
    (lambda (port)
    (map (define-on model port #{
        '#port .#event ': m.#port .#direction port.#event ,
#}) (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model))     }
#(map (init-port #{
    m.#name .inport.component = c
    m.#name .inport.name = '<internal>'
    def log_flush ():
           sys.stderr.write ('#name .<flush>\n')
           m.rt.flush (m.#name .inport.component)
    e['#name .<flush>'] = log_flush
#}) (filter om:requires? (om:ports model)))
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction port.#event  = lambda *args: #(string-if (eq? return-type 'void) #{log_#direction ('#port .', '#event ', e)#}#{log_valued ('#port .', '#event ', e, lambda s: dzn.#((om:scope-name) interface) .#reply-name .__dict__.get (drop_prefix(s, '#port .#reply-name _'), None), dzn.#((om:scope-name) interface) .#reply-name _to_string)#})
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))     return e

def main ():
    def illegal ():
        sys.stderr.write('illegal')
        sys.exit (0)
    loc = locator.Locator ()
    rt = runtime.Runtime (illegal)
    sut = dzn.#.scope_model  (loc.set (rt), name='sut')

    event_map = #.scope_model _fill_event_map (sut)

    s = sys.stdin.readline ().strip ()
    while s:
        if s in event_map.keys ():
            event_map[s] ()
        s = sys.stdin.readline ().strip ()

if __name__ == '__main__':
    main ()
