##include <iostream>
##include <functional>
##include <map>
##include <string>

struct #.model 
{
#(map-ports
#{  
  #.interface Port #.port ;
#}
 (ast:ports model))

  #.model ()
  : foo ()
#(map-ports
#{
  , #.port {#(let* ((e (map ast:name (filter (ast:dir-matches? port) (ast:events port))))
        (m (map (lambda (x) (list "[this]{" x "();}")) e)))
  (if (eq? (ast:direction port) 'provides)
     (list (comma-join m) ",{}")
     (list "{}, " (comma-join m))))}
#} (ast:ports model))
  {}

#(map-ports
#{
#(map-port-events
#{
  void #.event ()
  {
    std::cout << "#.model .#.event " << std::endl;
    #.port .#(ast:direction event).#(action .port .event)();
  }
#} port (ast:events port)))
#} (ast:ports model))

XXXhandwrittervoid disarm()
  {
    std::cout << "#.model .disarm" << std::endl;
    sensor.in.disable();
  }

  void triggered()
  {
    std::cout << "#.model .triggered" << std::endl;
    siren.in.on();
    console.out.tripped();
  }
  void deactivated()
  {
    std::cout << "#.model .deactivated" << std::endl;
    siren.in.off();
    console.out.switched_off();
  }};
