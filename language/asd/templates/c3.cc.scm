##include <boost/bind.hpp>
##include <boost/function.hpp>

namespace asd
{
  using boost::function; //event
  using boost::bind;
}

##include <iostream>
##include <map>
##include <string>

//port
#(map-ports
#{
struct #.interface Port
{
  struct
  {
    #(map-port-events
#{asd::function<void()> #.event;
#} port (filter ast:in? (ast:events port)))  } in;

  struct
  {
    #(map-port-events
#{asd::function<void()> #.event;
#} port (filter ast:out? (ast:events port)))  } out;
};

#} (ast:ports model))

//component
struct #.model
{
#(map-ports
#{
  #.interface Port #.port ;
#} (ast:ports model))
  #.model ()
  : #(map-ports
#{#.port ()#} (ast:ports model) "\n, ")
  {
#(map-ports
#{#(map-port-events
#{#.port .in.#.event  = asd::bind(&#.model ::#.event , this);
#} port (filter ast:in? (ast:events port)))
#} (filter ast:provides? (ast:ports model)))
#(map-ports
#{#(map-port-events
#{#.port .out.#.event  = asd::bind(&#.model ::#.event , this);
#} port (filter ast:out? (ast:events port)))
#} (filter ast:requires? (ast:ports model)))
  }
};
