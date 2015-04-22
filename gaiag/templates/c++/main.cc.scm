
##include "runtime.hh"
##include "locator.hh"

##include "#.model .hh"

##include <iostream>

namespace dezyne
{

int config(std::string)
{
  return 0;                          
}

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
  R get_value(std::function<R(std::string)> string_to_value)
  {
    std::string s;
    while (std::cin >> s)
      {
        R r = string_to_value(s);
        if ((int)r != -1)
          {
            return r;
          }
      }
    exit(0);
    return (R)0;
  }
  
  template <typename R>
  R log_valued(std::string prefix, std::string event, std::function<R(std::string)> string_to_value, std::function<std::string(R)> value_to_string)
  {
    std::clog << prefix << event << std::endl;
    R r = get_value(string_to_value);
    if ((int)r != -1)
    {
      std::clog << prefix << value_to_string(r) << std::endl;
      return r;
    }
    return (R)0;
  }
               
void fill_event_map(#.model & m, event_map& e)
{
  int dzn_i = 0;
  #(map
    (lambda (port)
    (map (define-on model port #{
      m.#port .#direction .#event  = [] (#parameters) {#(string-if (eq? return-type 'void) #{log_#direction("#port .#direction .", "#event ");#}#{return log_valued("#port .#direction .", "#event ", (std::function<#reply-type #(if reply-type "::")#reply-name ::type(std::string)>)([](std::string s) {return (#reply-type #(if reply-type "::")#reply-name ::type)to_#reply-type #(if reply-type '_)#reply-name(drop_prefix(s,"#port ."));}), (std::function<std::string(#reply-type #(if reply-type "::")#reply-name ::type)>)([](#reply-type #(if reply-type "::")#reply-name ::type r) {return (std::string)to_string(r);}));#})};
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
  dezyne::locator l;
  dezyne::runtime rt;
  l.set(rt);
  dezyne::illegal_handler ih;
  ih.illegal = [] {std::clog << "illegal" << std::endl;exit(0);};
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
