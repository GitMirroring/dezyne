##include "#(c++:skel-file model).hh"

##include <dzn/locator.hh>
##include <dzn/runtime.hh>

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
namespace skel {
#.model ::#.model (const dzn::locator& dezyne_locator)
: dzn_meta#(c++:init-brace-open)"","#.model",0,0,{#(comma-join (map (lambda (port) (list "&" (.name port) ".meta")) (filter om:requires? (om:ports model))))},{},{#((->join ",") (map (lambda (port) (list "[this]{"(.name port) ".check_bindings();}")) (om:ports model)))}#(c++:init-brace-close)
, dzn_rt(dezyne_locator.get<dzn::runtime>())
, dzn_locator(dezyne_locator)
, #
((->join  "\n, ")
 (append
  (map (init-member model #{
#name(#(if (not (eq? expression *unspecified*)) expression))#}) (om:variables model))
  (map (lambda (port) (list (.name port) "{" (if (.injected port) (list "dezyne_locator.get<" ((c++:scope-name) (.type port)) ">()") (list "{" (if (eq? (.direction port) 'requires) "{\"\",0,0},") "{\"" (.name port) "\",this,&dzn_meta}" (if (eq? (.direction port) 'provides) ",{\"\",0,0}") "}")) "}")) (om:ports model))))
  {
    //dzn_rt.performs_flush(this) = true; //only turn off when flush is performed explicitly
#
   (map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = [&] (#formals) { return dzn::call_in(this, [&]{return #port _#event (#arguments);}, this->#port .meta, "#event "); };
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = [&] (#formals) { return dzn::call_out(this, [=]{return #port _#event (#arguments);}, this->#port .meta, "#event "); };
#}) (filter om:out? (om:events port))))
    (filter om:requires? (om:ports model)))
}

#.model ::~#.model () {}

void #.model ::check_bindings() const
{
 dzn::check_bindings(&dzn_meta);
}
void #.model ::dump_tree(std::ostream& os) const
{
  dzn::dump_tree(os, &dzn_meta);
}
}
#(map (lambda (x) (list "}\n")) (om:scope model))
