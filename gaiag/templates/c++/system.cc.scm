##include "#.model .hh"

namespace dezyne
{
#.model ::#.model (const dezyne::locator& dezyne_locator)
: #((->join "\n, ")
    (append
            (list
             (->string
              (list
               "meta{\"\",reinterpret_cast<component*>(this),0,{"
               ((->join ",")
                (map (init-instance #{reinterpret_cast<component*>(&#name)#})
                     (non-injected-instances model)))
               "}}")))
            (map (lambda (binding) (list (injected-instance-name binding) "(dezyne_locator)"))
                 (injected-bindings model))
            (list (if (pair? (injected-bindings model))
                      (list "dezyne_local_locator(dezyne_locator.clone()" (map (lambda (binding) (list ".set(" (binding-name model (injected-binding binding)) ")"))  (injected-bindings model)) ")")))
            (map (init-instance #{ #name (#(if (pair? (injected-bindings model)) "dezyne_local_locator" "dezyne_locator"))#})
                 (non-injected-instances model))
            (map (init-bind model #{ #port(#instance)#})
                 (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))))
{
 #(map (init-instance #{#name .meta.parent = reinterpret_cast<component*>(this);
    #name .meta.address = reinterpret_cast<component*>(&#name );
    #name .meta.name = "#name ";
#})
       (non-injected-instances model))#
 (map (connect-ports model #{
    connect(#provided , #required );
#}) (filter (negate bind-port?) ((compose .elements .bindings) model))) }
}
