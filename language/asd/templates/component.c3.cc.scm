##include "#.model -c3.hh"

#.model ::#.model ()
: #(map-ports
#{#.port ()#} (ast:ports model) "\n, ")
  {
#(map-ports #{#(map-port-events #{#.port .in.#.event  = asd::bind(&#.model ::#.event , this);
#} port (filter ast:in? (ast:events port))) #} (filter ast:provides? (ast:ports model)))#
(map-ports #{#(map-port-events #{#.port .out.#.event  = asd::bind(&#.model ::#.event , this);
#} port (filter ast:out? (ast:events port))) #} (filter ast:requires? (ast:ports model))) }
#(map-ports #{#(map-port-events #{void #.model ::#.event ()
  {
    std::cout << "#.model ::#.event " << std::endl;
  }
#} port (filter ast:in? (ast:events port))) #} (filter ast:provides? (ast:ports model)))#
(map-ports #{#(map-port-events #{void #.model ::#.event ()
  {
    std::cout << "#.model ::#.event " << std::endl;
  }
#} port (filter ast:out? (ast:events port))) #} (filter ast:requires? (ast:ports model)))
