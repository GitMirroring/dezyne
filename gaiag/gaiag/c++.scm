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
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)
  #:use-module (srfi srfi-1)

  #:use-module (gaiag animate)

  #:use-module (gaiag animate-code) ; FIXME: injected-binding?, injected-bindings
  #:use-module (gaiag norm-event)

  #:use-module (gaiag c)
  #:use-module (gaiag code)
  #:use-module (gaiag command-line)
  #:use-module (gaiag indent)
  #:use-module (gaiag misc)
  #:use-module (gaiag reader)
  #:use-module (gaiag resolve)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast2om)
  #:use-module (gaiag om)
  #:use-module (gaiag xpand)

  #:use-module (language dezyne location))

(define asd-interfaces (@@ (gaiag deprecated c++) asd-interfaces))
(define c++:scope-join (@@ (gaiag deprecated c++) c++:scope-join))
(define c++:scope-name (@@ (gaiag deprecated c++) c++:scope-name))

(define asd? #f) ;; FIXME: asd glue

;;; ast accessors / template helpers
;; (define-method (c++:scope+name-type (o <ast>))
;;   (om:scope+name o))

;; (define-method (c++:scope+name-type (o <bind>))
;;   ((compose c++:scope+name-type .type (cut om:instance (ast:model-scope) <>) injected-instance-name) o))

;; (define-method (c++:scope+name-type (o <instance>))
;;   ((compose c++:scope+name-type .type) o))

(define-method (c++:type-ref (o <formal>))
  (if (not (eq? 'in (.direction o))) "&" ""))

(define-method (c++:name (o <bind>))  ;; FIXME
  (injected-instance-name o))

(define-method (code:injected-instances-system (o <system>))
  (if (null? (injected-bindings o)) ""
      o))

(define-method (code:injected-instances (o <system>))
  (if (null? (injected-bindings o)) ""
      (injected-instances o)))

(define-method (code:port-name (o <instance>)) ;; MORTAL SIN HERE!!?
  (.name (om:port (om:component (ast:model-scope) o))))

(define-method (code:capture-arguments (o <trigger>))
  (map .name (filter (negate om:out-or-inout?) (ast:formals o))))



(define-method (c++:formal-type (o <formal>)) o)
(define-method (c++:formal-type (o <port>)) ((compose .elements .formals .signature car om:events) o))

(define-method (c++:return-type (o <trigger>)) ((compose .type .signature .event) o))
(define-method (c++:return-type (o <function>)) ((compose .type .signature) o))

(define-method (c++:reply-type-type (o <ast>))
  (let ((type (ast:expression-type o)))
    (match type
      (($ <bool>) "bool")
      (($ <int>) "int")
      (($ <enum>) (string-join (cons "" (map symbol->string (append (om:scope+name type) '(type)))) "::"))
      (($ <void>) "void"))))

(define-method (c++:type-name o)
  (let ((type (or (as o <model>) (as o <type>) (.type o))))
    (om:scope+name type)))

(define-method (c++:type-name (o <bind>))
  ((compose c++:type-name .type (cut om:instance (ast:model-scope) <>) injected-instance-name) o))

(define-method (c++:type-name (o <enum-field>))
  (om:scope+name o))

(define-method (c++:type-name (o <literal>))
  (map code:->string (cons (symbol) (om:scope+name o))))

(define-method (c++:type-name-type o)
  (let* ((type (or (as o <model>) (as o <type>) (.type o)))
         (scope+name (om:scope+name type)))
    (map code:->string
         (match type
           (($ <enum>) (cons (symbol) (append scope+name (list 'type))))
           ((or ($ <bool>) ($ <int>) ($ <void>)) scope+name)
           (_ (cons (symbol) scope+name))))))

(define-method (c++:type-name-type (o <enum-field>))
  (map code:->string (cons (symbol) (om:scope+name o))))

(define-method (c++:type-name-type (o <literal>))
  (map code:->string (cons (symbol) (om:scope+name o))))

(define (c++:scoped-model-name o)
  (let* ((scope+name (.name o))
         (scope (map symbol->string (.scope scope+name)))
         (name (symbol->string (.name scope+name))))
    (string-join (append scope (list name)) "_")))

(define (xc++:scope-name o)
  (let* ((scope+name (.name o))
         (scope (map symbol->string (.scope scope+name))))
    (string-join scope "_" 'suffix)))

(define-method (code:port-name (o <on>))
  ((compose .port.name car .elements .triggers) o))

(define (c++:pump-include o) (if (pair? (om:ports (.behaviour o))) "#include <dzn/pump.hh>" ""))

(define-method (c++:enum-field->string (o <enum>))
  (map (symbol->enum-field o) ((compose .elements .fields) o)))
(define-method (c++:string->enum (o <model>))
  (om:enums o))
(define-method (c++:string->enum (o <enum>))
  (map (symbol->enum-field o) ((compose .elements .fields) o)))

(define-method (c++:enum->string (o <interface>))
  (append (om:enums) (om:enums o)))


(define-method (code:instance-name (o <trigger>)) ;; MORTAL SIN HERE!!?
  ((compose code:instance-name (cut .port (ast:model-scope) <>)) o))

(define-method (code:instance-name (o <port>)) ;; MORTAL SIN HERE!!?
  (.name (om:instance (ast:model-scope) o)))

(define-method (code:instance-name (o <bind>))
  (ast:instance-name o))

(define-method (code:instance-name (o <binding>))
  (ast:instance-name o))


(define-method (code:instance-port-name (o <trigger>)) ;; MORTAL SIN HERE!!?
  ((compose code:instance-port-name (cut .port (ast:model-scope) <>)) o))
(define-method (code:instance-port-name (o <port>)) ;; MORTAL SIN HERE!!?
  (let* ((bind (om:port-bind (ast:model-scope) o))
         (instance-bind (om:instance-binding? bind)))
    (.port.name instance-bind)))

(define-method (trigger->on (o <trigger>))
  (make <on> #:triggers (make <triggers> #:elements (list o)) #:statement (make <compound>)))

(define-method (code:syntesize-ons (o <component>))
  (map trigger->on (ast:in-triggers o)))

(define-method (code:dzn-locator (o <instance>)) ;; MORTAL SIN HERE!!?
  (let* ((model (ast:model-scope)))
    (if (null? (injected-bindings model)) ""
        "_local")))

(define-method (code:component-port (o <port>)) ;; MORTAL SIN HERE!!?
  (let* ((model (ast:model-scope))
         (bind (om:port-bind model o)))
    (om:instance-binding? bind)))

(define-method (code:non-injected-bindings (o <system>))
  (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) o))))

(define-method (code:main-out-arg-define (o <trigger>))
  (let ((formals ((compose .elements .formals) o)))
    (map (lambda (f i) (clone f #:name i))
         formals (iota (length formals)))))

(define-method (code:main-out-arg-define-formal (o <formal>)) ;; MORTAL SIN HERE!!?
  (let ((type ((compose .value .type) o)))
    (if (not (om:out-or-inout? o)) ""
        (if (equal? type 'int) (x:main-out-arg-define-formal-int o)
            "/*FIXME*/"))))

(define-method (code:main-out-arg (o <trigger>))
  (let ((formals ((compose .elements .formals) o)))
    (map (lambda (f i) (if (not (om:out-or-inout? f)) (clone f #:name i)
                           (clone f #:name (string-append "_" (number->string i)))))
         formals (iota (length formals)))))

(define-method (code:main-event-map-match-return (o <trigger>))
  (if (om:in? (.event o)) o ""))


(define-method (ast:req-events (o <component>))
  (append-map (lambda (port)
                (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
                     (filter (conjoin om:in? (compose (cut eq? 'req <>) .name)) (om:events port))))
              (om:ports (.behaviour o))))

(define-method (ast:clr-events (o <component>))
  (append-map (lambda (port)
                (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
                     (filter (conjoin om:in? (compose (cut eq? 'clr <>) .name)) (om:events port))))
              (om:ports (.behaviour o))))

(define-method (ast:argument_n (o <trigger>))
  (map
   (lambda (f i) (clone f #:name (string-append "_"  (number->string i))))
   (ast:formals o)
   (iota (length (ast:formals o)) 1 1)))


;;; templates

(define-template x:name c++:name)
(define-template x:declare-method code:trigger)
(define-template x:formal-type c++:formal-type)
(define-template x:return-type c++:return-type #f <type>)
(define-template x:type-name c++:type-name 'type-infix)
(define-template x:c++:type-name-type c++:type-name-type 'type-infix)
(define-template x:calls ast:void-in-triggers)
(define-template x:rcalls ast:valued-in-triggers)
(define-template x:prefix-formals-type ast:formals 'formal-prefix)
(define-template x:reqs ast:req-events)
(define-template x:clrs ast:clr-events)
(define-template x:direction ast:direction)
(define-template x:variable-expression (compose code:expression .expression) #f <expression>)

(define-template x:scoped-model-name c++:scoped-model-name)

(define-template x:scope-name xc++:scope-name)


(define-template x:reply-type-type c++:reply-type-type)

(define-template x:port-name code:port-name)
(define-template x:pump-include c++:pump-include)

(define-template x:open-namespace (lambda (o) (map (lambda (x) (string-join (list " namespace " (symbol->string x) " {") "")) (om:scope o))))
(define-template x:close-namespace (lambda (o) (map (lambda (x) "}\n") (om:scope o))))

(define-template x:meta identity)
(define-template x:ports-meta-list (lambda (o) (filter om:requires? (om:ports o))) 'meta-infix)
(define-template x:check-bindings-list (lambda (o) ((->join ",") (map (lambda (port) (list "[this]{"(.name port) ".check_bindings();}")) (om:ports o)))))

(define-template x:interface-include (lambda (o) (map (lambda (p) (string-append "#include \"" (code:file-name p) ".hh\"\n")) (om:ports o))))

(define-template x:global-enum-definer (lambda (o) (om:enums)))
(define-template x:check-in-binding (lambda (o) (filter om:in? (om:events o))))
(define-template x:check-out-binding (lambda (o) (filter om:out? (om:events o))))

(define-template x:interface-enum-to-string c++:enum->string)
(define-template x:interface-string-to-enum c++:enum->string)

(define-template x:enum-field-to-string c++:enum-field->string)


(define-template x:string-to-enum c++:string->enum)

(define-template x:asd-voidreply (lambda (o) (if asd? "__ASD_VoidReply, " "")))

(define-template x:async-member-initializer (lambda (o) (om:ports (.behaviour o))))

(define-template x:scoped-port-name (lambda (port) (let ((scope-name ((compose .name .type) port))) (append (.scope scope-name) (list (.name scope-name))))) 'type-infix)

(define-template x:reply-member-declare code:reply-types)

(define-template x:variable-member-declare (lambda (o) (om:variables o)))

(define-template x:out-binding-lambda (lambda (o) (filter om:provides? (om:ports o))))
(define-template x:provided-port-declare (lambda (o) (filter om:provides? (om:ports o))))
(define-template x:required-port-declare (lambda (o) (filter om:requires? (om:ports o))))
(define-template x:async-port-declare (lambda (o) (om:ports (.behaviour o))))

(define-template x:stream-member om:variables 'stream-comma-infix)
(define-template x:method-declare code:ons)
(define-template x:function-declare code:functions)

(define-template x:meta-child code:instances 'meta-child-infix)
(define-template x:include-guard (lambda (o) (if (model2file) o "")))
(define-template x:endif (lambda (o) (if (model2file) o "")))

(define-template x:component-include (if (model2file) om:instances
                                         (lambda (o) (filter (disjoin (compose (is? <foreign>) .type)
                                                                      (conjoin om:imported? (lambda (i) (not (equal? (source-file o)
                                                                                                                     (source-file (.type i)))))))
                                                             (om:instances o)))))

(define-template x:provided-port-reference-declare (lambda (o) (filter om:provides? (om:ports o))))
(define-template x:required-port-reference-declare (lambda (o) (filter om:requires? (om:ports o))))

(define-template x:injected-instance-declare code:injected-instances-system)
(define-template x:injected-binding-declare injected-bindings)
(define-template x:non-injected-instance-declare non-injected-instances)
(define-template x:system-rank ast:provided)

;;(define-template x:type c++:scope+name-type 'type-infix)


;; source-system
(define-template x:meta-child om:instances 'meta-child-infix)
(define-template x:injected-instance-system-initializer code:injected-instances-system)
(define-template x:injected-instance-initializer code:injected-instances)


(define-template x:component-port code:component-port)
(define-template x:provided-port-reference-initializer ast:provided)
(define-template x:required-port-reference-initializer ast:required)

(define-template x:constructor-meta-initializer non-injected-instances)
(define-template x:shell-provided-meta-initializer ast:provided)
(define-template x:shell-required-meta-initializer ast:required)
(define-template x:injected-instance-meta-initializer injected-instances)
(define-template x:non-injected-instance-meta-initializer non-injected-instances)

(define-template x:dzn-locator code:dzn-locator)

(define-template x:header- (lambda (o) (filter (is? <interface>) (.elements o))))
(define-template x:header (lambda (o) (topological-sort (filter (negate (disjoin (is? <type>) (is? <interface>))) (.elements o)))))
(define-template x:source (lambda (o) (topological-sort (filter (negate (is? <type>)) (.elements o)))))

;; shell-header-system
(define-template x:provided-port-instance-declare (lambda (o) (filter om:provides? (om:ports o))))
(define-template x:required-port-instance-declare (lambda (o) (filter om:requires? (om:ports o))))

;; shell-source-system
(define-template x:instance-meta-initializer identity)
(define-template x:shell-provided-in ast:provided-in-triggers)
(define-template x:shell-required-out ast:required-out-triggers)
(define-template x:shell-provided-out ast:provided-out-triggers)
(define-template x:shell-required-in ast:required-in-triggers)
(define-template x:capture-list identity)
(define-template x:capture code:capture-arguments 'capture-prefix)
(define-template x:shell-non-injected-instance-meta non-injected-instances)

(define-template x:instance-name code:instance-name)
(define-template x:instance-port-name code:instance-port-name)

;; foreign-header-component
(define-template x:pure-virtual-method-declare ast:in-triggers)
(define-template x:declare-method code:trigger)
(define-template x:declare-pure-virtual-method identity)

(define-template x:reply-type-name code:reply-scope+name)
(define-template x:main-out-arg-define code:main-out-arg-define)
(define-template x:main-out-arg-define-formal code:main-out-arg-define-formal 'formal-infix)
(define-template x:main-out-arg-define-formal-int identity)
(define-template x:main-out-arg code:main-out-arg 'argument-infix)

(define-template x:main-port-connect-in ast:out-triggers-in-events)
(define-template x:main-port-connect-out ast:out-triggers-out-events)
(define-template x:main-provided-port-init ast:provided)
(define-template x:main-required-port-init ast:required)

(define-template x:main-event-map-void ast:void-in-triggers 'event-map-prefix)
(define-template x:main-event-map-valued ast:valued-in-triggers 'event-map-prefix)
(define-template x:main-event-map-flush (if (and #f asd?) (const '()) ast:required) 'event-map-prefix)
(define-template x:main-event-map-flush-asd (if (and #f asd?) ast:required (const '())) 'event-map-prefix)

(define-template x:main-event-map-match-return code:main-event-map-match-return)
(define-template x:main-required-port-name ast:required 'main-port-name-infix)


(define-template x:arguments-n ast:argument_n 'argument-infix <expression>)
(define-template x:prefix-arguments-n ast:argument_n 'argument-prefix <expression>)

(define-template x:argument_n identity)

(define-template x:c++:type-ref c++:type-ref)

;;; dump to file

(define (dzn-async? o)
  (or (gaiag-dzn-async? o)
      (generator-dzn-async? o)))

(define (gaiag-dzn-async? o)
  (equal? ((compose .scope .name) o) '(dzn async)))

(define (generator-dzn-async? o)
  (let* ((name (.name o))
         (scope (.scope name)))
    (and (pair? scope)
         (eq? (car scope) 'dzn)
         (symbol-prefix? 'async (.name name)))))

(define (c++:skel-file model)
  ((->symbol-join '_) (append (drop-right (om:scope+name model) 1) '(skel) (take-right (om:scope+name model) 1))))

(define (dump o)
  (match o
    (($ <interface>) (dump-interface o))
    ((or ($ <component>) ($ <foreign>)) (dump-component o))
    (($ <system>) (dump-system o))))

(define (dump-interface o)
  ((@@ (gaiag c) dump-interface) o))

(define c++-file (@ (gaiag deprecated c++) c++-file)) ;; FIXME
(define (dump-component o)
  (if (and (glue)
           (eq? (glue) 'asd)
           (map-file o))
      ;; TODO: asd glue templates
      (let ((name ((om:scope-name) o)))
        (dump-indented (symbol-append name '.hh)
                       (lambda ()
                         (c++-file 'asd.hh.scm (code:module o))))
        (dump-indented (symbol-append name '.cc)
                       (lambda ()
                         (c++-file 'asd.cc.scm (code:module o))))
        ((@@ (gaiag c) dump-main) o)
        (for-each (lambda (port)
                    (let* ((module (code:module o))
                           (interface (symbol-drop (last (.type port)) 1))
                           (INTERFACE (symbol-upcase interface)))
                      (module-define! module '.interface interface)
                      (module-define! module '.INTERFACE INTERFACE)
                      (dump-indented (symbol-append interface 'Component.h)
                                     (cute c++-file 'asdcomponent.h.scm module))))
                  (filter om:requires? (om:ports o))))
      (let ((name ((om:scope-name) o))
            (skel-name (if (is-a? o <foreign>) (c++:skel-file o) ((om:scope-name) o)))
            (interfaces (map .type ((compose .elements .ports) o))))
        ((@@ (gaiag c) dump-main) o)
        (dump-indented (symbol-append skel-name (code:extension (make <interface>)))
                       (cute c++-file (if (is-a? o <foreign>) 'foreign.hh.scm 'component.hh.scm) (code:module o)))
        (dump-indented (symbol-append skel-name (code:extension o))
                       (cute c++-file (if (is-a? o <foreign>) 'foreign.cc.scm 'component.cc.scm) (code:module o)))
        ;; TODO: rename dzn glue templates
        (when (and (is-a? o <foreign>) (map-file o))
            (dump-indented (symbol-append name '.hh)
                           (lambda ()
                             (c++-file 'glue-bottom-component.hh.scm (code:module o))))
            (dump-indented (symbol-append name '.cc)
                           (lambda ()
                             (c++-file 'glue-bottom-component.cc.scm (code:module o))))))))

(define (dump-system o)
  ((@@ (gaiag c) dump-system) o)
  (if (map-file o) ((@ (gaiag deprecated c++) dump-system-glue) o)))

(define (map-file o)
  (let* ((files (command-line:get '() '()))
         (map-files (filter (cut string-suffix? ".map" <>) files))
         (map-file-name (string-append (symbol->string (map-file-name o)) ".map"))
         (map-files (if (pair? map-files) map-files (list map-file-name))))
    (and=> (find (lambda (f) (equal? (basename f) map-file-name)) map-files)
           try-find-file)))

(define (map-file-name o)
  (match o
    ((or ($ <foreign>) ($ <component>) ($ <system>)) (map-file-name (om:port o)))
    (_ (om:name o)) ;; dzn::IConsole ==> IConsole.map
    (_ ((om:scope-name) o)))) ;; dzn::IConsole ==> dzn_IConsole.map


(define (ast-> ast)
  (let* ((om ((om:register code:om #t) ast))
         (models ((om:filter:p <model>) om))
         (models (filter (negate om:imported?) models))
         ;; Generator-synthesized models look non-imported, filter harder
         (models (filter (negate dzn-async?) models))
         (deprecated (command-line:get 'deprecated #f)))
    (ast:set-scope om
                   (if (and deprecated (string-contains deprecated "model2file"))
                       (map (@ (gaiag deprecated c++) dump) models)
                       (let* ((main (command-line:get 'model #f))
                              (main (and main (find (compose (cut eq? (string->symbol main) <>) (om:scope-name)) models)))
                              (module (make-module 31 `(,(resolve-module '(gaiag animate-code))
                                                        ,(resolve-module '(gaiag c++)))))
                              (models (sort (filter (disjoin (is? <data>)
                                                             (conjoin (negate dzn-async?) (negate om:imported?) (negate (is? <foreign>))))
                                                    (.elements om))
                                            (lambda (a b) (or (and (is-a? <interface> a)
                                                                   (is-a? <component> b))
                                                              (and (is-a? <interface> a)
                                                                   (is-a? <system> b))
                                                              (and (is-a? <component> a)
                                                                   (is-a? <system> b)))))))
                         (module-define! module 'root (clone om #:elements (if (glue) (filter (negate (is? <system>)) models) models)))
                         (code:dump-file (basename (symbol->string (source-file om)) ".dzn") module)
                         (map dump-component (filter (is? <foreign>) (.elements om)))
                         (if (glue) (map dump-system (filter (is? <system>) (.elements om))))
                         (when main ((@@ (gaiag c) dump-main) main))))))
  "")

