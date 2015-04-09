##! /usr/bin/python

import sys
import os
sys.path.insert (0, os.path.dirname (sys.argv[0]))
##
import dezyne.#.model
import runtime

#(map
  (lambda (model)
  (append
   `("def " ,(.name model) "_fill_event_map (m, e):\n")
   (if (is-a? model <component>)
      (map
       (lambda (port)
       (map (define-on model port #{
    if (not m.#port .#direction s.#event):
        m.#port .#direction s.#event  = lambda *args: sys.stderr.write ('#port .#event \n')
    if ('#port .#event ' not in e.keys ()):
        e['#port .#event '] = m.#port .#direction s.#event
#}) (gom:events port))) (delete-duplicates (gom:ports model)))
    '("    pass"))
    '("\n")))
  (if (is-a? model <component>) (list model) (delete-duplicates (map (lambda (i) (gom:import (.component i))) (.elements (.instances model))))))
def main ():
    rt = runtime.runtime ()
    event_map = {}
    sut = dezyne.#.model  (rt, name='sut')

#(string-if (is-a? model <component>)
#{
    #.model _fill_event_map (sut, event_map)#}
 (->string
 (map
 (lambda (i)
 `("    " ,(.component i) "_fill_event_map (sut." ,(.name i) ", event_map)\n")) (.elements (.instances model)))))
    event = sys.stdin.readline ().strip ()
    while event:
        if event in event_map.keys ():
            event_map[event] ()
        event = sys.stdin.readline ().strip ()

if __name__ == '__main__':
    main ()
