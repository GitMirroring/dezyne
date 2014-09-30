##include "#.model Component.h"

##include "component-#.model -c3.hh"

##include <boost/bind.hpp>
##include <boost/function.hpp>
##include <boost/enable_shared_from_this.hpp>
##include <boost/make_shared.hpp>

inline void push(boost::shared_ptr<asd::channels::ISingleThreaded> st, boost::function<void()> cb)
{
  cb(); st->processCBs();
}

struct #.model Glue: public #.model Component
                   , public boost::enable_shared_from_this<#.model Glue>
{
  component::#.model  component;

#(map (lambda (port)
        (->string
         (list "struct " (.type port) "_API: public ::" (.type port) "_API\n"
               "{\n"
               "interface::" (.type port) "& api;\n"
               (.type port) "_API(interface::" (.type port) "& api)\n"
               ": api(api)\n"
               "{}\n"
               (map
                (lambda (event)
                  (let* ((return-type (return-type port event)))
                    (->string
                     (list return-type " " (.name event) "()\n"
                           "{\n"
                           "return api.in." (.name event) "();\n"
                           "}\n"))))
                (filter gom:in? (gom:events port)))
               "};\n")))
      (filter gom:provides? ((compose .elements .ports) model)))

#(map (lambda (port)
        (->string
         (list "boost::shared_ptr<" (.type port) "_API> api_" (.name port) ";\n")))
      (filter gom:provides? ((compose .elements .ports) model)))
#(map (lambda (port)
        (->string
         (list "boost::shared_ptr<" (.type port) "_CB> cb_" (.name port) ";\n")))
      (filter gom:provides? ((compose .elements .ports) model)))
#.model Glue ()
: component()
#(map (lambda (port)
        (->string
         (list ", api_" (.name port)
               "(boost::make_shared<" (.type port) "_API>(boost::ref(component." (.name port) ")))\n")))
      (filter gom:provides? ((compose .elements .ports) model))){
#(map (lambda (port)
        (->string
         (list
          (map
           (lambda (event)
             (->string
              (list "component." (.name port) ".out." (.name event)
                    " = boost::bind(push, st, boost::function<void()>(boost::bind(&" (.type port) "_CB::" (.name event) ", cb_" (.name port) ")));\n")))
           (filter gom:out? (gom:events port))))))
      (filter gom:provides? ((compose .elements .ports) model)))}

#(map (lambda (port)
        (->string
         (list "void GetAPI(boost::shared_ptr< ::" (.type port) "_API>* api)\n"
               "{\n"
               "*api = api_" (.name port) ";\n"
               "}\n")))
      (filter gom:provides? ((compose .elements .ports) model)))
#(map (lambda (port)
        (->string
         (list "void RegisterCB(boost::shared_ptr< ::" (.type port) "_CB> cb)\n"
               "{\n"
               "cb_" (.name port) " = cb;\n"
               "}\n")))
      (filter gom:provides? ((compose .elements .ports) model)))

boost::shared_ptr<asd::channels::ISingleThreaded> st;

void RegisterCB (boost::shared_ptr<asd::channels::ISingleThreaded> st)
{
  this->st = st;
}
};

boost::shared_ptr<#.model Interface> #.model Component::GetInstance ()
{
  return boost::make_shared<#.model Glue> ();
}
void #.model Component::ReleaseInstance () {}
