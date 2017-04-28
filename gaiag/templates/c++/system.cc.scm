##include "#.scope_model .hh"

##include <dzn/runtime.hh>

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
#.model ::#.model (const dzn::locator& dzn_locator)
: #((->join "\n, ")
    (append
            (list
             (->string
              (list
               "dzn_meta" (c++:init-brace-open) "\"\",\"" .model "\",0,0,{},{"
               ((->join ",")
                (map (init-instance model #{&#name .dzn_meta#})
                     (non-injected-instances model)))
               "},{" ((->join ",") (map (lambda (port) (list "[this]{"(.name port) ".check_bindings();}")) (om:ports model))) "}" (c++:init-brace-close)))
             "dzn_rt(dzn_locator.get<dzn::runtime>())"
             "dzn_locator(dzn_locator)")
            (map (lambda (binding) (list (injected-instance-name binding) "(dzn_locator)"))
                 (injected-bindings model))
            (list (if (pair? (injected-bindings model))
                      (list "dzn_local_locator(dzn_locator.clone()" (map (lambda (binding) (list ".set(" (binding-name model (injected-binding binding)) ")"))  (injected-bindings model)) ")")))
            (map (init-instance model #{ #name (#(if (pair? (injected-bindings model)) "dzn_local_locator" "dzn_locator"))#})
                 (non-injected-instances model))
            (map (init-bind model #{ #port(#instance)#})
                 (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) model))))))
{
 #(map (init-instance model #{#name .dzn_meta.parent = &dzn_meta;
    #name .dzn_meta.name = "#name ";#
    (map (lambda (port) (animate #{#'()
       #name .#port .meta.requires.port = "#port ";#}
     `((name ,name)
       (port ,port)))) injected-ports)
#})
       ((compose .elements .instances) model))#
 (map (connect-ports model #{
    connect(#provided , #required );
#}) (filter (negate om:port-bind?) ((compose .elements .bindings) model)))
    #(map (lambda (port) (animate #{dzn::rank(#port .meta.provides.meta, 0); #}
    `((port ,(.name port))))) (filter om:provides? (om:ports model)))
  }

  void #.model ::check_bindings() const
  {
    dzn::check_bindings(&dzn_meta);
  }
  void #.model ::dump_tree(std::ostream& os) const
  {
    dzn::dump_tree(os, &dzn_meta);
  }
#(map (lambda (x) (list "}\n")) (om:scope model))
