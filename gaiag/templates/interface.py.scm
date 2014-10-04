try:
    from enum import Enum
except:
    class Enum (): pass
##

class #.interface  ():
#(->string (map declare-enum (gom:interface-enums model)))
    def __init__ (self):
        class Ins ():
#((->join "\n") (map
      (lambda (event)
        (let* ((name (.name event)))
          (->string (list "            " name " = None"))))
      (filter gom:in? ((compose .elements .events) model))))#
(if (null? (filter gom:in? ((compose .elements .events) model)))
    "            pass")
        self.ins = Ins ()
        class Outs ():
#((->join "\n") (map
      (lambda (event)
        (let* ((name (.name event)))
          (->string (list "            " name " = None"))))
      (filter gom:out? ((compose .elements .events) model))))#
(if (null? (filter gom:out? ((compose .elements .events) model)))
    "            pass")
        self.outs = Outs ()
