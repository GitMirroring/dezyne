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

(define-module (language asd gom)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 match)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd pretty)
  :use-module (language asd reader)

  :use-module (oop goops)
  :export (ast-> ast->gom))

(define-class <ast> ()
  (name :accessor .name :init-value #f :init-keyword :name))

(define-class <named> (<ast>)
  (name :accessor .name :init-value #f :init-keyword :name))

(define-class <model> (<named>)
  (behaviour :accessor .behaviour :init-value #f :init-keyword :behaviour))

(define-class <interface> (<model>)
  (events :accessor .events :init-form (make <events>) :init-keyword :events)
  (types :accessor .types :init-form (make <types>) :init-keyword :types))

(define-class <event> (<named>)
  (direction :accessor .direction :init-value 'in :init-keyword :direction)
  (signature :accessor .signature :init-form (make <signature>) :init-keyword :signature))

(define-class <signature> (<ast>)
  (return-type :accessor .return-type :init-value 'void :init-keyword :return-type)
  (parameters :accessor .parameters :init-form (make <parameters>) :init-keyword :parameters))

(define-class <component> (<model>))
(define-class <ast-list> (<ast>)
  (elements :accessor .elements :init-form (list) :init-keyword :elements))
(define-class <types> (<ast-list>))
(define-class <events> (<ast-list>))
(define-class <ports> (<ast-list>))

(define-class <enum> (<named>)
  (elements :accessor .elements :init-form (list) :init-keyword :elements))
(define-class <parameters> (<ast-list>))

(define (ast->gom ast)
  (match ast
    ((? ast:interface?) (make <interface> 
                          :name (ast:name ast)
                          :events (ast->gom (ast:event-list ast))
                          :types (ast->gom (ast:type-list ast))
                          :behaviour (ast->gom (ast:behaviour ast))))
    ((? ast:component?) (make <component> :name (ast:name ast)))
    ((? ast:event?) (make <event> 
                      :name (ast:name ast)
                      :signature (ast->gom (ast:signature ast))
                      :direction (ast:direction ast)))
    ((? ast:enum?) (make <enum>
                     :name (ast:name ast)
                     :elements (ast:elements ast)))
    ((? ast:event-list?) (make <events> :elements (ast:body ast)))
    ((? ast:type-list?) (make <types> :elements (ast:body ast)))
    ((h t ...) (map ast->gom ast))
    (_ ast)))


;; AST printing
(define-method (display-slots (o <ast>) port))

(define-method (display-slots (o <named>) port)
  (next-method)
  (display (.name o) port))

(define-method (display-slots (o <interface>) port)
  (next-method)
  (display #\space port)
  (display (.types o) port)
  (display #\space port)
  (display (.events o) port)
  (display #\space port)
  (display (.behaviour o) port))

(define-method (display-slots (o <event>) port)
;; events are written as (in or (out .. not (event
;;  (next-method)
;;  (display #\space port)
  (display (.direction o) port)
  (display #\space port)
  (display (.signature o) port)
  (display #\space port)
  (next-method))

(define-method (write (o <event>) port)
  (display "(" port)
  (display-slots o port)
  (display #\) port))

(define-generic class-name)
(define-method (class-name (o <ast>))
  (string->symbol (string-drop (string-drop-right (symbol->string (class-name (class-of o))) 1) 1)))

(define-method (write (o <ast>) port)
  (display "(" port)
  (display (class-name o) port)
  (display #\space port)
  (display-slots o port)
  (display #\) port))

(define (ast-> ast)
  (pretty-print (ast->gom ast)) "")
