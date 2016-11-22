##ifndef #.COMPONENT _HH
##define #.COMPONENT _HH

##include <iostream>

#(map (include-interface #{
##include "#interface .hh"
#}) (delete-duplicates (append (om:ports model) (om:ports (.behaviour model))) (lambda (x y) (equal? (.type x) (.type y)))))

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
    #(map (declare-enum model) (om:enums (.behaviour model)))#
    (map (init-member model #{
#type  #name;
#}) (om:variables model))#
    (delete-duplicates (append-map (compose declare-replies code:import .type) ((compose .elements .ports) model)) equal?)#
    (map (init-port #{
    std::function<void ()> out_#name;
#}) (filter om:provides? (om:ports model)))#
    (map (init-port #{
#((c++:scope-join model) interface)  #name ;
#}) (append (om:ports model) (om:ports (.behaviour model))))
    #.model (const dzn::locator&);
  void check_bindings() const;
  void dump_tree(std::ostream& os) const;
  friend std::ostream& operator << (std::ostream& os, const #.model & m) {
    return os << "[" #(map (lambda (v s) (string-append ((init-member model #{ << m.#name #}) v) s))
     (om:variables model) (cdr (append (make-list (length (om:variables model)) " << \",\" ") (list ""))))  << "]" ;
  }
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
