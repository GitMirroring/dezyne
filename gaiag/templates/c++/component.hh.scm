##ifndef #.COMPONENT _HH
##define #.COMPONENT _HH

##include <iostream>

#(map (include-interface #{
##include "#interface .hh"
#}) (delete-duplicates (om:ports model) (lambda (x y) (eq? (.type x) (.type y)))))

##include "runtime.hh"

namespace dezyne {
struct locator;
struct runtime;
}

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
struct #.model
{
    dezyne::meta dzn_meta;
    dezyne::runtime& dzn_rt;
    dezyne::locator const& dzn_locator;
    #(->string (map (declare-enum model) (om:enums (.behaviour model))))#
    (->string (map declare-integer (om:integers (.behaviour model))))#
    (map (init-member model #{
#type  #name;
#}) (om:variables model))#
    (delete-duplicates (append-map (compose declare-replies code:import .type) ((compose .elements .ports) model)))#
    (map (init-port #{
    std::function<void ()> out_#name;
#}) (filter ;;om:provides?
            identity
     ((compose .elements .ports) model)))#
    (map (init-port #{
#((c++:scope-join model) interface)  #name ;
#}) ((compose .elements .ports) model))
    #.model (const dezyne::locator&);
  void check_bindings() const;
  void dump_tree(std::ostream& os=std::clog) const;

private:
#(map
  (lambda (port)
    (map (define-on model port #{
#return-type  #port _#event (#formals);
#}) (filter om:in? (om:events port))))
  (filter om:provides? (om:ports model)))#
(map
  (lambda (port)
    (map (define-on model port #{
#return-type  #port _#event (#formals);
#}) (filter om:out? (om:events port))))
  (filter om:requires? (om:ports model)))#
(map (define-function model #{
  #return-type  #name (#formals);
#}) (om:functions model)) };
#(map (lambda (x) (list "}\n")) (om:scope model))
##endif // #.COMPONENT _HH
