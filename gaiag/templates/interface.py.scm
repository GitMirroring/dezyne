class #.interface  ():#
(->string (map declare-enum (gom:interface-enums model)))
    def __init__ (self):
        class Ins ():
#(map
     (lambda (event)
       (let* ((name (.name event)))
         (->string (list "            " name " = None\n"))))
     (filter gom:in? ((compose .elements .events) model)))
        self.ins = Ins ()
        class Outs ():
#(map
     (lambda (event)
       (let* ((name (.name event)))
         (->string (list "           " name " = None\n"))))
     (filter gom:out? ((compose .elements .events) model)))
        self.outs = Outs ()
