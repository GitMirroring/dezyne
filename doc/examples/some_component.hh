struct some_component
{
  some_interface provided_port;
  some_interface required_port;
  some_component ()
  : provided_port ()
  , required_port ()
  {
    provided_port.in.in_event
      = dezyne::ref (required_port.in.in_event);
    required_port.out.out_event
      = dezyne::ref (provided_port.out.out_event);
  }
};
