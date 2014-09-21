##ifndef COMPONENT_#.COMPONENT _HH
##define COMPONENT_#.COMPONENT _HH

#(map (lambda (instance)
        (let ((component (.component instance)))
          (->string (list "#include \"component-" component "-c3.hh\"\n"))))
      ((compose .elements .instances) model))

#(map (lambda (port)
        (let ((interface (.type port)))
          (->string (list "#include \"interface-" interface "-c3.hh\"\n"))))
      (gom:ports model))
namespace component
{
struct #.model
{
#(map
  (lambda (instance)
    (let ((component (.component instance))
          (name (.name instance)))
     (->string (list component " " name ";\n"))))
  ((compose .elements .instances) model))
#(map
  (lambda (port)
    (let ((name (.name port))
          (interface (.type port)))
      (->string (list "interface::" interface "& " name ";\n"))))
  ((compose .elements .ports) model))
  #.model ();
};
}
##endif
