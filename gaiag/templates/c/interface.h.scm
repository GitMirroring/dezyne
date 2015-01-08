##ifndef DEZYNE_#.INTERFACE _HH
##define DEZYNE_#.INTERFACE _HH

##include <boost/bind.hpp>
##include <boost/function.hpp>

namespace dezyne
{

struct #.interface
{
 #(->string (map declare-enum (gom:interface-enums model)))
  struct
  {
   #(map (declare-io model
          #{boost::function<#return-type  (#parameters)> #name;
#}) (filter gom:in? ((compose .elements .events) model)))
   } in;

  struct
  {
   #(map (declare-io model
          #{boost::function<#return-type  (#parameters)> #name;
#}) (filter gom:out? ((compose .elements .events) model)))
 } out;
  };
}
##endif // DEZYNE_#.INTERFACE _HH
