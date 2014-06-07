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
           behaviour-variable

           component
           component-behaviour
           component-bottom?
           component-name
           component-ports
           ;; component-spec
           component-interface
           type-name-component

           enum-elements
           enum-name
           enum-type

           event-direction
           event-name
           event-type
           event-in?
           event-out?
           event-dir-matches?

           interface
           interface-events
           interface-name
           interface-types
           ;; interface-spec
           
           port-direction
           port-name
           port-interface
           port-provides?
           port-requires?
           port-in?
           port-out?
           port-typed-event?
           event-typed?

           port-events ;; FIXME

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
(define (event-in? event) (eq? (event-direction event) 'in))
(define (event-out? event) (eq? (event-direction event) 'out))

(define (event-dir-matches? port) 
  (lambda (event)
    (or (and (eq? (port-direction port) 'provides)
             (eq? (event-direction event) 'in))
        (and (eq? (port-direction port) 'requires)
             (eq? (event-direction event) 'out)))))

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
(define (port-provides? port) (eq? (port-direction port) 'provides))
(define (port-requires? port) (eq? (port-direction port) 'requires))

(define (port-in? port) (or (port-requires? port) event-in? event-out?)) 
(define (port-out? port) (or (port-provides? port) event-out? event-in?)) 

(define (event-typed? event) (not (eq? (event-type event) 'void)))
(define (port-typed-event? port)
  (null-is-#f (filter event-typed? (port-events port))))

(define (port-events port)  ;;; FIXME
  (case (port-name port) 
    ((console) '((in void arm) (in void disarm) (out void detected (out void deactivated))))
    ((sensor) '((in void enable) (in void disable) (out void triggered) (out void disabled)))
    ((siren) '((in void turnon) (in void turnoff)))))

(define (component-behaviour component) 
  (assoc 'behaviour (component-spec component)))
(define (behaviour-spec behaviour) (cddr behaviour))
(define (behaviour-types behaviour) (assoc-ref (behaviour-spec behaviour) 'types))
(define (behaviour-variables behaviour) (assoc-ref (behaviour-spec behaviour) 'variables))

(define (behaviour-variable behaviour variable) (assoc-ref (behaviour-variables behaviour variable)))
(define (variable-type variable) (cadr variable))
(define (variable-name variable) (caddr variable))
(define (variable-initial-value variable) (cadddr variable))

(define (enum-elements enum) (caddr enum))
(define (enum-name enum) (cadr enum))

(define (type-name type) (car type))
(define enum-type type-name)

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

