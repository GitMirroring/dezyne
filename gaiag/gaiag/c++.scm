;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2014, 2015, 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

  #:use-module (gaiag norm-event)

  #:use-module (gaiag code)
  #:use-module (gaiag command-line)
  #:use-module (gaiag indent)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag resolve)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag ast)
  #:use-module (gaiag xpand)

  #:use-module (language dezyne location)

  #:export (.asd-channel
            .asd-event
            <glue-event>))

(define ast-> (@@ (gaiag code) ast->))

(define-class <glue-event> (<event>)
  (asd-channel #:getter .asd-channel #:init-value #f #:init-keyword #:asd-channel)
  (asd-event #:getter .asd-event #:init-value #f #:init-keyword #:asd-event))

(define-class <glue-system> (<system>)
  (asd-in #:getter .asd-in #:init-form (list) #:init-keyword #:asd-in)
  (asd-out #:getter .asd-out #:init-form (list) #:init-keyword #:asd-out))

(define asd? #f) ;; FIXME: asd glue

(define* ((c++:scope-name #:optional (infix (string->symbol "::"))) o) ;; JUNKME
  ((om:scope-name infix) o))

;;; ast accessors / template helpers

(define-method (c++:type-ref (o <formal>))
  (if (not (eq? 'in (.direction o))) "&" ""))

(define-method (c++:name (o <bind>))  ;; FIXME
  (injected-instance-name o))

(define-method (code:capture-arguments (o <trigger>))
  (map .name (filter (negate om:out-or-inout?) (code:formals o))))

(define-method (c++:formal-type (o <formal>)) o)
(define-method (c++:formal-type (o <port>)) ((compose .elements .formals .signature car om:events) o))

(define-method (c++:return-type (o <void>))
  o)

(define-method (c++:return-type (o <glue-event>))
  (c++:return-type (.type (.signature o))))

(define-method (c++:return-type (o <trigger>)) ((compose .type .signature .event) o))
(define-method (c++:return-type (o <function>)) ((compose .type .signature) o))

(define (c++:pump-include o) (if (pair? (om:ports (.behaviour o))) "#include <dzn/pump.hh>" ""))

(define-method (c++:enum-field->string (o <enum>))
  (map (symbol->enum-field o) ((compose .elements .fields) o)))
(define-method (c++:string->enum (o <model>))
  (om:enums o))
(define-method (c++:string->enum (o <enum>))
  (map (symbol->enum-field o) ((compose .elements .fields) o)))

(define-method (c++:enum->string (o <interface>))
  (append (filter (is? <enum>) (om:globals)) (om:enums o)))

(define-method (trigger->on (o <trigger>))
  (make <on> #:triggers (make <triggers> #:elements (list o)) #:statement (make <compound>)))

(define-method (code:syntesize-ons (o <component>))
  (map trigger->on (ast:in-triggers o)))

(define-method (code:dzn-locator (o <instance>)) ;; MORTAL SIN HERE!!?
  (let* ((model (ast:model-scope)))
    (if (null? (injected-bindings model)) ""
        "_local")))

(define-method (code:main-out-arg-define (o <trigger>))
  (let ((formals ((compose .elements .formals) o)))
    (map (lambda (f i) (clone f #:name i))
         formals (iota (length formals)))))

(define-method (code:main-out-arg-define-formal (o <formal>)) ;; MORTAL SIN HERE!!?
  (let ((type ((compose .value .type) o)))
    (if (not (om:out-or-inout? o)) ""
        (if (equal? type 'int) o
            "/*FIXME*/"))))

(define-method (c++:argument_n (o <trigger>))
  (map
   (lambda (f i) (clone f #:name (string-append "_"  (number->string i))))
   (code:formals o)
   (iota (length (code:formals o)) 1 1)))


;;; templates

(define-template x:name c++:name)
(define-template x:declare-method code:trigger)
(define-template x:return-type c++:return-type #f <type>)
(define-template x:calls ast:void-in-triggers)
(define-template x:rcalls ast:valued-in-triggers)
(define-template x:prefix-formals-type code:formals 'formal-prefix)
(define-template x:pump (lambda (o) (if (null? (ast:req-events o)) "" o)))
(define-template x:reqs ast:req-events)
(define-template x:clrs ast:clr-events)
(define-template x:variable-expression (compose code:expression .expression) #f <expression>)

(define-template x:open-namespace (lambda (o) (map (lambda (x) (string-join (list " namespace " (symbol->string x) " {") "")) (om:scope o))))
(define-template x:close-namespace (lambda (o) (map (lambda (x) "}\n") (om:scope o))))

(define-template x:meta identity)
(define-template x:ports-meta-list (lambda (o) (filter ast:requires? (om:ports o))) 'meta-infix)
(define-template x:check-bindings-list (lambda (o) ((->join ",") (map (lambda (port) (list "[this]{"(.name port) ".check_bindings();}")) (om:ports o)))))

(define-template x:global-enum-definer (lambda (o) (filter (is? <enum>) (om:globals))))
(define-template x:check-in-binding (lambda (o) (filter om:in? (om:events o))))
(define-template x:check-out-binding (lambda (o) (filter om:out? (om:events o))))

(define-template x:interface-enum-to-string c++:enum->string)
(define-template x:interface-string-to-enum c++:enum->string)

(define-template x:enum-field-to-string c++:enum-field->string)


(define-template x:string-to-enum c++:string->enum)

(define-template x:asd-voidreply (lambda (o) (if asd? "__ASD_VoidReply, " "")))

(define-template x:scoped-port-name (lambda (port) (let ((scope-name ((compose .name .type) port))) (append (.scope scope-name) (list (.name scope-name))))) 'type-infix)

(define-template x:reply-member-declare code:reply-types)

(define-template x:variable-member-declare (lambda (o) (om:variables o)))

(define-template x:out-binding-lambda (lambda (o) (filter ast:provides? (om:ports o))))
(define-template x:provided-port-declare (lambda (o) (filter ast:provides? (om:ports o))))
(define-template x:required-port-declare (lambda (o) (filter ast:requires? (om:ports o))))
(define-template x:async-port-declare (lambda (o) (om:ports (.behaviour o))))

(define-template x:stream-member om:variables 'stream-comma-infix)
(define-template x:method-declare code:ons)
(define-template x:function-declare code:functions)

(define-template x:include-guard (lambda (o) (if (code:model2file?) o "")))
(define-template x:endif (lambda (o) (if (code:model2file?) o "")))

(define-template x:provided-port-reference-declare (lambda (o) (filter ast:provides? (om:ports o))))
(define-template x:required-port-reference-declare (lambda (o) (filter ast:requires? (om:ports o))))

(define-template x:injected-instance-declare code:injected-instances-system)
(define-template x:injected-binding-declare injected-bindings)
(define-template x:non-injected-instance-declare non-injected-instances)
(define-template x:system-rank ast:provided)

(define-method (c++:optional-return (o <trigger>))
  (let ((type ((compose .type .signature .event) o)))
    (if (is-a? type <void>) "") type))

(define-template x:optional-return c++:optional-return)

;; source-system
(define-template x:provided-port-reference-initializer ast:provided)
(define-template x:required-port-reference-initializer ast:required)

(define-template x:constructor-meta-initializer non-injected-instances)
(define-template x:shell-provided-meta-initializer ast:provided)
(define-template x:shell-required-meta-initializer ast:required)
(define-template x:injected-instance-meta-initializer injected-instances)
(define-template x:non-injected-instance-meta-initializer non-injected-instances)

(define-template x:dzn-locator code:dzn-locator)

(define-template x:header-data (lambda (o) (filter (is? <data>) (.elements o))))
(define-template x:header (lambda (o) (topological-sort (filter (negate (disjoin (is? <type>) (is? <interface>))) (map code:annotate-shells (.elements o))))))

;; shell-header-system
(define-template x:provided-port-instance-declare (lambda (o) (filter ast:provides? (om:ports o))))
(define-template x:required-port-instance-declare (lambda (o) (filter ast:requires? (om:ports o))))

;; shell-source-system
(define-template x:instance-meta-initializer identity)
(define-template x:shell-provided-in ast:provided-in-triggers)
(define-template x:shell-required-out ast:required-out-triggers)
(define-template x:shell-provided-out ast:provided-out-triggers)
(define-template x:shell-required-in ast:required-in-triggers)
(define-template x:capture-list identity)
(define-template x:capture code:capture-arguments 'capture-prefix)
(define-template x:shell-non-injected-instance-meta non-injected-instances)

;; foreign-header-component
(define-template x:pure-virtual-method-declare ast:in-triggers)
(define-template x:declare-method code:trigger)
(define-template x:declare-pure-virtual-method identity)

;; main
(define-template x:main-out-arg-define code:main-out-arg-define)
(define-template x:main-out-arg-define-formal identity)

(define-template x:main-event-map-flush-asd (if (and #f asd?) ast:required (const '())) 'event-map-prefix)

(define-template x:prefix-arguments-n c++:argument_n 'argument-prefix <expression>)

(define-template x:c++:type-ref c++:type-ref)

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
  (map (lambda (api) (->string (list "boost::shared_ptr< ::" (.name (.name component)) "::" api "> api_" api ";\n")))
       (delete-duplicates (map second ((asd-interfaces om:in?) (provided-interface component))))))

(define (c++:asd-api-instance-init component)
  (map (lambda (interface)
         (let ((port-name (.name (om:port component))))
           (->string (list ", api_" interface
                           "(boost::make_shared<" interface ">(boost::ref(component." port-name ")))\n"))))
       (delete-duplicates (map second ((asd-interfaces om:in?) (provided-interface component))))))

(define (c++:asd-cb-instance-declaration component)
  (map (lambda (cb) (->string (list "boost::shared_ptr< ::" (.name (.name component)) "::" cb "> cb_" cb ";\n")))
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
          (->string (list "struct " name ": public ::" (om:name component) "::" name "\n{\n"
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
     (make <glue-event> #:name (.name dzn) #:signature (.signature dzn) #:direction (.direction dzn) #:asd-channel (cadr asd) #:asd-event (caddr asd)))
   (filter om:in? (om:events (om:port model))) ((asd-interfaces om:in?) (provided-interface model))))

(define (c++:asd-method-definition model)
  (map
   (lambda (dzn asd)
     (make <glue-event> #:name (.name dzn) #:signature (.signature dzn) #:direction (.direction dzn) #:asd-channel (cadr asd) #:asd-event (caddr asd)))
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
           (->string (list "struct " interface "\n: public ::" name "::" interface "\n"
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
                                    (list "::" (om:name model) "::" interface "::PseudoStimulus " asd "(" formals ")\n"
                                          "{\n"
                                          (list "return static_cast< ::" (om:name model) "::" interface "::PseudoStimulus>(1 + api.in." dzn "(" arguments "));\n")
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
           (->string (list "void GetAPI(boost::shared_ptr< ::" (om:name model) "::" interface ">* api)\n"
                           "{\n"
                           "*api = api_" interface ";\n"
                           "}\n"))))
       (delete-duplicates (map second ((asd-interfaces om:in?) (provided-interface model))))))

(define (c++:asd-register-cb-definition model)
  (map (lambda (interface)
         (let ((port-type ((c++:scope-name) (om:port model))))
           (->string (list "void RegisterCB(boost::shared_ptr< ::" (om:name model) "::" interface "> cb)\n"
                           "{\n"
                           "cb_" interface " = cb;\n"
                           "}\n"))))
       (delete-duplicates (map second ((asd-interfaces om:out?) (provided-interface model))))))

(define-template x:construction-include c++:construction-include)

(define-template x:construction-signature c++:construction-signature)

(define-template x:construction-parameters c++:construction-parameters)

(define-template x:construction-parameters-locator-set c++:construction-parameters-locator-set)

(define-template x:construction-parameters-locator-get c++:construction-parameters-locator-get)

(define-template x:asd-constructor c++:asd-constructor)

(define-template x:asd-api-instance-declaration c++:asd-api-instance-declaration)

(define-template x:asd-api-instance-init c++:asd-api-instance-init)

(define-template x:asd-api-definition c++:asd-api-definition)

(define-template x:asd-cb-definition c++:asd-cb-definition)

(define-template x:asd-cb-instance-declaration c++:asd-cb-instance-declaration)

(define-template x:asd-cb-instance-init c++:asd-cb-instance-init)

(define-template x:asd-cb-event-init c++:asd-cb-event-init)

(define-template x:asd-get-api c++:asd-get-api)

(define-template x:asd-register-cb c++:asd-register-cb)

(define-template x:asd-register-st c++:asd-register-st)

(define-template x:asd-method-declaration c++:asd-method-declaration)

(define-template x:asd-method-definition c++:asd-method-definition)

(define-template x:asd-cb-method-definition c++:asd-cb-method-definition)

(define-template x:asd-get-api-definition c++:asd-get-api-definition)

(define-template x:asd-register-cb-definition c++:asd-register-cb-definition)
