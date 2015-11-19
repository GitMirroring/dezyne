##include "#.scope_model .hh"

##include "locator.hh"
##include "runtime.hh"

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
#.model ::#.model (const dezyne::locator& dezyne_locator)
: dzn_meta#(c++:init-brace-open)"","#.model",0,{},{#((->join ",") (map (lambda (port) (list "[this]{" (.name port) ".check_bindings();}")) (om:ports model)))}#(c++:init-brace-close)
, dzn_rt(dezyne_locator.get<dezyne::runtime>())
, dzn_locator(dezyne_locator)
, #
((->join  "\n, ")
 (map (init-member model #{
#name(#(if (not (eq? expression *unspecified*)) expression))#}) (om:variables model)))#
(if (null? (om:variables model)) "" "\n, ") #
((->join  "\n, ") (map (lambda (port) (list (.name port) "{" (if (.injected port) (list "dezyne_locator.get<" ((c++:scope-name) (.type port)) ">()") (list "{" (if (eq? (.direction port) 'requires) "{\"\",0,0},") "{\"" (.name port) "\",this,&dzn_meta}" (if (eq? (.direction port) 'provides) ",{\"\",0,0}") "}")) "}")) (om:ports model)))
  {
    dzn_rt.performs_flush(this) = true;
#
   (map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = [&] (#formals) {
    #(if (eq? return-type 'void) "" "return ")dezyne::call_in(this, #(string-if (and (eq? return-type 'void) (null? argument-list)) #{ [this] {#port _#event();}#} #{std::function<#return-type ()>([&] {#(if (eq? return-type 'void) "" "return ")#port _#event (#arguments);})#}), std::make_tuple(&#port , "#event ", "return"));
};
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = [&] (#formals) {
    dezyne::call_out(this, #(string-if (null? argument-list) #{[this] {#port _#event();}#} #{ std::function<void()>([&#comma #arguments] {this->#port _#event (#arguments);}) #}), std::make_tuple(&#port , "#event ", "return"));
};
#}) (filter om:out? (om:events port))))
    (filter om:requires? (om:ports model)))
}

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
  (om:ports model))#
((->join "\n  ")(map (define-function model #{
  #scope-return-type  #.model ::#name (#formals)
  {
    #statements }
#}) (om:functions model)))
  void #.model ::check_bindings() const
  {
    dezyne::check_bindings(&dzn_meta);
  }
  void #.model ::dump_tree(std::ostream& os) const
  {
    dezyne::dump_tree(dzn_locator.get<typename std::ostream>(), &dzn_meta);
  }
#(map (lambda (x) (list "}\n")) (om:scope model))
