;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn glue)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 regex)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn misc)
  #:use-module (dzn command-line)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn shell-util)
  #:use-module (dzn config)

  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn dzn)
  #:use-module (dzn normalize)
  #:use-module (dzn parse)
  #:use-module (dzn templates)

  #:export (<glue-event>
            .asd-channel
            .asd-event

            asd?
            asd-interfaces
            map-file
            event2->interface1-event1-alist
            code:glue
            c++:dump-glue
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
            c++:asd-reset-api
            c++:construction-include
            c++:construction-parameters
            c++:construction-parameters-locator-get
            c++:construction-parameters-locator-set
            c++:construction-signature
            c++:decapitalize-asd-interface-name
            c++:implemented-port-name
            ;; c++:header-model-glue
            ;; c++:model-glue

            %x:glue-bottom-header
            %x:glue-bottom-source
            %x:glue-top-header
            %x:glue-top-source
            ))

(define-ast <glue-event> (<event>)
  (asd-channel)
  (asd-event))

(define-ast <glue-system> (<system>)
  (asd-in #:init-form (list))
  (asd-out #:init-form (list)))

(define %x:glue-bottom-header (make-parameter #f))
(define %x:glue-bottom-source (make-parameter #f))
(define %x:glue-top-header (make-parameter #f))
(define %x:glue-top-source (make-parameter #f))

(define asd? #f) ;; FIXME: asd glue

(define (code:glue)
  (command-line:get 'glue #f))

(define (glue:model-name o)
  (string-join (ast:full-name o) "_"))

(define (glue:type-name o)
  (string-join (ast:full-name (.type o)) "::"))

(define ((om:type model) o)
  (or (as o <type>)
      (.type o)))

;; (define-method (c++:header-model-glue (o <root>))
;;   (filter-map (lambda (o)
;;                 (if (and (code:glue) (is-a? o <foreign>)) o
;;                     #f))
;;               ((@@ (dzn c++)
;;                    c++:model) o)))

;; (define-method (c++:model-glue (o <root>))
;;   (filter (lambda (o) (and (code:glue) (is-a? o <foreign>)))
;;           ((@@ (dzn c++) c++:model) o)))

(define-method (c++:dump-glue (o <system>))
  (let* ((dir (command-line:get 'output "."))
         (stdout? (equal? dir "-"))
         (dir (string-append dir "/" (dzn:dir o)))
         (name (ast:name o)))
    (if stdout?
        (begin ((%x:glue-top-header) o)
               ((%x:glue-top-source) o))
        (begin (with-output-to-file (string-append dir name "Component.h") (cut (%x:glue-top-header) o))
               (with-output-to-file (string-append dir name "Component.cpp") (cut (%x:glue-top-source) o))))))

(define-method (c++:dump (o <foreign>))
  (let* ((dir (command-line:get 'output "."))
         (stdout? (equal? dir "-"))
         (dir (string-append dir "/" (dzn:dir o)))
         (name (string-join (ast:full-name o) "_")) ;;MORTAL SIN HERE
         (skel-name (code:skel-file o))
         (iext (dzn:extension (make <interface>)))
         (cext (dzn:extension (make <component>))))
    (when (map-file o)
      (if stdout?
          (begin (when (code:header?) ((%x:glue-bottom-header) o))
                 ((%x:glue-bottom-source) o))
          (begin (when (code:header?)
                   (with-output-to-file (string-append dir name iext) (cut (%x:glue-bottom-header) o)))
                 (with-output-to-file (string-append dir name cext) (cut (%x:glue-bottom-source) o)))))))

(define-method (code:function-type (o <glue-event>))
  ((compose code:function-type .signature) o))

(define-method (c++:decapitalize-asd-interface-name o)
  ((compose (cut string-downcase <> 0 1)
            (lambda (o) (if (eq? #\I (string-ref o 0)) (substring o 1) o))
            ast:name .type ast:provides-port)
   (parent o <model>)))

(define (event2->interface1-event1-alist- string)
  (and-let* ((string string)
             (lst (string-split string #\newline))
             (lst (filter (lambda (x) (not (string-prefix? "//" x))) lst))
             (lst (map (lambda (o) (string-tokenize o char-set:graphic)) lst))
             (lst (filter pair? lst)))
            (fold (lambda (e r) (acons (third e) (take e 2) r)) '() lst)))

(define (event2->interface1-event1-alist port-or-model)
  (event2->interface1-event1-alist-
   ((compose gulp-file map-file) port-or-model)))

(define* ((asd-interfaces #:optional (dir? identity)) model)
  (let* ((interfaces
          (filter dir? (ast:event* model)))
         (alist (event2->interface1-event1-alist model))
         (interfaces (filter-map (lambda (x) (assoc (.name x) alist)) interfaces)))
    (if (pair? interfaces) interfaces '())))

(define (map-file o)
  (let* ((files (command-line:get '() '()))
         (map-files (filter (cut string-suffix? ".map" <>) files))
         (map-file-name (map-file-name o)))
    (and map-file-name
        (let* ((map-file-name (string-append map-file-name ".map"))
               (map-files (if (pair? map-files) map-files (list map-file-name))))
          (and=> (find (lambda (f) (equal? (basename f) map-file-name)) map-files)
                 try-find-file)))))

(define (map-file-name o)
  (match o
    ((or ($ <foreign>) ($ <component>) ($ <system>)) (and=> (ast:provides-port o) map-file-name))
    ((or ($ <interface>) ($ <port>)) (glue:model-name o)))) ;; dzn::IConsole ==> dzn_IConsole.map

(define (string->mapping string)
  (and-let* ((string string)
             (lst (string-split string #\newline))
             (lst (filter (lambda (x) (not (string-prefix? "//" x))) lst))
             (lst (map (lambda (o) (string-tokenize o char-set:graphic)) lst))
             (lst (filter pair? lst)))
    lst))

(define (mapping->channel mapping)
  (let loop ((lst mapping))
    (if (null? lst) '()
        (let ((channel (caar lst)))
          (receive (same rest)
              (partition (lambda (m) (equal? (car m) channel)) lst)
            (append (list (cons (caar same) (map cdr same))) (loop rest)))))))

;; glue-top-source-glue-system
(define-public (parse-component-map component)
  (or (and-let* ((files (command-line:get '() '()))
                 (map-files (filter (cut string-suffix? ".map" <>) files))
                 (file-name (string-append (glue:model-name component) ".map"))
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
  (let* ((name (glue:model-name component))
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
        (string-append (ast:name (.name component)) "Component::GetInstance()")
        (let* ((matches-list (map (lambda (third) (string-match "[(]([^)]*)[)]" third))
                                  (map third usr-list)))
               (matches-list (filter identity matches-list))
               (parameters-list (map (cut match:substring <> 1) matches-list)))
          (string-append
           (ast:name (.name component)) "Component::GetInstance("
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
       (delete-duplicates (map second ((asd-interfaces ast:in?) (provided-interface component))))))

(define (c++:asd-api-instance-init component)
  (map (lambda (interface)
         (let ((port-name (.name (ast:provides-port component))))
           (->string (list ", api_" interface
                           "(boost::make_shared<" interface ">(boost::ref(component." port-name ")))\n"))))
       (delete-duplicates (map second ((asd-interfaces ast:in?) (provided-interface component))))))

(define (c++:asd-cb-instance-declaration component)
  (map (lambda (cb) (->string (list "boost::shared_ptr< ::" cb "> cb_" cb ";\n")))
       (delete-duplicates (map second ((asd-interfaces ast:out?) (provided-interface component))))))

(define (c++:asd-cb-instance-init component)
  (map (lambda (cb) (->string (list "cb_" cb " = boost::make_shared<" cb ">(boost::ref(" (.name (ast:provides-port component)) "));\n")))
       (delete-duplicates (map second ((asd-interfaces ast:out?) (provided-interface component))))))

(define (c++:asd-cb-event-init component)
  (map (lambda (entry)
         (let* ((event (first entry))
                (interface (second entry))
                (event (ast:lookup (provided-interface component) event))
                (formals (ast:formal* event))
                (port (ast:provides-port component))
                (port-name (.name port)))
           (->string (list "component." port-name ".out." (first entry)
                           " = boost::bind(&" (ast:name component) "Glue::" (first entry) ","
                           (comma-join (list "this" (comma-join (map (compose (cut string-append "_" <>) number->string) (iota (length formals) 1 1))))) ");\n"))))
       ((asd-interfaces ast:out?) (provided-interface component))))

(define (c++:asd-cb-definition component)
  (map (lambda (entry)
        (let* ((name (car entry))
               (dzn-events (cadr entry))
               (asd-events (caddr entry)))
          (->string (list "struct " name ": public ::" name "\n{\n"
                 (glue:type-name (ast:provides-port component)) "& port;\n"
                 name "(" (glue:type-name (ast:provides-port component)) "& port)\n"
                 ": port(port)\n"
                 "{}\n"
                 (map (lambda (asd dzn)
                        (let* ((event (ast:lookup (provided-interface component) dzn))
                               (formals (ast:formal* event))
                               (arguments (comma-join (map .name formals)))
                               (formals (comma-join (map (lambda (formal)
                                               (list (if (eq? (.direction formal) 'in) "const ")
                                                     "asd::value<" ((compose .value (om:type component)) formal) ">::type& " (.name formal)))
                                             formals))))
                          (list "void " asd "(" formals "){\nport.out." dzn "(" arguments ");\n}\n")))
                      asd-events dzn-events)
                 "};\n"))))
      (map (lambda (name)
             (let* ((lst (filter (lambda (entry) (equal? name (second entry))) ((asd-interfaces ast:out?) (provided-interface component))))
                    (dzn-events (map first lst))
                    (asd-events (map third lst)))
              (list name dzn-events asd-events)))
           (delete-duplicates (map second ((asd-interfaces ast:out?) (provided-interface component)))))))

(define (c++:asd-get-api component)
  (map (lambda (api) (->string (list "component->GetAPI(&api_" api ");\n")))
       (delete-duplicates (map second ((asd-interfaces ast:in?) (provided-interface component))))))

(define (c++:asd-register-cb component)
  (map (lambda (cb) (->string (list "component->RegisterCB(cb_" cb ");\n")))
       (delete-duplicates (map second ((asd-interfaces ast:out?) (provided-interface component))))))

(define (c++:asd-register-st component)
  (if (pair? (filter ast:out? (ast:event* (ast:provides-port component))))
      (->string (list "component->RegisterCB(boost::make_shared<SingleThreaded>(this, boost::ref(dzn_rt)));\n"))
      ""))

(define (c++:asd-reset-api component)
  (map (lambda (api) (->string (list "api_" api ".reset();\n")))
       (delete-duplicates (map second ((asd-interfaces ast:in?) (provided-interface component))))))

(define (c++:asd-method-declaration model)
  (map
   (lambda (dzn asd)
     (clone (make <glue-event> #:name (.name dzn) #:signature (.signature dzn) #:direction (.direction dzn) #:asd-channel (cadr asd) #:asd-event (caddr asd))
            #:parent model))
   (filter ast:in? (ast:event* (ast:provides-port model))) ((asd-interfaces ast:in?) (provided-interface model))))

(define (c++:asd-method-definition model)
  (map
   (lambda (dzn asd)
     (clone (make <glue-event> #:name (.name dzn) #:signature (.signature dzn) #:direction (.direction dzn) #:asd-channel (cadr asd) #:asd-event (caddr asd))
            #:parent model))
   (filter ast:in? (ast:event* (ast:provides-port model))) ((asd-interfaces ast:in?) (provided-interface model))))

(define (c++:asd-cb-method-definition model)
  (map (lambda (entry)
         (let* ((event-name (first entry))
                (interface (second entry))
                (event (ast:lookup (provided-interface model) event-name))
                (formals (ast:formal* event))
                (arguments (comma-join (map .name formals)))
                (formals (comma-join (map (lambda (formal)
                                            (list ((compose .value (om:type model)) formal) (if (eq? (.direction formal) 'in) " " "& ") (.name formal)))
                                          formals)))
                (port (ast:provides-port model))
                (port-name (.name port)))
           (->string (list "void " (first entry) "(" formals ")\n"
                           "{\n"
                           "cb_" interface "->" (third entry) "(" arguments ");\n"
                           "defer_processCBs();\n"
                           "}\n"))))
       ((asd-interfaces ast:out?) (provided-interface model))))

(define (c++:asd-api-definition model)
  (map (lambda (entry)
         (let ((name (ast:name (.name model)))
               (port-type (glue:type-name (ast:provides-port model)))
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
                              (let* ((event (ast:lookup (provided-interface model) dzn))
                                     (void? (is-a? (.type (.signature event)) <void>))
                                     (formals (ast:formal* event))
                                     (arguments (comma-join (map .name formals)))
                                     (formals (comma-join (map (lambda (formal)
                                                                 (list (if (eq? (.direction formal) 'in) "const ") "asd::value< " ((compose .value (om:type model)) formal) " >::type& " (.name formal)))
                                                               formals)))
                                     (port (ast:provides-port model)))
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
              (let* ((lst (filter (lambda (entry) (equal? api (second entry))) ((asd-interfaces ast:in?) (provided-interface model))))
                     (dzn-events (map first lst))
                     (asd-events (map third lst)))
                (list api dzn-events asd-events)))
            (delete-duplicates (map second ((asd-interfaces ast:in?) (provided-interface model)))))))

(define (c++:asd-get-api-definition model)
  (map (lambda (interface)
         (let ((port-type (glue:type-name (ast:provides-port model))))
           (->string (list "void GetAPI(boost::shared_ptr< ::" interface ">* api)\n"
                           "{\n"
                           "*api = api_" interface ";\n"
                           "}\n"))))
       (delete-duplicates (map second ((asd-interfaces ast:in?) (provided-interface model))))))

(define (c++:asd-register-cb-definition model)
  (map (lambda (interface)
         (let ((port-type (glue:type-name (ast:provides-port model))))
           (->string (list "void RegisterCB(boost::shared_ptr< ::" interface "> cb)\n"
                           "{\n"
                           "cb_" interface " = cb;\n"
                           "}\n"))))
       (delete-duplicates (map second ((asd-interfaces ast:out?) (provided-interface model))))))

(define (c++:implemented-port-name model)
  (.name (ast:provides-port model)))
