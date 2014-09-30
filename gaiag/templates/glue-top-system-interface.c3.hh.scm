##ifndef #.COMPONENT _INTERFACE_H
##define #.COMPONENT _INTERFACE_H

##include "asdInterfaces.h"

##include <boost/shared_ptr.hpp>

#(map (lambda (port)
        (->string
         (list "struct " (.type port) "_API\n"
               "{\n"
               (map
                (lambda (event)
                  (let* ((return-type (return-type port event)))
                    (->string
                     (list "virtual " return-type " " (.name event) "() = 0;\n"))))
                (filter gom:in? (gom:events port)))
               "};\n")))
      (filter gom:provides? ((compose .elements .ports) model)))

#(map (lambda (port)
        (->string
         (list "struct " (.type port) "_CB\n"
               "{\n"
               (map
                (lambda (event)
                  (let* ((return-type (return-type port event)))
                    (->string
                     (list "virtual " return-type " " (.name event) "() = 0;\n"))))
                (filter gom:out? (gom:events port)))
               "};\n")))
      (filter gom:provides? ((compose .elements .ports) model)))

struct #.model Interface
{
#(map (lambda (port)
        (->string
         (list "virtual void GetAPI(boost::shared_ptr<" (.type port) "_API>*) = 0;\n")))
      (filter gom:provides? ((compose .elements .ports) model)))
#(map (lambda (port)
        (->string
         (list "virtual void RegisterCB(boost::shared_ptr<" (.type port) "_CB>) = 0;\n")))
      (filter gom:provides? ((compose .elements .ports) model)))
virtual void RegisterCB (boost::shared_ptr<asd::channels::ISingleThreaded>) = 0;
};

##endif
