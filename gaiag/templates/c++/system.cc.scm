##include "#.scope_model .hh"

##include "runtime.hh"

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
#.model ::#.model (const dezyne::locator& dezyne_locator)
: #((->join "\n, ")
    (append
            (list
             (->string
              (list
               "dzn_meta" (c++:init-brace-open) "\"\",\"" .model "\",0,{"
               ((->join ",")
                (map (init-instance #{&#name .dzn_meta#})
                     (non-injected-instances model)))
               "},{}" (c++:init-brace-close)))
             "dzn_rt(dezyne_locator.get<dezyne::runtime>())")
            (map (lambda (binding) (list (injected-instance-name binding) "(dezyne_locator)"))
                 (injected-bindings model))
            (list (if (pair? (injected-bindings model))
                      (list "dezyne_local_locator(dezyne_locator.clone()" (map (lambda (binding) (list ".set(" (binding-name model (injected-binding binding)) ")"))  (injected-bindings model)) ")")))
            (map (init-instance #{ #name (#(if (pair? (injected-bindings model)) "dezyne_local_locator" "dezyne_locator"))#})
                 (non-injected-instances model))
            (map (init-bind model #{ #port(#instance)#})
                 (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))))
{
 #(map (init-instance #{#name .dzn_meta.parent = &dzn_meta;
    #name .dzn_meta.name = "#name ";
#})
       (non-injected-instances model))#
 (map (connect-ports model #{
    connect(#provided , #required );
#}) (filter (negate bind-port?) ((compose .elements .bindings) model))) }

  void #.model ::check_bindings() const
  {
    dezyne::check_bindings(&dzn_meta);
  }
  void #.model ::dump_tree(std::ostream& os) const
  {
    dezyne::dump_tree(os, &dzn_meta);
  }
#(map (lambda (x) (list "}\n")) (om:scope model))
