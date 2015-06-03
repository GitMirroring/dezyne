;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (gaiag json-table)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (gaiag list match)

  :use-module (srfi srfi-1)
  :use-module (srfi srfi-9)
  
  :use-module (gaiag misc)
  :use-module (gaiag pretty-print)  

  :use-module (gaiag ast)
  :use-module (gaiag json)
  :use-module (gaiag pretty)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)  
  :use-module (gaiag simulate)

  :export (json-init
           json-table-event           
           json-table-state))

(define (json-init o)
  `((name . ,(.name o))
    (type . ,(ast-name o))))

(define ((json-table-event model) o)
  (match o
    (('compound s ...)
     `((table . ,(map (json-table-event model) s))))
    (($ <on> triggers (and ($ <guard> expression) (get! guard)))
     (let* ((state (.value expression))
            (var (match state
                   (($ <field> identifier field) identifier)
                   (('or ($ <field> identifier field) __1) identifier)
                   (_ '<state>))))
       (alist->hash-table
        `((event . ,(json-triggers o))
          (rules . ,((json-table- model var state) (guard)))))))
    (($ <on> triggers (and ('compound ($ <guard>) ...) (get! compound)))
     (let* ((var 'unknown)
            (state (make <field> :identifier var :field '<unknown>)))
       (alist->hash-table
        `((event . ,(json-triggers o))
          (rules . ,(apply append (map (json-table- model var state)
                                       (.elements (compound)))))))))
    (($ <on> triggers statement)
     (let* ((var 'unknown)
            (state (make <field> :identifier var :field '<unknown>)))
       (alist->hash-table `((event . ,(json-triggers o))
                            (rules . ,(list
                                       (alist->hash-table
                                        `((guard . ,(json-guard (make <guard> :expression 'true)))
                                          (actions . ,(json-action statement))
                                          (callbacks . ,(json-callback model statement))
                                          (next . ,(json-next model var state statement))))))))))
    (_ (stderr "catch all1:\n")
       (alist->hash-table `((event . ,(json-data-location '() o))
                            (rules . ,(list
                                       (alist->hash-table
                                        `((guard . ,(json-guard (make <guard> :expression 'true)))
                                          (actions . ,(json-action '()))
                                          (callbacks . ,(json-callback model '()))
                                          (next . ()))))))))))

(define ((json-table-state model) o)
  (match o
    (('compound statements ...)
     `((table . ,(map (json-table-state model) statements))))
    (($ <guard> expression (and ($ <on> triggers statement) (get! on)))
     (let ((var ((compose .identifier .value) expression))
           (state (.value expression)))
       (alist->hash-table
        `((state . ,(json-state (->symbol state) o))
          (rules . ,((json-table- model var state) (on)))))))
    (($ <guard> expression (and ('compound ($ <on>) ...) (get! compound)))
     (let ((var ((compose .identifier .value) expression))
           (state (.value expression)))
       (alist->hash-table
        `((state . ,(json-state (->symbol state) o))
          (rules . ,(apply append (map (json-table- model var state)
                                       (.elements (compound)))))))))
    (_ (stderr "catch all0:\n")
       (alist->hash-table `((state . ,(json-state (->symbol o) o))
                            (rules . ,(list
                                       (alist->hash-table
                                        `((triggers . ,(json-triggers (make <triggers>)))
                                          (guard . "")
                                          (actions . ,(json-action '()))
                                          (callbacks . ,(json-callback model '()))
                                          (next . ()))))))))))

(define ((json-table- model var state) o)
  (match o
    (($ <guard>)
     (let* ((statement (.statement o))
            (expression ((compose .value .expression) o))
            (state (if (is-a? expression <field>) expression (cadr expression)))
            (var (if (is-a? <field> state) (.identifier state) '<state>))
            (inner (.statement o)))
       (match inner
         (($ <guard> expression statement)
          (list
           (alist->hash-table
            `((guard . ,(json-guard o))
              (inner . ,(json-guard inner))
              (actions . ,(json-action statement))
              (callbacks . ,(json-callback model statement))
              (next . ,(json-next model var state statement))))))
         (('compound)
          (list
           (alist->hash-table
            `((guard . ,(json-guard o))
              ;;(inner . ,(json-data-location '() '()))
              (actions . ,(json-action inner))
              (callbacks . ,(json-callback model inner))
              (next . ,(json-next model var state inner))
              ))))
         ((and ($ <compound> ($ <guard>) ...) (get! compound))
          (map (lambda (inner)
                 (let ((expression (.expression inner))
                       (statement (.statement inner)))
                   (alist->hash-table
                    `((guard . ,(json-guard o))
                      (inner . ,(json-guard inner))
                      (actions . ,(json-action statement))
                      (callbacks . ,(json-callback model statement))
                      (next . ,(json-next model var state statement))))))
               (.elements (compound))))
         (($ <guard> expression (and ($ <compound> ($ <guard>) (get! compound))))
          (map (lambda (inner)
                 (let ((expression (.expression inner))
                       (statement (.statement inner)))
                   (alist->hash-table
                    `((guard . ,(json-guard o))
                      (inner . ,(json-guard inner))
                      (actions . ,(json-action statement))
                      (callbacks . ,(json-callback model statement))
                      (next . ,(json-next model var state statement))))))
               (.elements (compound))))

         (_ (list
             (alist->hash-table
              `((guard . ,(json-guard o))
                (actions . ,(json-action statement))
                (callbacks . ,(json-callback model statement))
                (next . ,(json-next model var state statement)))))))))
    (($ <on> triggers (and ($ <compound> ($ <guard> expression statement) ..1) (get! compound)))
     (map (json-inner-guard model var state triggers)
          (map .expression (.elements (compound)))
          (map .statement (.elements (compound)))))
    (($ <on> triggers ($ <guard> guard statement))
     (list ((json-inner-guard model var state triggers) guard statement)))
    (_
     (list
      (alist->hash-table
      `((triggers . ,(json-triggers (.triggers o)))
        (guard . "")
        (actions . ,(json-action (.statement o)))
        (callbacks . ,(json-callback model (.statement o)))
        (next . ,(json-next model var state (.statement o)))))))))

(define ((json-inner-guard model var state triggers) guard statement)
  (alist->hash-table
   `((triggers . ,(json-triggers triggers))
     (guard . ,(->symbol guard))
     (actions . ,(json-action statement))
     (callbacks . ,(json-callback model statement))
     (next . ,(json-next model var state statement)))))

(define (json-next model var next o)
  (let ((next (delete-duplicates (json-next- model var (list next) o '()))))
    (if (=1 (length next))
        (->symbol (car next))
        (map ->symbol next))))

(define (json-next- model var next o functions)
  (define (var? identifier) (eq? identifier var))
  (let ((unknown (make <field> :identifier var :field '<unknown>)))
   (match o
     (('compound statements ...)
      (let loop ((statements statements) (next next))
        (if (null? statements)
            next
            (loop (cdr statements) (json-next- model var next (car statements) functions)))))
     (($ <assign> (? var?) ($ <expression> ($ <literal> scope type field)))
      (list (make <field> :identifier var :field field)))
     (($ <assign> (? var?) expression)
      (list unknown))
     (($ <call>)
      (let* ((identifier (.identifier o))
             (function (om:function model identifier)))
        (if (member identifier functions)
            next
            (json-next- model var next (.statement function) (cons identifier functions)))))
     (($ <if> expression then #f)
      (let ((then (json-next- model var next then functions)))
        (add-state next then)))
     (($ <if> expression then else)
      (let ((then (json-next- model var next then functions))
            (else (json-next- model var next else functions)))
        (add-state then else)))
     (($ <illegal>) '())
     (_ next))))

(define (add-state o state)
  (match state
    ((h ...)
     (append o state))
    (($ <field>) (add-state o (list state)))))

(define (json-data-location data location)
  (alist->hash-table
   `((data . ,data)
     (location . ,(json-location location)))))

(define (json-event data o)
  (json-data-location data o))

(define (json-state data o)
  (json-data-location data o))

(define (json-action o)
  (json-data-location (ast->dezyne o) o))

(define (json-callback model o)
  (define (function? identifier) (om:function model identifier))
  (define (recursive? identifier) (.recursive (function? identifier)))
  (define (non-recursive? identifier)
    (not (recursive? identifier)))
  
  (define (return-action o)
    (match o
      (($ <action>) (list o))
      (($ <assign> name (and ($ <action>) (get! action))) (list (action)))
      (($ <variable> name type (and ($ <action>) (get! action))) (list (action)))
      (($ <call> (and (? non-recursive?) (get! function))) (return-actions (function? (function))))
      (($ <function> name signature #f statement) (return-actions statement))
      (_ '())))

  (define (return-actions o)
    (filter identity
            (apply append
                   (map return-action ((om:collect return-action) o)))))

  (or (and-let* (((is-a? o <statement>))
                 (actions (return-actions o))
                 (actions (delete-duplicates actions)))
                (map ast->dezyne actions))
      '()))

(define (json-triggers o)
  (match o
    (('triggers triggers ...)
     (json-data-location (map ->symbol triggers) o))
    (($ <on>)
     (json-data-location (map ->symbol ((compose .elements .triggers) o)) o))))

(define (json-guard o)
  (json-data-location (->symbol (.expression o)) o))

(define (->symbol o)
  (match o
    (#f 'false)
    (#t 'true)
    (($ <otherwise>) 'otherwise)
    (($ <expression> expression) (->symbol expression))
    (($ <var> identifier) identifier)
    (($ <field> type field) (->symbol (list (->symbol type) "." field)))
    (('! ($ <expression> value)) (symbol-append '! (->symbol value)))
    ((identifier ($ <field> type field)) (->symbol (list (->symbol identifier) " = " (->symbol type) "." field)))
    ((identifier ($ <literal> scope type field)) (->symbol (list (->symbol identifier) " = " (->symbol type) "." (->symbol field))))
    (($ <literal> scope type field) (->symbol (list (->symbol type) "." (->symbol field))))
    (('triggers triggers ...) (->symbol ((->join ",") (map ->symbol triggers))))
    (($ <trigger> #f event) (->symbol event))
    (($ <trigger> port event) (->symbol (list port "." event)))
    ((? (is? <ast>)) (->symbol (om->list o)))
    (('and lhs rhs) (->symbol (list '&& lhs rhs)))
    (('or lhs rhs) (->symbol (list '#{||}# lhs rhs)))
    (((or '< '<= '> '>= '+ '- '&& '#{||}# '== '!=) lhs rhs)
     (let ((op (car o)))
       (->symbol (list lhs " " op " " rhs))))
    ((h ... t) (apply symbol-append (map ->symbol o)))
;;    ((h . t) (list (->symbol h) '= (->symbol t)))
    (((h ... t)) (->symbol (car o)))
    ((? string?) (string->symbol o))
    ((? number?) (->symbol (number->string o)))
    ((? symbol?) o)
    (() (string->symbol ""))
    (*unspecified* '<unknown>)
    (_ (throw 'match-error  (format #f "~a: ->symbol match: ~a\n"  (current-source-location) o)))))
