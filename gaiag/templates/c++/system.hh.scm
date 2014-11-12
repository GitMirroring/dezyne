##ifndef COMPONENT_#.COMPONENT _HH
##define COMPONENT_#.COMPONENT _HH

#(map (include-component #{
##include "#component .hh"
#}) ((compose .elements .instances) model))

#(map (include-interface #{
##include "#interface .hh"
#}) (gom:ports model))

#(if (pair? (injected-bindings model)) (list "#include \"locator.h\"") (list "namespace dezyne {\nstruct locator;\n}"))

namespace component
{
struct #.model
{
#(map (lambda (binding) (list (.component (gom:instance model (injected-instance-name binding))) " "
                              (injected-instance-name binding) ";\n")) (injected-bindings model)) #
(if (pair? (injected-bindings model)) (list "dezyne::locator dezyne_local_locator;\n")) #
(map (init-instance #{
  #component  #name;
#}) (non-injected-instances model))
#(map (init-port #{
  interface::#interface & #name;
#}) ((compose .elements .ports) model))
  #.model (const dezyne::locator&);
};
}
##endif
