##ifndef DEZYNE_#.INTERFACE _HH
##define DEZYNE_#.INTERFACE _HH

##include "meta.hh"

##include <cassert>
##include <map>

namespace dezyne
{
 #(string-if (pair? (om:enums)) #{
 namespace global
 {
#})#
  (->string (map (declare-enum model) (om:enums)))
 #(string-if (pair? (om:enums)) #{
 }
#})
struct #.interface
{
 #(->string (map (declare-enum model) (om:interface-enums model)))
  struct
  {
   #(map (declare-io model
          #{std::function<#return-type  (#formals)> #name;
#}) (filter om:in? ((compose .elements .events) model))) } in;

  struct
  {
   #(map (declare-io model
          #{std::function<#return-type  (#formals)> #name;
#}) (filter om:out? ((compose .elements .events) model))) } out;

   port::meta meta;
   inline #.interface(port::meta m) : meta(m) {}

   void check_bindings() const
   {
   #(map (declare-io model
         #{if (not in.#name) throw dezyne::binding_error_in(meta, "in.#name");
#}) (filter om:in? ((compose .elements .events) model)))
   #(map (declare-io model
         #{if (not out.#name) throw dezyne::binding_error_out(meta, "out.#name");
#}) (filter om:out? ((compose .elements .events) model)))
   }
  };

  inline void connect (#.interface & provided, #.interface & required)
  {
     provided.out = required.out;
     required.in = provided.in;
     provided.meta.requires = required.meta.requires;
     required.meta.provides = provided.meta.provides;
   }
   #(->string (map (enum-to-string model) (om:interface-enums model)))
   #(->string (map (enum-to-string model) (om:enums)))
   #(->string (map (string-to-enum model) (om:interface-enums model)))
   #(->string (map (string-to-enum model) (om:enums)))
}
##endif // DEZYNE_#.INTERFACE _HH
