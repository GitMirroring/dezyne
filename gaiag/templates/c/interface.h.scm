##ifndef DEZYNE_#.INTERFACE _H
##define DEZYNE_#.INTERFACE _H

typedef struct #.interface  #.interface;

struct #.interface  {
 #(->string (map declare-enum (gom:interface-enums model)))
  struct {
   #(map (declare-io model
          #{ #return-type  (*#name)(void* self);
#}) (filter gom:in? ((compose .elements .events) model)))
     void* self;
   } in;

  struct {
   #(map (declare-io model
          #{ #return-type  (*#name) (void* self);
#}) (filter gom:out? ((compose .elements .events) model)))
     void* self;
 } out;
};

##endif // DEZYNE_#.INTERFACE _H
