##ifndef #.COMPONENT _HH
##define #.COMPONENT _HH

#(map (include-interface #{
##include "#interface .hh"
#}) (delete-duplicates (om:ports model) (lambda (x y) (eq? (.type x) (.type y)))))

##include <dzn/meta.hh>
##include <dzn/runtime.hh>

namespace dzn {
struct locator;
struct runtime;
}

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
struct #.model
{
    dzn::meta dzn_meta;
    dzn::runtime& dzn_rt;
    dzn::locator const& dzn_locator;
    #(->string (map (declare-enum model) (om:enums (.behaviour model))))#
;;    (->string (map declare-integer (om:integers (.behaviour model))))#
    (map (init-member model #{
#type  #name;
#}) (om:variables model))#
    (delete-duplicates (map (compose declare-replies .type) ((compose .elements .ports) model)))#
    (map (init-port #{
    boost::function<void ()> out_#name;
#}) (filter om:provides? (om:ports model)))#
    (map (init-port #{
#((c++:scope-join model) interface)  #name ;
#}) ((compose .elements .ports) model))#
    (map (init-async-port model #{
dzn::async<#type  (#formal-types)> #name ;
#}) (om:ports (.behaviour model)))
    #.model (const dzn::locator&);
  void check_bindings() const;
  void dump_tree() const;
private:
#(map
  (lambda (port)
    (map (define-on model port #{
#return-type  #port _#event (#formals);
#}) (filter om:in? (om:events port))))
  (filter om:provides? (om:ports model)))#
(map
  (lambda (port)
    (map (define-on model port #{
#return-type  #port _#event (#formals);
#}) (filter om:out? (om:events port))))
  (filter om:requires? (append (om:ports model) (om:ports (.behaviour model)))))#
(map (define-function model #{
  #return-type  #name (#formals);
#}) (om:functions model)) };
#(map (lambda (x) (list "}\n")) (om:scope model))
##endif // #.COMPONENT _HH
