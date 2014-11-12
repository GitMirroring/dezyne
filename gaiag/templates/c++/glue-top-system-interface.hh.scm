##ifndef #.INTERFACE _INTERFACE_H
##define #.INTERFACE _INTERFACE_H

##include "asdInterfaces.h"

##include <boost/shared_ptr.hpp>

namespace dezyne
{
#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry)))
          (list "struct " interface "\n"
                "{\n"
                "virtual ~" interface "(){}\n"
                (map
                 (lambda (entry)
                   (let* ((event (gom:event model (first entry)))
                          (return-type (return-type #f event)))
                     (list "virtual " return-type " " (third entry) "() = 0;\n")))
                 alist)
                "};\n")))
      ((gen1-interfaces gom:in?) model))

#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry)))
          (list "struct " interface "\n"
                "{\n"
                "virtual ~" interface "(){}\n"
                (map
                 (lambda (entry)
                   (let* ((event (gom:event model (first entry)))
                          (return-type (return-type #f event)))
                     (list "virtual " return-type " " (third entry) "() = 0;\n")))
                 alist)
                "};\n")))
      ((gen1-interfaces gom:out?) model))

struct #.model Interface
{
#(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry)))
          (list "virtual void GetAPI(boost::shared_ptr<" interface ">*) = 0 ;\n")))
      ((gen1-interfaces gom:in?) model))#
(map (lambda (alist)
        (let* ((entry (car alist))
               (interface (second entry)))
          (list "virtual void RegisterCB(boost::shared_ptr<" interface ">) = 0;\n")))
      ((gen1-interfaces gom:out?) model))
virtual void RegisterCB (boost::shared_ptr<asd::channels::ISingleThreaded>) = 0;
};
}
##endif
