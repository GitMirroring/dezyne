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
  :use-module (oop goops describe)
  :export (
           ast->
           ast->gom
           ast->gom*

           <action>
           <assign>
           <ast>
           <compound>
           <expression>
           <trigger>

           .elements
           .event
           .expression
           .identifier
           .port
           .trigger
           .value


           ;; utilities
           gom:find-triggers
           gom:statements-of-type
           gom:statement
           ))

(define-class <ast> ())
(define-class <statement> (<ast>))

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

(define-class <type> (<ast>)
  (name :accessor .name :init-value 'void :init-keyword :name))

(define-class <expression> (<ast>)
  (value :accessor .value :init-value #f :init-keyword :value))

(define-class <variable> (<named>)
  (type :accessor .type :init-value (make <type> :name 'bool) :init-keyword :type)
  (expression :accessor .expression :init-form (make <expression>) :init-keyword :expression))

(define-class <signature> (<ast>)
  (type :accessor .type :init-value (make <type>) :init-keyword :type)
  (parameters :accessor .parameters :init-form (make <parameters>) :init-keyword :parameters))

(define-class <component> (<model>)
  (ports :accessor .ports :init-form (make <ports>) :init-keyword :ports)
  (behaviour :accessor .behaviour :init-value #f :init-keyword :behaviour))

(define-class <compound> (<ast-list> <statement>))
(define-class <events> (<ast-list>))
(define-class <ports> (<ast-list>))
(define-class <triggers> (<ast-list>))
(define-class <types> (<ast-list>))
(define-class <variables> (<ast-list>))

(define-class <enum> (<named>)
  (fields :accessor .fields :init-form (list) :init-keyword :fields))

(define-class <parameters> (<ast-list>))

(define-class <behaviour> (<named>)
  (types :accessor .types :init-form (make <types>) :init-keyword :types)
  (variables :accessor .variables :init-form (make <variables>) :init-keyword :variables)
  (statement :accessor .statement :init-value #f :init-keyword :statement))

(define-class <action> (<statement>)
  (trigger :accessor .trigger :init-value #f :init-keyword :trigger))

(define-class <assign> (<statement>)
  (identifier :accessor .identifier :init-value #f :init-keyword :identifier)
  (expression :accessor .expression :init-form (make <expression>) :init-keyword :expression))

(define-class <illegal> (<statement>))

(define-class <guard> (<statement>)
  (expression :accessor .expression :init-form (make <expression>) :init-keyword :expression)
  (statement :accessor .statement :init-value #f :init-keyword :statement))

(define-class <on> (<statement>)
  (triggers :accessor .triggers :init-form (list) :init-keyword :triggers)
  (statement :accessor .statement :init-value #f :init-keyword :statement))

(define-class <trigger> (<ast>)
  (port :accessor .port :init-value #f :init-keyword :port)
  (event :accessor .event :init-value #f :init-keyword :event))

(define-class <value> (<ast>)
  (type :accessor .type :init-value #f :init-keyword :type)
  (field :accessor .field :init-value #f :init-keyword :field))

(define (ast->gom- ast)
  (match ast
    ((? ast:interface?) (make <interface>
                          :name (ast:name ast)
                          :events (ast->gom (ast:event-list ast))
                          :types (ast->gom (ast:type-list ast))
                          :behaviour (ast->gom (ast:behaviour ast))))
    ((? ast:component?) (make <component>
                          :name (ast:name ast)
                          :ports (ast->gom (ast:port-list ast))
                          :behaviour (ast->gom (ast:behaviour ast))))
    ((? ast:event?) (make <event>
                      :name (ast:name ast)
                      :type (ast->gom (ast:signature ast))
                      :direction (ast:direction ast)))
    ((? ast:port?) (make <port>
                      :name (ast:name ast)
                      :type (ast:type ast)
                      :direction (ast:direction ast)))
    ((? ast:enum?) (make <enum>
                     :name (ast:name ast)
                     :fields (ast:fields ast)))
    ((? ast:variable?) (make <variable>
                         :name (ast:name ast)
                         :type (ast:type ast)
                         :expression (make <expression>
                                       :value (ast->gom (ast:expression ast)))))

    ((? ast:event-list?) (make <events>
                           :elements (map ast->gom (ast:body ast))))
    ((? ast:parameter-list?) (make <parameters>
                               :elements (map ast->gom (ast:body ast))))
    ((? ast:port-list?) (make <ports>
                          :elements (map ast->gom (ast:body ast))))
    ((? ast:statement-list?) (make <compound>
                               :elements (map ast->gom (ast:body ast))))
    ((? ast:trigger-list?) (make <triggers>
                             :elements (map ast->gom (ast:body ast))))
    ((? ast:type-list?) (make <types>
                          :elements (map ast->gom (ast:body ast))))
    ((? ast:variable-list?) (make <variables>
                          :elements (map ast->gom (ast:body ast))))

    ((? ast:signature?) (make <signature>
                          :type (ast:type ast)
                          :parameters (ast->gom (ast:parameter-list ast))))
    ((? ast:behaviour?) (make <behaviour>
                          :name (ast:name ast)
                          :types (ast->gom (ast:type-list ast))
                          :variables (ast->gom (ast:variable-list ast))
                          :statement (ast->gom (ast:statement ast))))
    ((? ast:trigger?) (make <trigger>
                       :port (ast:port-name ast)
                       :event (ast:event-name ast)))

    ((? ast:action?) (make <action>
                       :trigger (ast->gom (ast:trigger ast))))
    ((? ast:assign?) (make <assign>
                       :identifier (ast:identifier ast)
                       :expression (make <expression>
                                     :value (ast->gom (ast:expression ast)))))
    ((? ast:guard?) (make <guard>
                       :expression (make <expression>
                                     :value (ast->gom (ast:expression ast)))
                       :statement (ast->gom (ast:statement ast))))
    ((? ast:illegal?) (make <illegal>))
    ((? ast:on?) (make <on>
                       :triggers (map ast->gom (ast:triggers ast))
                       :statement (ast->gom (ast:statement ast))))

    ((? ast:value?) (make <value>
                      :type (ast:type ast)
                      :field (ast:field ast)))
    ((h t ...) (map ast->gom ast))
    (_ ast)))

(define (ast->sugar ast)
  (match ast
    (('on ('triggers t ...) statement the-end ...) ast)
    (('on triggers statement) (ast:make 'on (list (ast:make 'triggers (map ast->trigger-sugar triggers)) statement)))
    (('on triggers statement the-end) (list 'on (ast:make 'triggers (map ast->trigger-sugar triggers)) statement the-end))
    (_ ast)))

(define (ast->trigger-sugar ast)
  (match ast
    ((port event) (ast:make 'trigger ast))
    ((? symbol?) (ast:make 'trigger (list #f ast)))
    (_ ast)))

(define (ast->gom ast)
  ((compose ast->gom- ast->sugar) ast))

(define (ast->gom*- ast)
  (match ast
    ((? ast:action?) (make <action>
                       :trigger (ast->gom (ast:trigger ast))))
    ((? ast:assign?) (make <assign>
                       :identifier (ast:identifier ast)
                       :expression (make <expression>
                                     :value (ast->gom* (ast:expression ast)))))
    ((? ast:statement-list?) (make <compound>
                               :elements (map ast->gom* (ast:body ast))))
    ((? ast:trigger?) (make <trigger>
                       :port (ast:port-name ast)
                       :event (ast:event-name ast)))
    ((h t ...) (map ast->gom* ast))
    (_ ast)))

(define (ast->gom* ast)
  ((compose ast->gom*- ast->sugar) ast))

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

(define-method (write (o <dir-ast>) port)
  (display "(" port)
  (display-slots o port)
  (display #\) port))

(define-generic class-name)
(define-method (class-name (o <ast>))
  (string->symbol (string-drop (string-drop-right (symbol->string (class-name (class-of o))) 1) 1)))

(define-method (write (o <ast>) port)
  (display "(" port)
  (display (class-name o) port)
  (star port)
  (display-slots o port)
  (display #\) port))

(define (ast-> ast)
  (pretty-print (with-input-from-string
                    (with-output-to-string (lambda () (write (ast->gom ast))))
                  read)) "")


;;;; utilities

;;;; temporary hetorogenous AST compatibility
(define (gom:class ast)
  (match ast
    ((? ast:enum?) 'type)
    ((? ast:event?) 'event)
    ((? ast:int?) 'type)
    ((? ast:port?) 'port)
    ((? ast:trigger?) 'trigger)
    ((? ast:value?) 'value)
    ((? ast:variable?) 'variable)
    ('() #f)
    (#f #f)
    (($ <compound>) 'compound)
    (_ (car ast))))

(define-method (gom:trigger< (lhs <trigger>) (rhs <trigger>))
  (if (and (not (.port lhs)) (not (.port rhs)))
      (symbol< (.event lhs) (.event rhs))
      (if
       (and (symbol? (.port lhs)) (symbol? (.port rhs))
            (list< (list (.port lhs) (.event lhs))
                   (list (.port rhs) (.event rhs))))
       (not (symbol? (.port lhs))))))

(define* (gom:find-triggers ast :optional (found '()))
  "Search for optional and inevitable."
  (match ast
    ((or (? ast:interface?) (? ast:component?))
     (delete-duplicates (sort (gom:find-triggers (gom:statement (ast:behaviour ast))) gom:trigger<)))
    (($ <compound>) (append (apply append (map gom:find-triggers (.elements ast))) found))
    (('on t statement) (gom:find-triggers t))
    (('trigger port event) ast)
    (('triggers triggers ...) triggers)
    (('guard expression statement) (gom:find-triggers statement found))
    (('inevitable) ast)
    (('optional) ast)
    (('action x) '())
    (('illegal) '())
    (_ (throw 'match-error  (format #f "~a:gom:find-triggers: no match: ~a\n" (current-source-location) ast)))))

(define (statement? ast)
  (member (gom:class ast) '(action assign bind call compound guard if instance on reply variable return)))

(define (gom:statement ast)
  (match ast
    ((? ast:system?) (or (find (lambda (x) (is-a? x <compound>)) (ast:body ast))))
    ((? ast:model?) (or (null-is-#f (gom:statement (ast:behaviour ast))) (make <compound>)))
    ((? ast:behaviour?) (or (find (lambda (x) (is-a? x <compound>)) (ast:body ast))
                            (make <compound>)))
    ((or (? ast:guard?) (? ast:on?)) (caddr ast))
    ((? ast:function?) (cadddr ast))
    (_ (throw 'match-error  (format #f "~a:gom:statement: no match: ~a\n" (current-source-location) ast)))))

(define ((gom:statement-of-type type) statement)
  (eq? (gom:class statement) type))

(define ((gom:statements-of-type type) statement)
  (match statement
    ((? (gom:statement-of-type type)) (list statement))
    (($ <compound>) (filter identity (apply append (map (gom:statements-of-type type) (.elements statement)))))
    (('guard expr s) (filter identity ((gom:statements-of-type type) s)))
    ((? statement?) '())
    ('() '())
    ((t ...) (filter identity (apply append (map (gom:statements-of-type type) t))))
    (_ (throw 'match-error  (format #f "~a:gom:statements-of-type, type: ~a: no match: ~a\n" (current-source-location) type statement)))))
