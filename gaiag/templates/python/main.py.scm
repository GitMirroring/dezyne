##! /usr/bin/python

import sys
import os
sys.path.insert (0, os.path.dirname (sys.argv[0]))
##
import dezyne.#.model
import runtime

def drop_prefix (string, prefix):
    if string.startswith (prefix):
        return string[len(prefix):]
    return string

def log_void (prefix, event):
    sys.stderr.write (prefix + event + '\n')
    sys.stderr.write (prefix + 'return' + '\n')    

def get_value (string_to_value):
    while True:
        s = sys.stdin.readline ().strip ()
        if not s:
            return 0
        r = string_to_value (s)
        if (r != None):
            return r

def log_valued (prefix, event, string_to_value, value_to_string):
    sys.stderr.write (prefix + event + '\n')
    r = get_value (string_to_value)
    if (r != None):
        sys.stderr.write (prefix + value_to_string[r] + '\n')
        return r
    return 0

def #.model _fill_event_map (m):
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction port.#event  = lambda *args: #(string-if (eq? return-type 'void) #{log_void ('#port .#direction .', '#event ')#}#{log_valued ('#port .#direction .', '#event ', lambda s: dezyne.#interface .#reply-name .__dict__.get (drop_prefix(s, '#port .#reply-name _'), None), dezyne.#interface .#reply-name _to_string)#})
#}) (filter (negate (gom:dir-matches? port))
       (gom:events port)))) (gom:ports model))     return {
#(map
    (lambda (port)
    (map (define-on model port #{
        '#port .#event ': m.#port .#direction port.#event ,
#}) (filter (gom:dir-matches? port)
       (gom:events port)))) (gom:ports model))     }

def main ():
    def illegal ():
        sys.stderr.write('illegal')
        sys.exit (0)
    rt = runtime.Runtime (illegal)
    sut = dezyne.#.model  (rt, name='sut')

    event_map = #.model _fill_event_map (sut)

    event = sys.stdin.readline ().strip ()
    while event:
        if event in event_map.keys ():
            event_map[event] ()
        event = sys.stdin.readline ().strip ()

if __name__ == '__main__':
    main ()
