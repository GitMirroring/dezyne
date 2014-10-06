##ifndef INTERFACE_#.INTERFACE _C3_HH
##define INTERFACE_#.INTERFACE _C3_HH

##include <boost/bind.hpp>
##include <boost/function.hpp>

namespace asd
{
  using boost::function;
  using boost::bind;
}

namespace interface
{
struct #.interface
{
 #(->string (map declare-enum (gom:interface-enums model)))
  struct
  {
   #(map
     (lambda (event)
       (let* ((name (.name event))
              (type (.name (.type (.type event))))
              (return-type (list type (if (not (eq? type 'void)) "::type"))))
         (->string (list "asd::function<" return-type "()> " name ";\n"))))
     (filter gom:in? ((compose .elements .events) model))) } in;

  struct
  {
   #(map
     (lambda (event)
       (let* ((name (.name event))
              (type (.name (.type (.type event))))
              (return-type (list type (if (not (eq? type 'void)) "::type"))))
         (->string (list "asd::function<" return-type "()> " name ";\n"))))
     (filter gom:out? ((compose .elements .events) model))) } out;
  };
}

##endif
