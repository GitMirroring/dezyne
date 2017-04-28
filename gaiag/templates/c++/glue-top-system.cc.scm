##include "#.model Component.h"

##include <dzn/locator.hh>
##include <dzn/runtime.hh>

##include "#.model .hh"

##include <boost/bind.hpp>
##include <boost/function.hpp>
##include <boost/enable_shared_from_this.hpp>
##include <boost/make_shared.hpp>

inline void push(boost::shared_ptr<asd::channels::ISingleThreaded> st, boost::function<void()> cb)
{
  cb(); if(st) st->processCBs();
}

struct #.model Glue
: public #.model Component
, public boost::enable_shared_from_this<#.model Glue>
{
  #((c++:scope-name) model)  component;

#(define mapping->event first)
#(define mapping->asd-interface second)
#(define mapping->asd-event third)
#(define (mapping->component mapping) (symbol-drop (mapping->asd-interface mapping) 1))
#(map (lambda (mapping-list)
        (let* ((mapping (car mapping-list))
               (port (om:port model))
               (port-type ((c++:scope-name) port))
               (member-functions
                (map
                 (animate-pairs `((asd-interface ,mapping->asd-interface)
                                  (event ,mapping->event)
                                  (asd-event ,mapping->asd-event)
                                  (return-type ,(compose (lambda (e) (return-type port e)) (lambda (e) (om:event (om:interface model) e)) mapping->event))) #{
#return-type  #asd-event ()
{
  return api.in.#event();
}
#})
                 mapping-list)))
((animate-pairs `((component ,mapping->component)
                  (asd-interface ,mapping->asd-interface)
                  (member-functions ,member-functions)
                  (port-type ,port-type)) #{
struct #component : public #asd-interface
{
 #port-type & api;
 #component(#port-type & api)
 : api(api)
 {}
 #member-functions
};
#}) mapping)))
      ((asd-interfaces om:in?) (om:interface model)))

#(map (animate-pairs `((asd-interface ,(compose mapping->asd-interface car)))
#{
   boost::shared_ptr<#asd-interface > api_#asd-interface;
#}) ((asd-interfaces om:in?) (om:interface model)))
#(map (animate-pairs `((asd-interface ,(compose mapping->asd-interface car)))
#{
   boost::shared_ptr<#asd-interface > cb_#asd-interface;
#}) ((asd-interfaces om:out?) (om:interface model)))
boost::shared_ptr<asd::channels::ISingleThreaded> st;

#.model Glue (const dzn::locator& l)
: component(l)
#(map
  (lambda (mapping-list)
   ((animate-pairs `((asd-interface ,mapping->asd-interface)
                       (component ,mapping->component)
                       (port-name ,(.name (om:port model))))
#{
  , api_#asd-interface(boost::make_shared<#component >(boost::ref(component .#port-name)))
#}) (car mapping-list))) ((asd-interfaces om:in?) (om:interface model)))
{
#(map
  (lambda (mapping-list)
    (map
      (animate-pairs `((asd-interface ,mapping->asd-interface)
                       (asd-event ,mapping->asd-event)
                       (event ,mapping->event)
                       (component ,mapping->component)
                       (port-name ,(.name (om:port model))))
#{
   component.#port-name .out.#event  = boost::bind(push, boost::ref(st), boost::function<void()>(boost::bind(& #asd-interface ::#asd-event , boost::ref(cb_#asd-interface))));
#}) mapping-list)) ((asd-interfaces om:out?) (om:interface model)))
}

#(map
  (lambda (mapping-list)
   ((animate-pairs `((asd-interface ,mapping->asd-interface))
#{
void GetAPI(boost::shared_ptr<#asd-interface >* api)
{
  *api = api_#asd-interface;
}
#}) (car mapping-list))) ((asd-interfaces om:in?) (om:interface model)))

#(map
  (lambda (mapping-list)
   ((animate-pairs `((asd-interface ,mapping->asd-interface))
#{
void RegisterCB(boost::shared_ptr<#asd-interface > cb)
{
  cb_#asd-interface  = cb;
}
#}) (car mapping-list))) ((asd-interfaces om:out?) (om:interface model)))

void RegisterCB (boost::shared_ptr<asd::channels::ISingleThreaded> st)
{
  this->st = st;
}
};

dzn::locator dzn_locator;
dzn::runtime dzn_runtime;

boost::shared_ptr<#(om:name (om:port model)) Interface> #.model Component::GetInstance ()
{
  dzn_locator.set(dzn_runtime);
  return boost::make_shared<#.model Glue> (dzn_locator);
}
void #.model Component::ReleaseInstance () {}
