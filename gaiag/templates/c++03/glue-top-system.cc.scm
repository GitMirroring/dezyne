##include "#.model Component.h"

##include <dzn/locator.hh>
##include <dzn/runtime.hh>

##include "#((om:scope-name) model) .hh"

##include <boost/bind.hpp>
##include <boost/function.hpp>
##include <boost/make_shared.hpp>

struct #.model Glue
: public #.model Component
{
  dzn::runtime dezyne_runtime;
  dzn::locator dezyne_locator;
 #((c++:scope-name) model)  component;

#(define (api port) (->string (list ((om:scope-name) port) "_API")))#
 (define (cb port) (->string (list ((om:scope-name) port) "_CB")))#
 (map (lambda (entry)
        (let ((port-type ((c++:scope-name) (om:port model)))
              (interface (car entry))
              (dzn-events (cadr entry))
              (asd-events (caddr entry)))
          (list "struct " interface "\n: public ::" .model "::" interface "\n"
                "{\n"
                port-type "& api;\n"
                interface "(" port-type "& api)\n"
                ": api(api)\n"
                "{}\n"
                (map
                 (lambda (dzn asd)
                   (let* ((event (om:event (om:interface model) dzn))
                          (formals (.elements (.formals (.signature event))))
                          (arguments (comma-join (map .name formals)))
                          (formals (comma-join (map (lambda (formal)
                                           (list (if (eq? (.direction formal) 'in) "const ") "asd::value< " ((compose .value (om:type model)) formal) " >::type& " (.name formal)))
                                         formals)))
                          (port (om:port model)))
                     (list "::" (om:name model) "::" interface "::PseudoStimulus " asd "(" formals ")\n"
                           "{\n"
                           "return static_cast< ::" (om:name model) "::" interface "::PseudoStimulus>(1 + api.in." dzn "(" arguments "));\n"
                           "}\n")))
                 dzn-events asd-events)
                "};\n")))
      (map (lambda (api)
             (let* ((lst (filter (lambda (entry) (eq? api (second entry))) ((asd-interfaces om:in?) (om:interface model))))
                    (dzn-events (map first lst))
                    (asd-events (map third lst)))
              (list api dzn-events asd-events)))
           (delete-duplicates (map second ((asd-interfaces om:in?) (om:interface model))))))

#(map (lambda (interface)
        (list "boost::shared_ptr< ::" (om:name model) "::" interface "> api_" interface ";\n"))
      (delete-duplicates (map second ((asd-interfaces om:in?) (om:interface model)))))
#(map (lambda (interface)
        (list "boost::shared_ptr< ::" (om:name model) "::" interface "> cb_" interface ";\n"))
      (delete-duplicates (map second ((asd-interfaces om:out?) (om:interface model)))))
boost::shared_ptr<asd::channels::ISingleThreaded> st;

#.model Glue ()
: component(dezyne_locator.set(dezyne_runtime))
#(map (lambda (interface)
        (let ((port-name (.name (om:port model))))
          (list ", api_" interface
                "(boost::make_shared<" interface ">(boost::ref(component." port-name ")))\n")))
      (delete-duplicates (map second ((asd-interfaces om:in?) (om:interface model)))))
{
 #(use-modules (srfi srfi-26))#
 (map (lambda (entry)
        (let* ((event (first entry))
               (interface (second entry))
               (event (om:event (om:interface model) event))
               (formals (.elements (.formals (.signature event))))
               (port (om:port model))
               (port-name (.name port)))
          (list "component." port-name ".out." (first entry)
                " = boost::bind(&" (om:name model) "Glue::" (first entry) ","
                (comma-join (list "this" (comma-join (map (compose (cut string-append "_" <>) number->string) (iota (length formals) 1 1))))) ");\n")))
      ((asd-interfaces om:out?) (om:interface model)))}
#(map (lambda (entry)
        (let* ((event-name (first entry))
               (interface (second entry))
               (event (om:event (om:interface model) event-name))
               (formals (.elements (.formals (.signature event))))
               (arguments (comma-join (map .name formals)))
               (formals (comma-join (map (lambda (formal)
                                          (list ((compose .value (om:type model)) formal) (if (eq? (.direction formal) 'in) " " "& ") (.name formal)))
                                         formals)))
               (port (om:port model))
               (port-name (.name port)))
          (list "void " (first entry) "(" formals ")\n"
                "{\n"
                "cb_" interface "->" (third entry) "(" arguments ");\n"
                "st->processCBs();\n"
                "}\n")))
      ((asd-interfaces om:out?) (om:interface model)))

#(map (lambda (interface)
        (let ((port-type ((c++:scope-name) (om:port model))))
          (list "void GetAPI(boost::shared_ptr< ::" (om:name model) "::" interface ">* api)\n"
               "{\n"
               "*api = api_" interface ";\n"
               "}\n")))
      (delete-duplicates (map second ((asd-interfaces om:in?) (om:interface model)))))


#(map (lambda (interface)
        (let ((port-type ((c++:scope-name) (om:port model))))
          (list "void RegisterCB(boost::shared_ptr< ::" (om:name model) "::" interface "> cb)\n"
               "{\n"
               "cb_" interface " = cb;\n"
               "}\n")))
      (delete-duplicates (map second ((asd-interfaces om:out?) (om:interface model)))))

void RegisterCB (boost::shared_ptr<asd::channels::ISingleThreaded> st)
{
  this->st = st;
}
};

boost::shared_ptr<#.model ::#.model Interface> #.model Component::GetInstance ()
{
  return boost::make_shared<#.model Glue> ();
}
void #.model Component::ReleaseInstance () {}
