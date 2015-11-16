##ifndef #.COMPONENT _HH
##define #.COMPONENT _HH

#(map (include-component #{
##include "#component .hh"
#}) ((compose .elements .instances) model))

#(map (include-interface #{
##include "#interface .hh"
#}) (delete-duplicates (om:ports model) (lambda (x y) (eq? (.type x) (.type y)))))

#(if (pair? (injected-bindings model)) (list "#include \"locator.hh\"") (list "namespace dezyne\n {\nstruct locator;\n}"))

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
struct #.model
{
   dezyne::meta dzn_meta;
   dezyne::runtime& dzn_rt;
#(map (lambda (binding) (list ((c++:scope-name) (.component (om:instance model (injected-instance-name binding)))) " "
                              (injected-instance-name binding) ";\n")) (injected-bindings model)) #
(if (pair? (injected-bindings model)) (list "dezyne::locator dezyne_local_locator;\n")) #
(map (init-instance #{
  #((c++:scope-name) component)  #name;
#}) (non-injected-instances model))
#(map (init-bind model #{ #((c++:scope-name) interface)  #port;
#}) (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
  #.model (const dezyne::locator&);
  void check_bindings() const;
  void dump_tree() const;
};
#(map (lambda (x) (list "}\n")) (om:scope model))
##endif // #.COMPONENT _HH
