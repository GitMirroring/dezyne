;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2014, 2015, 2016, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gaiag c++)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)

  #:use-module (gaiag misc)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag resolve)
  #:use-module (gaiag util)

  #:use-module (gaiag command-line)
  #:use-module (gaiag dzn)
  #:use-module (gaiag code)
  #:use-module (gaiag indent)
  #:use-module (gaiag parse)
  #:use-module (gaiag compare)

  #:use-module (gaiag deprecated om)
  #:use-module (gaiag ast)

  #:use-module (gaiag location)
  #:use-module (gaiag templates)

  #:export (c++:argument_n
            c++:asd-api-definition
            c++:asd-api-instance-declaration
            c++:asd-api-instance-init
            c++:asd-cb-definition
            c++:asd-cb-event-init
            c++:asd-cb-instance-declaration
            c++:asd-cb-instance-init
            c++:asd-cb-method-definition
            c++:asd-constructor
            c++:asd-get-api
            c++:asd-get-api-definition
            c++:asd-method-declaration
            c++:asd-method-definition
            c++:asd-register-cb
            c++:asd-register-cb-definition
            c++:asd-register-st
            c++:capture-arguments
            c++:construction-include
            c++:construction-parameters
            c++:construction-parameters-locator-get
            c++:construction-parameters-locator-set
            c++:construction-signature
            c++:global-enum-definer
            c++:enum->string
            c++:enum-field->string
            c++:name
            c++:optional-type
            c++:function-type
            c++:string->enum
            c++:type-ref
            c++:void-in-triggers
            asd?
            ))

(export
 .asd-channel
 .asd-event
 <glue-event>)

(define-ast <glue-event> (<event>)
  (asd-channel)
  (asd-event))

(define-ast <glue-system> (<system>)
  (asd-in #:init-form (list))
  (asd-out #:init-form (list)))

(define asd? #f) ;; FIXME: asd glue

(define* ((c++:scope-name #:optional (infix (string->symbol "::"))) o) ;; JUNKME
  ((om:scope-name infix) o))

;;; ast accessors / template helpers

(define-method (c++:type-ref (o <formal>))
  (if (not (eq? 'in (.direction o))) "&" ""))

(define-method (c++:name (o <bind>))  ;; FIXME
  (injected-instance-name o))

(define-method (c++:capture-arguments (o <trigger>))
  (map .name (filter (negate om:out-or-inout?) (code:formals o))))

(define-method (c++:formal-type (o <formal>)) o)
(define-method (c++:formal-type (o <port>)) ((compose .elements .formals .signature car om:events) o))

(define-method (c++:function-type (o <type>))
  o)

(define-method (c++:function-type (o <glue-event>))
  ((compose c++:function-type .signature) o))

(define-method (c++:function-type (o <trigger>))
  ((compose c++:function-type .signature .event) o))

(define-method (c++:function-type (o <signature>))
  ((compose c++:function-type .type) o))

(define-method (c++:function-type (o <function>))
  ((compose c++:function-type .signature) o))

(define (c++:pump-include o) (if (pair? (om:ports (.behaviour o))) "#include <dzn/pump.hh>" ""))

(define-method (c++:enum-field->string (o <enum>))
  (map (symbol->enum-field o) ((compose .elements .fields) o)))
(define-method (c++:string->enum (o <model>))
  (om:enums o))
(define-method (c++:string->enum (o <enum>))
  (map (symbol->enum-field o) ((compose .elements .fields) o)))

(define-method (c++:enum->string (o <interface>))
  (append (filter (is? <enum>) (om:globals o)) (om:enums o)))

(define-method (c++:global-enum-definer (o <interface>))
  (filter (is? <enum>) (ast:global* (parent o <root>))))

(define-method (c++:argument_n (o <trigger>))
  (map
   (lambda (f i) (clone f #:name (string-append "_"  (number->string i))))
   (code:formals o)
   (iota (length (code:formals o)) 1 1)))

(define-method (c++:optional-type (o <trigger>))
  (let ((type (ast:type o)))
    (if (is-a? type <void>) '() type)))

;; glue-top-source-glue-system
(define-public (parse-component-map component)
  (or (and-let* ((files (command-line:get '() '()))
                 (map-files (filter (cut string-suffix? ".map" <>) files))
                 (file-name (string-append (symbol->string ((om:scope-name) component)) ".map"))
                 (file-name (find (lambda (f) (equal? (basename f) file-name)) map-files))
                 (lines (filter (negate (disjoin (cut string-every char-set:blank <>)
                                                 (cut string-prefix? "//" <>))) (string-split (gulp-file file-name) #\newline)))
                 (words-list (map (cut string-split <> #\space) lines)))
        (filter (compose (negate (cut equal? "usr" <>)) car) words-list))
      '()))

(define (c++:construction-signature component)
  (or (and-let* ((words-list (parse-component-map component))
                 (parameters (map (lambda (lst)
                                    (cond((equal? (car lst) "simple") (string-append (cadr lst) " " (caddr lst)))
                                         ((equal? (car lst) "service") (string-append "boost::shared_ptr<" (cadr lst) "::" (cadr lst) "Interface> " (caddr lst)))
                                         (#t (string-append "boost::shared_ptr<" (cadr lst) "Component> " (caddr lst)))))
                                  words-list))
                 (signature (string-join parameters ",")))
        signature)
      ""))

(define (c++:construction-include component)
  (or (and-let* ((words-list (parse-component-map component))
                 (parameters (map (lambda (lst)
                                    (cond((equal? (car lst) "simple") "")
                                         ((equal? (car lst) "service") (string-append "#include \"" (cadr lst) (string-upcase (cadr lst) 0 1) "Interface.h\"\n"))
                                         (#t "")))
                                  words-list))
                 (signature (string-join parameters ",")))
        signature)
      ""))

(define (c++:construction-parameters component)
  (or (and-let* ((words-list (parse-component-map component))
                 (parameters (map caddr words-list)))
        (string-join parameters ","))
      ""))

(define (c++:construction-parameters-locator-set component)
    (or (and-let* ((words-list (parse-component-map component))
                   (parameters (map (compose (lambda (o) (string-append ".set(" o ",\"" o "\")")) caddr) words-list)))
          (string-join parameters ","))
        ""))

(define (c++:construction-parameters-locator-get component)
    (or (and-let* ((words-list (parse-component-map component))
                   (parameters (map (compose (lambda (o) (string-append ".get<" ">(\"" o "\">)")) caddr) words-list)))
          (string-join parameters ","))
        ""))

(define (c++:asd-constructor component)
  (let* ((name (symbol->string ((om:scope-name) component)))
         (files (command-line:get '() '()))
         (map-files (filter (cut string-suffix? ".map" <>) files))
         (lines (append-map (lambda (map-file)
                              (string-split (gulp-file map-file) #\newline))
                            map-files))
         (lines (filter (negate (disjoin (cut string-every char-set:blank <>)
                                         (cut string-prefix? "//" <>))) lines))
         (words-list (map (cut string-split <> #\space) lines))
         (usr-list (filter (lambda (o)
                             (and (equal? "usr" (first o))
                                  (equal? name (string-append "glue_" (second o)))))
                           words-list)))
    (if (null? usr-list)
        (string-append (symbol->string (.name (.name component))) "Component::GetInstance()")
        (let* ((matches-list (map (lambda (third) (string-match "[(]([^)]*)[)]" third))
                                  (map third usr-list)))
               (matches-list (filter identity matches-list))
               (parameters-list (map (cut match:substring <> 1) matches-list)))
          (string-append
           (symbol->string (.name (.name component))) "Component::GetInstance("
           (string-join
            (map (lambda (parameters)
                   (string-join (map (lambda (parameter)
                                       (let* ((entry (find (compose (cut equal? parameter <>) third) words-list))
                                              (type (second entry))
                                              (type (if (equal? "simple" (first entry)) type (string-append "boost::shared_ptr<" type "::" type "Interface> "))))
                                         (string-append "locator.get<" type ">(\"" parameter "\")")))
                                     (string-split parameters #\,)) ","))
                 parameters-list)
            ",")
           ")")))))

(define-method (provided-interface (o <component-model>))
  (let ((ports (ast:port* o)))
    (if (= (length ports) 1) ((compose .type car) ports)
        (error (format #f "expected one provided port, found: ~s\n" (length ports))))))

(define (c++:asd-api-instance-declaration component)
  (map (lambda (api) (->string (list "boost::shared_ptr< ::" api "> api_" api ";\n")))
       (delete-duplicates (map second ((asd-interfaces om:in?) (provided-interface component))))))

(define (c++:asd-api-instance-init component)
  (map (lambda (interface)
         (let ((port-name (.name (om:port component))))
           (->string (list ", api_" interface
                           "(boost::make_shared<" interface ">(boost::ref(component." port-name ")))\n"))))
       (delete-duplicates (map second ((asd-interfaces om:in?) (provided-interface component))))))

(define (c++:asd-cb-instance-declaration component)
  (map (lambda (cb) (->string (list "boost::shared_ptr< ::" cb "> cb_" cb ";\n")))
       (delete-duplicates (map second ((asd-interfaces om:out?) (provided-interface component))))))

(define (c++:asd-cb-instance-init component)
  (map (lambda (cb) (->string (list "cb_" cb " = boost::make_shared<" cb ">(boost::ref(" (.name (om:port component)) "));\n")))
       (delete-duplicates (map second ((asd-interfaces om:out?) (provided-interface component))))))

(define (c++:asd-cb-event-init component)
  (map (lambda (entry)
         (let* ((event (first entry))
                (interface (second entry))
                (event (resolve:event (provided-interface component) event))
                (formals (.elements (.formals (.signature event))))
                (port (om:port component))
                (port-name (.name port)))
           (->string (list "component." port-name ".out." (first entry)
                           " = boost::bind(&" (om:name component) "Glue::" (first entry) ","
                           (comma-join (list "this" (comma-join (map (compose (cut string-append "_" <>) number->string) (iota (length formals) 1 1))))) ");\n"))))
       ((asd-interfaces om:out?) (provided-interface component))))

(define (c++:asd-cb-definition component)
  (map (lambda (entry)
        (let* ((name (car entry))
               (dzn-events (cadr entry))
               (asd-events (caddr entry)))
          (->string (list "struct " name ": public ::" name "\n{\n"
                 ((c++:scope-name) (om:port component)) "& port;\n"
                 name "(" ((c++:scope-name) (om:port component)) "& port)\n"
                 ": port(port)\n"
                 "{}\n"
                 (map (lambda (asd dzn)
                        (let* ((event (resolve:event (provided-interface component) dzn))
                               (formals (.elements (.formals (.signature event))))
                               (arguments (map .name formals))
                               (formals (map (lambda (formal)
                                               (list (if (eq? (.direction formal) 'in) "const ")
                                                     "asd::value<" ((compose om:type-name (om:type component)) formal) ">::type& " (.name formal)))
                                             formals)))
                          (list "void " asd "(" formals "){\nport.out." dzn "(" arguments ");\n}\n")))
                      asd-events dzn-events)
                 "};\n"))))
      (map (lambda (name)
             (let* ((lst (filter (lambda (entry) (eq? name (second entry))) ((asd-interfaces om:out?) (provided-interface component))))
                    (dzn-events (map first lst))
                    (asd-events (map third lst)))
              (list name dzn-events asd-events)))
           (delete-duplicates (map second ((asd-interfaces om:out?) (provided-interface component)))))))

(define (c++:asd-get-api component)
  (map (lambda (api) (->string (list "component->GetAPI(&api_" api ");\n")))
       (delete-duplicates (map second ((asd-interfaces om:in?) (provided-interface component))))))

(define (c++:asd-register-cb component)
  (map (lambda (cb) (->string (list "component->RegisterCB(cb_" cb ");\n")))
       (delete-duplicates (map second ((asd-interfaces om:out?) (provided-interface component))))))

(define (c++:asd-register-st component)
  (if (pair? (filter om:out? (om:events (om:port component))))
      (->string (list "component->RegisterCB(boost::make_shared<SingleThreaded>(this, boost::ref(dzn_rt)));\n"))
      ""))

(define (c++:asd-method-declaration model)
  (map
   (lambda (dzn asd)
     (clone (make <glue-event> #:name (.name dzn) #:signature (.signature dzn) #:direction (.direction dzn) #:asd-channel (cadr asd) #:asd-event (caddr asd))
            #:parent model))
   (filter om:in? (om:events (om:port model))) ((asd-interfaces om:in?) (provided-interface model))))

(define (c++:asd-method-definition model)
  (map
   (lambda (dzn asd)
     (clone (make <glue-event> #:name (.name dzn) #:signature (.signature dzn) #:direction (.direction dzn) #:asd-channel (cadr asd) #:asd-event (caddr asd))
            #:parent model))
   (filter om:in? (om:events (om:port model))) ((asd-interfaces om:in?) (provided-interface model))))

(define (c++:asd-cb-method-definition model)
  (map (lambda (entry)
         (let* ((event-name (first entry))
                (interface (second entry))
                (event (resolve:event (provided-interface model) event-name))
                (formals (.elements (.formals (.signature event))))
                (arguments (comma-join (map .name formals)))
                (formals (comma-join (map (lambda (formal)
                                            (list ((compose .value (om:type model)) formal) (if (eq? (.direction formal) 'in) " " "& ") (.name formal)))
                                          formals)))
                (port (om:port model))
                (port-name (.name port)))
           (->string (list "void " (first entry) "(" formals ")\n"
                           "{\n"
                           "cb_" interface "->" (third entry) "(" arguments ");\n"
                           "st->processCBs();\n"
                           "}\n"))))
       ((asd-interfaces om:out?) (provided-interface model))))

(define (c++:asd-api-definition model)
  (map (lambda (entry)
         (let ((name (.name (.name model)))
               (port-type ((c++:scope-name) (om:port model)))
               (interface (car entry))
               (dzn-events (cadr entry))
               (asd-events (caddr entry)))
           (->string (list "struct " interface "\n: public ::" interface "\n"
                           "{\n"
                           port-type "& api;\n"
                           interface "(" port-type "& api)\n"
                           ": api(api)\n"
                           "{}\n"
                           (map
                            (lambda (dzn asd)
                              (let* ((event (resolve:event (provided-interface model) dzn))
                                     (void? (is-a? (.type (.signature event)) <void>))
                                     (formals (.elements (.formals (.signature event))))
                                     (arguments (comma-join (map .name formals)))
                                     (formals (comma-join (map (lambda (formal)
                                                                 (list (if (eq? (.direction formal) 'in) "const ") "asd::value< " ((compose .value (om:type model)) formal) " >::type& " (.name formal)))
                                                               formals)))
                                     (port (om:port model)))
                                (if void?
                                    (list "void " asd "(" formals ")\n"
                                          "{\n"
                                          "api.in." dzn "(" arguments ");\n"
                                          "}\n")
                                    (list "::" interface "::PseudoStimulus " asd "(" formals ")\n"
                                          "{\n"
                                          (list "return static_cast< ::" interface "::PseudoStimulus>(api.in." dzn "(" arguments "));\n")
                                          "}\n"))))
                            dzn-events asd-events)
                           "};\n"))))
       (map (lambda (api)
              (let* ((lst (filter (lambda (entry) (eq? api (second entry))) ((asd-interfaces om:in?) (provided-interface model))))
                     (dzn-events (map first lst))
                     (asd-events (map third lst)))
                (list api dzn-events asd-events)))
            (delete-duplicates (map second ((asd-interfaces om:in?) (provided-interface model)))))))

(define (c++:asd-get-api-definition model)
  (map (lambda (interface)
         (let ((port-type ((c++:scope-name) (om:port model))))
           (->string (list "void GetAPI(boost::shared_ptr< ::" interface ">* api)\n"
                           "{\n"
                           "*api = api_" interface ";\n"
                           "}\n"))))
       (delete-duplicates (map second ((asd-interfaces om:in?) (provided-interface model))))))

(define (c++:asd-register-cb-definition model)
  (map (lambda (interface)
         (let ((port-type ((c++:scope-name) (om:port model))))
           (->string (list "void RegisterCB(boost::shared_ptr< ::" interface "> cb)\n"
                           "{\n"
                           "cb_" interface " = cb;\n"
                           "}\n"))))
       (delete-duplicates (map second ((asd-interfaces om:out?) (provided-interface model))))))

(define-method (c++:void-in-triggers (o <component-model>))
  (filter
   (lambda (t) (is-a? ((compose .type .signature .event) t) <void>))
   (append (ast:provided-in-triggers o) (ast:required-out-triggers o))))

(define-templates-macro define-templates c++)
(include "../templates/dzn.scm")
(include "../templates/code.scm")
(include "../templates/c++.scm")

(define (c++:root-> root)
  (parameterize ((language 'c++)
                 (%x:header x:header)
                 (%x:source x:source)
                 (%x:glue-bottom-header x:glue-bottom-header)
                 (%x:glue-bottom-source x:glue-bottom-source)
                 (%x:glue-top-header x:glue-top-header)
                 (%x:glue-top-source x:glue-top-source)
                 (%x:main x:main))
    (code:root-> root)))

(define (ast-> ast)
  (let ((root (code:om ast)))
    (c++:root-> root))
  "")
