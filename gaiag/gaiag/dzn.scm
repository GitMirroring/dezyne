;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag dzn)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)

  #:use-module (json)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag ast)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag deprecated animate)

  #:use-module (gaiag command-line)
  #:use-module (gaiag indent)
  #:use-module (gaiag json)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag resolve)
  #:use-module (gaiag util)
  #:use-module (gaiag xpand)

  #:export (
           ast->
           ast->dzn
           ;; <assign-action>
           ;; <assign-call>
           ))

(define-class <assign-call> (<call>))
(define-class <assign-action> (<action>))

(define* ((->dzn #:optional (model #f)) o)
  (define (local-scope? scope)
    (or (null? scope) (equal? (list (om:name model)) scope)))
  (define (unspecified? x) (eq? x *unspecified*))

  (match o

    (($ <root> (model* ...)) ((->join "\n") (map (->dzn) model*)))

    (($ <import> file) ((animate-snippet 'import `((file ,file)))))

    ((? (is? <model>))
     (or (module-variable (current-module) 'model) (module-define! (current-module) 'model o))
     (model->dzn o))

    (($ <blocking> statement)
     ((animate-snippet 'blocking `((statement ,((->dzn model) statement))))))

    (($ <guard> expression statement)
     ((animate-snippet 'guard `((expression ,((->dzn model) expression))
                                (statement ,((->dzn model) statement))))))

    (($ <on> triggers statement)
     ((animate-snippet 'on `((triggers ,((->dzn model) triggers))
                             (statement ,((->dzn model) statement))))))

    (($ <compound> ())
     ((animate-snippet 'compound-empty '())))

    (($ <compound> (statement* ...))
     ((animate-snippet 'compound `((statements ,(map (->dzn model) statement*))))))

    ((and ($ <action>) (= .port.name #f) (= .event.name event))
     (let ((trigger ((animate-snippet 'itrigger `((event ,event))))))
      ((animate-snippet 'action `((trigger ,trigger)
                                  (location ,(location o)))))))

    ((and ($ <action>) (= .port.name port-name) (= .event.name event) (= .arguments arguments))
     (let* ((arguments ((->dzn model) arguments))
            (trigger ((animate-snippet 'action-trigger `((event ,event) (port ,port-name) (arguments ,arguments))))))
      ((animate-snippet 'action `((trigger ,trigger)
                                  (location ,(location o)))))))

    (($ <illegal>) ((animate-snippet 'illegal)))

    (($ <assign> var ($ <call> function-name arguments))
     ((->dzn model) (make <assign> #:variable var #:expression (make <assign-call> #:function function-name #:arguments arguments))))

    (($ <assign> var (and ($ <action>) (= .port.name port-name) (= .event event) (= .arguments arguments)))
     ((->dzn model) (make <assign> #:variable var #:expression (make <assign-action> #:port port-name #:event event #:arguments arguments))))

    (($ <assign> var expression)
     (->string (.name var) " = " ((->dzn model) expression) ";\n"))

    (($ <assign-call> function-name arguments)
     ((animate-snippet 'call-expression `((function ,function-name)
                                          (arguments ,((->dzn model) arguments))
                                          (location ,(location (om:function model function-name)))))))

    ((and ($ <assign-action>) (= .port.name port-name) (= .event.name event) (= .arguments arguments))
     (let ((arguments ((->dzn model) arguments)))
       ((animate-snippet 'action-trigger `((event ,event) (port ,port-name) (arguments ,arguments))))))

    (($ <call> function-name arguments)
     ((animate-snippet 'call `((function ,function-name)
                               (arguments ,((->dzn model) arguments))
                               (location ,(location function-name))))))

    (($ <if> expression then #f)
     ((animate-snippet 'if-then `((expression ,((->dzn model) expression))
                                  (then ,((->dzn model) then))))))

    (($ <if> expression then else)
     ((animate-snippet 'if-then-else `((expression ,((->dzn model) expression))
                                       (then ,((->dzn model) then))
                                       (else ,((->dzn model) else))))))

    (($ <otherwise> value) ((animate-snippet 'otherwise)))

    (($ <reply> expression #f) ((animate-snippet 'reply `((expression ,((->dzn model) expression))))))

    (($ <reply> expression port) ((animate-snippet 'reply-port `((expression ,((->dzn model) expression)) (port ,port)))))

    (($ <return> #f) ((animate-snippet 'return-void)))

    (($ <return> expression) ((animate-snippet 'return `((expression ,((->dzn model) expression))))))

    (($ <variable> name type ($ <call> function-name arguments))
     ((->dzn model) (make <variable> #:name name #:type type #:expression ((->dzn model) (make <assign-call> #:function function-name #:arguments arguments)))))

    (($ <variable> name type (and ($ <action>) (= .port.name port-name) (= .event event) (= .arguments arguments)))
     ((->dzn model) (make <variable> #:name name #:type type #:expression ((->dzn model) (make <assign-action> #:port port-name #:event event #:arguments arguments)))))

    (($ <variable> name type ($ <value> (? unspecified?)))
     (->string (type->dzn model type) " " name ";\n"))

    (($ <variable> name type expression)
     (->string (type->dzn model type) " " name " = " ((->dzn model) expression) ";\n"))

    (($ <bool>) ((animate-snippet 'bool)))
    (($ <enum>) ((declare-enum model) o))
    (($ <extern>) ((declare-extern model) o))
    (($ <int>) ((declare-int model) o))
    (($ <void>) ((animate-snippet 'void)))

    (($ <port> name type direction external injected)
     ((animate-snippet 'declare-port `((direction ,direction)
                                       (name ,name)
                                       (interface ,type)
                                       (external? ,external)
                                       (injected? ,injected)))
      o))


    (($ <binding> #f port-name) ((animate-snippet 'binding-port `((port ,port-name)))))
    (($ <binding> instance port-name) ((animate-snippet 'binding `((instance ,(.name instance)) (port ,port-name)))))

    (($ <formal> name #f #f) (.name o))
    (($ <formal> name type (or #f 'in)) (->string (list (type->dzn model type) " " name)))
    (($ <formal> name type dir) ((animate-snippet 'formal `((dir ,(if (not (om:out-or-inout? o)) "" dir))
                                                            (out? ,(om:out-or-inout? o))
                                                            (type ,(type->dzn model type))
                                                            (name ,name)))))

    ((and ($ <trigger>) (= .port.name #f) (= .event.name event)) ((animate-snippet 'itrigger `((event ,event)))))
    ((and ($ <trigger>) (= .port.name port-name) (= .event.name event) (= .formals formals))
     (let ((formals (clone formals #:elements (map (cut clone <> #:type #f #:direction #f) (.elements formals)))))
       ((animate-snippet 'trigger `((event ,event) (port ,port-name) (formals ,((->dzn model) formals)))))))
    (($ <out-bindings>) (->string (map (->dzn model) (.elements o))))
    ((and ($ <formal-binding>) (= .name formal) (= .variable.name global))
     ((animate-snippet 'out-binding `((formal ,((->dzn model) formal)) (global ,((->dzn model) global))))))
    (($ <expression> expression) (expression->dzn model expression))
    (($ <expression>) #f)
    (($ <data> (? unspecified?)) "")
    (($ <data> data) ((animate-snippet 'data `((data ,data)))))
    (($ <field> variable field) (->string (list (.name variable) "." field)))
    ((and ($ <literal>) (= .type type) (= .field field))
     (let* ((scope (.scope (.name type)))
            (name (.name (.name type))))
       (if (local-scope? scope)
           ((animate-snippet 'literal `((scope ()) (dot "") (name ,name) (field ,field))))
           ((animate-snippet 'literal `((scope ,((dzn:scope-join model) scope)) (dot ".") (name ,name) (field ,field)))))))
    ((and ($ <var>) (= .variable.name identifier)) ((->dzn model) identifier))
    (($ <not> expression) (->string (list "!" (paren model expression))))
    (($ <group> expression) (->string (list "(" ((->dzn model) expression) ")")))
    ((? (is? <binary>))
     (let* ((lhs ((->dzn model) (.left o)))
            (rhs ((->dzn model) (.right o)))
            (op (.operator o)))
       (->string (list lhs " " op " " rhs ))))
    (($ <value> #f) "")
    (($ <value> (? unspecified?)) "")
    (($ <value> value) ((->dzn model) value))
    (($ <arguments> (argument* ...)) ((->join ", ") (map (->dzn model) argument*)))
    (($ <fields> (field* ...)) ((->join ", ") (map (->dzn model) field*)))
    (($ <formals> (formal* ...)) ((->join ", ") (map (->dzn model) formal*)))
    (($ <triggers> (trigger* ...)) ((->join ", ") (map (->dzn model) trigger*)))

    ((? symbol?) (->string o))
    ((? string?) o)
    (() "")
    ((? unspecified?) "")
    (#f ((animate-snippet 'false)))
    (#t ((animate-snippet 'true)))
    (_ (->string o))))

(define-method (type->dzn model (o <type>))
  (define (local-scope? scope)
    (or (null? scope) (equal? (list (om:name model)) scope)))
  (match o
    (($ <bool>) ((animate-snippet 'bool)))
    (($ <void>) ((animate-snippet 'void)))
    ((and ($ <enum>) (= .name type))
     (let* ((scope (.scope type))
            (name (.name type)))
       (if (local-scope? scope)
           ((animate-snippet 'type `((scope ()) (dot "") (name ,name))))
           ((animate-snippet 'type `((scope ,((dzn:scope-join model) scope)) (dot ".") (name ,name)))))))
    ((and ($ <extern>) (= .name type))
     (let* ((scope (.scope type))
            (name (.name type)))
       (if (local-scope? scope)
           ((animate-snippet 'type `((scope ()) (dot "") (name ,name))))
           ((animate-snippet 'type `((scope ,((dzn:scope-join model) scope)) (dot ".") (name ,name)))))))
    ((and ($ <int>) (= .name type))
     (let* ((scope (.scope type))
            (name (.name type)))
       (if (local-scope? scope)
           ((animate-snippet 'type `((scope ()) (dot "") (name ,name))))
           ((animate-snippet 'type `((scope ,((dzn:scope-join model) scope)) (dot ".") (name ,name)))))))))

(define (location o)
  ((compose scm->json-string json-location) o))

(define (paren model expression)
  (if (or (number? expression) (symbol? expression)
          (as expression <field>) (as expression <literal>) (as expression <var>))
      ((->dzn model) expression)
      ;;(->string expression)
      (->string (list "(" ((->dzn model) expression) ")"))))

(define (expression->dzn model src)
  (let ((unparen (lambda (s) (if (and s
                                      (string-prefix? "(" s)
                                      (string-postfix? ")" s))
                                 (string-drop (string-drop-right s 1) 1)
                                 s))))
    (and=> src (compose unparen (->dzn model)))))


(define (statement->dzn model)
  (map (->dzn model) ((compose .elements .statement .behaviour) model)))

(define* ((dzn:scope-join model #:optional (infix '.)) o)
  ((om:scope-join model infix) o))

(define* ((animate-pairs pairs string) #:optional parameter)
  (animate string (pairs->module pairs parameter)))

(define* ((animate-snippet file-name #:optional (pairs '())) #:optional parameter)
  (snippet file-name (pairs->module pairs parameter)))

(define* (pairs->module key-procedure-pairs #:optional (parameter #f))
  (let ((module (dzn:module (and=> (module-variable (current-module) 'model)
                                   variable-ref))))
    (populate-module module key-procedure-pairs parameter)))

(define ((declare-extern model) extern)
  (let* ((value (.value extern)))
    ((animate-snippet 'declare-extern
                      `((scope ,(om:scope extern)) (name ,(om:name extern)) (value ,value)))
     extern)))

(define ((declare-int model) int)
  (let* ((range (.range int)))
    ((animate-snippet 'declare-int
                      `((scope ,(om:scope int)) (name ,(om:name int)) (range ,range) (from ,(.from range)) (to ,(.to range))))
     int)))

(define ((declare-enum model) enum)
  (let* ((fields ((compose .elements .fields) enum))
         (length (length fields))
         (asd? #f))
   (snippet 'declare-enum
            `((scope+name ,(om:scope+name enum)) (scope ,(om:scope enum)) (name ,(om:name enum)) (fields ,fields) (length ,length) (asd? ,asd?)))))

(define ((declare-event model) event)
  ((animate-snippet 'declare-event
                    `((direction ,.direction)
                      (formals ,(compose (->dzn model) .formals .signature))
                      (name ,.name)
                      (type ,(type->dzn model ((compose .type .signature) event)))
                      (scope.type ,(compose (om:scope-name '.) .type .signature))))
   event))

(define ((define-function model) function)
  ((animate-snippet 'function
                    `((formals ,(compose (->dzn model) .formals .signature))
                      (name ,.name)
                      (statement ,(compose (->dzn model) .statement))
                      (type ,(type->dzn model ((compose .type .signature) function)))))
   function))

(define ((init-binding model) binding)
  ((animate-snippet 'bind
                    `((left ,(compose (->dzn model) .left))
                      (right ,(compose (->dzn model) .right))))
   binding))

(define-syntax-rule (pseudo-pipe producer consumer)
  (with-input-from-string
      (with-output-to-string (lambda () producer))
    (lambda () consumer)))

(define (model->dzn o)
  (with-output-to-string (lambda () (dump-model o))))

(define (dump-model o)
  (pseudo-pipe (dzn-file o) (indent)))

(define (dzn-file o)
  (let ((file-name (ast-name o))
        (module (dzn:module o)))
    (animate-file (symbol-append file-name '.dzn.scm) module)))

(define (dzn:module o)
  (let ((module (make-module 31 (list (resolve-module '(oop goops))
                                      (resolve-module '(gaiag goops))
                                      (resolve-module '(gaiag dzn))
                                      (resolve-module '(gaiag misc))))))
    (module-define! module 'model o)
    (module-define! module '.model (and=> ((is? <model>) o) om:name))
    (module-define! module '.scope.model (and=> ((is? <model>) o) (om:scope-name '.)))
    module))

(define (language)
  (let ((language (string->symbol (command-line:get 'language "dzn"))))
    (if (member language '(dzn html)) language
        'dzn)))

(define* ((ast->dzn #:optional (model #f) (language (language))) o)
  (parameterize ((template-dir (append (prefix-dir) `(templates ,language))))
    (indent-string ((->dzn model) o))))

(define (ast-> ast)
  ((compose
    (ast->dzn)
    ast:resolve
    parse->om
    )
   ast))
