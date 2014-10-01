;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(read-set! keywords 'prefix)

(define-module (gaiag normstate)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (ice-9 match)
  :use-module (ice-9 curried-definitions)

  :use-module (srfi srfi-1)

  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
  :use-module (gaiag scheme)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (ast-> normstate))

(define-method (normstate (o <list>))
  ((compose normstate ast:resolve ast->gom) o))

(define-method (normstate (o <ast>))
  ((compose
    remove-skip
    aggregate-on
    expand-on
    aggregate-guard
    flatten-compound
    combine-guards
    passdown-on
    (remove-otherwise '())
    add-skip)
   o))

(define (normstate:gom ast)
  (ast:resolve ast))

(define (remove-skip o)
  (match o
    (('skip) (make <compound>))
    ((? (is? <ast>)) (gom:map remove-skip o))
    ((h t ...) (map remove-skip o))
    (_ o)))

(define (aggregate-on o)
  "Aggregate triggers with matching port and statement into one on-statement."
  ;; find all ons with matching port and statement
  ;; push all ons into first on, discard the rest
  (match o
    (($ <compound> (($ <on>) ...))
     (make <compound>
       :elements
       (let loop ((ons (.elements o)))
         (if (null? ons)
             '()
             (receive (shared-ons remainder)
                 (partition (lambda (x) (on-equal? (car ons) x)) ons)
               (let* ((triggers
                       (apply append
                              (map (compose .elements .triggers) shared-ons)))
                      (statement (.statement (car ons)))
                      (aggregated-on (make <on>
                                       :triggers (make <triggers> :elements triggers)
                                       :statement statement)))
                 (cons aggregated-on (loop remainder))))))))
     (($ <functions>) o)
     ((? (is? <ast>)) (gom:map aggregate-on o))
     ((h t ...) (map aggregate-on o))
     (_ o)))

(define-method (on-equal? (lhs <on>) (rhs <on>))
  "On-statements LHS and RHS share the same statement and port."
  (on-equal?- lhs rhs))

(define-method (on-equal?- (lhs <on>) (rhs <on>))
  (and (eq? ((compose .port car .elements .triggers) lhs)
            ((compose .port car .elements .triggers) rhs))
       (statement-equal? (.statement lhs) (.statement rhs))))

(define-method (statement-equal? (lhs <statement>) (rhs <statement>))
  (equal? (gom->list lhs) (gom->list rhs)))

(define-method (statement-equal? (lhs <top>) (rhs <top>))
  (equal? lhs rhs))

(define (expand-on o)
  (match o
    (($ <compound> (($ <on>) ...))
     (make <compound>
       :elements (apply append (map port-split-triggers (.elements o)))))
    (($ <on> triggers statement)
     (let ((ons (port-split-triggers o)))
       (if (=1 (length ons))
           o
           (make <compound> :elements ons))))
    ((? (is? <ast>)) (gom:map expand-on o))
    ((h t ...) (map expand-on o))
    (_ o)))

(define-method (port-split-triggers (o <top>)) o)

(define-method (port-split-triggers (o <on>))
  (let loop ((triggers (.elements (.triggers o))))
    (if (null? triggers)
        '()
        (receive (shared-triggers remainder)
            (partition (lambda (x) (port-equal? (car triggers) x)) triggers)
          (let* ((triggers (append shared-triggers))
                 (shared-on (make <on>
                              :triggers (make <triggers> :elements triggers)
                              :statement (.statement o))))
            (cons shared-on (loop remainder)))))))

(define-method (port-equal? (lhs <trigger>) (rhs <trigger>))
  (eq? (.port lhs) (.port rhs)))

(define (aggregate-guard o)
  "Aggregate on-statements with matching guard into one guard."
;; find all ons with matching guards
;; push all ons into first guard, discard the rest
  (match o
    (($ <compound> (($ <guard>) ...))
     (make <compound>
       :elements
       (let loop ((guards (.elements o)))
         (if ( null? guards)
             '()
             (receive (shared-guards remainder)
                 (partition (lambda (x) (guard-equal? (car guards) x)) guards)
               (let* ((expression (.expression (car shared-guards)))
                      (aggregated-guard
                       (make <guard>
                         :expression (.expression (car guards))
                         :statement (wrap-compound-as-needed (map .statement shared-guards)))))
                 (cons aggregated-guard (loop remainder))))))))
     (($ <functions>) o)
     ((? (is? <ast>)) (gom:map aggregate-guard o))
     ((h t ...) (map aggregate-guard o))
     (_ o)))

(define-method (guard-equal? (lhs <guard>) (rhs <guard>))
  (equal? (gom->list (.expression lhs)) (gom->list (.expression rhs))))

(define (wrap-compound-as-needed statements)
  (if (or (null? statements) (>1 (length statements)))
      (make <compound> :elements statements)
      (car statements)))

(define (flatten-compound o)
  (match o
    (($ <compound>)
     (make <compound>
       :elements (apply append (map flatten-compound-compound (.elements o)))))
    (($ <on>) o)
    ((? (is? <ast>)) (gom:map flatten-compound o))
    ((h t ...) (map flatten-compound o))
    (_ o)))

(define (flatten-compound-compound o)
  (let ((result (flatten-compound o)))
    (match result
      (($ <compound> statements) statements)
      (_ (list result)))))

(define (combine-guards o)
  (match o
    (($ <guard>)
     ((passdown-guard (.expression o)) (.statement o)))
    ((? (is? <ast>)) (gom:map combine-guards o))
    ((h t ...) (map combine-guards o))
    (_ o)))

(define-method (passdown-guard (expression <expression>))
  (lambda (o) (passdown-guard o expression)))

(define-method (passdown-guard (o <top>) (expression <expression>))
  (make <guard> :expression expression :statement o))

(define-method (passdown-guard (o <guard>) (expression <expression>))
  (make <guard>
    :expression (make <expression> :value (list 'and
                                                (.value expression)
                                                (.value (.expression o))))
    :statement (.statement o)))

(define-method (passdown-guard (o <compound>) (expression <expression>))
  (make <compound> :elements (map (passdown-guard expression) (.elements o))))

(define (passdown-on o)
  (match o
    (($ <on>)
     ((passdown-triggers (.triggers o)) (.statement o)))
    ((? (is? <ast>)) (gom:map passdown-on o))
    ((h t ...) (map passdown-on o))
    (_ o)))

(define-method (passdown-triggers (triggers <triggers>))
  (lambda (o) (passdown-triggers o triggers)))

(define-method (passdown-triggers (o <top>) (triggers <triggers>))
  (make <on> :triggers triggers :statement o))

(define-method (passdown-triggers (o <guard>) (triggers <triggers>))
  (make <guard>
    :expression (.expression o)
    :statement ((passdown-triggers triggers) (.statement o))))

(define-method (passdown-triggers (o <compound>) (triggers <triggers>))
  (let ((statements (.elements o)))
    (match statements
      ((($ <guard>) ...)
       (make <compound>
         :elements (map (passdown-triggers triggers) statements)))
      (_ (make <on> :triggers triggers :statement o)))))

(define ((remove-otherwise statements) o)
  (match o
    (($ <guard> ($ <otherwise>)) (=> failure)
     (if (null? statements)
         (failure)
         (make <guard>
           :expression (guards-not-or statements)
           :statement (gom:map (remove-otherwise '()) (.statement o)))))
    (($ <compound> statements)
     (make <compound>
       :elements (map (remove-otherwise statements) statements)))
    ((? (is? <ast>)) (gom:map (remove-otherwise statements) o))
    ((h t ...) (map (remove-otherwise statements) o))
    (_ o)))

(define-method (guards-not-or (o <list>))
  (let* ((expressions (map .expression o))
         (others (remove (is? <otherwise>) expressions))
         (values (map .value others)))
    (make <expression>
      :value (list '! (reduce (lambda (g0 g1) (list 'or g0 g1)) '() values)))))

(define (add-skip o)
  (match o
    (($ <compound> '()) (list 'skip)) ;; FIXME: not an <AST>
    ((? (is? <ast>)) (gom:map add-skip o))
    ((h t ...) (map add-skip o))
    (_ o)))

(define (ast-> ast)
  ((compose gom->list normstate ast:resolve) ast))
