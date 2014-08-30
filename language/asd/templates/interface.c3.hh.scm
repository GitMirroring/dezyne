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
  struct
  {
    #(map-events
#{asd::function<void()> #.event;
#} (filter gom:in? ((compose .elements .events) (gom:interface ast))))  } in ;

  struct
  {
    #(map-events
#{asd::function<void()> #.event;
#} (filter gom:out? ((compose .elements .events) (gom:interface ast)))) } out;
};
}

##endif
