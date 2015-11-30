
##include "runtime.hh"
##include "locator.hh"

##include "#.scope_model .hh"

##include <unistd.h>

##include <iostream>

//##define SHELL 1

namespace dezyne
{
  static bool flush = false;
  static bool relaxed = false;
  typedef std::map<std::string, std::function<void()>> event_map;

  bool prefix_p(std::string s, std::string prefix) {
    return std::equal(prefix.begin(), prefix.end(), s.begin());
  }

  void match_event(std::string match, int line=__LINE__)
  {
    std::string s;
    std::cin >> s;
    if (s==match) return;
    throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(line) + ": invalid event; expected: `" + match + "', found: `" + s + "'");
  }

  std::string get_return(dezyne::pump& pump, std::string prefix, std::string event, event_map& event_map, bool value=false)
  {
    std::string s;
    std::string match = prefix + event;
    while(std::cin >> s) {
      if (s == match
          || (value
              && event_map.find(s) == event_map.end()
              && prefix_p(s, prefix)))
        return s;
      if (event_map.find(s) == event_map.end()
          && !relaxed)
      throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": no such event: `" + s + "'");
      if (!prefix_p(s, prefix))
      throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": wrong port; found: `" + s + ", expected: " + prefix);
      event_map[s]();
    }
    throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": invalid event; expected: `" + match + "', found: `" + s + "'");
  }

  void call_in(dezyne::pump& pump, std::string prefix, std::string event, event_map& event_map)
  {
    std::clog << prefix << event << std::endl;
    if (relaxed) return;
    match_event(prefix + event, __LINE__);
    get_return(pump, prefix, "return", event_map);
    std::clog << prefix << "return" << std::endl;
  }

  template <typename R>
  R call_valued(dezyne::pump& pump, std::string prefix, std::string event, event_map& event_map, R (*string_to_value)(std::string), const char* (*value_to_string)(R))
  {
    std::clog << prefix << event << std::endl;
    if (relaxed) return (R)0;
    match_event(prefix + event, __LINE__);
    std::string s = get_return(pump, prefix, "", event_map, true);
    R r = string_to_value(s.erase(std::min(s.size(), s.find(prefix)), prefix.size()));
    if (static_cast<int>(r) != -1)
    {
      std::clog << prefix << value_to_string(r) << std::endl;
      return r;
    }
    throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": not a reply value: `" + s + "', expected: `" + prefix + "*'");
  }

  void call_out(dezyne::pump&, std::string prefix, std::string event, event_map& event_map)
  {
    std::clog << prefix << event << std::endl;
    if (relaxed) return;
    match_event(prefix + event, __LINE__);
  }

  struct component
  {
    meta dzn_meta;
    runtime& dzn_rt;
    component(runtime& rt) : dzn_rt(rt)
    {
    rt.performs_flush(this) = flush;
    }
  };

  void fill_event_map(dezyne::pump& pump, component* c, #((om:scope-name (string->symbol "::")) model) & m, event_map& e)
  {
    static int dzn_i = 0;
    (void)dzn_i;

##if BLOCKING && SHELL
    auto wait = [=,&pump] (std::function<void()> const& f) {return [=,&pump] {pump.and_wait(f);};};
    auto wait_return = [=,&pump] (std::function<void()> const& f, std::string prefix) {return [=,&pump] {pump.and_wait(f); if (!relaxed) match_event(prefix + "return", __LINE__);};};
##else //!(BLOCKING && SHELL)
    auto wait = [=] (std::function<void()> const& f) {return f;};
    auto wait_return = [=] (std::function<void()> const& f, std::string prefix) {return [=] {f(); if (!relaxed) match_event(prefix + "return", __LINE__);};};
##endif //!(BLOCKING && SHELL)
  (void)wait;
  (void)wait_return;

 #(map
   (lambda (port)
     (map (define-on model port #{m.#port .#direction .#event  = [&] (#formals) {#(string-if (eq? return-type 'void) #{call_#direction(pump, "#port .", "#event ", e);#}
                                                                                                                 #{return call_valued<#((c++:scope-join #f) reply-scope)::#reply-name ::type>(pump, "#port .", "#event ", e, to_#((c++:scope-join #f) reply-scope)_#reply-name , static_cast<const char*(*)(#((c++:scope-join #f) reply-scope)::#reply-name ::type)>(to_string));#})};
     #}) (filter (negate (om:dir-matches? port)) (om:events port)))) (om:ports model))

##if 0
 // actions
 #(map
   (lambda (port)
     (map (define-on model port #{e["#port .#event "] = nullptr;
   #}) (filter (negate (om:dir-matches? port)) (om:events port)))) (om:ports model))
 #(map (init-port #{
     e["#name .return"] = nullptr;
     #}) (om:ports model))
##endif

 #(map (init-port #{
     if (flush) {
       m.#name .meta.provides.address = c;
       m.#name .meta.provides.meta = &c->dzn_meta;
     }
     e["#name .<flush>"] = [&] { std::clog << "#name .<flush>" << std::endl; m.dzn_rt.flush(m.#name .meta.provides.address); };
     #}) (filter om:requires? (om:ports model)))
 #(map
    (lambda (port)
    (map (define-on model port #{
       e["#port .#event "] = wait_return(#(string-if (null? argument-list) #{m.#port .#direction .#event #} #{ [&] {m.#port .#direction .#event (#(comma-join (map (lambda (i) "dzn_i") argument-list)));}#}), "#port .");
       #(string-if (is-a? model <system>) #{
       e["#instance .#instance-port .#event "] = e["#port .#event "];
       #})
#}) (filter (om:dir-matches? port) (om:events port))))
            (filter om:provides? (om:ports model)))
 #(map
    (lambda (port)
    (map (define-on model port #{
       e["#port .#event "] = wait(#(string-if (null? argument-list) #{m.#port .#direction .#event #} #{ [&] {m.#port .#direction .#event (#(comma-join (map (lambda (i) "dzn_i") argument-list)));}#}));
#}) (filter (om:dir-matches? port) (om:events port))))
            (filter om:requires? (om:ports model)))
 #(map (init-port #{
     m.#name .meta.provides.port = "#name ";
     m.#name .meta.requires.port = "#name ";
 #}) (om:ports model)) }
}

int main(int argc, char const* argv[])
{
  dezyne::flush = argc > 1 && argv[1] == std::string("--flush");
  dezyne::relaxed = argc > 1 && argv[1] == std::string("--relaxed");

##if BLOCKING
  bool main_p = true;
  std::mutex mutex;
##endif //BLOCKING

  dezyne::locator l;
  dezyne::runtime rt;
  l.set(rt);
  dezyne::illegal_handler ih;
  ih.illegal = [] {std::clog << "illegal" << std::endl; exit(0);};
  l.set(ih);

  dezyne::event_map event_map;
  #((om:scope-name (string->symbol "::")) model)  sut(l);
  sut.dzn_meta.name = "sut";

  dezyne::component c(rt);
  c.dzn_meta.parent = 0;
  c.dzn_meta.name = "<internal>";

  dezyne::pump pump;
  dezyne::g_pump = &pump;
  l.set(pump);

  dezyne::fill_event_map(rt, &c, sut, event_map);

##if BLOCKING
  pump.next_event = [&] {
    pump([&]{
        std::unique_lock<std::mutex> lock(mutex);
        std::string s;
        while(!dezyne::main_p && std::cin >> s && event_map.find(s) != event_map.end())
        {
          lock.unlock();
          event_map[s]();
          lock.lock();
        }
      });
  };
##endif

  sut.check_bindings();
  sut.dump_tree();

  std::string s;
  while(std::cin >> s) {
    if (event_map.find(s) == event_map.end()
        && !dezyne::relaxed)
    throw std::runtime_error(std::string(__FILE__) + ":" + std::to_string(__LINE__) + ": no such event: `" + s + "'");
##if BLOCKING
      std::unique_lock<std::mutex> lock(dezyne::mutex);
      dezyne::main_p = false;
      lock.unlock();
##endif //BLOCKING
##if BLOCKING && SHELL
      event_map[s]();
##else //!(BLOCKING && SHELL)
    pump.and_wait(event_map[s]);
##endif //!(BLOCKING && SHELL)
##if BLOCKING
      lock.lock();
      dezyne::main_p = true;
##endif //BLOCKING
  }
}
