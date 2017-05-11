##include "#.model .hh"

#(use-modules (ice-9 receive))

##include "asdInterfaces.h"
##include "#(symbol-drop-right .model 4)Component.h"

boost::shared_ptr<asd::channels::ISingleThreaded> g_singlethreaded;

#(map (lambda (port)
        (let* ((interface (symbol-drop (last (.type port)) 1)))
          (->string (list "#include" "\"" interface 'Component.h "\"\n"))))
      (filter om:requires? (om:ports model)))

##include <dzn/locator.hh>
##include <dzn/runtime.hh>

##include <boost/bind.hpp>
##include <boost/enable_shared_from_this.hpp>
##include <boost/make_shared.hpp>
##include <boost/ref.hpp>

dzn::locator* g_locator = nullptr;

#(define mapping->event first)#
(define mapping->asd-interface second)#
(define mapping->asd-event third)#
(define ((mapping->formals interface) mapping)
   ((compose .formals .signature) (om:event interface (mapping->event mapping))))#
(define ((mapping->formals-code interface) mapping)
   (code:->code model ((mapping->formals interface) mapping)))#
(define ((mapping->asd-formals-code interface) mapping)
   ((->join ", ") (map (lambda (f) (->string (list  (if (om:in? f) "const " "") "asd::value<" (code:->code model (.type f)) ">::type&" (code:->code model (.name f))))) (.elements ((mapping->formals interface) mapping)))))#
(define ((mapping->arguments-code interface) mapping)
   ((->join ", ") (map .name (.elements ((mapping->formals interface) mapping)))))



#
(map (lambda (port)

((animate-pairs `((port ,identity)
                  (port-glue ,(lambda (port) (symbol-drop (om:name port) 1)))
                  (asd-component ,(symbol-drop (om:name port) 1))
                  (port-name ,(c++:scope-name)))

#{
struct #port-glue Glue
: public #port-glue Component
, public boost::enable_shared_from_this<#port-glue Glue>
  {//}

  static const char* name(int i)
  {
    static const char* n[] = {#((->join ",") (map (lambda (p) (list "\"" (.name p) "\"")) (filter (lambda (p) (om:equal? (.type port) (.type p))) (om:ports model))))};
    return n[i];
  }

  #(map (lambda (mapping)

   (if (om:in? (om:event (om:interface port) (cadadr mapping)))
      ((animate-pairs `(
                      (api ,car)
                      (port-name ,port-name)
                      (port-glue ,port-glue)
                      (mapping ,mapping)
                      (port ,port))
#{
struct ASD#api : public #api
{
  static int s_i;
  #port-name  & port;
  ASD#api ()
  : port(g_locator->get<#port-name >(#port-glue Glue::name(s_i++)))
  {}
 #(map (lambda (asd-event event)
   (let ((interface (om:import (.type port))))
    ((animate-pairs  `((event ,identity)
                       (asd-event ,asd-event)
                       (reply-type ,(return-type interface (om:event interface event)))
                       (asd-reply-type ,(if (is-a? (return-type interface (om:event interface event)) <void>) 'void (->string api "::PseudoStimulus")))
                       (direction ,(lambda (e) (.direction (om:event interface event))))
                       (asd-formals ,(event->asd-formals-code interface))
                       (arguments ,(event->arguments-code interface)))
#{
  #asd-reply-type  #asd-event (#asd-formals)
  {
   return #(string-if (not (is-a? asd-reply-type <void>)) #{static_cast<#asd-reply-type >(port.#direction .#event (#arguments))#} #{port.#direction .#event (#arguments)#});
  }
#}
    ) event))) (map car (cdr mapping)) (map cadr (cdr mapping)))
};

void GetAPI(boost::shared_ptr<#api >* api)
{
  *api = boost::make_shared<ASD#api >();
}


#}


) mapping)

((animate-pairs `((mapping ,mapping)
                  (port ,port)
                  (callback ,car)
                  (port-name ,port-name)
                  (port-glue ,port-glue)) #{

void RegisterCB(boost::shared_ptr<#callback > cb)
{
   static int s_i = 0;
   auto& port  = g_locator->get<#port-name >(#port-glue Glue::name(s_i++));
   #(map (lambda (asd-event event)
       (let ((interface (om:import (.type port))))
       ((animate-pairs `((port-name ,port-name)
                         (asd-event ,asd-event)
                         (event ,identity)
                         (formals ,(event->formals-code interface))
                         (arguments ,(event->arguments-code interface)))
#{
   port.out.#event  = [&,this,cb](#formals){std::clog << port.meta.requires.port << ".#event" << std::endl; cb->#asd-event(#arguments);};
#}) event))) (map car (cdr mapping)) (map cadr (cdr mapping)))
}

#}) mapping)))   (port->mapping-list port))

void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded> st)
{
  g_singlethreaded = st;
}

//{
};

#(map (lambda (mapping)
   (if (om:in? (om:event (om:interface port) (cadadr mapping)))
      ((animate-pairs `((api ,car)
                        (port-glue ,port-glue)) #{
int #port-glue Glue::ASD#api ::s_i = 0;
#}) mapping)))   (port->mapping-list port))

boost::shared_ptr<#asd-component Interface> #asd-component Component::GetInstance()
{
  return boost::make_shared<#port-glue Glue>();
}

void #asd-component Component::ReleaseInstance(){}

#}) port))

(delete-duplicates (filter om:requires? (om:ports model)) (lambda (a b) (om:equal? (.type a) (.type b))))
)



/****************************/
#(map (lambda (port)

((animate-pairs `((port ,identity)
                  (port-glue ,(lambda (port) (symbol-drop (om:name port) 1)))
                  (asd-component ,(symbol-drop (om:name port) 1))
                  (port-name ,(c++:scope-name)))

#{

  #(map (lambda (mapping)

   (if (om:out? (om:event (om:interface port) (cadadr mapping)))
     ((animate-pairs `(
                      (api ,car)
                      (port-name ,port-name)
                       (mapping ,mapping)
                      (port ,port)
                          )
#{
struct ASD#api : public #api
{
  #port-name  & port;
  ASD#api (#port-name &port)
  : port(port)
  {}
 #(map (lambda (asd-event event)
   (let ((interface (om:import (.type port))))
    ((animate-pairs  `((event ,identity)
                       (asd-event ,asd-event)
                       (direction ,(lambda (e) (.direction (om:event interface event))))
                       (asd-formals ,(event->asd-formals-code interface))
                       (arguments ,(event->arguments-code interface)))
#{
  void #asd-event (#asd-formals)
  {
    port.#direction .#event (#arguments);
  }
#}
    ) event))) (map car (cdr mapping)) (map cadr (cdr mapping)))
};

#}


) mapping)
  "/* empty */"))   (port->mapping-list port))

#}) port))

(filter om:provides? (om:ports model)))




struct SingleThreaded
  : public asd::channels::ISingleThreaded
{
  void processCBs(){}
};

struct call_helper
{
  const dzn::port::meta& meta;
  const char* event;
  std::string reply;
  call_helper(const dzn::port::meta& meta, const char* event)
  : meta(meta)
  , event(event)
  , reply("return")
  {
    std::clog << meta.provides.port << "." << event << std::endl;
  }
  template <typename L, typename = typename std::enable_if<std::is_void<typename std::result_of<L()>::type>::value>::type>
  void operator()(L&& l)
  {
    return l();
  }
  template <typename L, typename = typename std::enable_if<!std::is_void<typename std::result_of<L()>::type>::value>::type>
  auto operator()(L&& l) -> decltype(l())
  {
    auto r = l();
    reply = to_string(r);
    return r;
  }
  ~call_helper()
  {
    std::clog << meta.provides.port << "." << reply.c_str() << std::endl;
  }
};

#(map (lambda (x) (list " namespace " x " {\n")) (om:scope model))
#.model ::#.model (dzn::locator& locator)
: dzn_rt(locator.get<dzn::runtime>())
, dzn_locator(locator)
, #(map (lambda (port) (if (eq? (.direction port) 'provides) (list (.name port) "({{\"" (.name port) "\",this,&dzn_meta},{\"\",0,0}})") (list "\n, " (.name port) "({{\"\",0,0},{\"" (.name port)"\",this,&dzn_meta}})"))) ((compose .elements .ports) model))
{
# (map (animate-pairs `((port ,.name)) #{ locator.set(#port ,"#port ");
#}) (om:ports model))
g_locator = &locator;

component = #(symbol-drop-right .model 4)Component::GetInstance();
#(let ((port (om:port model)))
  (map
     (animate-pairs `((port ,(.name (om:port model)))
                      (component ,(symbol-drop (om:name (om:interface model)) 1))
                      (asd-interface ,car))
#{boost::shared_ptr<#asd-interface > api_#asd-interface ;
  component->GetAPI(&api_#asd-interface);
#}) (filter (lambda (mapping) (om:in? (om:event (om:interface port) (cadadr mapping)))) (port->mapping-list port))))
#(let ((port (om:port model)))
  (map
     (animate-pairs `((interface ,(om:name (om:interface model)))
                       (component ,(symbol-drop (om:name (om:interface model)) 1))
                       (port ,(.name port))
                       (asd-interface ,car))
#{component->RegisterCB(boost::make_shared<ASD#asd-interface >(boost::ref(#port)));
#}) (filter (lambda (mapping) (om:out? (om:event (om:interface port) (cadadr mapping)))) (port->mapping-list port))))#
(if (pair? ((asd-interfaces om:out?) (om:interface model))) "component->RegisterCB(boost::make_shared<SingleThreaded>());")
#
(let* ((port (om:port model))
        (interface (om:interface port))
        (interface-name (om:name interface))
        (component-name (symbol-drop interface-name 1))
        (port-name (.name port))
        (port-type (om:name port)))
(map
  (lambda (mapping-list)
    (map
      (animate-pairs `((asd-interface ,mapping->asd-interface)
                       (asd-event ,mapping->asd-event)
                       (event ,mapping->event)
                       (reply-type ,(lambda (p) (return-type interface (om:event interface (mapping->event p)))))
                       (component ,component-name)
                       (port ,port-name)
                       (formals ,(mapping->formals-code interface))
                       (arguments ,(mapping->arguments-code interface)))
#{
#port .in.#event  = [=](#formals){return call_helper(#port .meta, "#event ")([&]{#(string-if (not (is-a? reply-type <void>)) #{return static_cast<#reply-type >(api_#asd-interface ->#asd-event (#arguments))#} #{api_#asd-interface ->#asd-event (#arguments)#});});};
#}) mapping-list)) ((asd-interfaces om:in?) (om:interface port))))}
#(map (lambda (x) (list "}\n")) (om:scope model))
