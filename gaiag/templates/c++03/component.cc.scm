##include "#.scope_model .hh"

##include <dzn/locator.hh>
##include <dzn/runtime.hh>

##include <iostream>

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
#.model ::#.model (const dzn::locator& dezyne_locator)
: dzn_meta("","#.model",0)
, dzn_rt(dezyne_locator.get<dzn::runtime>())
, dzn_locator(dezyne_locator)
, #
((->join  "\n, ")
 (map (init-member model #{
#name(#(if (not (eq? expression *unspecified*)) expression))#}) (om:variables model)))#
(if (null? (om:variables model)) "" "\n, ") #
((->join  "\n, ") (map (lambda (port) (list (.name port) (if (.injected port) (list "(dezyne_locator.get<" ((c++:scope-name) (.type port)) ">())") "()"))) (om:ports model)))
{
#((->join "\n") (map (lambda (port) (list "dzn_meta.ports_connected.push_back(boost::function<void()>(boost::bind(&::" ((c++:scope-name) (.type port)) "::check_bindings,&" (.name port) ")));"))
                      (om:ports model)))

#(map (init-port #{#name .meta.provides.port = "#name ";
                   #name .meta.provides.address = this;
                   #name .meta.provides.meta = &this->dzn_meta;
                   #}) (filter om:provides? ((compose .elements .ports) model)))

#(map (init-port #{#name .meta.requires.port = "#name ";
                   #name .meta.requires.address = this;
                   #name .meta.requires.meta = &this->dzn_meta;
                   #}) (filter om:requires? ((compose .elements .ports) model)))

dzn_rt.performs_flush(this) = true;
#
   (map
    (lambda (port)
      (map (define-on model port #{#port .#direction .#event  = boost::bind(&#(string-if (eq? return-type 'void) "dzn::call_in< " #{dzn::rcall_in< #(if (not (member reply-name '(void int bool))) (list ((om:scope-join model "::") reply-scope) "::" reply-name "::type") reply-name), #})#.model ,::#((c++:scope-name) interface) #comma #((->join ",") formal-types)>,this,boost::function< #return-type(#((->join ",") formal-types))>(boost::bind(&#.model ::#port _#event ,this#comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list))))))#comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list)))),boost::make_tuple(&#port , "#event ", "return"));
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = boost::bind(&dzn::call_out<#.model , ::#((c++:scope-name) interface) #comma #((->join ",") formal-types)>, this, boost::function< #return-type(#((->join ",") formal-types))>(boost::bind(&#.model ::#port _#event , this #comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list))))))#comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list)))), boost::make_tuple(&#port , "#event ", "return"));
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
    dzn::check_bindings(&dzn_meta);
  }
  void #.model ::dump_tree() const
  {
    dzn::dump_tree(&dzn_meta);
  }
#(map (lambda (x) (list "}\n")) (om:scope model))
