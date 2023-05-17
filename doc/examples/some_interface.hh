struct some_interface
{
  struct
  {
    dezyne::function<void ()> in_event;
  } in;
  struct
  {
    dezyne::function<void ()> out_event;
  } out;
};
