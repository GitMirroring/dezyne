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
  (stderr "json-table: ~a\n" o)
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
      (($ <guard> expression ($ <on> triggers statement))
       (let ((var ((compose .identifier .value) expression)))
         (alist->hash-table
          `((state . ,(->symbol expression))
            (rules
             .
             ,(list
               (alist->hash-table
                `((triggers . ,(map ->symbol (.elements triggers)))
                  (guard . "")
                  (actions . ,(json-actions statement))
                  (next . ,(json-next var statement))))))))))
      (($ <guard> expression ($ <compound> (and (($ <on>) ...) (get! ons))))
       (let ((var ((compose .identifier .value) expression)))
         (alist->hash-table
          `((state . ,(->symbol expression))
            (rules . ,(apply append (map (json-table- var) (ons))))))))
      (_ (stderr "catch all:\n")
         (pretty-print (gom->list o) (current-error-port))
         (alist->hash-table `((state . ,(->symbol o))
                              (rules . ,(list
                                         (alist->hash-table
                                          `((triggers . ())
                                            (guard . "")
                                            (actions . ,(json-actions '()))
                                            (next . ()))))))))))

(define-method (json-table (var <symbol>) (o <on>))
  (match o
   (($ <on> triggers ($ <compound> (($ <guard> guard statement) ...)))
    (map (json-inner-guard var triggers) guard statement))
   (_
    (list
     (alist->hash-table
      `((triggers . ,(map ->symbol ((compose .elements .triggers) o)))
        (guard . "")
        (actions . ,(json-actions (.statement o)))
        (next . ,(json-next var (.statement o)))))))))

(define-method (json-table- (var <symbol>))
  (lambda (o) (json-table var o)))

(define-method (json-inner-guard (var <symbol>) (triggers <triggers>) (guard <expression>) (statement <statement>))
  (alist->hash-table
   `((triggers . ,(map ->symbol (.elements triggers)))
     (guard . ,(->symbol guard))
     (actions . ,(json-actions statement))
     (next . ,(json-next var statement)))))

(define-method (json-inner-guard (var <symbol>) (o <triggers>))
  (lambda (e s) (json-inner-guard var o e s)))

(define-method (json-next (var <symbol>) (o <statement>))
  (or
   (and-let* ((assignments ((gom:collect <assign>) o))
              (state (null-is-#f (filter (lambda (a) (eq? (.identifier a) var))
                                         assignments)))
              (o (.expression (last state))))
             (match o
               (($ <expression> ($ <literal> scope type field))
                (->symbol (list var '. field)))
               (_ '())))
      '()))

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
    ((h ... t) (apply symbol-append (map ->symbol o)))
;;    ((h . t) (list (->symbol h) '= (->symbol t)))
    (((h ... t)) (->symbol (car o)))
    ((? string?) (string->symbol o))
    ((? symbol?) o)
    (() (string->symbol ""))
    (_ (throw 'match-error  (format #f "~a: ->symbol match: ~a\n"  (current-source-location) o)))))
