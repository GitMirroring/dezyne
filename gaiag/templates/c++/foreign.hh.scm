##ifndef SKEL_#.COMPONENT _HH
##define SKEL_#.COMPONENT _HH

#(map (include-interface #{
##include "#interface .hh" #})
  (delete-duplicates (om:ports model) (lambda (x y) (eq? (.type x) (.type y)))))

namespace dzn {
struct locator;
struct runtime;
}#
(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
namespace skel {
struct #.model
{
    dzn::meta dzn_meta;
    dzn::runtime& dzn_rt;
    dzn::locator const& dzn_locator;
    #
    (map (init-port #{
#((c++:scope-join model) interface)  #name ;
#}) ((compose .elements .ports) model))
    #.model (const dzn::locator&);
    virtual ~#.model ();

    void check_bindings() const;
    void dump_tree(std::ostream& os) const;
private:
#(map
  (lambda (port)
    (map (define-on model port #{
virtual #return-type  #port _#event (#formals) = 0;
#}) (filter om:in? (om:events port))))
  (filter om:provides? (om:ports model)))#
(map
  (lambda (port)
    (map (define-on model port #{
virtual #return-type  #port _#event (#formals) = 0;
#}) (filter om:out? (om:events port))))
  (filter om:requires? (om:ports model)))};
}#
(map (lambda (x) (list "}\n")) (om:scope model))
##endif // SKEL_#.COMPONENT _HH
