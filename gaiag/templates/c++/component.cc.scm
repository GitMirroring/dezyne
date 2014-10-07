##include "component-#.model -c3.hh"

void handle_event(void*, const asd::function<void()>&);

template <typename R>
inline asd::function<R()> connect(void*, const asd::function<R()>& event)
{
  return event;
}

template <>
inline asd::function<void()> connect<void>(void* scope, const asd::function<void()>& event)
{
  return asd::bind(handle_event, scope, event);
}

namespace component
{
#.model ::#.model ()
: #
((->join  "\n, ")
 (map (init-member model #{
#name(#expression)#}) (gom:variables model)))#
(if (null? (gom:variables model)) "" "\n, ") #
  ((->join  "\n, ") (map (init-port #{ #name() #}) (gom:ports model)))
  {
#
   (map
    (lambda (port)
      (map
       (lambda (event)
         (->string (list (.name port) ".in." (.name event) " = connect<" (return-type port event) ">(this, asd::bind<" (return-type port event) ">(&" (.name model) "::" (.name port) "_" (.name event) ", this));\n")))
       (filter gom:in? (gom:events port))))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (map
       (lambda (event)
         (->string (list (.name port) ".out." (.name event) " = connect<" (return-type port event) ">(this, asd::bind<" (return-type port event) ">(&" (.name model) "::" (.name port) "_" (.name event) ", this));\n")))
       (filter gom:out? (gom:events port))))
    (filter gom:requires? (gom:ports model))) }

#(map
  (lambda (port)
    (map (define-on model port #{
  #return-type  #model ::#port _#event ()
  {
    std::cout << "#model .#port _#event" << std::endl;
    #statement #
    (if (not (eq? type 'void))
(list "    return reply_" reply-type ";\n"
      ))
  }
#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))

#((->join "\n")
  (map (define-function model #{
  #return-type  #model ::#name (#parameters)
  {
    #statements
  }
#}) (gom:functions model)))
}
