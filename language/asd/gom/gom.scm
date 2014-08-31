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

(define (std-renamer lst)
  (lambda (x) (case x ((<parameter>) '<std:parameter>) ((<port>) '<std:port>) (else x))))

(define-module (language asd gom gom)
  :use-module (oop goops)
;;  :use-module ((oop goops) :renamer (std-renamer '(port parameter)))
  :export (
           .arguments
           .behaviour
           .direction
           .elements
           .else
           .event
           .events
           .expression
           .field
           .fields
           .functions
           .identifier
           .instance
           .left
           .name
           .parameters
           .port
           .ports
           .right
           .scope
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
           <ast-list>
           <behaviour>
           <bind>
           <call>
           <component>
           <compound>
           <dir-ast>
           <enum>
           <event>
           <events>
           <expression>
           <field>
           <fields>
           <function>
           <functions>
           <guard>
           <if>
           <illegal>
           <instance>
           <interface>
           <literal>
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
           <system>
           <trigger>
           <triggers>
           <types>
           <variable>
           <variables>
           ))

(define-class <ast> ())

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

(define-class <trigger> (<ast>)
  (port :accessor .port :init-value #f :init-keyword :port)
  (event :accessor .event :init-value #f :init-keyword :event))

(define-class <type> (<named>))

(define-class <expression> (<ast>)
  (value :accessor .value :init-value #f :init-keyword :value))

(define-class <field> (<ast>)
  (identifier :accessor .identifier :init-value #f :init-keyword :identifier)
  (field :accessor .field :init-value #f :init-keyword :field))

(define-class <literal> (<ast>)
  (scope :accessor .scope :init-value #f :init-keyword :scope)
  (type :accessor .type :init-value #f :init-keyword :type)
  (field :accessor .field :init-value #f :init-keyword :field))

(define-class <value> (<ast>)
  (type :accessor .type :init-value #f :init-keyword :type)
  (field :accessor .field :init-value #f :init-keyword :field))

(define-class <variable> (<named>)
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

(define-class <system> (<model>)
  (ports :accessor .ports :init-form (make <ports>) :init-keyword :ports)
  (statement :accessor .statement :init-value #f :init-keyword :statement))

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

(define-class <bind> (<statement>)
  (left :accessor .left :init-value #f :init-keyword :left)
  (right :accessor .right :init-value #f :init-keyword :right))

(define-class <instance> (<named> <statement>)
  (type :accessor .type :init-value #f :init-keyword :type))
