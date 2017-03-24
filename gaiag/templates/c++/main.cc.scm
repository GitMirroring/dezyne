##include <dzn/container.hh>

##include "#.scope_model .hh"

##include <algorithm>
##include <cstring>

void
connect_ports (dzn::container<#((om:scope-name (string->symbol "::")) model), std::function<void()>>& c)
{
 #(map (lambda (port)
       (map (define-on model port #{
    c.system.#port .#direction .#event  = [&] (#formals) {
    dzn::trace_#direction(std::clog, c.system.#port .meta, "#event "); std::clog << std::endl;
    #(string-if (eq? direction 'out) #{c.match("#port .#event ");#}
    #{c.match("#port .#event "); std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.#port m.meta, tmp.substr(tmp.rfind('.')+1).c_str()); std::clog << std::endl;
    return to_#((c++:scope-join #f '_) reply-scope)_#reply-name(tmp.substr(tmp.rfind('.')+1)); #})
  };
  #}) (filter (negate (om:dir-matches? port)) (om:events port))))
  (om:ports model))}


std::map<std::string,std::function<void()> >
event_map (dzn::container<#((om:scope-name (string->symbol "::")) model), std::function<void()>>& c)
{
 #(map (init-port #{
     c.system.#name .meta.requires.port = "#name ";
 #}) (filter om:provides? (om:ports model)))
 #(map (init-port #{
     c.system.#name .meta.provides.address = &c;
     c.system.#name .meta.provides.meta = &c.meta;
     c.system.#name .meta.provides.port = "#name ";
 #}) (filter om:requires? (om:ports model)))

  return {{"illegal", []{std::clog << "illegal" << std::endl; std::exit(0);}},
  #((->join "\n  ,")
    (append (map (lambda (port)
       ((->join "\n  ,") (map (define-on model port #{{"#port .#event ",[&]{#(string-if (is-a? type-type <void>)
       #{ #(c++:out-var-decls model formal-objects) c.system.#port .#direction .#event (#(c++:out-param-list model formal-objects));
       #(string-if (eq? direction 'in) #{c.match("#port .return");#}) #}
       #{ #(c++:out-var-decls model formal-objects) c.match("#port ." + to_string(c.system.#port .#direction .#event (#(c++:out-param-list model formal-objects)))); #})}} #})
       (filter (om:dir-matches? port) (om:events port)))))

  (om:ports model))
  (map (init-port (if (not (eq? (glue) 'asd)) #{{"#name .<flush>",[&]{std::clog << "#name .<flush>" << std::endl; c.runtime.flush(&c);}}#}
                                             #{{"#name .<flush>",[&]{std::clog << "#name .<flush>" << std::endl; g_singlethreaded->processCBs();}}#}))
                                             (filter om:requires? (om:ports model)))))
  };
}


int
main(int argc, char* argv[])
{
  if(argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--debug") == 0;})) dzn::debug.rdbuf(std::clog.rdbuf());
  dzn::container<#((om:scope-name (string->symbol "::")) model), std::function<void()>> c(argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--flush") == 0;}));

  connect_ports (c);
  c(event_map (c), {#((->join ",") (map (lambda (port) (list "\"" (.name port) "\"")) (filter om:requires? (om:ports model))))});
}
