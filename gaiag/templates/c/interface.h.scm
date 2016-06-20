##ifndef #.INTERFACE _H
##define #.INTERFACE _H

##include <dzn/runtime.h>

#(->string (map (declare-enum model) (append (om:interface-enums model) (om:enums))))

typedef struct #.scope_model  #.scope_model;

struct #.scope_model  {
  dzn_port_meta_t meta;
  struct {
   #(map (declare-io model
          #{ #return-type  (*#name)(#.scope_model * self#comma #formals);
#}) (filter om:in? ((compose .elements .events) model)))
   } in;

  struct {
   #(map (declare-io model
          #{ #return-type  (*#name) (#.scope_model * self#comma #formals);
#}) (filter om:out? ((compose .elements .events) model)))
 } out;
};

##endif // #.INTERFACE _H
