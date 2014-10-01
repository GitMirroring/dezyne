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
 (map
  (lambda (variable)
    (let* ((name (.name variable))
           (type (.type variable))
           (enum? (gom:enum model (.name type)))
           (scope (if enum? (->string (list (.name type) "::"))))
           (value (expression->string model (.expression variable))))
      (->string (list name "(" scope value ")"))))
  (gom:variables model)))#
(if (null? (gom:variables model)) "" "\n, ") #
  ((->join  "\n, ")
   (map (lambda (port) (->string (list (.name port) "()"))) (gom:ports model)))
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
    (map
     (lambda (event)
       (let* ((type ((compose .type .type) event))
              (return-type (return-type port event))
              (reply-type (->string (list (.type port) "_" (.name type))))
              (statement
               (or (and-let*
                    (((is-a? model <component>))
                     (component model)
                     (behaviour (.behaviour component))
                     (statement (.statement behaviour)))
                    (parameterize ((statements.port port)
                                   (statements.event event))
                      (statements->string model statement '() #f)))
                   "")))
         (->string
          (list
           return-type " " (.name model) "::" (.name port) "_" (.name event) "()"
           "\n{\n"
           "std::cout << \"" (.name model) "." (.name port) "_" (.name event) "\" << std::endl;\n"
           statement
           (if (not (eq? (.name type) 'void))
               (->string (list "return reply_" reply-type ";\n")))
           "\n}\n")))) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))

#((->join "\n")
  (map
   (lambda (function)
     (let* ((signature (.signature function))
            (return-type (statements->string model signature))
            (name (.name function))
            (parameters (.parameters signature))
            (statement (.statement function))
            (locals (map (lambda (x) (cons (.name x) x)) (.elements parameters)))
            (parameters (statements->string model parameters))
            (statements (statements->string model statement locals))
            (model (.name model)))
       (->string (list return-type " " model "::" name "(" parameters ")\n"
                       "{\n"
                       statements
                       "\n}"
                       ))))
   (gom:functions model)))
}
