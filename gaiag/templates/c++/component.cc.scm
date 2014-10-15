##include "component-#.model -c3.hh"

##include "locator.h"
##include "runtime.h"

namespace dezyne {
template <typename R, bool checked>
inline R valued_helper(runtime& rt, void* scope, const function<R()>& event)
{
  bool& handle = rt.handling(scope);
  if(checked and handle) throw std::logic_error("a valued event cannot be deferred");

  runtime::scoped_value<bool> sv(handle, true);
  R tmp = event();
  if(not sv.initial)
  {
    rt.flush(scope);
  }
  return tmp;
}

template <typename R>
inline function<R()> connect_in(runtime& rt, void* scope, const function<R()>& event)
{
  return bind(valued_helper<R,false>, boost::ref(rt), scope, event);
}

template <>
inline function<void()> connect_in<void>(runtime& rt, void* scope, const function<void()>& event)
{
  return bind(&runtime::handle_event, boost::ref(rt), scope, event);
}

template <typename R>
inline function<R()> connect_out(runtime& rt, void* scope, const function<R()>& event)
{
  return bind(valued_helper<R,true>, boost::ref(rt), scope, event);
}

template <>
inline function<void()> connect_out<void>(runtime& rt, void* scope, const function<void()>& event)
{
  return bind(&runtime::handle_event, boost::ref(rt), scope, event);
}
}

namespace component
{
#.model ::#.model (const dezyne::locator& dezyne_locator)
: rt(dezyne_locator.get<dezyne::runtime>())
, #
((->join  "\n, ")
 (map (init-member model #{
#name(#expression)#}) (gom:variables model)))#
(if (null? (gom:variables model)) "" "\n, ") #
((->join  "\n, ") (map (lambda (port) (list (.name port) "(" (if (.injected port) (list "dezyne_locator.get<interface::" (.type port) ">()")) ")")) (gom:ports model)))
  {
#
   (map
    (lambda (port)
      (map (define-on model port #{
    #port .#direction .#event  = dezyne::connect_in<#return-type >(rt, this, dezyne::bind<#return-type >(&#model ::#port _#event , this));
#}) (filter gom:in? (gom:events port))))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (map (define-on model port #{
    #port .#direction .#event  = dezyne::connect_out<#return-type >(rt, this, dezyne::bind<#return-type >(&#model ::#port _#event , this));
#}) (filter gom:out? (gom:events port))))
    (filter gom:requires? (gom:ports model))) }

#(map
  (lambda (port)
    (map (define-on model port #{
  #return-type  #model ::#port _#event ()
  {
    std::cout << "#model .#port _#event" << std::endl;
    #statement #
    (if (not (eq? type 'void))
(list "    return reply_" reply-type "_" reply-name ";\n"
      )) }

#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))#
((->join "\n  ")(map (define-function model #{
  #return-type  #model ::#name (#parameters)
  {
    #statements }
#}) (gom:functions model))) }
