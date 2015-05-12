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

(define-module (g json-table)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)

  :use-module (srfi srfi-1)

  :use-module (g json)
  :use-module (g ast-colon)
  :use-module (g misc)
  :use-module (g pretty)
  :use-module (g pretty-print)
  :use-module (g reader)
  :use-module (g simulate)

  :export (json-init
           json-table-event
           json-table-state))

(define (json-init o)
  `((name . ,(ast:name o))
    (type . ,(ast:type o))))

(define ((json-table-event model) o)
  (match o
    (('compound statements ...)
     `((table . ,(map (json-table-event model) statements))))
    (('on triggers (and ('guard expression s) (get! guard)))
     (let ((var ((compose ast:identifier ast:value) expression))
           (state (ast:value expression)))
       (alist->hash-table
        `((event . ,(json-triggers o))
          (rules . ,((json-table- model var state) (guard)))))))
    (;;('on triggers ('compound (and (('guard e s) ...) (get! guards))))
     ('on triggers (and ('compound ('guard _ ...) ..1) (get! compound)))
     (let* ((var 'unknown)
            (state (list 'field var '<unknown>)))
       (alist->hash-table
        `((event . ,(json-triggers o))
          (rules . ,(apply append (map (json-table- model var state) (cdr (compound)))))))))
    (('on triggers statement)
     (let ((var 'unknown)
           (state (list 'field var '<unknown>)))
       (alist->hash-table `((event . ,(json-triggers o))
                            (rules . ,(list
                                       (alist->hash-table
                                        `((guard . ,(json-guard (list 'guard '(expression true) '(compound))))
                                          (actions . ,(json-action statement))
                                          (callbacks . ,(json-callback model statement))
                                          (next . ,(json-next model var state statement))))))))))
    (_ 
     (alist->hash-table `((event . ,(json-data-location '() o))
                          (rules . ,(list
                                     (alist->hash-table
                                      `((guard . ,(json-guard (list 'guard '(expression true) '(compound))))
                                        (actions . ,(json-action '()))
                                        (callbacks . ,(json-callback model '()))
                                        (next . ()))))))))))

(define ((json-table-state model) o)
  (match o
    (('compound statements ...)
     `((table . ,(map (json-table-state model) statements))))
    (('guard expression (and ('on triggers statement) (get! on)))
     (let ((var ((compose ast:identifier ast:value) expression))
           (state (ast:value expression)))
       (alist->hash-table
        `((state . ,(json-state (->symbol state) o))
          (rules . ,((json-table- model var state) (on)))))))
    (;;('guard expression ('compound (and (('on t s) ...) (get! ons))))
     ('guard expression (and ('compound ('on _ ...) ..1) (get! compound)))
     (let ((var ((compose ast:identifier ast:value) expression))
           (state (ast:value expression)))
       (alist->hash-table
        `((state . ,(json-state (->symbol state) o))
          (rules . ,(apply append (map (json-table- model var state) (cdr (compound)))))))))

    (_ ;;(stderr "catch all <state>:\n")
       ;;(alist->hash-table `())
       (alist->hash-table `((state . ,(json-state (->symbol o) o))
                            (rules . ,(list
                                       (alist->hash-table
                                        `((triggers . ,(json-triggers (list 'triggers)))
                                          (guard . "")
                                          (actions . ,(json-action '()))
                                          (callbacks . ,(json-callback model '()))
                                          (next . ()))))))))))

(define ((json-table- model var state) o)
  (match o
    (('guard expression statement)
     (let* (;;(statement (ast:statement o))
            ;;(expression ((compose ast:value ast:expression) o))
            (value (ast:value expression))
            (state (if (ast:is-a? value 'field) value (cadr value)))
            (var (ast:identifier state))
            (inner (ast:statement o)))
       (match inner
         (('guard expression statement)
          (list
           (alist->hash-table
            `((guard . ,(json-guard o))
              (inner . ,(json-guard inner))
              (actions . ,(json-action statement))
              (callbacks . ,(json-callback model statement))
              (next . ,(json-next model var state statement))))))
         (;;('guard expression ('compound (and (('guard) ...) (get! guards))))
          ('guard expression (and ('compound ('guard _ ...) ..1) (get! compound)))
          (map (lambda (inner)
                 (let ((expression (ast:expression inner))
                       (statement (ast:statement inner)))
                   (alist->hash-table
                    `((guard . ,(json-guard o))
                      (inner . ,(json-guard inner))
                      (actions . ,(json-action statement))
                      (callbacks . ,(json-callback model statement))
                      (next . ,(json-next model var state statement))))))
               (cdr (compound))))
         (_ (list
             (alist->hash-table
              `((guard . ,(json-guard o))
                (actions . ,(json-action statement))
                (callbacks . ,(json-callback model statement))
                (next . ,(json-next model var state statement)))))))))
    (;;('on triggers ('compound (('guard guard statement) ..1)))
     ('on triggers (and ('compound ('guard _ _) ..1) (get! compound)))
     (map (json-inner-guard model var state triggers) (map ast:expression (cdr (compound))) (map ast:statement (cdr (compound)))))
    (('on triggers ('guard guard statement))
     (list ((json-inner-guard model var state triggers) guard statement)))
    (_ ;; FIXME <on>
     ;;(stderr "CATCH ALL: ~a\n" o)
     (list
      (alist->hash-table
       `((triggers . ,(json-triggers (ast:trigger-list o)))
         (guard . "")
         (actions . ,(json-action (ast:statement o)))
         (callbacks . ,(json-callback model (ast:statement o)))
         (next . ,(json-next model var state (ast:statement o)))))))))

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
  (let ((unknown (list 'field var '<unknown>)))
   (match o
     (('compound statements ...)
      (let loop ((statements statements) (next next))
        (if (null? statements)
            next
            (loop (cdr statements) (json-next- model var next (car statements) functions)))))
     (('assign (? var?) ('expression ('literal scope type field)))
      (list (list 'field var field)))
     (('assign (? var?) expression)
      (list unknown))
     (('call identifier)
      (let ((function (ast:function model identifier)))
        (if (member identifier functions)
            next
            (json-next- model var next (ast:statement function) (cons identifier functions)))))
     (('if expression then #f)
      (let ((then (json-next- model var next then functions)))
        (add-state next then)))
     (('if expression then else)
      (let ((then (json-next- model var next then functions))
            (else (json-next- model var next else functions)))
        (add-state then else)))
     (('illegal) '())
     (_ next))))

(define (add-state o state)
  (match state
    ((? list?) (append o state))
    ((? ast:field?) (add-state o (list state)))))

(define (json-data-location data location)
  (alist->hash-table
   `((data . ,data)
     (location . ,(json-location location)))))

(define (json-event data o)
  (json-data-location data o))

(define (json-state data o)
  (json-data-location data o))

(define (json-action o)
  (json-data-location (ast->dzn o) o))

(define (json-callback model o)
  (define (function? identifier) (ast:function model identifier))
  (define (recursive? identifier) (ast:recursive (function? identifier)))
  (define (non-recursive? identifier)
    (not (recursive? identifier)))

  (define (return-action o)
    (match o
      (('action trigger) (list o))
      (('assign name (and ('action) (get! action))) (list (action)))
      (('variable name type (and ('action) (get! action))) (list (action)))
      (('call (and (? non-recursive?) (get! function))) (return-actions (function? (function))))
      (('function name signature #f statement) (return-actions statement))
      (_ (list #f))))

  (define (return-actions o)
    (filter identity
            (apply append
                   (map return-action ((ast:collect return-action) o)))))

  (or (and-let* (((ast:is-a? model 'interface))
                 ((ast:statement? o))
                 (actions (return-actions o))
                 (actions (delete-duplicates actions)))
                (map ast->dzn actions))
      '()))

(define (json-triggers o)
  (match o
    (('triggers triggers ...) (json-data-location (map ->symbol triggers) o))
    (('on ('triggers triggers ...) statement) (json-data-location (map ->symbol triggers) o))))

(define (json-guard o)
  (json-data-location (->symbol (ast:expression o)) o))

(define (->symbol o)
  (match o
    (#f 'false)
    (#t 'true)
    (('otherwise) 'otherwise)
    (('otherwise value) 'otherwise)    
    (('expression expression) (->symbol expression))
    (('var identifier) identifier)
    (('field type field) (->symbol (list (->symbol type) "." field)))
    (('! expression) (symbol-append '! (->symbol expression)))
    ((identifier ('field type field)) (->symbol (list (->symbol identifier) " = " (->symbol type) "." field)))
    ((identifier ('literal scope type field)) (->symbol (list (->symbol identifier) " = " (->symbol type) "." (->symbol field))))
    (('literal scope type field) (->symbol (list (->symbol type) "." (->symbol field))))
    (('triggers triggers) (->symbol ((->join ",") (map ->symbol triggers))))
    (('trigger #f event _ ...) (->symbol event))
    (('trigger port event _ ...) (->symbol (list port "." event)))
    ;;    ((? (is? <ast>)) (->symbol (gom->list o)))
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
