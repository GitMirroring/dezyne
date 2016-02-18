##ifndef #.COMPONENT _HH
##define #.COMPONENT _HH

##include <iostream>

##include <dzn/pump.hh>

#(map (include-component #{
##include "#component .hh"
#}) ((compose .elements .instances) model))

#(map (include-interface #{
##include "#interface .hh"
#}) (delete-duplicates (om:ports model) (lambda (x y) (eq? (.type x) (.type y)))))

#(string-if (pair? (injected-bindings model))
#{
##include <dzn/locator.hh>
#}
#{
namespace dzn {struct locator;}
#})

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
struct #.model
{
 dzn::meta dzn_meta;
 dzn::runtime dzn_runtime;
 #(map (lambda (binding) (list ((c++:scope-name) (.component (om:instance model (injected-instance-name binding)))) " "
                              (injected-instance-name binding) ";\n")) (injected-bindings model))
 dzn::locator dzn_locator;
#(map (init-instance #{
  #((c++:scope-name) component)  #name;
#}) (non-injected-instances model))
#(map (init-bind model #{ #((c++:scope-name) interface)  #port;
#}) (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
  dzn::pump dzn_pump;
  #.model (const dzn::locator&);
  void check_bindings() const;
  void dump_tree(std::ostream& os=std::clog) const;
};
#(map (lambda (x) (list "}\n")) (om:scope model))
##endif // #.COMPONENT _HH
