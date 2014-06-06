;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (language asd ast)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 match)
  :use-module (language asd misc)
  :export (behaviour-types
           behaviour-variables

           component
           component-behaviour
           component-bottom?
           component-name
           component-ports
           ;; component-spec
           component-interface
           type-name-component

           enum-elements
           
           interface
           interface-name
           interface-types
           ;; interface-spec
           
           port-direction
           port-name
           port-interface

           type-name
           variable-initial-value
           variable-name
           variable-type

           ->string
           interface-
           ))

(define (interface ast) (assoc 'interface ast)) 
(define (interface-name interface) (cadr interface))
(define (interface-spec interface) (cddr interface)) 
(define (interface-types interface) (assoc-ref (interface-spec interface) 'types))
(define (interface-events interface) (assoc-ref (interface-spec interface) 'events))

(define (event-direction event) (car event))
(define (event-type event) (cadr event))
(define (event-name event) (caddr event))
(define (in-event? event) (eq? (event-direction event) 'in))
(define (out-event? event) (eq? (event-direction event) 'out))

(define (component ast) (assoc 'component ast))
(define (component-bottom? component)
  (and-let* ((ports (component-ports component))
             ((=1 (length ports))))
            (eq? (port-direction (car ports)) 'provides)))

(define (component-name component) (cadr component))
(define (component-spec component) (cddr component)) 
(define (component-ports component) (cdr (assoc 'ports (component-spec component)))) 
(define (component-interface component) (car (assoc-ref (component-ports component) 'provides)))

(define (port-direction port) (car port))
(define (port-name port) (caddr port))
(define (port-interface port) (cadr port))

;;(define (port-events ()))

(define (component-behaviour component) 
  (assoc 'behaviour (component-spec component)))
(define (behaviour-spec behaviour) (cddr behaviour))
(define (behaviour-types behaviour) (assoc-ref (behaviour-spec behaviour) 'types))
(define (behaviour-variables behaviour) (assoc-ref (behaviour-spec behaviour) 'variables))

(define (variable-type variable) (cadr variable))
(define (variable-name variable) (caddr variable))
(define (variable-initial-value variable) (cadddr variable))

(define (enum-elements enum) (caddr enum))

(define (type-name type) (car type))

(define (type-name-component type component)
  (symbol-append (component-name component) (variable-type type)))

(define (->string src) 
  (match src
    (#f "false")
    (#t "true")
    ((? char?) (make-string 1 src))
    ((? string?) src)
    ((? symbol?) (symbol->string src))
    ((h ... t) (apply string-append (map ->string src)))
    (_ "")))



;;;;;;;;;;FIXME experimental C++ output
(define ast '())
(define (*interface*) (interface-name (interface ast)))
(define (*api-class*) (map ->string (list (*interface*) (*api*))))
(define (*callback-class*) (map ->string (list (*interface*) (*callback*))))

(define (*api-events*) (map (lambda (x) (list "  virtual void " (event-name x) "() = 0;\n")) (filter in-event? (interface-events (interface ast)))))
(define (*callback-events*)  (map (lambda (x) (list "  virtual void " (event-name x) "() = 0;\n")) (filter out-event? (interface-events (interface ast)))))

(define (*api*) 'API)
(define (*callback*) 'CB)
(define (*ap*) 'api)
(define (*cb*) 'cb)

(define (comma-join lst) (string-join (map symbol->string lst) ", "))

(define (enum->string enum)
  (->string (list " Enum {" (comma-join (enum-elements enum)) " };\n")))

(define (*enums*) (->string (map enum->string (interface-types (interface ast)))))
