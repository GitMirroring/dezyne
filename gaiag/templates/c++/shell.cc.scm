##include "#.scope_model .hh"

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
#.model ::#.model (const dezyne::locator& locator)
: #((->join "\n, ")
    (append
            (list
             (->string
              (list
               "dzn_meta" (c++:init-brace-open) "\"\",\"" .model "\",0,{"
               ((->join ",")
                (map (init-instance #{&#name .dzn_meta#})
                     (non-injected-instances model)))
               "},{}" (c++:init-brace-close))))
            (list "dzn_locator(locator.clone().set(dzn_runtime).set(dzn_pump))")
            (map (init-instance #{ #name (dzn_locator)#})
                 (non-injected-instances model))
            (map (init-bind model #{ #port(#instance)#})
                 (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
            (list "dzn_pump()")
            ))
{
#(map
 (lambda (port)
   (map (define-on model port #{
#port .#direction .#event  = [&] (#formals) {
    return dezyne::#(string-if (eq? return-type 'void) #{shell#}#{valued_shell<#return-type >#})(dzn_pump, [&] {return #instance .#instance-port .in.#event(#arguments);});
};
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = [&] (#formals) {
    return dezyne::shell(dzn_pump, [&] {return #instance .#instance-port .out.#event(#arguments);});
};
#}) (filter om:out? (om:events port))))
    (filter om:requires? (om:ports model)))#
(map
 (lambda (port)
   (map (define-on model port #{
    #instance .#instance-port .out.#event  = std::ref(#port .out.#event);
#}) (filter om:out? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
    (lambda (port)
      (map (define-on model port #{
    #instance .#instance-port .in.#event  = std::ref(#port .in.#event);
#}) (filter om:in? (om:events port))))
    (filter om:requires? (om:ports model)))

 #(map (init-instance #{#name .dzn_meta.parent = &dzn_meta;
    #name .dzn_meta.name = "#name ";
#})
       (non-injected-instances model))#
 (map (connect-ports model #{
    connect(#provided , #required );
#}) (filter (negate bind-port?) ((compose .elements .bindings) model))) }

  void #.model ::check_bindings() const
  {
    dezyne::check_bindings(&dzn_meta);
  }
  void #.model ::dump_tree(std::ostream& os) const
  {
    dezyne::dump_tree(os, &dzn_meta);
  }
#(map (lambda (x) (list "}\n")) (om:scope model))
