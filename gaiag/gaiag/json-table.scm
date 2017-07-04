;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag json-table)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 match)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)

  #:use-module (language dezyne location)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast2om)
  #:use-module (gaiag util)
  #:use-module (gaiag om)

  #:use-module (gaiag evaluate)
  #:use-module (gaiag html)
  #:use-module (gaiag json)
  #:use-module (gaiag misc)
  #:use-module (gaiag reader)
  #:use-module (gaiag resolve)

  #:export (json-init
           json-table-event
           json-table-state))

(define (json-init o)
  `((name . ,((om:scope-name '.) o))
    (type . ,(ast-name o))))

(define ((json-table-event model) o)
  (match o
    (($ <compound> (s ...))
     `((table . ,(map (json-table-event model) s))))
    (($ <on> triggers (and ($ <guard> expression) (get! guard)))
     (let ((var (state-var model expression)))
       `((event . ,(json-triggers o))
         (rules . ,((json-table- model var expression) (guard))))))
    (($ <on> triggers (and ($ <compound> (($ <guard>) ...)) (get! compound)))
     (let* ((var 'unknown)
            (state (make <field> #:variable var #:field '<unknown>)))
       `((event . ,(json-triggers o))
         (rules . ,(apply append (map (json-table- model var state)
                                      (.elements (compound))))))))
    (($ <on> triggers statement)
     (let* ((var 'unknown)
            (state (make <field> #:variable var #:field '<unknown>)))
       `((event . ,(json-triggers o))
         (rules . ,(list
                    `((guard . ,(json-guard (make <guard> #:expression 'true)))
                      (actions . ,(json-action model statement))
                      (callbacks . ,(json-callback model statement))
                      (next . ,(json-next model var state statement))))))))
    (_ (stderr "catch all1:\n")
       `((event . ,(json-data-location '() o))
         (rules . ,(list
                    `((guard . ,(json-guard (make <guard> #:expression 'true)))
                      (actions . ,(json-action model '()))
                      (callbacks . ,(json-callback model '()))
                      (next . ()))))))))

(define (state-var model o)
  (match o
    (($ <expression> value) (state-var model value))
    (($ <field> variable) variable)
    (('or ($ <field> variable field) __1) variable)
    (($ <var> identifier) identifier)
    ((! ($ <var> identifier)) identifier)
    (('== ($ <var> identifier) (and (? number?) (get! number))) identifier)
    (_ '<state>)))

(define ((state->value model) o)
  (match o
    (($ <field> x (and (? number?) (get! number))) (number))
    (($ <field> x (and (or 'true 'false) (get! bool))) (bool))
    (($ <field> var field)
     (let* ((enum ((om:type model) var)))
       (make <literal> #:type enum #:field field)))
    (_ o )))

(define ((value->state variable) o)
  (match o
    ((? number?) (make <field> #:variable variable #:field o))
    ((? symbol?) (make <field> #:variable variable #:field o))
    (_ o)))

(define ((json-table-state model) o)
  (match o
    (($ <compound> (statements ...))
     `((table . ,(map (json-table-state model) statements))))
    (($ <guard> expression (and ($ <on> triggers statement) (get! on)))
     (let ((var (state-var model expression)))
       `((state . ,(json-state (->symbol expression) o))
         (rules . ,((json-table- model var expression) (on))))))
    (($ <guard> expression (and ($ <compound> (($ <on>) ...)) (get! compound)))
     (let ((var (state-var model expression)))
       `((state . ,(json-state (->symbol expression) o))
         (rules . ,(apply append (map (json-table- model var expression)
                                      (.elements (compound))))))))
    (_ (stderr "catch all0:\n")
       `((state . ,(json-state (->symbol o) o))
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
                     (($ <field>) expression)
                     (('== ($ <var> name) number) expression)
                     (($ <var> name) (state-var model name))
                     ((h t ...) (cadr expression))
                     (_ expression)))
            (var (state-var model state))
            (inner (.statement o)))
       (match inner
         (($ <guard> expression statement)
          (list
           `((guard . ,(json-guard o))
             (inner . ,(json-guard inner))
             (actions . ,(json-action model statement))
             (callbacks . ,(json-callback model statement))
             (next . ,(json-next model var state statement)))))
         (($ <compound> ())
          (list
           `((guard . ,(json-guard o))
             ;;(inner . ,(json-data-location '() '()))
             (actions . ,(json-action model inner))
             (callbacks . ,(json-callback model inner))
             (next . ,(json-next model var state inner))
             )))
         ((and ($ <compound> (($ <guard>) ...)) (get! compound))
          (map (lambda (inner)
                 (let ((expression (.expression inner))
                       (statement (.statement inner)))
                   `((guard . ,(json-guard o))
                     (inner . ,(json-guard inner))
                     (actions . ,(json-action model statement))
                     (callbacks . ,(json-callback model statement))
                     (next . ,(json-next model var state statement)))))
               (.elements (compound))))
         (($ <guard> expression (and ($ <compound> (($ <guard>)) (get! compound))))
          (map (lambda (inner)
                 (let ((expression (.expression inner))
                       (statement (.statement inner)))
                   `((guard . ,(json-guard o))
                     (inner . ,(json-guard inner))
                     (actions . ,(json-action model statement))
                     (callbacks . ,(json-callback model statement))
                     (next . ,(json-next model var state statement)))))
               (.elements (compound))))

         (_ (list
             `((guard . ,(json-guard o))
               (actions . ,(json-action model statement))
               (callbacks . ,(json-callback model statement))
               (next . ,(json-next model var state statement))))))))
    (($ <on> triggers (and ($ <compound> (($ <guard> expression statement) ..1)) (get! compound)))
     (map (json-inner-guard model var state triggers)
          (map .expression (.elements (compound)))
          (map .statement (.elements (compound)))))
    (($ <on> triggers ($ <guard> guard statement))
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
                  (if (source-location triggers) triggers
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
  (define (var? identifier) (eq? identifier var))
  (let ((unknown (make <field> #:variable var #:field '<unknown>)))
   (match o
     (($ <compound> (statements ...))
      (let loop ((statements statements) (next next))
        (if (null? statements)
            next
            (loop (cdr statements) (json-next- model var next (car statements) functions)))))
     (($ <assign> (? var?) ($ <expression> ($ <literal> type field)))
      (list (make <field> #:variable var #:field field)))
     (($ <assign> (? var?) ($ <expression> ('! ($ <var> (? var?)))))
      (match next
        ((('! (and ($ <var> (? var?)) (get! var)))) (list (var)))
        (_ (list (list '! (make <var> #:variable var))))))
     (($ <assign> (? var?) ($ <expression> 'false))
      (list (list '! (make <var> #:variable var))))
     (($ <assign> (? var?) ($ <expression> 'true))
      (list (make <var> #:variable var)))
     (($ <assign> (? var?) ($ <action>))
      (list unknown))
     (($ <assign> (? var?) ($ <call>))
      (list unknown))
     (($ <assign> (? var?) expression)
      (let* ((state (map (undefined-variable-state model (lambda (x) unknown)) (om:variables model)))
             (values (map (state->value model) next))
             (states (map (lambda (v) (var! state var v)) values))
             (updates (map (lambda (s) (eval-expression model s expression)) states)))
        (map (value->state var) updates)))
     (($ <call>)
      (let ((function (.function (ast:resolve o))))
        (if (member function functions)
            next
            (json-next- model var next (.statement function) (cons function functions)))))
     (($ <blocking> statement)
      (json-next- model var next statement functions))
     (($ <guard> expression statement)
      (add-state next (json-next- model var next statement functions)))
     (($ <if> expression then #f)
      (let ((then (json-next- model var next then functions)))
        (add-state next then)))
     (($ <if> expression then else)
      (let ((then (json-next- model var next then functions))
            (else (json-next- model var next else functions)))
        (add-state then else)))
     (($ <illegal>) '())
     (_  next))))

(define (add-state o state)
  (match state
    ((h ...)
     (append o state))
    (($ <field>) (add-state o (list state)))))

(define (json-data-location data location)
  `((data . ,data)
    (location . ,(json-location location))))

(define (json-event data o)
  (json-data-location data o))

(define (json-state data o)
  (json-data-location data o))

(define (json-action model o)
  (json-data-location ((ast->html model) o) o))

(define (json-callback model o)

  (define (function? ref)  (ast:resolve ref))
  (define (recursive? ref) (.recursive (function? ref)))
  (define (non-recursive? ref)
    (not (recursive? ref)))

  (define (return-action o)
    (match o
      (($ <action>) (list o))
      (($ <assign> name (and ($ <action>) (get! action))) (list (action)))
      (($ <variable> name type (and ($ <action>) (get! action))) (list (action)))
      (($ <call> (and (? non-recursive?) (get! function))) (return-actions (function)))
      (($ <function> name signature #f statement) (return-actions statement))
      (_ '())))

  (define (return-actions o)
    (filter identity
            (apply append
                   (map return-action ((om:collect return-action) o)))))

  (or (and-let* (((is-a? model <interface>))
                 ((is-a? o <statement>))
                 (actions (return-actions o)))
                (map (ast->html model) actions))
      '()))

(define* (json-triggers o #:optional (location o))
  (match o
    (($ <triggers> (triggers ...))
     (json-data-location (map ->symbol triggers) location))
    (($ <on>)
     (json-data-location (map ->symbol ((compose .elements .triggers) o)) location))))

(define (json-guard o)
  (json-data-location (->symbol (.expression o)) o))

(define (->symbol o)
  (match o
    (#f 'false)
    (#t 'true)
    (($ <otherwise>) 'otherwise)
    (($ <expression> expression) (->symbol expression))
    ((and ($ <var>) (= .variable.name identifier)) identifier)
    (($ <field> variable (and (? number?) (get! number))) (->symbol (list variable '== (number))))
    (($ <field> variable field) (->symbol (list (->symbol variable) "." field)))
    (('! ($ <expression> value)) (symbol-append '! (->symbol value)))
    ((identifier ($ <field> variable field)) (->symbol (list (->symbol identifier) " = " (->symbol variable) "." field)))
    ((identifier ($ <literal> type field)) (->symbol (list (->symbol identifier) " = " (->symbol type) "." (->symbol field))))
    (($ <literal> type field) (->symbol (list (->symbol type) "." (->symbol field))))
    (($ <scope.name> scope name) ((->symbol-join '.) (append scope (list name))))
    (($ <triggers> (triggers ...)) (->symbol ((->join ",") (map ->symbol triggers))))
    ((and ($ <trigger>) (= .event.name event)) (->symbol event))
    ((and ($ <trigger>) (= .port.name port) (= .event.name event)) (->symbol (list port "." event)))
    (('and lhs rhs) (->symbol (list '&& lhs rhs)))
    (('or lhs rhs) (->symbol (list '#{||}# lhs rhs)))
    (((or '< '<= '> '>= '+ '- '&& '#{||}# '== '!=) lhs rhs)
     (let ((op (car o)))
       (->symbol (list lhs " " op " " rhs))))
    (((h t ...)) (->symbol (car o)))
    ((h t ...) (apply symbol-append (map ->symbol o)))
    ((? (is? <ast>)) (->symbol (om->list o)))
    ((? string?) (string->symbol o))
    ((? number?) (->symbol (number->string o)))
    ((? symbol?) o)
    (() (string->symbol ""))
    (*unspecified* '<unknown>)
    (_ (throw 'match-error  (format #f "~a: ->symbol match: ~a\n"  (current-source-location) o)))))
