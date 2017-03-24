##include "#(c++:skel-file model).hh"

##include <dzn/locator.hh>
##include <dzn/runtime.hh>

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
namespace skel {
#.model ::#.model (const dzn::locator& dezyne_locator)
: dzn_meta("","#.model",0)
, dzn_rt(dezyne_locator.get<dzn::runtime>())
, #
((->join  "\n, ")
 (append
  (list "dzn_locator(dezyne_locator)")
  (map (init-member model #{
#name(#(if (not (eq? expression *unspecified*)) expression))#}) (om:variables model))))
{
 #(map (init-port #{#name .meta.provides.port = "#name ";
                   #name .meta.provides.address = this;
                   #name .meta.provides.meta = &this->dzn_meta;
                   #}) (filter om:provides? ((compose .elements .ports) model)))

 #(map (init-port #{#name .meta.requires.port = "#name ";
                   #name .meta.requires.address = this;
                   #name .meta.requires.meta = &this->dzn_meta;
                   #}) (filter om:requires? ((compose .elements .ports) model)))

   //dzn_rt.performs_flush(this) = true; //only turn off when flush is performed explicitly
#
   (map
    (lambda (port)
      (map (define-on model port #{#port .#direction .#event  = boost::bind(&#(string-if (is-a? type-type <void>) "dzn::call_in< " #{dzn::rcall_in< #(if (not (member reply-name '(void int bool))) (list ((om:scope-join model "::") reply-scope) "::" reply-name "::type") reply-name), #})#.model ,::#((c++:scope-name) interface) #comma #((->join ",") formal-types)>,this,boost::function< #return-type(#((->join ",") formal-types))>(boost::bind(&#.model ::#port _#event ,this#comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list))))))#comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list)))),boost::make_tuple(&#port , "#event ", "return"));
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = boost::bind(&dzn::call_out<#.model , #((c++:scope-name) interface) #comma #((->join ",") formal-types)>, this, boost::function< #return-type(#((->join ",") formal-types))>(boost::bind(&#.model ::#port _#event , this #comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list))))))#comma #((->join ",") (map (lambda (x) (->string '_ (+ 1 x))) (iota (length formal-list)))), boost::make_tuple(&#port , "#event ", "return"));
#}) (filter om:out? (om:events port))))
    (filter om:requires? (om:ports model)))
}

#.model ::~#.model () {}
}
#(map (lambda (x) (list "}\n")) (om:scope model))
