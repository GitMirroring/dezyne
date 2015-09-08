;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag dzn)
  :use-module (gaiag list match)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)

  :use-module (gaiag om)

  :use-module (gaiag animate)
  :use-module (gaiag indent)
  :use-module (gaiag code)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
;;  :use-module (gaiag wfc)

  :export (
           ast->
           ast->dzn
           ))

(define* ((->dzn :optional (model #f)) o)
  (define (unspecified? x) (eq? x *unspecified*))

  ;;(stderr "DZN: ~a\n" o)
  (match o

    (('root models ...) ((->join "\n") (map (->dzn) models)))

    (($ <import> ('name file ...)) ((animate-snippet 'import `((file ,file)))))

    ((? (is? <model>))
     (or (module-variable (current-module) 'model) (module-define! (current-module) 'model o))
     (model->dzn o))

    (($ <guard> expression statement)
     ((animate-snippet 'guard `((expression ,((->dzn model) expression))
                                (statement ,((->dzn model) statement))))))

    (($ <on> triggers statement)
     ((animate-snippet 'on `((triggers ,((->dzn model) triggers))
                             (statement ,((->dzn model) statement))))))

    (('compound)
     ((animate-snippet 'compound-empty '())))

    (('compound statements ...)
     ((animate-snippet 'compound `((statements ,(map (->dzn model) statements))))))

    (($ <action> trigger) (->string ((->dzn model) trigger) ";\n"))

    (($ <illegal>) "illegal;\n")

    (($ <assign> var ($ <call> function arguments))
     ((->dzn model) (list 'assign var (list 'assign-call function arguments))))

    (($ <assign> var ($ <action> trigger))
     ((->dzn model) (list 'assign var (list 'assign-action trigger))))

    (($ <assign> var expression)
     (->string var " = " ((->dzn model) expression) ";\n"))

    (('assign-call function arguments)
     ((animate-snippet 'call-expression `((function ,function)
                                          (arguments ,((->dzn model) arguments))))))

    (('assign-action action trigger)
     (->string ((->dzn model) trigger)))

    (($ <call> function arguments)
     ((animate-snippet 'call `((function ,function)
                               (arguments ,((->dzn model) arguments))))))

    (($ <if> expression then #f)
     ((animate-snippet 'if-then `((expression ,((->dzn model) expression))
                                  (then ,((->dzn model) then))))))

    (($ <if> expression then else)
     ((animate-snippet 'if-then-else `((expression ,((->dzn model) expression))
                                       (then ,((->dzn model) then))
                                       (else ,((->dzn model) else))))))

    (($ <otherwise> value) "otherwise")

    (($ <reply> expression) (->string "reply(" ((->dzn model) expression) ");\n"))

    (($ <return> (? unspecified?)) (->string "return;"))

    (($ <return> expression) (->string "return " ((->dzn model) expression) ";\n"))

    (($ <variable> name type ($ <call> function arguments))
     ((->dzn model) (list 'variable name type ((->dzn model) (list 'assign-call function arguments)))))

    (($ <variable> name type ($ <action> trigger))
     ((->dzn model) (list 'variable name type ((->dzn model) (list 'assign-action trigger)))))

    (($ <variable> name type (? unspecified?))
     (->string ((->dzn model) type) " " name ";\n"))

    (($ <variable> name type expression)
     (->string ((->dzn model) type) " " name " = " ((->dzn model) expression) ";\n"))

    (($ <enum>) ((declare-enum model) o))
    (($ <extern>) ((declare-extern model) o))
    (($ <int>) ((declare-int model) o))

    (($ <port> name type direction injected)
     ((animate-snippet 'declare-port `((direction ,direction)
                                       (name ,name)
                                       (interface ,type)
                                       (injected? ,injected)))
      o))

    (($ <type> ('name scope ... name))
     ((->join ".") (list ((dzn:scope-join model) scope) name)))

    (($ <binding> #f port) (->string port))
    (($ <binding> instance port) (->string instance "." port))

    (($ <formal> name type (or #f 'in)) (->string (list ((->dzn model) type) " " name)))
    (($ <formal> name type dir) (->string (list dir " " ((->dzn model) type) " " name)))
    (($ <trigger> #f event) (->string event))
    (($ <trigger> port event arguments) (->string port '. event ((->dzn model) arguments)))



    (('group expression) (->string (list "(" ((->dzn model) expression) ")")))
    (($ <expression> expression) (expression->dzn model expression))
    (($ <expression>) #f)
    (($ <data> data) (->string (list "$" data "$")))
    (($ <field> type field) (->string (list ((->dzn model) type) "." field)))
    (($ <literal> ('name scope ... name) field)
     ((->join ".") (list ((dzn:scope-join model) scope) name field)))
    (($ <var> identifier) ((->dzn model) identifier))
    (('! ($ <expression> expression)) (->string (list "!" (paren model expression))))
    (('! expression) (->string (list "!" (paren model expression))))
    (((or 'or 'and '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let* ((lhs ((->dzn model) lhs))
            (rhs ((->dzn model) rhs))
            (op (car o))
            (op (match op ('and "&&") ('or "||") (_ op))))
       (->string (list lhs " " op " " rhs ))))


    (('arguments arguments ...) (->string "(" ((->join ", ") (map (->dzn model) arguments)) ")"))
    ;;(('fields fields ...) ((->join ", ") fields))
    ;;(((or 'triggers 'formals) t ...) ((->join ", ") (map (->dzn model) t)))
    ((h t ...) ((->join ", ") (map (->dzn model) t)))
    ((? symbol?) (->string o))
    ((? string?) o)
    (() "")
    ((? unspecified?) "")
    (#f "false")
    (#t "true")
    (_ (->string o))))

(define (paren model expression)
  (if (or (number? expression) (symbol? expression)
          (is-a? expression <field>) (is-a? expression <literal>) (is-a? expression <var>))
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

(define* ((dzn:scope-join model :optional (infix '.)) o)
  ((om:scope-join model infix) o))

(define* ((animate-pairs pairs string) :optional parameter)
  (animate string (pairs->module pairs parameter)))

(define* ((animate-snippet file-name pairs) :optional parameter)
  (snippet file-name (pairs->module pairs parameter)))

(define* (pairs->module key-procedure-pairs :optional (parameter #f))
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

(define ((declare-event model) event)
  ((animate-snippet 'declare-event
                    `((direction ,.direction)
                      (formals ,(compose (->dzn model) .formals .signature))
                      (name ,.name)
                      (type ,(compose om:name .type .signature))
                      (scope.type ,(compose (om:scope-name '.) .type .signature))))
   event))

(define ((define-function model) function)
  ((animate-snippet 'function
                    `((formals ,(compose (->dzn model) .formals .signature))
                      (name ,.name)
                      (statement ,(compose (->dzn model) .statement))
                      (type ,(compose .name .type .signature))))
   function))

(define ((init-binding model) binding)
  ((animate-snippet 'binding
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
  (let ((module (make-module 31 (list (resolve-module '(gaiag dzn))
                                      (resolve-module '(gaiag misc))))))
    (module-define! module 'model o)
    (module-define! module '.model (and=> ((is? <model>) o) om:name))
    (module-define! module '.scope.model (and=> ((is? <model>) o) (om:scope-name '.)))
    module))

(define* ((ast->dzn :optional (model #f)) o)
  (parameterize ((template-dir (append (prefix-dir) `(templates dzn))))
    ((->dzn model) o)))

(define (ast-> ast)
  ((compose
    (ast->dzn)
    ast:resolve
    ast->om
    )
   ast))
