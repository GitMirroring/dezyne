##include "#.scope_model .hh"

##include "locator.hh"
##include "runtime.hh"

##include <iostream>

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
#.model ::#.model (const dezyne::locator& dezyne_locator)
: dzn_meta("","#.model",reinterpret_cast<const dezyne::component*>(this),0)
, dzn_rt(dezyne_locator.get<dezyne::runtime>())
, dzn_locator(dezyne_locator)
, #
((->join  "\n, ")
 (map (init-member model #{
#name(#(if (not (eq? expression *unspecified*)) expression))#}) (om:variables model)))#
(if (null? (om:variables model)) "" "\n, ") #
((->join  "\n, ") (map (lambda (port) (list (.name port) "()")) (om:ports model)))
{
#((->join "\n") (map (lambda (port) (list "dzn_meta.ports_connected.push_back(boost::function<void()>(boost::bind(&" ((om:scope-name) (.type port)) "::check_bindings,&" (.name port) ")));"))
                      (om:ports model)))

#(map (init-port #{#name .meta.provides.port = "#name ";
                   #name .meta.provides.address = this;
                   #}) (filter om:provides? ((compose .elements .ports) model)))

#(map (init-port #{#name .meta.requires.port = "#name ";
                   #name .meta.requires.address = this;
                   #}) (filter om:requires? ((compose .elements .ports) model)))

dzn_rt.performs_flush(this) = true;
#
   (map
    (lambda (port)
      (map (define-on model port #{#port .#direction .#event  = boost::bind(&#(string-if (eq? return-type 'void) "dezyne::call_in< " #{dezyne::rcall_in< #((om:scope-join #f) reply-scope) ::#reply-name ::type, #})#.model ,#((om:scope-name "::") interface) #comma #((->join ",") formal-types)>,this,boost::function< #return-type(#((->join ",") formal-types))>(boost::bind(&#.model ::#port _#event ,this#comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list))))))#comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list)))),boost::make_tuple(&#port , "#event ", "return"));
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = boost::bind(&dezyne::call_out<#.model , #((om:scope-name "::") interface) #comma #((->join ",") formal-types)>, this, boost::function< #return-type(#((->join ",") formal-types))>(boost::bind(&#.model ::#port _#event , this #comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list))))))#comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list)))), boost::make_tuple(&#port , "#event ", "return"));
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
#{  return reply_#((om:scope-join #f) reply-scope)_#reply-name ;
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
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void #.model ::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
#(map (lambda (x) (list "}\n")) (om:scope model))
