##! /usr/bin/python

import sys
import os
sys.path.insert (0, os.path.dirname (sys.argv[0]))
##
import dezyne.#.model
import runtime

def #.model _fill_event_map (m, e):
#(map
    (lambda (port)
    (map (define-on model port #{
    m.#port .#direction s.#event  = lambda *args: sys.stderr.write ('#port .#direction .#event \n')
#}) (filter (negate (gom:dir-matches? port))
       (gom:events port)))) (gom:ports model))#
(map
    (lambda (port)
    (map (define-on model port #{
    e['#port .#event '] = m.#port .#direction s.#event
#}) (filter (gom:dir-matches? port)
       (gom:events port)))) (gom:ports model))
def main ():
    rt = runtime.runtime ()
    event_map = {}
    sut = dezyne.#.model  (rt, name='sut')

    #.model _fill_event_map (sut, event_map)

    event = sys.stdin.readline ().strip ()
    while event:
        if event in event_map.keys ():
            event_map[event] ()
        event = sys.stdin.readline ().strip ()

if __name__ == '__main__':
    main ()
