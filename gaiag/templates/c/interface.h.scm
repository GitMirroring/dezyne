##ifndef DEZYNE_#.INTERFACE _H
##define DEZYNE_#.INTERFACE _H

typedef struct #.interface  #.interface;

#(->string (map declare-enum (gom:interface-enums model)))

struct #.interface  {
  struct {
   #(map (declare-io model
          #{ #return-type  (*#name)(void* self #comma #parameters);
#}) (filter gom:in? ((compose .elements .events) model)))
     void* self;
   } in;

  struct {
   #(map (declare-io model
          #{ #return-type  (*#name) (void* self #comma #parameters);
#}) (filter gom:out? ((compose .elements .events) model)))
     void* self;
 } out;
};

##endif // DEZYNE_#.INTERFACE _H
