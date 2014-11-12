##ifndef COMPONENT_#.COMPONENT _HH
##define COMPONENT_#.COMPONENT _HH

#(map (include-interface #{
##include "#interface .hh"
#}) (gom:ports model))

namespace dezyne {
struct locator;
struct runtime;
}

struct #.model
{
    dezyne::runtime& rt;
    #(->string (map declare-enum (gom:enums (.behaviour model))))#
    (->string (map declare-integer (gom:integers (.behaviour model))))#
    (map (init-member model #{
#type  #name;
#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))#
    (map (init-port #{
#interface  #name;
#}) ((compose .elements .ports) model))
    #.model (const dezyne::locator&);
#(map
  (lambda (port)
    (map (define-on model port #{
#return-type  #port _#event (#parameters);
#}) (filter gom:in? (gom:events port))))
  (filter gom:provides? (gom:ports model)))#
(map
  (lambda (port)
    (map (define-on model port #{
#return-type  #port _#event (#parameters);
#}) (filter gom:out? (gom:events port))))
  (filter gom:requires? (gom:ports model)))#
(map (define-function model #{
  #return-type  #name (#parameters);
#}) (gom:functions model))};
##endif
