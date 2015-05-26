##ifndef DEZYNE_#.COMPONENT _HH
##define DEZYNE_#.COMPONENT _HH

#(map (include-interface #{
##include "#interface .hh"
#}) (delete-duplicates (om:ports model) (lambda (x y) (eq? (.type x) (.type y)))))

##include "runtime.hh"

namespace dezyne
{
struct locator;
struct runtime;

struct #.model
{
    dezyne::meta dzn_meta;
    runtime& dzn_rt;
    locator const& dzn_locator;
    #(->string (map (declare-enum model) (om:enums (.behaviour model))))#
    (->string (map declare-integer (om:integers (.behaviour model))))#
    (map (init-member model #{
#type  #name;
#}) (om:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))#
    (map (init-port #{
#interface  #name;
#}) ((compose .elements .ports) model))
    #.model (const locator&);
  void check_bindings() const;
  void dump_tree() const;

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
}
##endif // DEZYNE_#.COMPONENT _HH
