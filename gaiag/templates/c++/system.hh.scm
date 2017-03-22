##ifndef #.COMPONENT _HH
##define #.COMPONENT _HH

##include <iostream>

#(map (include-component #{
##include "#component .hh"
#}) (delete-duplicates ((compose .elements .instances) model)))

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
   dzn::runtime& dzn_rt;
   const dzn::locator& dzn_locator;
#(map (lambda (binding) (list ((c++:scope-name) (.type (om:instance model (injected-instance-name binding)))) " "
                              (injected-instance-name binding) ";\n")) (injected-bindings model))#
(if (pair? (injected-bindings model)) (list "dzn::locator dezyne_local_locator;\n")) #
(map (init-instance model #{
  #((c++:scope-name) component)  #name;
#}) (non-injected-instances model))
#(map (init-bind model #{ #((c++:scope-name) interface) & #port;
#}) (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
  #.model (const dzn::locator&);
  void check_bindings() const;
  void dump_tree(std::ostream& os=std::clog) const;
};
#(map (lambda (x) (list "}\n")) (om:scope model))
##endif // #.COMPONENT _HH
