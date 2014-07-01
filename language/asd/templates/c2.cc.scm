##include <iostream>
##include <functional>
##include <map>
##include <string>

struct #.component 
{
#(map-ports
#{  
  #.interface Port #.port ;
#}
 ((compose ast:ports ast:component) ast))

  #.component ()
  : foo ()
#(map-ports
#{
  , #.port {#(let* ((e (map ast:identifier (filter (ast:dir-matches? port) (ast:events port))))
        (m (map (lambda (x) (list "[this]{" x "();}")) e)))
  (if (eq? (ast:direction port) 'provides)
     (list (comma-join m) ",{}")
     (list "{}, " (comma-join m))))}
#} ((compose ast:ports ast:component) ast))
  {}

#(map-ports
#{
#(map-port-events
#{
  void #.event ()
  {
    std::cout << "#.component .#.event " << std::endl;
    #.port .#(ast:direction event).#(action .port .event)();
  }
#} port (ast:events port)))
#} ((compose ast:ports ast:component) ast))

XXXhandwrittervoid disarm()
  {
    std::cout << "#.component .disarm" << std::endl;
    sensor.in.disable();
  }

  void triggered()
  {
    std::cout << "#.component .triggered" << std::endl;
    siren.in.on();
    console.out.tripped();
  }
  void deactivated()
  {
    std::cout << "#.component .deactivated" << std::endl;
    siren.in.off();
    console.out.switched_off();
  }};
