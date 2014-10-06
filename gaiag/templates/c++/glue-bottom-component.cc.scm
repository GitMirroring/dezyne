##include <boost/tuple/tuple.hpp>

##include "component-#.model -c3.hh"

##include "#.model Component.h"

##include <map>

namespace component
{
  static std::map<#.model *,boost::tuple< boost::shared_ptr<#.model Interface>, #
(comma-join (map (lambda (type) (->string (list "boost::shared_ptr<" type ">")))
                 (map .type (filter gom:provides? ((compose .elements .ports) model)))))  > > g_handwritten;

#(define (api port event)
   (list
    (or
     (and-let* ((port-alist (assoc-ref *glue-alist* (.type port)))
                ((stderr "port-alist: ~a\n" port-alist))
                ((stderr "event: ~a\n" event))
                (port (assoc-ref port-alist (.name event))))
               port)
     (.name event))
    "_API"))
#(define (cb port event)
   (list
    (or
     (and-let* ((port-alist (assoc-ref *glue-alist* (.type port)))
                ((stderr "port-alist: ~a\n" port-alist))
                ((stderr "event: ~a\n" event))
                (port (assoc-ref port-alist (.name event))))
               port)
     "_fixme_from_spec" (.name event))))

#(define (ap- port) (->string (list (.type port) "_API")))
#(define (cb- port) (->string (list (.type port) "_fixme_from_spec")))

#(define (cbx port) (list (.type port) "_fixme_from_spec"))

#(map (lambda (port)
        (->string
         (list "struct " (cbx port) "\n: public interface::" (.type port) "\n"
               "{\n"
               "interface::iprovides_once& cb;\n"
               (.type port) "(interface::" (.type port) "& cb)\n"
               ": cb(cb)\n"
               "{}\n"
               (map
                (lambda (event)
                  (let* ((type ((compose .type .type) event))
                         (return-type (return-type port event))
                         (reply-type (->string (list (.type port) "_" (.name type)))))
                    (->string
                     (list "void " (cb port event) "(){ cb.out." (.name event) "(); }\n"))))
                (filter gom:out? (gom:events port)))
               "};\n")))
      (filter gom:provides? ((compose .elements .ports) model)))
#.model ::#.model ()
{
  boost::shared_ptr<#.model Interface> component = boost::shared_ptr<#.model Interface::GetInstance();
#(map (lambda (port) (->string (list "boost::shared_ptr<interface::" (.type port) "> api_" (.name port) ";\n"
                                       "component->GetAPI(&api_" (.name port) ");\n")))
        (filter gom:provides? ((compose .elements .ports) model)))
g_handwritten.insert (std::make_pair (this,boost::make_tuple (component,#(comma-join (map (lambda (port) (->string (list "api_" (.name port))))
                                                                                          (filter gom:provides? ((compose .elements .ports) model)))))));

#(map
  (lambda (port)
    (map
     (lambda (event)
       (let* ((type ((compose .type .type) event))
              (return-type (return-type port event))
              (reply-type (->string (list (.type port) "_" (.name type)))))
         (->string
          (list
           "component->RegisterCB(boost::make_shared<" (.type port) "_todo_get_from_spec>(boost::ref(api_" (.name port) ")));\n"))))
     (filter gom:out? (gom:events port))))
  (filter gom:provides? (gom:ports model)))
    component->RegisterCB(boost::make_shared<SingleThreaded>()); //fixme

#(map
  (lambda (port)
    (map
     (lambda (event)
       (let* ((type ((compose .type .type) event))
              (return-type (return-type port event))
              (reply-type (->string (list (.type port) "_" (.name type)))))
         (->string
          (list
           (.name port) "." (.name event) " = asd:bind(&" (.type port) ",api_" (.name port) ");\n"))))
     (filter (gom:dir-matches? port) (gom:events port))))
  (filter gom:provides? (gom:ports model)))}
}
#(map
  (lambda (port-index)
    (let ((port (car port-index))
          (index (1+ (cadr port-index))))
     (map
      (lambda (event)
        (let* ((type ((compose .type .type) event))
               (return-type (return-type port event))
               (reply-type (->string (list (.type port) "_" (.name type)))))
          (->string
           (list
            return-type " " (.name model) "::" (.name port) "_" (.name event) "()"
            "\n{\n"
            "g_handwritten[this].get<" index ">()->" (.name event) "();"
            "\n}\n")))) (filter (gom:dir-matches? port) (gom:events port)))))
(let* ((ports (filter gom:provides? (gom:ports model)))
       (indices (iota (length ports))))
  (zip ports indices)))
