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
  :export (interface
           interface-name
           component
           component-name
           component-spec
           component-ports
           component-interface
           port-direction
           port-name
           port-interface))

(define (interface ast) (assoc 'interface ast)) 
(define (interface-name interface) (cadr interface))

(define (component ast) (assoc 'component ast))
(define (component-name component) (cadr component))
(define (component-spec component) (cddr component)) 
(define (component-ports component) (cdr (assoc 'ports (component-spec component)))) 
(define (component-interface component) (car (assoc-ref (component-ports component) 'provides)))

(define (port-direction port) (car port))
(define (port-name port) (caddr port))
(define (port-interface port) (cadr port))
