##ifndef DEZYNE_#.INTERFACE _HH
##define DEZYNE_#.INTERFACE _HH

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
#}) (filter gom:in? ((compose .elements .events) model)))
    struct
    {
      const char* component;
      const char* port;
      void*       address;
    } meta;
   } in;

  struct
  {
   #(map (declare-io model
          #{std::function<#return-type  (#parameters)> #name;
#}) (filter gom:out? ((compose .elements .events) model)))
    struct
    {
      const char* component;
      const char* port;
      void*       address;
    } meta;
 } out;
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
   }
   #(->string (map enum-to-string (gom:interface-enums model)))
}
##endif // DEZYNE_#.INTERFACE _HH
