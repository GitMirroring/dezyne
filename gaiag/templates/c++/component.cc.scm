##include "#.model .hh"

##include "locator.hh"
##include "runtime.hh"

##include <iostream>

namespace dezyne
{
#.model ::#.model (const locator& dezyne_locator)
: rt(dezyne_locator.get<runtime>())
, #
((->join  "\n, ")
 (map (init-member model #{
#name(#(if (not (eq? expression *unspecified*)) expression))#}) (gom:variables model)))#
(if (null? (gom:variables model)) "" "\n, ") #
((->join  "\n, ") (map (lambda (port) (list (.name port) "(" (if (.injected port) (list "dezyne_locator.get<" (.type port) ">()")) ")")) (gom:ports model)))
  {
#
   (map
    (lambda (port)
      (->string
       (list
        (.name port) ".in.meta.component = \"" .model "\";\n"
        (.name port) ".in.meta.port = \"" (.name port) "\";\n"
        (.name port) ".in.meta.address = this;\n"
        )))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (->string
       (list
        (.name port) ".out.meta.component = \"" .model "\";\n"
        (.name port) ".out.meta.port = \"" (.name port) "\";\n"
        (.name port) ".out.meta.address = this;\n"
        )))
    (filter gom:requires? (gom:ports model)))
#
   (map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = [&] (#parameters) {
    #(if (eq? return-type 'void) "" "return ")call_in(this, std::function<#return-type ()>([&] {#(if (eq? return-type 'void) "" "return ")this->#port _#event (#arguments); }), std::make_tuple(&#port , "#event ", "return"));
};
#}) (filter gom:in? (gom:events port))))
    (filter gom:provides? (gom:ports model)))#
(map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = [&] (#parameters) {
    call_out(this, std::function<#return-type ()>([&#comma #arguments] {this->#port _#event (#arguments); }), std::make_tuple(&#port , "#event ", "return"));
};
#}) (filter gom:out? (gom:events port))))
    (filter gom:requires? (gom:ports model))) }

#(map
  (lambda (port)
    (map (define-on model port #{
  #return-type  #.model ::#port _#event (#parameters)
  {
    #statement #
    (if (not (eq? type 'void))
(list "    return reply_" reply-type "_" reply-name ";\n"
      )) }

#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))#
((->join "\n  ")(map (define-function model #{
  #return-type  #.model ::#name (#parameters)
  {
    #statements }
#}) (gom:functions model)))
}
