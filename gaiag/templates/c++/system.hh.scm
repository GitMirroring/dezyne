##ifndef DEZYNE_#.COMPONENT _HH
##define DEZYNE_#.COMPONENT _HH

#(map (include-component #{
##include "#component .hh"
#}) ((compose .elements .instances) model))

#(map (include-interface #{
##include "#interface .hh"
#}) (delete-duplicates (gom:ports model) (lambda (x y) (eq? (.type x) (.type y)))))

#(if (pair? (injected-bindings model)) (list "#include \"locator.hh\"") (list "namespace dezyne\n {\nstruct locator;\n}"))

namespace dezyne
{
struct #.model
{
   dezyne::meta meta;
#(map (lambda (binding) (list (.component (gom:instance model (injected-instance-name binding))) " "
                              (injected-instance-name binding) ";\n")) (injected-bindings model)) #
(if (pair? (injected-bindings model)) (list "dezyne::locator dezyne_local_locator;\n")) #
(map (init-instance #{
  #component  #name;
#}) (non-injected-instances model))
#(map (init-port #{
  #interface & #name;
#}) ((compose .elements .ports) model))
  #.model (const dezyne::locator&);
};
}
##endif // DEZYNE_#.COMPONENT _HH
