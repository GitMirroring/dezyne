##include "#.model .hh"

##include "locator.hh"
##include "runtime.hh"

##include <iostream>

namespace dezyne
{
#.model ::#.model (const locator& dezyne_locator)
: dzn_meta{"","#.model",reinterpret_cast<const component*>(this),0,{},{#((->join ",") (map (lambda (port) (list "[this]{" (.name port) ".check_bindings();}")) (gom:ports model)))}}
, dzn_rt(dezyne_locator.get<runtime>())
, dzn_locator(dezyne_locator)
, #
((->join  "\n, ")
 (map (init-member model #{
#name(#(if (not (eq? expression *unspecified*)) expression))#}) (gom:variables model)))#
(if (null? (gom:variables model)) "" "\n, ") #
((->join  "\n, ") (map (lambda (port) (list (.name port) "(" (if (.injected port) (list "dezyne_locator.get<" (.type port) ">()") (list "{" (if (eq? (.direction port) 'requires) "{\"\",0},") "{\"" (.name port) "\",this}" (if (eq? (.direction port) 'provides) ",{\"\",0}") "}")) ")")) (gom:ports model)))
  {
    dzn_rt.performs_flush(this) = true; 
#
   (map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = [&] (#parameters) {
    #(if (eq? return-type 'void) "" "return ")call_in(this, #(string-if (and (eq? return-type 'void) (null? argument-list)) #{ [this] {#port _#event();}#} #{std::function<#return-type ()>([&] {#(if (eq? return-type 'void) "" "return ")#port _#event (#arguments);})#}), std::make_tuple(&#port , "#event ", "return"));
};
#}) (filter gom:in? (gom:events port))))
    (filter gom:provides? (gom:ports model)))#
(map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = [&] (#parameters) {
    call_out(this, #(string-if (null? argument-list) #{[this] {#port _#event();}#} #{ std::function<void()>([&#comma #arguments] {this->#port _#event (#arguments);}) #}), std::make_tuple(&#port , "#event ", "return"));
};
#}) (filter gom:out? (gom:events port))))
    (filter gom:requires? (gom:ports model)))
}

#(map
  (lambda (port)
    (map (define-on model port #{
  #return-type  #.model ::#port _#event (#parameters)
  {
    #statement #
    (string-if (not (eq? type 'void))
#{  return reply_#(*scope* reply-scope)_#reply-name ;
#}) }

#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))#
((->join "\n  ")(map (define-function model #{
  #return-type  #.model ::#name (#parameters)
  {
    #statements }
#}) (gom:functions model)))
  void #.model ::check_bindings() const
  {
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void #.model ::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
}
