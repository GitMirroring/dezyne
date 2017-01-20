##include "#(om:scope model)_skel_#.model .hh"

##include "asdInterfaces.h"

##include <dzn/runtime.hh>

##include "#.model #(symbol-upcase-first .model) Interface.h"

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
struct #.model : public skel::#.model
{
 #.model (const dzn::locator&);
 ~#.model ();
 boost::shared_ptr< ::#(symbol-drop (om:name (om:port model)) 1) ::#(symbol-drop (om:name (om:port model)) 1) Interface> component;
#(map (lambda (api) (->string (list "boost::shared_ptr< ::" (symbol-drop (om:name (om:port model)) 1) "::" api "> api_" api ";\n")))
      (delete-duplicates (map second ((asd-interfaces om:in?) (om:interface model)))))
  struct SingleThreaded: public asd::channels::ISingleThreaded
  {
    void* p;
    dzn::runtime& rt;
    SingleThreaded (void* p, dzn::runtime& rt) : p (p) , rt (rt) {}
    void processCBs () { rt.flush (p); }
  };
#(map (lambda (entry)
        (let* ((name (car entry))
               (api (symbol-drop name 1))
               (dzn-events (cadr entry))
               (asd-events (caddr entry)))
          (list "struct " api ": public ::" (om:name model) "::" name "\n{\n"
                ((c++:scope-name) (om:port model)) "& port;\n"
                api "(" ((c++:scope-name) (om:port model)) "& port)\n"
                ": port(port)\n"
                "{}\n"
                (map (lambda (asd dzn)
                       (let* ((event (om:event (om:interface model) dzn))
                              (formals (.elements (.formals (.signature event))))
                              (arguments (map .name formals))
                              (formals (map (lambda (formal)
                                              (list (if (eq? (.direction formal) 'in) "const ")
                                                    "asd::value<" ((compose om:type-name (om:type model)) formal) ">::type& " (.name formal)))
                                            formals)))
                        (list "void " asd "(" formals "){\nport.out." dzn "(" arguments ");\n}\n")))
                     asd-events dzn-events)
                "};\n")))
      (map (lambda (api)
             (let* ((lst (filter (lambda (entry) (eq? api (second entry))) ((asd-interfaces om:out?) (om:interface model))))
                    (dzn-events (map first lst))
                    (asd-events (map third lst)))
              (list api dzn-events asd-events)))
           (delete-duplicates (map second ((asd-interfaces om:out?) (om:interface model))))))
#(map
  (lambda (port)
    (map (define-on model port #{
#return-type  #port _#event (#formals);
#}) (filter om:in? (om:events port))))
  (filter om:provides? (om:ports model)))
};
#(map (lambda (x) (list "}\n")) (om:scope model))
