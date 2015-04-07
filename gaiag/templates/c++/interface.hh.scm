##ifndef DEZYNE_#.INTERFACE _HH
##define DEZYNE_#.INTERFACE _HH

##include "meta.hh"

##include <cassert>

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

   void check_bindings() const
   {
   #(map (declare-io model
         #{if (not in.#name) throw dezyne::binding_error_in(meta, "in.#name");
#}) (filter gom:in? ((compose .elements .events) model)))
   #(map (declare-io model
         #{if (not out.#name) throw dezyne::binding_error_out(meta, "out.#name");
#}) (filter gom:out? ((compose .elements .events) model)))
   }
  };

  inline void connect (#.interface & provided, #.interface & required)
  {
     provided.out = required.out;
     required.in = provided.in;
     provided.meta.requires = required.meta.requires;
     required.meta.provides = provided.meta.provides;
   }
   #(->string (map enum-to-string (gom:interface-enums model)))
}
##endif // DEZYNE_#.INTERFACE _HH
