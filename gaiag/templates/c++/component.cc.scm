##include "#.model .hh"

##include "locator.hh"
##include "runtime.hh"

##include <iostream>

namespace dezyne
{
#.model ::#.model (const locator& dezyne_locator)
: dzn_meta{"","#.model",reinterpret_cast<const component*>(this),0,{},{#((->join ",") (map (lambda (port) (list "[this]{" (.name port) ".check_bindings();}")) (om:ports model)))}}
, dzn_rt(dezyne_locator.get<runtime>())
, dzn_locator(dezyne_locator)
, #
((->join  "\n, ")
 (map (init-member model #{
#name(#(if (not (eq? expression *unspecified*)) expression))#}) (om:variables model)))#
(if (null? (om:variables model)) "" "\n, ") #
((->join  "\n, ") (map (lambda (port) (list (.name port) "{" (if (.injected port) (list "dezyne_locator.get<" (.type port) ">()") (list "{" (if (eq? (.direction port) 'requires) "{\"\",0},") "{\"" (.name port) "\",this}" (if (eq? (.direction port) 'provides) ",{\"\",0}") "}")) "}")) (om:ports model)))
  {
    dzn_rt.performs_flush(this) = true;
#
   (map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = [&] (#formals) {
    #(if (eq? return-type 'void) "" "return ")call_in(this, #(string-if (and (eq? return-type 'void) (null? argument-list)) #{ [this] {#port _#event();}#} #{std::function<#return-type ()>([&] {#(if (eq? return-type 'void) "" "return ")#port _#event (#arguments);})#}), std::make_tuple(&#port , "#event ", "return"));
};
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = [&] (#formals) {
    call_out(this, #(string-if (null? argument-list) #{[this] {#port _#event();}#} #{ std::function<void()>([&#comma #arguments] {this->#port _#event (#arguments);}) #}), std::make_tuple(&#port , "#event ", "return"));
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
#{  return reply_#(*scope* reply-scope)_#reply-name ;
#}) }

#}) (filter (om:dir-matches? port) (om:events port))))
  (om:ports model))#
((->join "\n  ")(map (define-function model #{
  #return-type  #.model ::#name (#formals)
  {
    #statements }
#}) (om:functions model)))
  void #.model ::check_bindings() const
  {
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void #.model ::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
}
