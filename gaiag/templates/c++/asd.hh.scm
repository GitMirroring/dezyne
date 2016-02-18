##ifndef #.COMPONENT _HH
##define #.COMPONENT _HH

namespace dzn {
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
  dzn::meta dzn_meta;
  dzn::runtime& dzn_rt;
  dzn::locator& dzn_locator;
  #(map (init-port #{#((c++:scope-join model) interface)  #name ;
                     #}) ((compose .elements .ports) model))
  boost::shared_ptr<#(symbol-drop (om:name (om:port model)) 1) Interface> component;
  #.model (dzn::locator&);
  void check_bindings() const {}
  void dump_tree() const {}
};

##endif // #.COMPONENT _HH
