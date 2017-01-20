##include "#((om:scope-name) model) .hh"

##include "#.model Component.h"

##include <boost/make_shared.hpp>

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
#.model ::#.model (const dzn::locator& locator)
: skel::#.model(locator)
, component(#.model Component::GetInstance())
{
#(map (lambda (api) (->string (list "component->GetAPI(&api_" api ");\n")))
        (delete-duplicates (map second ((asd-interfaces om:in?) (om:interface model)))))
#(map (lambda (cb)
          (list "component->RegisterCB(boost::make_shared<" (symbol-drop cb 1) ">(boost::ref(" (.name (om:port model)) ")));\n"))
      (delete-duplicates (map second ((asd-interfaces om:out?) (om:interface model)))))
#(if (pair? (filter om:out? (om:events (om:port model))))
     (list "component->RegisterCB(boost::make_shared<SingleThreaded>(this, boost::ref(dzn_rt)));\n"))
  dzn_rt.performs_flush (this) = true;
}
#.model ::~#.model ()
{
#(map (lambda (api) (->string (list "api_" api ".reset();\n")))
        (delete-duplicates (map second ((asd-interfaces om:in?) (om:interface model)))))
 component.reset();
 #.model Component::ReleaseInstance();
}
#(map
  (lambda (event entry)
    (list ((define-on model (om:port model) #{
#return-type  #.model ::#port _#event (#
(comma-join (map (lambda (formal)
                   (list ((compose .value (om:type model)) formal) (if (eq? (.direction formal) 'in) " " "& ") (.name formal)))
                 formal-objects)))
{
#}) event)
(let ((arguments (comma-join (map .name ((compose .elements .formals .signature) event)))))
  (if (equal? 'void (return-type model event))
      (list "api_" (second entry) "->" (third entry) "(" arguments ");\n}\n")
      (list "return static_cast<" (return-type model event) ">(api_" (second entry) "->" (third entry) "(" arguments ") - 1);\n}\n")))))
(filter om:in? (om:events (om:port model))) ((asd-interfaces om:in?) (om:interface model)))
#(map (lambda (x) (list "}\n")) (om:scope model))
