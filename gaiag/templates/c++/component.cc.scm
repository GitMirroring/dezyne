##include "#.model .hh"

##include "locator.hh"
##include "runtime.hh"

namespace dezyne
{
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
      (map (define-on model port #{
#port .#direction .#event  = connect#(if (string-null? parameters) (list "<" return-type ">") (list "<" (comma-join (append (if (eq? return-type 'void) '() (list return-type)) parameter-types))">"))(rt, this, boost::function<#return-type(#(comma-join parameter-types))>(boost::bind<#return-type >(&#model ::#port _#event , #(comma-join (append '("this") (map (lambda (i) (list " _" i)) (iota (length parameter-types) 1)))))));
#}) (filter gom:in? (gom:events port))))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (map (define-on model port #{
#port .#direction .#event  = connect#(if (string-null? parameters) (list "<" return-type ">") (list "<" (comma-join (append (if (eq? return-type 'void) '() (list return-type)) parameter-types))">"))(rt, this, boost::function<#return-type(#(comma-join parameter-types))>(boost::bind<#return-type >(&#model ::#port _#event , #(comma-join (append '("this") (map (lambda (i) (list " _" i)) (iota (length parameter-types) 1)))))));
#}) (filter gom:out? (gom:events port))))
    (filter gom:requires? (gom:ports model))) }

#(map
  (lambda (port)
    (map (define-on model port #{
  #return-type  #model ::#port _#event (#parameters)
  {
    std::cout << "#model .#port _#event" << std::endl;
    #statement #
    (if (not (eq? type 'void))
(list "    return reply_" reply-type "_" reply-name ";\n"
      )) }

#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))#
((->join "\n  ")(map (define-function model #{
  #return-type  #model ::#name (#parameters)
  {
    #statements }
#}) (gom:functions model)))
}
