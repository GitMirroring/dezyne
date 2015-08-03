##include "#.model .hh"

##include "asdInterfaces.h"

##include "locator.hh"
##include "runtime.hh"

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

#(define ((gen1-interfaces dir?) model)
   (let* ((port (om:port model))
          (provided
           (filter dir? ((compose .elements .events om:interface) port)))
          (alist (event2->interface1-event1-alist port))
          (gen1-provided (filter identity (map (lambda (x) (assoc (.name x) alist)) provided))))
     (if (pair? gen1-provided) (list gen1-provided) '())))

#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry))
               (component (symbol-drop interface 1))
               (port-type ((c++:scope-name) (om:port model))))
         (list "struct " component "\n: public " interface "\n"
               "{\n"
               port-type "& port;\n"
               component "(" port-type "& port)\n"
               ": port(port)\n"
               "{}\n"
               (map
                (lambda (entry)
                  (list "void " (third entry) "(){ port.out." (first entry) "(); }\n"))
                alist)
               "};\n")))
      ((gen1-interfaces om:out?) model))

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
static std::map<#.model *, boost::shared_ptr<#(om:name (om:port model)) Interface> > g_handwritten;

#.model ::#.model (const dezyne::locator& dezyne_locator)
: dzn_meta{"glue","#.model",reinterpret_cast<const dezyne::component*>(this),0,{},{#((->join ",") (map (lambda (port) (list "[this]{" (.name port) ".check_bindings();}")) (om:ports model)))}}
, dzn_rt(dezyne_locator.get<dezyne::runtime>())
, dzn_locator(dezyne_locator)#
(map (lambda (port) (if (eq? (.direction port) 'provides) (list "\n, " (.name port) "({{\"" (.name port) "\",this},{\"\",0}})") (list "\n, " (.name port) "({{\"\",0},{\"" (.name port) "\",this}})"))) ((compose .elements .ports) model))
{
  boost::shared_ptr< ::#(om:name (om:port model)) Interface> component = ::#.model Component::GetInstance() ;
#(map (lambda (port) (->string (list "boost::shared_ptr< ::" (om:name port) "> api_" (.name port) ";\n"
                                       "component->GetAPI(&api_" (.name port) ");\n")))
        (filter om:provides? ((compose .elements .ports) model)))
g_handwritten.insert (std::make_pair (this,component));
#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry))
               (component (symbol-drop interface 1)))
          (list "component->RegisterCB(boost::make_shared<" component ">(boost::ref(" (.name (om:port model)) ")));\n")))
      ((gen1-interfaces om:out?) model))
#(if (pair? ((gen1-interfaces om:out?) model)) "component->RegisterCB(boost::make_shared< ::SingleThreaded>()); //fixme")
#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry)))
          (map
           (lambda (entry)
             (let ((port (om:port model)))
              (list (.name port) ".in." (first entry) " = boost::bind(&::" (om:name port) "::" (third entry) ",api_" (.name port) ");\n")))
           alist)))
      ((gen1-interfaces om:in?) model))}
#(map (lambda (x) (list "}\n")) (om:scope model))
