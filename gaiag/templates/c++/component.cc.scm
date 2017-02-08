##include "#.scope_model .hh"

##include <dzn/locator.hh>
##include <dzn/runtime.hh>
#(string-if (pair? (om:ports (.behaviour model))) #{
##include <dzn/pump.hh>
#})

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
#.model ::#.model (const dzn::locator& dezyne_locator)
: dzn_meta#(c++:init-brace-open)"","#.model",0,0,{#(comma-join (map (lambda (port) (list "&" (.name port) ".meta")) (filter om:requires? (om:ports model))))},{},{#((->join ",") (map (lambda (port) (list "[this]{"(.name port) ".check_bindings();}")) (om:ports model)))}#(c++:init-brace-close)
, dzn_rt(dezyne_locator.get<dzn::runtime>())
, dzn_locator(dezyne_locator)
, #
((->join  "\n, ")
 (append
  (map (init-member model #{
#name(#(if (not (eq? expression *unspecified*)) expression))#}) (om:variables model))
  (map (define-reply #{reply_#((c++:scope-join #f '_) scope)_#name()#}) (om:reply-enums model))
  (map (lambda (port) (list (.name port) "{" (if (.injected port) (list "dezyne_locator.get<" ((c++:scope-name) (.type port)) ">()") (list "{" (if (eq? (.direction port) 'requires) "{\"\",0,0},") "{\"" (.name port) "\",this,&dzn_meta}" (if (eq? (.direction port) 'provides) ",{\"\",0,0}") "}")) "}")) (append (om:ports model) (om:ports (.behaviour model))))))
{
  dzn_rt.performs_flush(this) = true;
  #(string-if (pair? (om:ports (.behaviour model))) #{dzn::pump& dzn_pump = dzn_locator.get<dzn::pump>();#})
#map:x:call
#map:x:rcall
#map:x:req
#map:x:clr
}

#map:x:on

#((->join "\n  ")(map (define-function model #{
  #scope-return-type  #.model ::#name (#formals)
  {
    #statements }
#}) (om:functions model)))
  void #.model ::check_bindings() const
  {
    dzn::check_bindings(&dzn_meta);
  }
  void #.model ::dump_tree(std::ostream& os) const
  {
    dzn::dump_tree(os, &dzn_meta);
  }
#(map (lambda (x) (list "}\n")) (om:scope model))
