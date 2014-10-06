##include "component-#.model -c3.hh"

template<typename Port>
void connect(Port& provided, Port& required)
{
  provided.out = required.out;
  required.in = provided.in;
}

namespace component
{
#.model ::#.model ()
: #((->join  "\n, ")
    (map
     (lambda (instance)
      (let ((name (.name instance)))
        (->string (list name "()"))))
     ((compose .elements .instances) model)))
, #((->join  "\n, ")
    (map
     (lambda (bind)
       (let* ((left (.left bind))
              (left-port (gom:port model left))
              (right (.right bind))
              (port (and (bind-port? bind)
                         (if (not (.instance left)) (.port left) (.port right))))
              (instance (and (bind-port? bind)
                             (if (not (.instance left))
                                 (binding-name model right)
                                 (binding-name model left)))))
         (->string (list port "("instance ")"))))
     (filter bind-port? ((compose .elements .bindings) model))))
{
 # (map
    (lambda (bind)
      (let* ((left (.left bind))
             (left-port (gom:port model left))
             (right (.right bind))
             (provided-required (if (gom:provides? left-port)
                                    (cons left right)
                                    (cons right left)))
             (provided (binding-name model (car provided-required)))
             (required (binding-name model (cdr provided-required))))
        (->string (list "connect("provided "," required ");\n"))))
    (filter (negate bind-port?) ((compose .elements .bindings) model))) }
}
