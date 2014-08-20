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
#} (filter ast:in? (ast:events (ast:interface ast))))  } in;

  struct
  {
    #(map-events
#{asd::function<void()> #.event;
#} (filter ast:out? (ast:events (ast:interface ast))))  } out;
};
}

##endif
