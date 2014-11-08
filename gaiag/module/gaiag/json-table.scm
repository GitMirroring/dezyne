;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
  :use-module (ice-9 match)

  :use-module (srfi srfi-1)

  :use-module (oop goops)

  :use-module (gaiag gom)
  :use-module (gaiag json)
  :use-module (gaiag misc)
  :use-module (gaiag pretty)
  :use-module (gaiag pretty-print)
  :use-module (gaiag reader)
  :use-module (gaiag simulate)

  :export (json-init
           json-table))

(define-method (json-init (model <model>))
  `((name . ,(.name model))
    (type . ,(ast-name model))))

(define-method (json-table (o <root>))
  (map json-table (.elements o)))

(define-method (json-table (o <compound>))
  `((table . ,(map json-table (.elements o)))))

(define (event statement)
  (if (is-a? statement <on>)
      (.event (.trigger statement))
      (or (and-let* (((is-a? statement <action>))
                     (trigger (.trigger statement))
                     ((.port trigger)))
                    (.port trigger))
          'out)))

(define-method (json-table (o <guard>))
    (match o
      (($ <guard> expression (and ($ <on> triggers statement) (get! on)))
       (let ((var ((compose .identifier .value) expression))
             (state (.value expression)))
         (alist->hash-table
          `((state . ,(->symbol state))
            (rules . ,(json-table var state (on)))))))
      (($ <guard> expression ($ <compound> (and (($ <on>) ...) (get! ons))))
       (let ((var ((compose .identifier .value) expression))
             (state (.value expression)))
         (alist->hash-table
          `((state . ,(->symbol state))
            (rules . ,(apply append (map (json-table- var state) (ons))))))))
      (_ (stderr "catch all:\n")
         (pretty-print (gom->list o) (current-error-port))
         (alist->hash-table `((state . ,(->symbol o))
                              (rules . ,(list
                                         (alist->hash-table
                                          `((triggers . ())
                                            (guard . "")
                                            (actions . ,(json-actions '()))
                                            (next . ()))))))))))

(define-method (json-table (var <symbol>) (state <field>) (o <on>))
  (match o
   (($ <on> triggers ($ <compound> (($ <guard> guard statement) ..1)))
    (map (json-inner-guard var state triggers) guard statement))
   (($ <on> triggers ($ <guard> guard statement))
    (list (json-inner-guard var state triggers guard statement)))
   (_
    (list
     (alist->hash-table
      `((triggers . ,(map ->symbol ((compose .elements .triggers) o)))
        (guard . "")
        (actions . ,(json-actions (.statement o)))
        (next . ,(json-next var state (.statement o)))))))))

(define-method (json-table- (var <symbol>) (state <field>))
  (lambda (o) (json-table var state o)))

(define-method (json-inner-guard (var <symbol>) (state <field>) (triggers <triggers>) (guard <expression>) (statement <statement>))
  (alist->hash-table
   `((triggers . ,(map ->symbol (.elements triggers)))
     (guard . ,(->symbol guard))
     (actions . ,(json-actions statement))
     (next . ,(json-next var state statement)))))

(define-method (json-inner-guard (var <symbol>) (state <field>) (o <triggers>))
  (lambda (e s) (json-inner-guard var state o e s)))

(define-method (json-next (var <symbol>) (next <field>) (o <statement>))
  (let ((next (delete-duplicates (json-next- var (list next) o))))
    (if (=1 (length next))
        (->symbol (car next))
        (map ->symbol next))))

(define-method (json-next- (var <symbol>) (next <list>) (o <statement>))
  (define (var? identifier) (eq? identifier var))
  (let ((unknown (make <field> :identifier var :field '<unknown>)))
   (match o
     (($ <compound> statements)
      (let loop ((statements statements) (next next))
        (if (null? statements)
            next
            (loop (cdr statements) (json-next- var next (car statements))))))
     (($ <assign> (? var?) ($ <expression> ($ <literal> scope type field)))
      (list (make <field> :identifier type :field field)))
     (($ <assign> (? var?) expression)
      (list unknown))
     (($ <call>)
      (list unknown))
     (($ <if> expression then #f)
      (let ((then (json-next- var next then)))
        (add-state next then)))
     (($ <if> expression then else)
      (let ((then (json-next- var next then))
            (else (json-next- var next else)))
        (add-state (add-state next then) else)))
     (_ next))))

(define-method (add-state (o <list>) (state <list>))
  (append o state))

(define-method (add-state (o <list>) (state <field>))
  (add-state o (list state)))

(define-method (json-actions o)
  (alist->hash-table
   `((data . ,(ast->asd o))
     (location . ,(json-location o)))))

(define (->symbol o)
  (match o
    (#f 'false)
    (#t 'true)
    (($ <expression> expression) (->symbol expression))
    (($ <otherwise>) 'otherwise)
    (($ <var> identifier) identifier)
    (($ <field> type field) (->symbol (list (->symbol type) "." field)))
    ((identifier ($ <field> type field)) (->symbol (list (->symbol identifier) " = " (->symbol type) "." field)))
    ((identifier ($ <literal> scope type field)) (->symbol (list (->symbol identifier) " = " (->symbol type) "." (->symbol field))))
    (($ <literal> scope type field) (->symbol (list (->symbol type) "." (->symbol field))))
    (($ <triggers> triggers) (->symbol ((->join ",") (map ->symbol triggers))))
    (($ <trigger> #f event) (->symbol event))
    (($ <trigger> port event) (->symbol (list port "." event)))
    ((? (is? <ast>)) (->symbol (gom->list o)))
    (('and lhs rhs) (->symbol (list lhs " " '&& " " rhs)))
    (('or lhs rhs) (->symbol (list lhs " " 'or " " rhs)))
    ((h ... t) (apply symbol-append (map ->symbol o)))
;;    ((h . t) (list (->symbol h) '= (->symbol t)))
    (((h ... t)) (->symbol (car o)))
    ((? string?) (string->symbol o))
    ((? symbol?) o)
    (() (string->symbol ""))
    (_ (throw 'match-error  (format #f "~a: ->symbol match: ~a\n"  (current-source-location) o)))))
