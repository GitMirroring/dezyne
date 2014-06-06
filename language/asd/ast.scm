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
           variable-type))

(define (interface ast) (assoc 'interface ast)) 
(define (interface-name interface) (cadr interface))
(define (interface-spec interface) (cddr interface)) 
(define (interface-types interface) (assoc-ref (interface-spec interface) 'types))

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
