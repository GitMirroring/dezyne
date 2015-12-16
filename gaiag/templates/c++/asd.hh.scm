##ifndef #.COMPONENT _HH
##define #.COMPONENT _HH

namespace dezyne {
struct locator;
struct runtime;
}
#(define ((xinclude-interface string) port)
  (let ((interface (last (.type port))))
    (animate string `((interface ,interface)))))

#(map (xinclude-interface #{
##include "#interface .hh"
#}) (delete-duplicates (om:ports model) (lambda (x y) (eq? (.type x) (.type y)))))

##include "#(symbol-drop (om:name (om:port model)) 1) Interface.h"

struct #.model
{
  dezyne::meta dzn_meta;
  dezyne::runtime& dzn_rt;
  dezyne::locator& dzn_locator;
  #(map (init-port #{#((c++:scope-join model) interface)  #name ;
                     #}) ((compose .elements .ports) model))
  boost::shared_ptr<#(symbol-drop (om:name (om:port model)) 1) Interface> component;
  #.model (dezyne::locator&);
  void check_bindings() const {}
  void dump_tree() const {}
};

##endif // #.COMPONENT _HH
