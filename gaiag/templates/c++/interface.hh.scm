##ifndef DEZYNE_#.INTERFACE _HH
##define DEZYNE_#.INTERFACE _HH

##include "meta.hh"

##include <cassert>
##include <functional>

namespace dezyne
{
struct #.interface
{
 #(->string (map declare-enum (gom:interface-enums model)))
  struct
  {
   #(map (declare-io model
          #{std::function<#return-type  (#parameters)> #name;
#}) (filter gom:in? ((compose .elements .events) model))) } in;

  struct
  {
   #(map (declare-io model
          #{std::function<#return-type  (#parameters)> #name;
#}) (filter gom:out? ((compose .elements .events) model))) } out;
   port::meta meta;
   inline #.interface(port::meta m) : meta(m) {}
  };

  inline void connect (#.interface & provided, #.interface & required)
  {
    #(map (declare-io model
          #{assert (not required.in.#name);
#}) (filter gom:in? ((compose .elements .events) model)))
    #(map (declare-io model
          #{assert (not provided.out.#name);
#}) (filter gom:out? ((compose .elements .events) model)))
     provided.out = required.out;
     required.in = provided.in;
     provided.meta.requires = required.meta.requires;
     required.meta.provides = provided.meta.provides;
   }
   #(->string (map enum-to-string (gom:interface-enums model)))
}
##endif // DEZYNE_#.INTERFACE _HH
