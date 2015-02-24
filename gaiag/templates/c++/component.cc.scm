##include "#.model .hh"

##include "locator.hh"
##include "runtime.hh"

##include <iostream>

namespace dezyne
{
  template <typename T>
  void trace(const T& t, const char* e)
  {
    std::clog << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << e << " -> " << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << e << std::endl;
  }

  template <typename T>
  void trace_return(const T& t, const char* e)
  {
   std::clog << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << "return" << " -> " << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << "return" << std::endl ;
  }

#.model ::#.model (const locator& dezyne_locator)
: rt(dezyne_locator.get<runtime>())
, #
((->join  "\n, ")
 (map (init-member model #{
#name(#(if (not (eq? expression *unspecified*)) expression))#}) (gom:variables model)))#
(if (null? (gom:variables model)) "" "\n, ") #
((->join  "\n, ") (map (lambda (port) (list (.name port) "(" (if (.injected port) (list "dezyne_locator.get<" (.type port) ">()")) ")")) (gom:ports model)))
  {
#
   (map
    (lambda (port)
      (->string
       (list
        (.name port) ".in.meta.component = \"" .model "\";\n"
        (.name port) ".in.meta.port = \"" (.name port) "\";\n"
        (.name port) ".in.meta.address = this;\n"
        )))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (->string
       (list
        (.name port) ".out.meta.component = \"" .model "\";\n"
        (.name port) ".out.meta.port = \"" (.name port) "\";\n"
        (.name port) ".out.meta.address = this;\n"
        )))
    (filter gom:requires? (gom:ports model)))
#
   (map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = connect#(if (string-null? parameters) (list "<" return-type ">") (list "<" (comma-join (append (if (eq? return-type 'void) '() (list return-type)) parameter-types))">"))(rt, this,
boost::function<#return-type(#(comma-join parameter-types))>
([this] (#parameters)
{
   trace (#port , "#event ");
   #(if (eq? return-type 'void) "" "auto r = ") #port _#event (#arguments);
   trace_return (#port , "#event ");
   return#(if (eq? return-type 'void) "" " r");
   }
));
#}) (filter gom:in? (gom:events port))))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = connect#(if (string-null? parameters) (list "<" return-type ">") (list "<" (comma-join (append (if (eq? return-type 'void) '() (list return-type)) parameter-types))">"))(rt, this,
boost::function<#return-type(#(comma-join parameter-types))>
([this] (#parameters)
{
   trace (#port , "#event ");
   #(if (eq? return-type 'void) "" "auto r = ") #port _#event (#arguments);
   return#(if (eq? return-type 'void) "" " r");
   }
));
#}) (filter gom:out? (gom:events port))))
    (filter gom:requires? (gom:ports model))) }

#(map
  (lambda (port)
    (map (define-on model port #{
  #return-type  #.model ::#port _#event (#parameters)
  {
    #statement #
    (if (not (eq? type 'void))
(list "    return reply_" reply-type "_" reply-name ";\n"
      )) }

#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))#
((->join "\n  ")(map (define-function model #{
  #return-type  #.model ::#name (#parameters)
  {
    #statements }
#}) (gom:functions model)))
}
