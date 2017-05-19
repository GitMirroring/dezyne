;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2016, 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
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

(define-module (gaiag code)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 peg)
  #:use-module (ice-9 peg codegen)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (gaiag lexicals)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag ast2om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag util)

  #:use-module (gaiag animate)
  #:use-module (gaiag animate-code)
  #:use-module (gaiag command-line)
  #:use-module (gaiag compare)
  #:use-module (gaiag indent)
  #:use-module (gaiag misc)
  #:use-module (gaiag norm-event)
  #:use-module (gaiag resolve)

  #:export (ast:code
            ast:scope+name
            code-file
            code:animate-file
            code:extension
            code:indenter
            code:module
            code:om
            dump-component
            dump-global
            dump-header
            dump-indented
            dump-main
            dump-system
            language
            pipe))

(define code:indenter (make-parameter indent))

(define (ast:code ast)
  (let ((om ((om:register code:om #t) ast)))
    (parameterize ((ast:root om)
                   (template-dir (append (prefix-dir) `(templates ,(language)))))
                  (map dump (filter (negate om:imported?) ((om:filter:p <model>) om)))
                  (dump-header)))
  "")

(define (code:om ast)
  ((compose-root
    (lambda (o)
      (let ((model-names (map (compose .name car) (@@ (gaiag om) *ast-alist*))))
        (if (and (member (language) '(c++ c++03 c++-msvc11 xjavascript))
                 (not (member 'iclient_socket model-names))
                 (not (member 'imodelchecker model-names)))
            (code-norm-event o)
            (code-norm-event-auwe-meuk o))))
    ast:resolve
    ast->om
    ) ast))

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define (dump-indented file-name thunk)
  (dump-output file-name
               (if (code:indenter)
                   (lambda () (pipe thunk (lambda () ((code:indenter)))))
                   thunk)))

(define (dump-header)
  (and-let* ((header (template-file `(header ,(code:extension (make <component>)))))
             (header (components->file-name header))
             ((file-exists? header)))
            (dump-string (basename header) (gulp-file header))))

(define (dump-global o)
  (and-let* (((null-is-#f (om:enums)))
             (template (template-file `(global ,(symbol-append (code:extension o) '.scm))))
             ((file-exists? (components->file-name template))))
            (dump-indented (list 'dzn 'global (code:extension o))
                           (lambda ()
                             (code-file 'global (code:module o))))))

(define (dump o)
  (match o
    (($ <interface>) (dump-interface o))
    (($ <component>) (dump-component o))
    (($ <system>) (dump-system o))))

(define (dump-interface o)
  (dump-global o)
  (let ((name ((om:scope-name) o)))
    (dump-indented `(,@(code:dir o) ,name ,(code:extension o))
                   (lambda ()
                     (code-file 'interface (code:module o))))))

(define (code:dir o)
  (if (eq? (language) 'cs) '()
      '(dzn)))

(define (dump-component o)
  (dump-global o)
  (let ((name ((om:scope-name) o))
        (interfaces (map .type ((compose .elements .ports) o))))
    (when (.behaviour o)
      (map dump interfaces)
      (dump-indented `(,@(code:dir o) ,name ,(code:extension o))
                     (lambda ()
                       (code-file 'component (code:module o)))))
    (dump-main o)))

(define (dump-main o)
  (and-let* ((name ((om:scope-name) o))
             (model (and (and=> (command-line:get 'model #f) string->symbol)))
             ((eq? model name)))
            (dump-indented (symbol-append 'main (code:extension o))
                           (lambda ()
                             (code-file 'main (code:module o))))))

(define (dump-system o)
  (let* ((name ((om:scope-name) o))
         (model (and (and=> (command-line:get 'model #f) string->symbol)))
         (interfaces (map .type ((compose .elements .ports) o)))
         (shell (command-line:get 'shell #f))
         (template (if (and shell (eq? name (string->symbol shell))) 'shell 'system)))
    (dump-indented `(,@(code:dir o) ,name ,(code:extension o))
                   (lambda ()
                     (code-file template (code:module o))))
    (dump-main o)))

(define (code-file file-name module)
  (let ((model (module-ref module 'model)))
   (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
     (code:animate-file (symbol-append file-name (code:extension model) '.scm) module))))

(define (language)
  (string->symbol (command-line:get 'language "c++")))

(define (code:extension o)
  (match o
    (($ <interface>)
     (assoc-ref '((c . .h)
                  (c++ . .hh)
                  (c++03 . .hh)
                  (c++-msvc11 . .hh)
                  (dzn . .dzn)
                  (scheme . .scm)
                  (java . .java)
                  (java7 . .java)
                  (javascript . .js)
                  (cs . .cs)
                  (python . .py))
                (language)))
    ((or ($ <component>) ($ <system>))
     (assoc-ref '((c . .c)
                  (c++ . .cc)
                  (c++03 . .cc)
                  (c++-msvc11 . .cc)
                  (dzn . .dzn)
                  (scheme . .scm)
                  (java . .java)
                  (java7 . .java)
                  (javascript . .js)
                  (cs . .cs)
                  (python . .py))
                (language)))))

(define (code:dir o)
  (if (eq? (language) 'cs) '()
      '(dzn)))

(define* (code:module o)
  (let ((module (make-module 31 (list
                                 (resolve-module (list 'gaiag (language)))
                                 (resolve-module '(gaiag lexicals))
                                 (resolve-module '(gaiag misc))
                                 (resolve-module '(oop goops))
                                 (resolve-module '(gaiag goops))
                                 (resolve-module '(gaiag animate-code))))))
    (module-define! module 'model o)
    (module-define! module '.model (om:name o))
    (module-define! module '.scope_model ((om:scope-name) o))
    (match o
      (($ <interface>)
       (module-define! module '.interface (om:name o))
       (let ((events (.events o)))
         (module-define! module 'events events)
         (module-define! module 'in-events (filter om:in? (.elements events)))
         (module-define! module 'out-events (filter om:out? (.elements events))))
       (module-define! module '.scope_interface ((om:scope-name) o))
       (module-define! module '.INTERFACE (string-upcase (symbol->string ((om:scope-name) o)))))
      ((? (is? <model>))
       (module-define! module '.COMPONENT (string-upcase (symbol->string ((om:scope-name) o))))))
      module))

(define (unspecified? x) (eq? x *unspecified*))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; helper functions/macros to identify bottlenecks ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-syntax *match*
  (syntax-rules ... ()
    ((_ obj (pat exp ...) ...)
     (match obj (pat (begin (map display (list "match " 'pat ":")) (newline)
                            (measure-perf- '(exp ...) (lambda () exp ...)))) ...))))

(define (measure-perf- label thunk)
  (let ((t1 (get-internal-run-time))
        (result (thunk))
        (t2 (get-internal-run-time)))
    (stderr "~a: ~a\n" (- t2 t1) label)
    result))

(define-syntax measure-perf
  (syntax-rules ()
    ((_ label exp)
     (let ((t1 (get-internal-run-time))
           (result ((lambda () exp)))
           (t2 (get-internal-run-time)))
       (stderr "~a: ~a\n" (- t2 t1) label)
       result))))

(define-syntax *let*
  (syntax-rules ()
    ((_ ((var val) ...) exp exp* ...)
     (let* ((var (measure-perf 'var val)) ...)
       (measure-perf '*let* exp exp* ...)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    template procedures: map procedure name to template and                 ;;
;;                         pass the appropriate ast type                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; requirements:
;; - trivially define a new template function by name
;; - trivially define which part of the passed ast is to be available in the template
;; - trivially map such a template function over a list of ast or parts of ast
;; - allow template functions to recurse (and therefore do not self reference ;-)

;; TODO:
;; - remove need for ->code (MORTAL SIN)
;; - cleanup (scope+)type expansion
;;      x:type, x:reply-type, x:reply-type, x:return-type, x:formal-type, ast:scope+name-*
;; - sort-out OM: AST: and CODE: prefixes
;; - system, foreign, shell
;; - asd/dzn-glue?
;; - non-c++ languages (c, javascript)
;; - rewrite toplevel entry point; apply root ast to source FILE.dzn -> FILE.cc + FILE.hh
;; - use Guile hash reader instead of PEG

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define debug? (command-line:get 'debug #f))
(define* (x:pand filename o #:optional (module (current-module)))
  (define (tree->string t)
    (match t
      (('script t ...) (tree->string t))
      (('pegprocedure s) (display (->string (eval (list (string->symbol (string-drop s 1)) o) module))))
      ((? string?) (display t))
      ((t ...) (map tree->string t))
      (_ #f)))
  (define-peg-string-patterns
    "script       <-- pegtext*
     pegtext      <-  (!pegprocedure (escape '#' / .))* pegprocedure?
     pegsep       <   [ ]?
     escape       <   '#'
     pegprocedure <-- '#' ('='/'.'/':'/'-'/'+'/[a-zA-Z0-9_])+ pegsep")
  ;; (stderr "X:PAND: ~a\n" o)
  (let* ((result (match-pattern script (gulp-template filename)))
         (end (peg:end result))
         (tree (peg:tree result)))
    (if debug?
        (format #t "/* ~a */\n" filename))
    ;; (stderr "tree: ~s\n" tree)
    ;; (stderr "   => ~a\n" filename)
    (tree->string tree)))

(define-syntax define-template
  (syntax-rules ()
    ((_ name f sep type)
     (define-public (name ast)
       (let* ((module (current-module))
              (filename (string-drop (symbol->string 'name) 2))
              (o (f ast)))
         (cond ((char? o) (display o))
               ((number? o) (display o))
               ((symbol? o) (display o))
               ((string? o) (display o))
               ((pair? o)
                ;;(stderr "PAIR [~a,t=~a,f=~a] ~a\n" (class-name (class-of ast)) (and type (class-name type)) filename (class-name (class-of (car o))))
                (let* ((sexp (if (not sep) '("")
                                 (with-input-from-string (gulp-template sep) read)))
                       (join (lambda (o) (apply string-join (cons o sexp))))
                       (ast-name (symbol->string (ast-name (if (is-a? (car o) type) type (class-of (car o))))))
                       (filename (if (equal? filename ast-name) filename
                                     (string-append filename "-" ast-name))))
                  (display (join (map (lambda (ast) (with-output-to-string
                                                      (lambda () (if (or (char? ast)
                                                                         (string? ast)
                                                                         (symbol? ast)) (display ast)
                                                                         (x:pand filename ast))))) o)))))
               ((null? o) #f)
               ((is-a? o <ast>)
                ;;(stderr "ATOM [~a,t=~a,f=~a] ~a\n" (class-name (class-of ast)) (and type (class-name type)) filename (class-name (class-of o)))
                (let* ((ast-name (symbol->string (ast-name (if (is-a? o type) type (class-of o)))))
                       (filename (if (equal? filename ast-name) filename
                                     (string-append filename "-" ast-name))))
                  (x:pand filename o)))
               (#t (x:pand filename o))))
       ""))
    ((_ name f sep)
     (define-template name f sep #f))
    ((_ name f)
     (define-template name f #f))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(define-template x:code-formal-type FIXME-code:formal-type)

(define-method (FIXME-code:formal-type (o <formal>)) ;; MORTAL SIN HERE!!?
  (let* ((type (.type o))
         (type (match type
                 (($ <extern>) (symbol->string (.value type)))
                 (_ (code:reply-type-type type)))))
    (string-append type (if (not (eq? 'in (.direction o))) "&" ""))))

(define-template x:on identity)

(define-template x:call identity)

(define-template x:reply (lambda (o)
                           (if (is-a? o <void>)
                               ""
                               (begin (display " ") (x:non-void-reply o))))) ;; MORTAL SIN HERE!!?

(define-method (ast:scope+name (o <scope.name>))
  (string-join (map symbol->string (append (.scope o) (list (.name o)))) "_"))

(define-method (ast:scope+name (o <scoped>))
  ((compose ast:scope+name .name) o))

(define-method (ast:scope+name (o <port>))
  ((compose ast:scope+name .type) o))

(define-method (ast:scope+name (o <event>))
  ((compose ast:scope+name .type .signature) o))

(define-method (ast:scope+name (o <trigger>))
  ((compose ast:scope+name .event) o))

(define-method (ast:scope+name-:: (o <scoped>))
  (string-join (map symbol->string (om:scope+name o)) "::"))

(define-method (ast:scope+name-:: (o <literal>))
  ((compose ast:scope+name-:: .type) o))

(define-method (ast:scope+name-:: (o <event>))
  ((compose ast:scope+name-:: .type .signature) o))

(define-class <enum-field> (<ast>)
  (type #:getter .type #:init-form #f #:init-keyword #:type)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

(define-method (ast:scope+name-:: (o <enum-field>))
  (string-join (map symbol->string (append (om:scope+name (.type o)) (list (.field o)))) "::"))


(export ast:scope+name-::)

(define-method (ast:port-name (o <bind>))
  (let* ((model ((ast:model) o))
         (left (.left o))
         (left-port (.port left))
         (right (.right o))
         (right-port (.port right))
         (port (and (om:port-bind? o)
                    (if (not (.instance left)) (.port left) (.port right)))))
    port))
(export ast:port-name)
(define-method (ast:instance-name (o <bind>))
  (let* ((model ((ast:model) o))
         (left (.left o))
         (left-port (.port left))
         (right (.right o))
         (right-port (.port right))
         (instance (and (om:port-bind? o)
                        (if (not (.instance left))
                            (binding-name model right)
                            (binding-name model left)))))
    instance))
(export ast:instance-name)

(define-template x:non-void-reply identity #f)

(define-template x:return-type code:return-type #f <type>)

(define-method (code:return-type (o <trigger>)) ((compose .type .signature .event) o))

(define-method (code:return-type (o <function>)) ((compose .type .signature) o))

(define-template x:model-name (compose om:name (ast:model)))

(define-template x:upcase-model-name (compose string-upcase (->join "_") om:scope+name (ast:model)))

;; c++03
(define-template x:port-type ast:port-type)
(define-method (ast:port-type (o <trigger>))
  ((->join "::") (om:scope+name ((compose .type (cut .port ((ast:model) o) <>)) o)))) ;; MORTAL SIN HERE!!?

(define-method (ast:port-type (o <port>))  ;; MORTAL SIN HERE!!?
  (cond ((member (language) '(javascript))
         ((->join ".") (om:scope+name (.type o))))
        ((member (language) '(c++ c++03 c++-msvc11))
         ((->join "::") (om:scope+name (.type o))))))

(define-template x:method code:trigger)

(define-template x:declare-method code:trigger)


(define-template x:formal-type code:formal-type)
(define-method (code:formal-type (o <formal>))
  o)

(define-method (code:formal-type (o <port>))
  ((compose .elements .formals .signature car om:events) o))

(define-template x:type-name (lambda (o)
                               ;;(stderr "TYPE-NAME: ~a\n" o)
                               (let* ((scope-name (ast:type-name o))
                                      (name (.name scope-name))
                                      (scope (.scope scope-name)))
                                 (if (member name '(void bool int))
                                     (append scope (list name))
                                     (cons "" (append scope (list name "type"))))))
  'type-infix)

(define-method (ast:type-name (o <int>)) (make <scope.name> #:name 'int))
(define-method (ast:type-name (o <void>)) (make <scope.name> #:name 'void))
(define-method (ast:type-name (o <bool>)) (make <scope.name> #:name 'bool))

(define-method (ast:type-name (o <event>))
  ((compose .name .type .signature) o))

(define-method (ast:type-name (o <type>))
  (.name o))

(define-method (ast:type-name (o <variable>))
  (ast:type-name (.type o)))

(define-method (ast:type-name (o <extern>))
  (make <scope.name> #:name (.value o)))

(define-template x:calls ast:void-in-triggers)
(define-template x:rcalls ast:valued-in-triggers)
(define-template x:formals ast:formals 'formal-infix)
(define-template x:formals-type ast:formals 'formal-infix)
(define-template x:prefix-formals-type ast:formals 'formal-prefix)

(define-template x:methods code:ons)
(define-template x:functions code:functions)
(define-template x:call identity)

(define-method (ast:void-in-triggers (o <component-model>))
  (filter
   (lambda (t) (is-a? ((compose .type .signature .event) t) <void>))
   (ast:in-triggers o)))

(define-method (ast:valued-in-triggers (o <component-model>))
  (filter
   (lambda (t) (not (is-a? ((compose .type .signature .event) t) <void>)))
   (ast:in-triggers o)))

(define-template x:reqs ast:req-events)

(define-template x:clrs ast:clr-events)

(define-template x:direction ast:direction)

(define-template x:field code:field-expression) ;; MORTAL SIN HERE!!?

(define-method (code:field-expression (o <field>))
  (string-join
   (cons "" (map symbol->string (append (om:scope+name ((compose .type .variable) o))
                                        (list (.field o)))))
   "::"))

(define-template x:data code:data)

(define-method (code:data (o <data>))
  (.value o))

(define-template x:expression code:expression)

(define-template x:variable-expression (compose code:expression .expression) #f <expression>)
(define-template x:left (compose code:expression .left) #f <expression>)
(define-template x:right (compose code:expression .right) #f <expression>)

(define-template x:expression-expand code:expression-expand #f <expression>)
(define-method (code:expression-expand (o <not>))
  ;;(stderr "code:expression-expand<not> o=~a\n" o)
  (.expression o))

(define-method (code:expression-expand (o <var>))
  ;;(stderr "code:expand-expression<var> o=~a\n" o)
  o)

(define-method (code:expression-expand (o <field>))
  ;;(stderr "code:expand-expression<field> o=~a\n" o)
  o)

(define-method (code:expression-expand (o <variable>))
  ;;(stderr "code:expand-expression<var> o=~a\n" o)
  o)

(define-method (code:expression-expand (o <reply>))
  ;;(stderr "code:expand-expression<reply> o=~a\n" o)
  o)

;; (define-method (code:expression-expand (o <call>))
;;   ;;(stderr "code:expand-expression<var> o=~a\n" o)
;;   (.expression o))

(define-method (code:expression (o <and>))
  ;;(stderr "code:expression<and> o=~a\n" o)
  o)

(define-method (code:expression (o <action>))
  o)

(define-method (code:expression (o <call>))
  o)

(define-method (code:expression (o <statement>))
  ;;(stderr "code:expression<statement> o=~a\n" o)
  (.expression o))

(define-method (code:expression (o <formal>))
  ;;(stderr "code:expression<formal> o=~a\n" o)
  (.name o))

(define-method (code:expression (o <variable>))
  ;;(stderr "code:expression<variable> o=~a\n" o)
  (.name o))

(define-method (code:expression (o <return>))
  ;;(stderr "code:expression<return> o=~a\n" o)
  (if (or (not (.expression o)) (eq? (.expression o) *unspecified*)) ""
          (.expression o)))

(define-method (code:expression (o <var>))
  ;;(stderr "code:expression<var> o=~a\n" o)
  (.variable o))

(define-method (code:expression (o <unary>))
  ;;(stderr "code:expression<unary> o=~a\n" o)
  o)

(define-method (code:expression (o <top>))
  ;;(stderr "code:expression<top> o=~a\n" o)
  o)

(define-method (code:expression (o <reply>))
  ;;(stderr "code:expression<reply> o=~a\n" o)
  (.expression o))

(define-template x:=expression code:=expression #f <expression>)
(define-method (code:=expression (o <ast>))
  (match (.expression o)
    ((and ($ <value>) (= .value (? unspecified?))) "")
    ((? unspecified?) "")
    (_ (.expression o))))

(define-template x:scoped-model-name (lambda (o)
                                       (let* ((scope+name (.name o))
                                              (scope (map symbol->string (.scope scope+name)))
                                              (name (symbol->string (.name scope+name))))
                                         (string-join (append scope (list name)) "_"))))

(define-template x:reply-type code:reply-type)

(define-method (code:reply-type (o <ast>)) ;; MORTAL SIN HERE!!?
  (let ((type (ast:expression-type o)))
    (match type
      (($ <bool>) "bool")
      (($ <int>) "int")
      (($ <enum>) (string-join (map symbol->string (om:scope+name type)) "_"))
      (($ <void>) "void"))))

(define-method (code:reply-type (o <reply>))
  ((compose code:reply-type .expression) o))

(define-template x:reply-type-type code:reply-type-type)

(define-method (code:reply-type-type (o <ast>))
  (let ((type (ast:expression-type o)))
    (match type
      (($ <bool>) "bool")
      (($ <int>) "int")
      (($ <enum>) (string-join (cons "" (map symbol->string (append (om:scope+name type) '(type)))) "::"))
      (($ <void>) "void"))))

(define-template x:then .then #f <statement>)

(define-template x:else (lambda (o) (or (.else o) '())) #f <statement>)


(define-template x:declarative-or-imperative code:declarative-or-imperative)

(define-method (code:declarative-or-imperative (o <compound>))
  (if (om:imperative? o) o
      (make <declarative-compound> #:elements o)))

(define-template x:on-statements .elements #f <statement>)


(define-template x:guard-statements .elements #f <statement>)

(define-template x:out-bindings .elements)

(define-template x:statements .elements #f <statement>)

(define-template x:variable-name (lambda (o)
                                   ;; FIXME: is (.variable o) a member?
                                   ;; checking name (as done now) is not good enough
                                   ;; we schould check .variable pointer equality
                                   ;; that does not work, however; someone makes a copy is clone
                                   ;; (memq o (om:variables ((ast:model) o)))
                                   (if (memq (.variable.name o) (map .name (om:variables ((ast:model) o))))
                                       (x:member-name (.variable o))
                                       (symbol->string (.variable.name o)))))

(define-template x:member-name identity)

(define-template x:assign-reply code:assign-reply)
(define-method (code:assign-reply (o <reply>))
  (let ((expression (.expression o)))
    (if (is-a? (ast:expression-type expression) <void>) ""
        o)))

(define-template x:port-name code:port-name)
(define-method (code:port-name (o <on>))
  ((compose .port.name car .elements .triggers) o))

(define-template x:block identity)
(define-template x:port-release (lambda (o) (if (om:blocking-compound? ((ast:model) o)) o "")))

(define-template x:on-statement code:on-statement)
(define-method (.statement (o <statement>)) o)
(define-method (code:on-statement (o <statement>))
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
      o))
(define-method (code:on-statement (o <on>))
  (let ((o (.statement o)))
   (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
       (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
       o)))

(define-template x:statement code:non-blocking-identity)

(define-method (code:non-blocking-identity (o <function>))
  (.statement o))

(define-method (code:non-blocking-identity (o <statement>))
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
      o))

(define-method (code:statement (o <statement>)) o)

(define-template x:guard-statement code:guard-statement)
(define-method (code:guard-statement (o <statement>))
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
      o))
(define-method (code:guard-statement (o <guard>))
  (let ((o (.statement o)))
   (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
       (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
       o)))


(define-method (.expression (o <value>)) (.value o))

(define-method (.expression (o <top>)) #f)

(define-template x:pump-include (lambda (o) (if (pair? (om:ports (.behaviour o)))
                                                "#include <dzn/pump.hh>"
                                                "")))

(define-template x:open-namespace (lambda (o) (map (lambda (x) (string-join (list " namespace " (symbol->string x) " {") "")) (om:scope o))))
(define-template x:close-namespace (lambda (o) (map (lambda (x) "}\n") (om:scope o))))

(define-template x:meta identity)

;; FIXME: all/vs requires
(define-template x:all-ports-meta-list om:ports 'meta-infix)

;; FIXME => x:required-ports-meta-list
(define-template x:ports-meta-list (lambda (o) (filter om:requires? (om:ports o))) 'meta-infix)

;;(define-template x:ports-meta-list (lambda (o) (comma-join (map (lambda (port) (list "&" (.name port) ".meta")) (filter om:requires? (om:ports o))))))

(define-template x:check-bindings-list (lambda (o) ((->join ",") (map (lambda (port) (list "[this]{"(.name port) ".check_bindings();}")) (om:ports o)))))

(define-template x:interface-include om:ports)

(define-template x:in-event-definer (lambda (o) (filter om:in? (om:events o))) 'event-definer-infix)
(define-template x:out-event-definer (lambda (o) (filter om:out? (om:events o))) 'event-definer-infix)

(define-template x:global-enum-definer (lambda (o) (om:enums)))

(define-template x:enum-definer (lambda (o) (append (om:enums o) (om:enums))))

(define-template x:check-in-binding (lambda (o) (filter om:in? (om:events o))))
(define-template x:check-out-binding (lambda (o) (filter om:out? (om:events o))))

(define-template x:interface-enum-to-string ast:enum-to-string)
(define-template x:interface-string-to-enum ast:enum-to-string)
(define-method (ast:enum-to-string (o <interface>))
  (append (om:enums) (om:enums o)))

(define-template x:enum-field-to-string ast:enum-field-to-string)
(define-method (ast:enum-field-to-string (o <enum>))
  (map (symbol->enum-field o) ((compose .elements .fields) o)))
;;(export ast:enum-field-to-string)

(define-template x:string-to-enum ast:string-to-enum)
(define-method (ast:string-to-enum (o <model>))
  (om:enums o))
(define-method (ast:string-to-enum (o <enum>))
  (map (symbol->enum-field o) ((compose .elements .fields) o)))
;;(export ast:string-to-enum)

(define asd? #f) ;; FIXME: asd glue
(define-template x:asd-voidreply (lambda (o) (if asd? "__ASD_VoidReply, " "")))

(define ((symbol->enum-field enum) o)
  (make <enum-field> #:type enum #:field o))

(define-method (.type.name (o <enum-field>))
  (symbol->string ((compose .name .name .type) o)))

(define-template x:enum-field-definer (lambda (o) (map (symbol->enum-field o) ((compose .elements .fields) o))) 'comma-infix)

(define-template x:variable-member-initializer (lambda (o) (om:variables o)))

(define-template x:injected-member-initializer (lambda (o) (filter .injected (om:ports o))))

(define-template x:provided-member-initializer (lambda (o) (filter om:provides? (om:ports o))))

(define-template x:required-member-initializer (lambda (o) (filter (conjoin (negate .injected) om:requires?) (om:ports o))))

(define-template x:async-member-initializer (lambda (o) (om:ports (.behaviour o))))

(define-template x:scope-name (lambda (port) (let ((scope-name ((compose .name .type) port))) (append (.scope scope-name) (list (.name scope-name))))) 'type-infix)

(define-template x:reply-member-declare ast:reply-types)

(define-method (ast:reply-types o)
  (let ((lst (om:reply-types o)))
    (delete-duplicates lst (lambda (a b) (or (and (is-a? a <bool>)
                                                  (is-a? b <bool>))
                                             (and (is-a? a <int>)
                                                  (is-a? b <int>))
                                             (and (is-a? a <void>)
                                                  (is-a? b <void>))
                                             (om:equal? a b))))))

(define-template x:variable-member-declare (lambda (o) (om:variables o)))

(define-template x:out-binding-lambda (lambda (o) (filter om:provides? (om:ports o))))

(define-template x:provided-port-declare (lambda (o) (filter om:provides? (om:ports o))))
(define-template x:required-port-declare (lambda (o) (filter om:requires? (om:ports o))))
(define-template x:async-port-declare (lambda (o) (om:ports (.behaviour o))))

(define-template x:stream-member om:variables 'stream-comma-infix)
(define-template x:method-declare code:ons)
(define-template x:function-declare code:functions)

;; header-system

(define-template x:meta-child code:instances 'meta-child-infix)
(define-method (code:instances (o <component>))
  '())
(define-method (code:instances (o <system>))
  (om:instances o))
(define-template x:component-include om:instances)

(define-template x:provided-port-reference-declare (lambda (o) (filter om:provides? (om:ports o))))
(define-template x:required-port-reference-declare (lambda (o) (filter om:requires? (om:ports o))))

(define-template x:injected-instance-declare code:injected-instances-system)
(define-template x:injected-binding-declare injected-bindings)
(define-template x:non-injected-instance-declare non-injected-instances)
(define-template x:system-rank ast:provided)

(define-template x:type code:x:type)
(define-method (ast:scope+name-:: (o <scope.name>))
  (string-join (map symbol->string (om:scope+name o)) "::"))
(define-method (code:x:type (o <bind>))
  ((compose ast:scope+name-:: .type (cut om:instance ((ast:model) o) <>) injected-instance-name) o))

(define-method (code:x:type (o <instance>))
  (ast:scope+name-:: (.type o)))

(define-template x:name code:x:name)
(define-method (code:x:name (o <bind>))
  (injected-instance-name o))

(define-method (ast:scope+name (o <instance>))
  ((compose ast:scope+name (cut om:component ((ast:model) o) <>)) o))

;; source-system
(define-template x:meta-child om:instances 'meta-child-infix)
(define-template x:injected-instance-system-initializer code:injected-instances-system)
(define-template x:injected-instance-initializer code:injected-instances)

(define-method (code:injected-instances-system (o <system>))
  (if (null? (injected-bindings o)) ""
      o))

(define-method (code:injected-instances (o <system>))
  (if (null? (injected-bindings o)) ""
      (injected-instances o)))

(define-method (code:port-name (o <instance>)) ;; MORTAL SIN HERE!!?
  (.name (om:port (om:component ((ast:model) o) o))))

(define-template x:component-port code:component-port)
(define-template x:provided-port-reference-initializer ast:provided)
(define-template x:required-port-reference-initializer ast:required)
(define-template x:non-injected-instance-initializer non-injected-instances)
(define-template x:injected-binding-initializer injected-bindings)
(define-template x:instance-initializer om:instances)
(define-template x:bind-connect code:non-injected-bindings)

(define-template x:injected-instance-meta-initializer injected-instances)
(define-template x:non-injected-instance-meta-initializer non-injected-instances)

(define-template x:dzn-locator code:dzn-locator)

(define-method (code:dzn-locator (o <instance>)) ;; MORTAL SIN HERE!!?
  (let* ((model ((ast:model) o)))
    (if (null? (injected-bindings model)) ""
        "_local")))

(define-method (code:component-port (o <port>)) ;; MORTAL SIN HERE!!?
  (let* ((model ((ast:model) o))
         (bind (om:port-bind model o)))
    (om:instance-binding? bind)))

(define-method (code:non-injected-bindings (o <system>))
  (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) o))))

(define-template x:bind-provided code:bind-provided)
(define-template x:bind-required code:bind-required)

(define-method (code:bind-provided-required (o <bind>))
  (let* ((model ((ast:model) o))
         (left (.left o))
         (left-port (.port left))
         (right (.right o))
         (right-port (.port right)))
    (if (om:provides? left-port)
                                (cons left right)
                                (cons right left))))

(define-method (code:bind-provided (o <bind>))
  ((compose car code:bind-provided-required) o))

(define-method (code:bind-required (o <bind>))
  ((compose cdr code:bind-provided-required) o))

(define-template x:binding-name (lambda (o) (binding-name ((ast:model) o) o)))

(define-template x:system-port-connect (lambda (o) (filter (negate om:port-bind?) ((compose .elements .bindings) o))))

;; main-component
(define code:reply-scope+name ast:scope+name)
;; reply-type-name-{int,bool} do not work not with /* file-name */ in generated main-component
;; we get: to_/*reply-type-name-int*/int (..)
(define-method (code:reply-scope+name (o <bool>))
  (if debug? "bool" ;; MORTAL SIN HERE!!!?
      o))
(define-method (code:reply-scope+name (o <int>))
  (if debug? "int" ;; MORTAL SIN HERE!!!?
      o))
(define-method (code:reply-scope+name (o <void>))
  (if debug? "void" ;; MORTAL SIN HERE!!!?
      o))

(define-method (ast:provided (o <component-model>))
  (filter om:provides? ((compose .elements .ports) o)))
(define-method (ast:required (o <component-model>))
  (filter om:requires? ((compose .elements .ports) o)))

(define-method (trigger-in-event? (o <trigger>))
  ((compose om:in? .event) o))

(define-method (ast:out-triggers-in-events (o <component-model>))
  (filter (compose om:in? .event) (ast:out-triggers o)))
(define-method (ast:out-triggers-out-events (o <component-model>))
  (filter (compose om:out? .event) (ast:out-triggers o)))

(define-template x:reply-type-name code:reply-scope+name)
(define-template x:main-out-arg-define code:main-out-arg-define)
(define-template x:main-out-arg-define-formal code:main-out-arg-define-formal 'formal-infix)
(define-template x:main-out-arg-define-formal-int identity)
(define-template x:main-out-arg code:main-out-arg 'argument-infix)

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

(define-template x:main-port-connect-in ast:out-triggers-in-events)
(define-template x:main-port-connect-out ast:out-triggers-out-events)
(define-template x:main-provided-port-init ast:provided)
(define-template x:main-required-port-init ast:required)

(define-template x:main-event-map-void ast:void-in-triggers 'event-map-prefix)
(define-template x:main-event-map-valued ast:valued-in-triggers 'event-map-prefix)
(define-template x:main-event-map-flush (if (and #f asd?) (const '()) ast:required) 'event-map-prefix)
(define-template x:main-event-map-flush-asd (if (and #f asd?) ast:required (const '())) 'event-map-prefix)

(define-template x:main-event-map-match-return code:main-event-map-match-return)
(define-method (code:main-event-map-match-return (o <trigger>))
  (if (om:in? (.event o)) o ""))

(define-template x:main-required-port-name ast:required 'main-port-name-infix)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   ast accessors; must return an ast type or a: string, number or symbol   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

(define ast:model (make-parameter (lambda (o) #f)))

(define-method (code:functions (o <component>))
  (om:functions o))

(define-method (code:ons (o <component>))
  (let ((behaviour (.behaviour o)))
    (if (not behaviour) '()
        ((compose .elements .statement) behaviour))))

(define-template x:arguments-n ast:argument_n 'argument-infix <expression>)
(define-template x:prefix-arguments-n ast:argument_n 'argument-prefix <expression>)

(define-template x:argument_n identity)

(define-method (ast:argument_n (o <trigger>))
  (map
   (lambda (f i) (clone f #:name (string-append "_"  (number->string i))))
   (ast:formals o)
   (iota (length (ast:formals o)) 1 1)))

(define-template x:arguments ast:arguments 'argument-infix <expression>)

(define-method (ast:arguments (o <trigger>))
  (map .name (ast:formals o)))

(define-method (ast:arguments (o <call>))
  ((compose .elements .arguments) o))

(define-method (ast:arguments (o <action>))
  ((compose .elements .arguments) o))

(define-template x:out-arguments ast:out-argument 'argument-prefix <expression>)

(define-method (ast:out-argument (o <trigger>))
  (filter om:out-or-inout? (ast:formals o)))

(define-method (ast:formals (o <function>))
  ((compose .elements .formals .signature) o))

(define-method (ast:formals (o <action>))
  ((compose .elements .formals .signature .event) o))

(define-method (ast:formals (o <trigger>))
  ((compose .elements .formals) o))

(define-method (ast:formals (o <event>))
  ((compose .elements .formals .signature) o))

(define-method (ast:formals (o <on>))
  (let* ((trigger ((compose car .elements .triggers) o))
         (event (.event trigger)))
    (map (lambda (name formal)
           (clone formal #:name name))
         (map .name ((compose .elements .formals) trigger))
         ((compose .elements .formals .signature) event))))

(define-method (code:trigger (o <on>))
  ((compose car .elements .triggers) o))

(define-template x:return code:return #f <type>)

(define-method (code:return (o <on>))
  ((compose .type .signature .event code:trigger) o))

(define (code:animate-file file-name module)
  (let ((model-names (map (compose .name car) (@@ (gaiag om) *ast-alist*))))
    (parameterize ((ast:model (lambda (_) (module-ref module 'model))))
      ;; use old animate+component.js.scm for
      ;; services/scripts/verification.dzn, daemon/lib/Controller.dzn
      ;; until regression test passes
      (cond  ((member file-name '(component.cc.scm))
              (x:pand 'source-component (module-ref module 'model) module))
             ((member file-name '(component.hh.scm))
              (x:pand 'header-component (module-ref module 'model) module))
             ((member file-name '(interface.hh.scm))
              (x:pand 'source-interface (module-ref module 'model) module))
             ((and (member file-name '(system.cc.scm))
                   (not (member (language) '(c++03 c++-msvc11))))
              (x:pand 'source-system (module-ref module 'model) module))
             ((member file-name '(system.hh.scm))
              (x:pand 'header-system (module-ref module 'model) module))
             ((member file-name '(main.cc.scm))
              (x:pand 'main-component (module-ref module 'model) module))
             (else (animate-file file-name module))))))
