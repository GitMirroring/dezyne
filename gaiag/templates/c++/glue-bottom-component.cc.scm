##include "#.model .hh"

##include "asdInterfaces.h"

##include "locator.h"
##include "runtime.h"

##include "#.model Component.h"

##include <boost/make_shared.hpp>

##include <map>

struct SingleThreaded
  : public asd::channels::ISingleThreaded
{
  void processCBs(){}
};

static std::map<dezyne::#.model *, boost::shared_ptr<#(.type (gom:port model)) Interface> > g_handwritten;

#(define ((gen1-interfaces dir?) model)
   (let* ((port (gom:port model))
          (provided
           (filter dir? ((compose .elements .events gom:interface) port)))
          (alist (event2->interface1-event1-alist (.type port)))
          (gen1-provided (filter identity (map (lambda (x) (assoc (.name x) alist)) provided))))
     (if (pair? gen1-provided) (list gen1-provided) '())))

#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry))
               (component (symbol-drop interface 1))
               (port-type (.type (gom:port model))))
         (list "struct " component "\n: public " interface "\n"
               "{\n"
               "dezyne::" port-type "& port;\n"
               component "(dezyne::" port-type "& port)\n"
               ": port(port)\n"
               "{}\n"
               (map
                (lambda (entry)
                  (list "void " (third entry) "(){ port.out." (first entry) "(); }\n"))
                alist)
               "};\n")))
      ((gen1-interfaces gom:out?) model))

namespace dezyne
{
#.model ::#.model (const locator& l)
  : rt (l.get<runtime>())
{
  boost::shared_ptr< ::#(.type (gom:port model)) Interface> component = ::#.model Component::GetInstance() ;
#(map (lambda (port) (->string (list "boost::shared_ptr< ::" (.type port) "> api_" (.name port) ";\n"
                                       "component->GetAPI(&api_" (.name port) ");\n")))
        (filter gom:provides? ((compose .elements .ports) model)))
g_handwritten.insert (std::make_pair (this,component));
#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry))
               (component (symbol-drop interface 1)))
          (list "component->RegisterCB(boost::make_shared<" component ">(boost::ref(" (.name (gom:port model)) ")));\n")))
      ((gen1-interfaces gom:out?) model))
#(if (pair? ((gen1-interfaces gom:out?) model)) "component->RegisterCB(boost::make_shared< ::SingleThreaded>()); //fixme")
#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry)))
          (map
           (lambda (entry)
             (let ((port (gom:port model)))
              (list (.name port) ".in." (first entry) " = boost::bind(&::" (.type port) "::" (third entry) ",api_" (.name port) ");\n")))
           alist)))
      ((gen1-interfaces gom:in?) model))}
}
