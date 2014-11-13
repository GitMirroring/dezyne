##include "#.model Component.h"

##include "locator.h"
##include "runtime.h"

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
  dezyne::#.model  component;

#(define (api port) (->string (list (.type port) "_API")))
#(define (cb port) (->string (list (.type port) "_CB")))

#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry))
               (component (symbol-drop interface 1))
               (port-type (.type (gom:port model))))
          (list "struct " component "\n: public " interface "\n"
                "{\n"
                "dezyne::" port-type "& api;\n"
                component "(dezyne::" port-type "& api)\n"
                ": api(api)\n"
                "{}\n"
                (map
                 (lambda (entry)
                   (let* ((event (gom:event (gom:interface model) (first entry)))
                          (port (gom:port model))
                          (return-type (return-type port event)))
                     (list return-type " " (third entry) "()\n"
                           "{\n"
                           "return api.in." (.name event) "();\n"
                           "}\n")))
                 alist)
                "};\n")))
      ((gen1-interfaces gom:in?) (gom:interface model)))

#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry)))
          (list "boost::shared_ptr<" interface "> api_" interface ";\n")))
      ((gen1-interfaces gom:in?) (gom:interface model)))
#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry)))
          (list "boost::shared_ptr<" interface "> cb_" interface ";\n")))
      ((gen1-interfaces gom:out?) (gom:interface model)))
boost::shared_ptr<asd::channels::ISingleThreaded> st;

#.model Glue (const dezyne::locator& l)
: component(l)
#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry))
               (component (symbol-drop interface 1))
               (port-name (.name (gom:port model))))
          (list ", api_" interface
                "(boost::make_shared<" component ">(boost::ref(component." port-name ")))\n")))
      ((gen1-interfaces gom:in?) (gom:interface model)))
{
#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry))
               (port (gom:port model))
               (port-name (.name port)))
          (map
           (lambda (entry)
             (list "component." port-name ".out." (first entry)
                   " = boost::bind(push, boost::ref(st), boost::function<void()>(boost::bind(&" interface "::" (third entry) ", boost::ref(cb_" interface "))));\n"))
           alist)))
      ((gen1-interfaces gom:out?) (gom:interface model)))
}

#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry))
               (port-type (.type (gom:port model))))
          (list "void GetAPI(boost::shared_ptr<" interface ">* api)\n"
               "{\n"
               "*api = api_" interface ";\n"
               "}\n")))
      ((gen1-interfaces gom:in?) (gom:interface model)))


#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry))
               (port-type (.type (gom:port model))))
          (list "void RegisterCB(boost::shared_ptr<" interface "> cb)\n"
               "{\n"
               "cb_" interface " = cb;\n"
               "}\n")))
      ((gen1-interfaces gom:out?) (gom:interface model)))

void RegisterCB (boost::shared_ptr<asd::channels::ISingleThreaded> st)
{
  this->st = st;
}
};

dezyne::locator dezyne_locator;
dezyne::runtime dezyne_runtime;

boost::shared_ptr<#(.type (gom:port model)) Interface> #.model Component::GetInstance ()
{
  dezyne_locator.set(dezyne_runtime);
  return boost::make_shared<#.model Glue> (dezyne_locator);
}
void #.model Component::ReleaseInstance () {}
