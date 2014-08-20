##ifndef #.INTERFACE _INTERFACE_C3_HH
##define #.INTERFACE _INTERFACE_C3_HH

##include <boost/bind.hpp>
##include <boost/function.hpp>

namespace asd
{
  using boost::function;
  using boost::bind;
}

struct #.interface Interface
{
  struct
  {
    #(map-events
#{asd::function<void()> #.event;
#} (filter ast:in? (ast:events (ast:interface ast))))  } in;

  struct
  {
    #(map-events
#{asd::function<void()> #.event;
#} (filter ast:out? (ast:events (ast:interface ast))))  } out;
};

##endif
