##ifndef #.INTERFACE _HH
##define #.INTERFACE _HH

##include <dzn/meta.hh>

##include <map>

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
 #(string-if (pair? (om:enums)) #{
#})#(map (declare-enum model) (om:enums))
 #(string-if (pair? (om:enums)) #{
#})
struct #.interface
{
 #(->string (map (declare-enum model) (om:interface-enums model)))
  struct
  {
   #(map (declare-io model
          #{std::function<#type (#formals)> #name;
#}) in-events) } in;

  struct
  {
    #(map (declare-interface-event model) (om:events model om:out?))
  } out;

   dzn::port::meta meta;
#(string-if (eq? (language) 'c++-msvc11) #{
   inline #.interface(dzn::port::meta &&m) : meta(std::move(m)){}
#}
#{
   inline #.interface(dzn::port::meta m) : meta(m) {}
#})

   void check_bindings() const
   {
   #(map (declare-io model
         #{if (! in.#name) throw dzn::binding_error(meta, "in.#name ");
#}) in-events)
   #(map (declare-io model
         #{if (! out.#name) throw dzn::binding_error(meta, "out.#name ");
#}) out-events)
   }
  };

  inline void connect (#.interface & provided, #.interface & required)
  {
    provided.out = required.out;
    required.in = provided.in;
    provided.meta.requires = required.meta.requires;
    required.meta.provides = provided.meta.provides;
  }

#(map (lambda (x) (list "}\n")) (om:scope model))

#(->string (map (enum-to-string model) (om:interface-enums model)))
#(->string (map (enum-to-string model) (om:enums)))
#(->string (map (string-to-enum model) (om:interface-enums model)))
#(->string (map (string-to-enum model) (om:enums)))

##endif // #.INTERFACE _HH
