##ifndef INTERFACE_#.INTERFACE _C3_HH
##define INTERFACE_#.INTERFACE _C3_HH

##include <boost/bind.hpp>
##include <boost/function.hpp>

namespace asd
{
  using boost::function;
  using boost::bind;
}

namespace interface
{
struct #.interface
{
 #(->string (map declare-enum (gom:interface-enums model)))
  struct
  {
    #(map-events
      #{asd::function<#(.name .type)#(if (not (eq? (.name .type) 'void)) "::type")()> #.event-name ;
#} (filter gom:in? ((compose .elements .events) model)))  } in;

  struct
  {
    #(map-events
#{asd::function<void()> #.event-name;
#} (filter gom:out? ((compose .elements .events) model))) } out;
};
}

##endif
