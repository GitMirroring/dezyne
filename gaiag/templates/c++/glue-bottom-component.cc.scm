##include "#.model .hh"

##include "asdInterfaces.h"

##include <dzn/locator.hh>
##include <dzn/runtime.hh>

##include "#.model Component.h"

##include <boost/bind.hpp>
##include <boost/make_shared.hpp>
##include <boost/ref.hpp>

##include <map>

struct SingleThreaded
  : public asd::channels::ISingleThreaded
{
  void processCBs(){}
};

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
#return-type  #asd-event(){ port.out.#event(); }
#})
                 mapping-list)))
((animate-pairs `((component ,mapping->component)
                  (asd-interface ,mapping->asd-interface)
                  (member-functions ,member-functions)
                  (port-type ,port-type)) #{
struct #component : public #asd-interface
{
 #port-type & port;
 #component(#port-type & port)
 : port(port)
 {}
 #member-functions
};
#}) mapping)))
      ((asd-interfaces om:out?) (om:interface model)))

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
static std::map<#.model *, boost::shared_ptr<#(om:name (om:port model)) Interface> > g_handwritten;

#.model ::#.model (const dzn::locator& dezyne_locator)
: dzn_meta{"glue","#.model",0,{},{#((->join ",") (map (lambda (port) (list "[this]{" (.name port) ".check_bindings();}")) (om:ports model)))}}
, dzn_rt(dezyne_locator.get<dzn::runtime>())
, dzn_locator(dezyne_locator)#
(map (lambda (port) (if (eq? (.direction port) 'provides) (list "\n, " (.name port) "({{\"" (.name port) "\",this},{\"\",0}})") (list "\n, " (.name port) "({{\"\",0},{\"" (.name port) "\",this}})"))) ((compose .elements .ports) model))
{
  boost::shared_ptr< ::#(om:name (om:port model)) Interface> component = ::#.model Component::GetInstance() ;
#(map (lambda (port) (->string (list "boost::shared_ptr< ::" (om:name port) "> api_" (.name port) ";\n"
                                       "component->GetAPI(&api_" (.name port) ");\n")))
        (filter om:provides? ((compose .elements .ports) model)))
g_handwritten.insert (std::make_pair (this,component));
#(map
  (lambda (mapping-list)
   ((animate-pairs `((component ,mapping->component)
                     (port ,(.name (om:port model)))
                     (asd-interface ,mapping->asd-interface))
#{
  component->RegisterCB(boost::make_shared<#component >(boost::ref(#port)));
#}) (car mapping-list))) ((asd-interfaces om:out?) (om:interface model)))
#(if (pair? ((asd-interfaces om:out?) (om:interface model))) "component->RegisterCB(boost::make_shared< ::SingleThreaded>()); //fixme")
#(map
  (lambda (mapping-list)
    (map
      (animate-pairs `((asd-interface ,mapping->asd-interface)
                       (asd-event ,mapping->asd-event)
                       (event ,mapping->event)
                       (component ,mapping->component)
                       (port ,(.name (om:port model)))
                       (port-type ,(om:name (om:port model))))
#{
 #port .in.#event  = boost::bind(&::#port-type ::#asd-event , api_#port);
#}) mapping-list)) ((asd-interfaces om:in?) (om:interface model)))}
#(map (lambda (x) (list "}\n")) (om:scope model))
