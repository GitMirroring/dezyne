;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define (std-renamer lst)
  (lambda (x) (case x ((<parameter>) '<std:parameter>) ((<port>) '<std:port>) (else x))))

(define-module (language asd gom)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 match)
  :use-module (srfi srfi-1)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd pretty)
  :use-module (language asd reader)

  :use-module (oop goops)
;;  :use-module ((oop goops) :renamer (std-renamer '(port parameter)))
  :use-module (oop goops describe)

  :use-module (language asd gom ast)

  :export (
           .arguments
           .behaviour
           .direction
           .elements
           .else
           .event
           .events
           .expression
           .fields
           .functions
           .identifier
           .name
           .parameters
           .port
           .ports
           .signature
           .statement
           .then
           .trigger
           .triggers
           .type
           .types
           .value
           .variables
           <action>
           <arguments>
           <assign>
           <ast>
           <behaviour>
           <call>
           <component>
           <compound>
           <enum>
           <event>
           <events>
           <expression>
           <fields>
           <function>
           <functions>
           <guard>
           <if>
           <illegal>
           <interface>
           <model>
           <on>
           <parameter>
           <parameters>
           <port>
           <ports>
           <reply>
           <return>
           <signature>
           <statement>
           <trigger>
           <triggers>
           <types>
           <variable>
           <variables>
           ast->
           ast-name
           display-slots
           sdisplay
           star
           ))

(define-class <ast> ())

(define-method (ast-name (o <ast>))
  (string->symbol (string-drop (string-drop-right (symbol->string (class-name (class-of o))) 1) 1)))

(define-class <named> (<ast>)
  (name :accessor .name :init-value #f :init-keyword :name))

(define-class <ast-list> (<ast>)
  (elements :accessor .elements :init-form (list) :init-keyword :elements))

(define-class <dir-ast> (<named>)
  (direction :accessor .direction :init-value 'in :init-keyword :direction)
  (type :accessor .type :init-value #f :init-keyword :type))

(define-class <model> (<named>))

(define-class <interface> (<model>)
  (events :accessor .events :init-form (make <events>) :init-keyword :events)
  (types :accessor .types :init-form (make <types>) :init-keyword :types)
  (behaviour :accessor .behaviour :init-value #f :init-keyword :behaviour))

(define-class <event> (<dir-ast>))
(define-class <port> (<dir-ast>))

(define-class <type> (<named>))

(define-class <expression> (<ast>)
  (value :accessor .value :init-value #f :init-keyword :value))

(define-class <variable> (<named>)
;;;  (type :accessor .type :init-value (make <type> :name 'bool) :init-keyword :type)
  (type :accessor .type :init-value 'bool :init-keyword :type)
  (expression :accessor .expression :init-form (make <expression>) :init-keyword :expression))

(define-class <parameter> (<ast>)
  (type :accessor .type :init-value (make <type>) :init-keyword :type)
  (identifier :accessor .identifier :init-value #f :init-keyword :identifier))

(define-class <signature> (<ast>)
  (type :accessor .type :init-value (make <type>) :init-keyword :type)
  (parameters :accessor .parameters :init-form (make <parameters>) :init-keyword :parameters))

(define-class <component> (<model>)
  (ports :accessor .ports :init-form (make <ports>) :init-keyword :ports)
  (behaviour :accessor .behaviour :init-value #f :init-keyword :behaviour))

(define-class <arguments> (<ast-list>))
(define-class <events> (<ast-list>))
(define-class <fields> (<ast-list>))
(define-class <functions> (<ast-list>))
(define-class <parameters> (<ast-list>))
(define-class <ports> (<ast-list>))
(define-class <triggers> (<ast-list>))
(define-class <types> (<ast-list>))
(define-class <variables> (<ast-list>))

(define-class <enum> (<named>)
  (fields :accessor .fields :init-form (list) :init-keyword :fields))

(define-class <behaviour> (<named>)
  (types :accessor .types :init-form (make <types>) :init-keyword :types)
  (variables :accessor .variables :init-form (make <variables>) :init-keyword :variables)
  (functions :accessor .functions :init-form (make <functions>) :init-keyword :functions)
  (statement :accessor .statement :init-value #f :init-keyword :statement))

(define-class <function> (<named>)
  (signature :accessor .signature :init-form (make <signature>) :init-keyword :signature)
  (statement :accessor .statement :init-value #f :init-keyword :statement))

;;; statements
(define-class <statement> (<ast>))
(define-class <action> (<statement>)
  (trigger :accessor .trigger :init-value #f :init-keyword :trigger))

(define-class <assign> (<statement>)
  (identifier :accessor .identifier :init-value #f :init-keyword :identifier)
  (expression :accessor .expression :init-form (make <expression>) :init-keyword :expression))

(define-class <call> (<statement>)
  (identifier :accessor .identifier :init-value #f :init-keyword :identifier)
  (arguments :accessor .arguments :init-form (make <arguments>) :init-keyword :arguments))

(define-class <compound> (<ast-list> <statement>))

(define-class <guard> (<statement>)
  (expression :accessor .expression :init-form (make <expression>) :init-keyword :expression)
  (statement :accessor .statement :init-value #f :init-keyword :statement))

(define-class <if> (<statement>)
  (expression :accessor .expression :init-form (make <expression>) :init-keyword :expression)
  (then :accessor .then :init-value #f :init-keyword :then)
  (else :accessor .else :init-value #f :init-keyword :else))

(define-class <illegal> (<statement>))

(define-class <on> (<statement>)
  (triggers :accessor .triggers :init-form (make <triggers>) :init-keyword :triggers)
  (statement :accessor .statement :init-value #f :init-keyword :statement))

(define-class <reply> (<statement>)
  (expression :accessor .expression :init-value #f :init-keyword :expression))

(define-class <return> (<statement>)
  (expression :accessor .expression :init-value #f :init-keyword :expression))

(define-class <trigger> (<ast>)
  (port :accessor .port :init-value #f :init-keyword :port)
  (event :accessor .event :init-value #f :init-keyword :event))

(define-class <value> (<ast>)
  (type :accessor .type :init-value #f :init-keyword :type)
  (field :accessor .field :init-value #f :init-keyword :field))

;; AST printing
(define (star port) (display #\* port))

(define-method (sdisplay (o <ast>) port)
  (display #\space port)
  (display o port))

(define-method (sdisplay (o <top>) port)
  (display #\space port)
  (display o port))

(define-method (display-slots (o <ast>) port)
  (for-each (lambda (slot)
              (let* ((name (slot-definition-name slot))
                     (value (slot-ref o name)))
                (when (not (eq? value '()))
                  (if (eq? name 'elements)
                      (for-each (lambda (x) (sdisplay x port)) value)
                      (sdisplay (slot-ref o name) port)))))
            (class-slots (class-of o))))

(define-method (write (o <expression>) port)
  (display (.value o) port))

(define-method (display-slots (o <dir-ast>) port)
  (display (.direction o) port)
  (star port)
  (sdisplay (.type o) port)
  (sdisplay (.name o) port))

(define-method (display-slots (o <call>) port)
  (sdisplay (.identifier o) port)
  (if (pair? (.elements (.arguments o)))
      (sdisplay (.arguments o) port)))

(define-method (write (o <dir-ast>) port)
  (display "(" port)
  (display-slots o port)
  (display #\) port))

(define-method (display-slots (o <if>) port)
  (sdisplay (.expression o) port)
  (sdisplay (.then o) port)
  (and=> (.else o) (lambda (x) (sdisplay x port))))

(define-method (display-slots (o <return>) port)
  (and=> (.expression o) (lambda (x) (sdisplay x port))))

(define-method (display-slots (o <signature>) port)
  (sdisplay (.type o) port)
  (if (pair? (.elements (.parameters o)))
      (sdisplay (.parameters o) port)))

(define-method (display-slots (o <variable>) port)
  (sdisplay (.type o) port)
  (sdisplay (.name o) port)
  (sdisplay (.expression o) port))

(define-method (write (o <ast>) port)
  (display "(" port)
  (display (ast-name o) port)
  (star port)
  (display-slots o port)
  (display #\) port))

(define (ast-> ast)
  (pretty-print (with-input-from-string
                    (with-output-to-string (lambda () (write (ast->gom* ast))))
                  read)) "")
