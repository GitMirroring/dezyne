
##include "runtime.hh"
##include "locator.hh"

##include "#.model .hh"

##include <iostream>

namespace dezyne
{
typedef std::map<std::string, std::function<void()>> event_map;

std::string drop_prefix(std::string string, std::string prefix)
{
   auto len = prefix.size();
   if (string.size() >= len && std::equal(prefix.begin(), prefix.begin() + len, string.begin()))
   {
     return string.erase(0, len);
   }
   return string;
}


void fill_event_map(#.model & m, event_map& e)
{
  int dzn_i = 0;
  #(map
    (lambda (port)
    (map (define-on model port #{
      m.#port .#direction .#event  = [] (#parameters) {std::clog << "#port .#direction .#event " << std::endl;#(string-if (not (eq? return-type 'void)) #{std::string s; std::cin >> s; return to_#interface _#reply-name(drop_prefix(s,"#port ."));#})};
#}) (filter (negate (gom:dir-matches? port))
       (gom:events port)))) (gom:ports model))
  #(map
    (lambda (port)
    (map (define-on model port #{
       e["#port .#event "] = #(string-if (null? argument-list) #{m.#port .#direction .#event; #} #{ [m,&dzn_i] {m.#port .#direction .#event (#(comma-join (map (lambda (i) "dzn_i") argument-list)));};#})
#}) (filter (gom:dir-matches? port)
       (gom:events port)))) (gom:ports model)) }
}

int main()
{
  dezyne::runtime rt;
  dezyne::locator l;
  l.set(rt);

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
