##ifndef INTERFACE_#.INTERFACE _C3_HH
##define INTERFACE_#.INTERFACE _C3_HH

##include <boost/bind.hpp>
##include <boost/function.hpp>

namespace dezyne
{
  using boost::function;
  using boost::bind;
}

struct #.interface
{
 #(->string (map declare-enum (gom:interface-enums model)))
  struct
  {
   #(map (declare-io model
          #{dezyne::function<#return-type  (#parameters)> #name;
#}) (filter gom:in? ((compose .elements .events) model)))
   } in;

  struct
  {
   #(map (declare-io model
          #{dezyne::function<#return-type  (#parameters)> #name;
#}) (filter gom:out? ((compose .elements .events) model)))
 } out;
  };

##endif
