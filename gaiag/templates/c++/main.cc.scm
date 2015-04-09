
##include "runtime.hh"
##include "locator.hh"

##include "#.model .hh"

##include <iostream>

namespace dezyne
{
  typedef std::map<std::string, std::function<void()>> event_map;

#(map
  (lambda (model)
  (append
   `("void fill_event_map(" ,(.name model) "& m, event_map& e)\n{\nint dzn_i = 0;\n")
   (if (is-a? model <component>)
      (map
       (lambda (port)
       (map (define-on model port #{
          if (not m.#port .#direction .#event) {
            m.#port .#direction .#event  = [] (#parameters) {std::clog << "#port .#direction .#event " << std::endl;#(string-if (not (eq? return-type 'void)) #{ return (#return-type)0;#})};
         }
         if (e.find("#port .#event ") == e.end()) e["#port .#event "] = #(string-if (null? argument-list) #{m.#port .#direction .#event; #} #{ [m,&dzn_i] {m.#port .#direction .#event (#(comma-join (map (lambda (i) "dzn_i") argument-list)));};#})
#}) (gom:events port))) (delete-duplicates (gom:ports model)))
    '())
    '("}\n")))
  (if (is-a? model <component>) (list model) (delete-duplicates (map (lambda (i) (gom:import (.component i))) (.elements (.instances model)))))) }

int main()
{
  dezyne::runtime rt;
  dezyne::locator l;
  l.set(rt);

  dezyne::event_map event_map;
  dezyne::#.model  sut(l);
  sut.dzn_meta.name = "sut";

  #(string-if (is-a? model <component>)
              #{dezyne::fill_event_map(sut, event_map); #}
              (->string
              (map
                (lambda (i)
                   `("dezyne::fill_event_map(sut." ,(.name i) ", event_map);\n")) (.elements (.instances model)))))
  sut.check_bindings();
  sut.dump_tree();

  std::string event;
  while(std::cin >> event) {
    if (event_map.find(event) != event_map.end()) {
      event_map[event]();
    }
  }
}
