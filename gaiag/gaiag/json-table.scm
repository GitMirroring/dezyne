;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Henk Katerberg <henk.katerberg@verum.com>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

(define-module (gaiag json-table)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 match)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag util)
  #:use-module (gaiag ast)

  #:use-module (gaiag evaluate)
  #:use-module (gaiag html)
  #:use-module (gaiag json)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag resolve)

  #:export (json-init
           json-table-event
           json-table-state))

(define (json-init o)
  `((name . ,((om:scope-name '.) o))
    (type . ,(ast-name o))))

(define ((json-table-event model) o)
  (match o
    ((and ($ <compound>) (= .elements s))
     `((table . ,(map (json-table-event model) s))))
    ((and ($ <on>) (= .statement ($ <guard>)) (= .statement guard) (= (compose .expression .statement) expression))
     (let ((var (state-var model expression)))
       `((event . ,(json-triggers o))
         (rules . ,((json-table- model var expression) guard)))))
    ((and ($ <on>) (= .statement (and ($ <compound>) (= .elements (($ <guard>) ...)))) (= .statement compound))
     (let* ((var 'unknown)
            (state (make <field-test> #:variable.name var #:field '<unknown>)))
       `((event . ,(json-triggers o))
         (rules . ,(apply append (map (json-table- model var state)
                                      (.elements compound)))))))
    ((and ($ <on>) (= .statement statement))
     (let* ((var 'unknown)
            (state (make <field-test> #:variable.name var #:field '<unknown>)))
       `((event . ,(json-triggers o))
         (rules . ,(list
                    `((guard . ,(json-guard (make <guard> #:expression (make <literal> #:value 'true))))
                      (actions . ,(json-action model statement))
                      (callbacks . ,(json-callback model statement))
                      (next . ,(json-next model var state statement))))))))
    (_ `((event . ,(json-data-location '() o))
         (rules . ,(list
                    `((guard . ,(json-guard (make <guard> #:expression (make <literal> #:value 'true))))
                      (actions . ,(json-action model '()))
                      (callbacks . ,(json-callback model '()))
                      (next . ()))))))))

(define (state-var model o)
  (match o
    ((and ($ <field-test>) (= .variable.name variable)) variable)
    ((and ($ <or>) (= .left (and ($ <field-test>) (= .variable.name variable)))) variable)
    ((and ($ <var>) (= .variable.name variable)) variable)
    ((and ($ <not>) (= .expression (and ($ <var>) (= .variable.name variable)))) variable)
    ((and ($ <equal>) (= .left (and ($ <var>) (= .variable.name variable)))) variable)
    (_ '<state>)))

(define ((state->value model) o)
  (match o
    ((and ($ <field-test>) (= .field (? number?)) (= .field number)) number)
    ((and ($ <field-test>) (= .field (or 'true 'false)) (= .field bool)) bool)
    ((and ($ <field-test>) (= .variable var) (= .field field))
     (let* ((enum ((om:type model) var)))
       (make <enum-literal> #:type.name (.name enum) #:field field)))
    ((and ($ <equal>) (= .left ($ <var>)) (= .right (and ($ <literal>) (= .value val)))) val)
    (_ o )))

(define ((value->state model var) o)
  (match o
    ((? number?) (make <field-test> #:variable.name var #:field o))
    ((? symbol?) (make <field-test> #:variable.name var #:field o))
    (_ o)))

(define ((json-table-state model) o)
  (match o
    ((and ($ <compound>) (= .elements statements))
     `((table . ,(map (json-table-state model) statements))))
    ((and ($ <guard>) (= .expression expression) (= .statement ($ <on>)) (= .statement on))
     (let ((var (state-var model expression)))
       `((state . ,(json-state (->symbol expression) o))
         (rules . ,((json-table- model var expression) on)))))
    ((and ($ <guard>) (= .expression expression) (= .statement (and ($ <compound>) (= .elements (($ <on>) ...)))) (= .statement compound))
     (let ((var (state-var model expression)))
       `((state . ,(json-state (->symbol expression) o))
         (rules . ,(apply append (map (json-table- model var expression)
                                      (.elements compound)))))))
    (_ `((state . ,(json-state (->symbol o) o))
         (rules . ,(list
                    `((triggers . ,(json-triggers (make <triggers>)))
                      (guard . "")
                      (actions . ,(json-action model '()))
                      (callbacks . ,(json-callback model '()))
                      (next . ()))))))))

(define ((json-table- model var state) o)
  (match o
    (($ <guard>)
     (let* ((statement (.statement o))
            (expression (.expression o))
            (state (match expression
                     (($ <field-test>) expression)
                     ((and ($ <equal>) (= .left ($ <var>))) expression)
                     ((and ($ <var>) (= .variable vexpression)) (state-var model vexpression))
                     ((h t ...) (cadr expression))
                     (_ expression)))
            (var (state-var model state))
            (inner (.statement o)))
       (match inner
         ((and ($ <guard>) (= .statement statement))
          (list
           `((guard . ,(json-guard o))
             (inner . ,(json-guard inner))
             (actions . ,(json-action model statement))
             (callbacks . ,(json-callback model statement))
             (next . ,(json-next model var state statement)))))
         ((and ($ <compound>) (= .elements ()))
          (list
           `((guard . ,(json-guard o))
             ;;(inner . ,(json-data-location '() '()))
             (actions . ,(json-action model inner))
             (callbacks . ,(json-callback model inner))
             (next . ,(json-next model var state inner))
             )))
         ((and ($ <compound>) (= .elements (($ <guard>) ...)))
          (map (lambda (inner)
                 (let ((expression (.expression inner))
                       (statement (.statement inner)))
                   `((guard . ,(json-guard o))
                     (inner . ,(json-guard inner))
                     (actions . ,(json-action model statement))
                     (callbacks . ,(json-callback model statement))
                     (next . ,(json-next model var state statement)))))
               (.elements inner)))
         ((and ($ <guard>) (= .statement (and ($ <compound>) (= .elements (($ <guard>))))) (= .statement compound))
          (map (lambda (inner)
                 (let ((expression (.expression inner))
                       (statement (.statement inner)))
                   `((guard . ,(json-guard o))
                     (inner . ,(json-guard inner))
                     (actions . ,(json-action model statement))
                     (callbacks . ,(json-callback model statement))
                     (next . ,(json-next model var state statement)))))
               (.elements compound)))

         (_ (list
             `((guard . ,(json-guard o))
               (actions . ,(json-action model statement))
               (callbacks . ,(json-callback model statement))
               (next . ,(json-next model var state statement))))))))
    ((and ($ <on>) (= .triggers triggers) (= .statement (and ($ <compound>) (= .elements (($ <guard>) ..1))) (= .statement compound)))
     (map (json-inner-guard model var state triggers)
          (map .expression (.elements compound))
          (map .statement (.elements compound))))
    ((and ($ <on>) (= .triggers triggers) (= .statement (and ($ <guard>) (= .expression guard) (= .statement statement))))
     (list ((json-inner-guard model var state triggers) guard statement)))
    (_
     (list
      `((triggers . ,(json-triggers (.triggers o)))
        (guard . "")
        (actions . ,(json-action model (.statement o)))
        (callbacks . ,(json-callback model (.statement o)))
        (next . ,(json-next model var state (.statement o))))))))

(define ((json-inner-guard model var state triggers) guard statement)
  `((triggers . ,(json-triggers
                  triggers
                  (if (ast:location triggers) triggers
                      statement)))
    (guard . ,(->symbol guard))
    (actions . ,(json-action model statement))
    (callbacks . ,(json-callback model statement))
    (next . ,(json-next model var state statement))))

(define (json-next model var next o)
  (let ((next (delete-duplicates (json-next- model var (list next) o '()))))
    (if (=1 (length next))
        (->symbol (car next))
        (map ->symbol next))))

(define (json-next- model var next o functions)
  (define (var? variable) (eq? variable var))
  (let ((unknown (make <field-test> #:variable.name var #:field '<unknown>)))
   (match o
     ((and ($ <compound>) (= .elements statements))
      (let loop ((statements statements) (next next))
        (if (null? statements)
            next
            (loop (cdr statements) (json-next- model var next (car statements) functions)))))
     ((and ($ <assign>) (= .variable.name (? var?)) (= .expression (and ($ <enum-literal>) (= .field field))))
      (list (make <field-test> #:variable.name var #:field field)))
     ((and ($ <assign>) (= .variable.name (? var?))
           (= .expression (and ($ <not>) (= .expression (and ($ <var>) (= .variable.name (? var?)))))))
      (match next
        (((and ($ <not>) (= .expression (and ($ <var>) (= .variable.name (? var?)))) (= (compose .variable.name .expression) var))) (list var))
        (_ (list (make <not> #:expression (make <var> #:variable.name var))))))
     ((and ($ <assign>) (= .variable.name (? var?)) (= .expression (and ($ <literal>) (= .value 'false))))
      (list (make <not> #:expression (make <var> #:variable.name var))))
     ((and ($ <assign>) (= .variable.name (? var?)) (= .expression (and ($ <literal>) (= .value 'true))))
      (list (make <var> #:variable.name var)))
     ((and ($ <assign>) (= .variable.name (? var?)) (= .expression ($ <action>)))
      (list unknown))
     ((and ($ <assign>) (= .variable.name (? var?)) (= .expression ($ <call>)))
      (list unknown))
     ((and ($ <assign>) (= .variable.name (? var?)) (= .expression expression))
      (let* ((state (map (undefined-variable-state model (lambda (x) unknown)) (om:variables model)))
             (values (map (state->value model) next))
             (states (map (lambda (v) (var! state var v)) values))
             (updates (map (lambda (s) (eval-expression model s expression)) states)))
        (map (value->state model var) updates)))
     (($ <call>)
      (let* ((function (.function o))
             )
        (if (member function functions)
            next
            (json-next- model var next (.statement function) (cons function functions)))))
     ((and ($ <blocking>) (= .statement statement))
      (json-next- model var next statement functions))
     ((and ($ <guard>) (= .statement statement))
      (add-state next (json-next- model var next statement functions)))
     ((and ($ <if>) (= .then then) (= .else #f))
      (let ((then (json-next- model var next then functions)))
        (add-state next then)))
     ((and ($ <if>) (= .then then) (= .else else))
      (let ((then (json-next- model var next then functions))
            (else (json-next- model var next else functions)))
        (add-state then else)))
     (($ <illegal>) '())
     (_  next))))

(define (add-state o state)
  (match state
    ((h ...)
     (append o state))
    (($ <field-test>) (add-state o (list state)))))

(define (json-data-location data location)
  `((data . ,data)
    (location . ,(json-location location))))

(define (json-event data o)
  (json-data-location data o))

(define (json-state data o)
  (json-data-location data o))

(define (json-action model o)
  (json-data-location (ast->html o) o))

(define (json-callback model o)

  (define (function? ref) (and=> (ast:resolve ref) .function))
  (define (recursive? ref) (.recursive (function? ref)))
  (define non-recursive? (compose negate recursive?))

  (define (return-action o)
    (match o
      (($ <action>) (list o))
      ((and ($ <assign>) (= .expression ($ <action>))) (list (.expression o)))
      ((and ($ <variable>) (= .expression ($ <action>))) (list (.expression o)))
      ((and ($ <call>) (? non-recursive?)) (return-actions (function? o)))
      ((and ($ <function>) (= .recursive #f) (= .statement statement)) (return-actions statement))
      (_ '())))

  (define (return-actions o)
    (filter identity
            (apply append
                   (map return-action ((om:collect return-action) o)))))

  (or (and-let* (((is-a? model <interface>))
                 ((is-a? o <statement>))
                 (actions (return-actions o)))
        (map ast->html actions))
      '()))

(define* (json-triggers o #:optional (location o))
  (match o
    ((and ($ <triggers>) (= .elements triggers))
     (json-data-location (map ->symbol triggers) location))
    (($ <on>)
     (json-data-location (map ->symbol ((compose .elements .triggers) o)) location))))

(define (json-guard o)
  (json-data-location (->symbol (.expression o)) o))

(define (->symbol o)
  (->symbol- o))

(define (->symbol- o)
  (match o
    (#f 'false)
    (#t 'true)
    (($ <otherwise>) 'otherwise)
    ((and ($ <var>) (= .variable.name identifier)) identifier)
    ((and ($ <literal>) (= .value value)) (->symbol value))
    ((and ($ <field-test>) (= .variable.name variable) (= .field (? number?)) (= .field number)) (->symbol (list variable '== number)))
    ((and ($ <field-test>) (= .variable.name variable) (= .field field)) (->symbol (list (->symbol variable) "." field)))
    ((identifier (and ($ <field-test>) (= .variable.name variable) (= .field field))) (->symbol (list (->symbol identifier) " = " (->symbol variable) "." field)))
    ((identifier (and ($ <enum-literal>) (= .type type) (= .field field))) (->symbol (list (->symbol identifier) " = " (->symbol type) "." (->symbol field))))
    ((and ($ <enum-literal>) (= .type type) (= .field field)) (->symbol (list (->symbol type) "." (->symbol field))))
    ((and ($ <scope.name>) (= .scope scope) (= .name name)) ((->symbol-join '.) (append scope (list name))))
    ((and ($ <triggers>) (= .elements triggers)) (->symbol ((->join ",") (map ->symbol triggers))))
    ((and ($ <trigger>) (= .event.name event)) (->symbol event))
    ((and ($ <trigger>) (= .port.name port) (= .event.name event)) (->symbol (list port "." event)))
    ((and ($ <and>) (= .left left) (= .right right)) (->symbol (list '&& left right)))
    ((and ($ <equal>) (= .left left) (= .right right)) (->symbol (list left '== right)))
    ((and ($ <greater-equal>) (= .left left) (= .right right)) (->symbol (list left '>= right)))
    ((and ($ <greater>) (= .left left) (= .right right)) (->symbol (list left '> right)))
    ((and ($ <less-equal>) (= .left left) (= .right right)) (->symbol (list left '<= right)))
    ((and ($ <less>) (= .left left) (= .right right)) (->symbol (list left '< right)))
    ((and ($ <minus>) (= .left left) (= .right right)) (->symbol (list left '- right)))
    ((and ($ <not-equal>) (= .left left) (= .right right)) (->symbol (list left '!= right)))
    ((and ($ <or>) (= .left left) (= .right right)) (->symbol (list left '#{||}# right)))
    ((and ($ <plus>) (= .left left) (= .right right)) (->symbol (list left '+ right)))

    ((and ($ <group>) (= .expression expression)) (->symbol (list '#{(}# expression '#{)}# )))
    ((and ($ <not>) (= .expression expression)) (->symbol (list '! expression)))

    (((h t ...)) (->symbol (car o)))
    ((h t ...) (apply symbol-append (map ->symbol o)))
    ((? (is? <ast>)) (->symbol (om->list o)))
    ((? string?) (string->symbol o))
    ((? number?) (->symbol (number->string o)))
    ((? symbol?) o)
    (() (string->symbol ""))
    (*unspecified* '<unknown>)
    (_ (throw 'match-error  (format #f "~a: ->symbol match: ~a\n"  (current-source-location) o)))))
