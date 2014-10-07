##ifndef COMPONENT_#.COMPONENT _HH
##define COMPONENT_#.COMPONENT _HH

#(map (include-interface #{
##include "interface-#interface -c3.hh"
#}) (gom:ports model))

namespace component
{
struct #.model
{
    #(->string (map declare-enum (gom:enums (.behaviour model))))#
    (->string (map declare-integer (gom:integers (.behaviour model))))#
    (map (init-member model #{
#type  #name;
#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies c++:import .type) ((compose .elements .ports) model)))#
    (map
     (lambda (port)
       (let ((name (.name port))
             (interface (.type port)))
         (->string (list "interface::" interface " " name ";\n") )))
     ((compose .elements .ports) model))
    #.model ();
#(map
  (lambda (port)
    (map
     (lambda (event)
       (let ((return-type (return-type port event))
             (function (list (.name port) "_" (.name event))))
         (->string (list return-type " " function "();\n"))))
     (filter gom:in? (gom:events port))))
  (filter gom:provides? (gom:ports model)))#
(map
 (lambda (port)
   (map (lambda (event)
          (let ((return-type (return-type port event)))
            (->string (list return-type " " (.name port) "_" (.name event) "();\n"))))
        (filter gom:out? (gom:events port))))
 (filter gom:requires? ((compose .elements .ports) model)))#
(map
 (lambda (function)
   (let* ((signature (.signature function))
          (return-type (c++:->code model signature))
          (name (.name function))
          (parameters (.parameters signature))
          (parameters (c++:->code model parameters)))
     (->string (list return-type " " name "(" parameters ");\n"))))
 (gom:functions model))};
}
##endif
