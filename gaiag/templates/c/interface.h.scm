##ifndef DEZYNE_#.INTERFACE _H
##define DEZYNE_#.INTERFACE _H

#(->string (map declare-enum (gom:interface-enums model)))

typedef struct #.model  #.model;

struct #.model {
  struct {
     void* self;
   #(map (declare-io model
          #{ #return-type  (*#name)(#.model * self#comma #parameters);
#}) (filter gom:in? ((compose .elements .events) model)))
   } in;

  struct {
     void* self;
   #(map (declare-io model
          #{ #return-type  (*#name) (#.model * self#comma #parameters);
#}) (filter gom:out? ((compose .elements .events) model)))
 } out;
};

##endif // DEZYNE_#.INTERFACE _H
