
##include "runtime.hh"
##include "locator.hh"

##include "#.scope_model .hh"

##include <iostream>

namespace dezyne
{
  static bool relaxed = false;
  typedef std::map<std::string, std::function<void()>> event_map;

  std::string consume_synchronous_out_events(event_map& event_map)
  {
    std::string s;
    std::cin >> s;
    while (std::cin >> s)
    {
      if (event_map.find(s) == event_map.end()) break;
      event_map[s]();
    }
    return s;
  }

  void log_in(std::string prefix, std::string event, event_map& event_map)
  {
    std::clog << prefix << event << std::endl;
    if (relaxed) return;
    consume_synchronous_out_events(event_map);
    std::clog << prefix << "return" << std::endl;
  }

  void log_out(std::string prefix, std::string event, event_map& event_map)
  {
    std::clog << prefix << event << std::endl;
  }

  template <typename R>
  R log_valued(std::string prefix, std::string event, event_map& event_map, R (*string_to_value)(std::string), const char* (*value_to_string)(R))
  {
    std::clog << prefix << event << std::endl;
    if (relaxed) return (R)0;
    std::string s = consume_synchronous_out_events(event_map);

    R r = string_to_value(s.erase(std::min(s.size(), s.find(prefix)), prefix.size()));
    if (static_cast<int>(r) != -1)
    {
      std::clog << prefix << value_to_string(r) << std::endl;
      return r;
    }
    throw std::runtime_error("\"" + s + "\" is not a reply value");
  }

  void fill_event_map(#((om:scope-name (string->symbol "::")) model) & m, event_map& e)
  {
    int dzn_i = 0;

 #(map
   (lambda (port)
     (map (define-on model port #{m.#port .#direction .#event  = [&] (#formals) {#(string-if (eq? return-type 'void) #{log_#direction("#port .", "#event ", e);#}
                                                                                                                 #{return log_valued<#((c++:scope-join #f) reply-scope)::#reply-name ::type>("#port .", "#event ", e, to_#((c++:scope-join #f) reply-scope)_#reply-name , static_cast<const char*(*)(#((c++:scope-join #f) reply-scope)::#reply-name ::type)>(to_string));#})};
     #}) (filter (negate (om:dir-matches? port)) (om:events port)))) (om:ports model))
 #(map
    (lambda (port)
    (map (define-on model port #{
       e["#port .#event "] = #(string-if (null? argument-list) #{m.#port .#direction .#event; #} #{ [&] {m.#port .#direction .#event (#(comma-join (map (lambda (i) "dzn_i") argument-list)));};#})
#}) (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model)) }
}

int main()
{
  dezyne::locator l;
  dezyne::runtime rt;
  l.set(rt);
  dezyne::illegal_handler ih;
  ih.illegal = [] {std::clog << "illegal" << std::endl; exit(0);};
  l.set(ih);

  dezyne::event_map event_map;
  #((om:scope-name (string->symbol "::")) model)  sut(l);
  sut.dzn_meta.name = "sut";

  dezyne::fill_event_map(sut, event_map);

  sut.check_bindings();
  sut.dump_tree();

  std::string event;
  while(std::cin >> event) {
    if (event_map.find(event) != event_map.end()) {
      event_map[event]();
    }
  }
}
