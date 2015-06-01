
##include "runtime.hh"
##include "locator.hh"

##include "#.model .hh"

##include <iostream>

namespace dezyne
{
typedef std::map<std::string, boost::function<void()> > event_map;

  void log_in(std::string prefix, std::string event)
  {
    std::clog << prefix << event << std::endl;
    std::clog << prefix << "return" << std::endl;
  }

  void log_out(std::string prefix, std::string event)
  {
    std::clog << prefix << event << std::endl;
  }

  template <typename R>
  R get_value(const std::string& prefix, R (*string_to_value)(std::string))
  {
    std::string s;
    while (std::cin >> s)
    {
      R r = string_to_value(s.erase(std::min(s.size(), s.find(prefix)), prefix.size()));
      if (static_cast<int>(r) != -1) return r;
    }
    throw std::runtime_error("\"" + s + "\" is not a reply value");
  }

  template <typename R>
  R log_valued(std::string prefix, std::string event, R (*string_to_value)(std::string), const char* (*value_to_string)(R))
  {
    std::clog << prefix << event << std::endl;
    R r = get_value(prefix, string_to_value);
    std::clog << prefix << value_to_string(r) << std::endl;
    return r;
  }

  void fill_event_map(#.model & m, event_map& e)
  {
    int dzn_i = 0;

 #(map
   (lambda (port)
     (map (define-on model port #{m.#port .#direction .#event  = boost::bind(#(string-if (eq? return-type 'void) #{&log_#direction , "#port .", "#event "#}
                                                                                                                 #{&log_valued<#(*scope* reply-scope)::#reply-name ::type>, "#port .", "#event ", to_#(*scope* reply-scope)_#reply-name , static_cast<const char*(*)(#(*scope* reply-scope)::#reply-name ::type)>(to_string)#}));
     #}) (filter (negate (om:dir-matches? port)) (om:events port)))) (om:ports model))
  #(map
    (lambda (port)
    (map (define-on model port #{
       e["#port .#event "] = #(string-if (null? argument-list) #{m.#port .#direction .#event; #} #{ boost::bind(m.#port .#direction .#event , #(comma-join (map (lambda (i) "dzn_i") argument-list))); #})
#}) (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model)) }
  }

void illegal_handler()
{
  std::clog << "illegal" << std::endl;
  exit(0);
}

int main()
{
  dezyne::locator l;
  dezyne::runtime rt;
  l.set(rt);

  dezyne::illegal_handler ih;
  ih.illegal = illegal_handler;
  l.set(ih);

  dezyne::event_map event_map;
  dezyne::#.model  sut(l);
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
