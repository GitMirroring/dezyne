##ifndef DEZYNE_#.INTERFACE _H
##define DEZYNE_#.INTERFACE _H

##include "runtime.h"

#(->string (map (declare-enum model) (append (om:interface-enums model) (om:enums))))

typedef struct #.model  #.model;

struct #.model {
  struct {
     char const* name;
     void* self;
   #(map (declare-io model
          #{ #return-type  (*#name)(#.model * self#comma #formals);
#}) (filter om:in? ((compose .elements .events) model)))
   } in;

  struct {
     char const* name;
     void* self;
   #(map (declare-io model
          #{ #return-type  (*#name) (#.model * self#comma #formals);
#}) (filter om:out? ((compose .elements .events) model)))
 } out;
};

##endif // DEZYNE_#.INTERFACE _H
