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
  (component-ports (component ast)))

  #.component ()
  : foo ()
#(map-ports
#{
  , #.port {#(let* ((e (map event-name (filter (event-dir-matches? port) (port-events port))))
        (m (map (lambda (x) (list "[this]{" x "();}")) e)))
  (if (eq? (port-direction port) 'provides)
     (list (comma-join m) ",{}")
     (list "{}, " (comma-join m))))}
#} (component-ports (component ast)))
  {}

#(map-ports
#{
#(map-port-events
#{
  void #.event ()
  {
    std::cout << "#.component .#.event " << std::endl;
    #.port .#(event-direction event).#(action .port .event)();
  }
#} port (port-events port))
#} (component-ports (component ast)))

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
