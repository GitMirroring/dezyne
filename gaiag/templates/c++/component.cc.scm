##include "#.scope_model .hh"

##include <dzn/locator.hh>
##include <dzn/runtime.hh>
#(string-if (pair? (om:ports (.behaviour model))) #{
##include <dzn/pump.hh>
#})

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
#.model ::#.model (const dzn::locator& dezyne_locator)
: dzn_meta#(c++:init-brace-open)"","#.model",0,{},{#((->join ",") (map (lambda (port) (list "[this]{"(.name port) ".check_bindings();}")) (om:ports model)))}#(c++:init-brace-close)
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
    (filter om:requires? (append (om:ports model) (om:ports (.behaviour model)))))#
(string-if (pair? (om:ports (.behaviour model))) #{
    dzn::pump& dzn_pump = dzn_locator.get<dzn::pump>();
#})#
(map
    (lambda (port)
      (map (define-on model port #{
#(string-if (eq? event 'req) #{
#port .#direction .#event  = [&] (#formals) {dzn_pump.handle(reinterpret_cast<size_t>(&#port), 0, [=] {#port _ack(#arguments);});}; #})#
(string-if (eq? event 'clr) #{
#port .#direction .#event  = [&] (#formals) {dzn_pump.remove(reinterpret_cast<size_t>(&#port));}; #})
#}) (filter om:in? (om:events port))))
    (om:ports (.behaviour model)))}

#(map
  (lambda (port)
    (map (define-on model port #{
  #return-type  #.model ::#port _#event (#formals)
  {
    #statement #
    (string-if (not (eq? type 'void))
#{  return this->reply_#((c++:scope-join #f '_) reply-scope)_#reply-name ;
#}) }

#}) (filter (om:dir-matches? port) (om:events port))))
  (append (om:ports model) (om:ports (.behaviour model))))#
((->join "\n  ")(map (define-function model #{
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
