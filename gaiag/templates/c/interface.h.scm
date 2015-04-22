##ifndef DEZYNE_#.INTERFACE _H
##define DEZYNE_#.INTERFACE _H

##include "runtime.h"

#(->string (map (declare-enum model) (append (gom:interface-enums model) (gom:enums))))

typedef struct #.model  #.model;

struct #.model {
  struct {
     char const* name;
     void* self;
   #(map (declare-io model
          #{ #return-type  (*#name)(#.model * self#comma #parameters);
#}) (filter gom:in? ((compose .elements .events) model)))
   } in;

  struct {
     char const* name;
     void* self;
   #(map (declare-io model
          #{ #return-type  (*#name) (#.model * self#comma #parameters);
#}) (filter gom:out? ((compose .elements .events) model)))
 } out;
};

##endif // DEZYNE_#.INTERFACE _H
