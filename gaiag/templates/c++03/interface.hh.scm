##ifndef #.INTERFACE _HH
##define #.INTERFACE _HH

##include <dzn/meta.hh>

##include <cassert>
##include <map>

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
 #(string-if (pair? (om:enums)) #{
#})#
  (->string (map (declare-enum model) (om:enums)))
 #(string-if (pair? (om:enums)) #{
#})
struct #.interface
{
 #(->string (map (declare-enum model) (om:interface-enums model)))
  struct
  {
   #(map (declare-io model
          #{boost::function<#type  (#formals)> #name ;
#}) (filter om:in? ((compose .elements .events) model))) } in;

  struct
  {
   #(map (declare-io model
          #{boost::function<#type  (#formals)> #name ;
#}) (filter om:out? ((compose .elements .events) model))) } out;

   dzn::port::meta meta;

   void check_bindings() const
   {
   #(map (declare-io model
         #{if (! in.#name) throw dzn::binding_error(meta, "in.#name");
#}) (filter om:in? ((compose .elements .events) model)))
   #(map (declare-io model
         #{if (! out.#name) throw dzn::binding_error(meta, "out.#name");
#}) (filter om:out? ((compose .elements .events) model)))
   }
  };

  inline void connect (#.interface & provided, #.interface & required)
  {
     provided.out = required.out;
     required.in = provided.in;
     provided.meta.requires = required.meta.requires;
     required.meta.provides = provided.meta.provides;
   }
   #(->string (map (enum-to-string model) (om:interface-enums model)))
   #(->string (map (enum-to-string model) (om:enums)))
   #(->string (map (string-to-enum model) (om:interface-enums model)))
   #(->string (map (string-to-enum model) (om:enums)))
#(map (lambda (x) (list "}\n")) (om:scope model))
##endif // #.INTERFACE _HH
