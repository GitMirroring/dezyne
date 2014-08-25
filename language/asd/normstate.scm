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

(define-module (language asd normstate)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (ice-9 match)
  :use-module (ice-9 curried-definitions)

  :use-module (srfi srfi-1)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd pretty)
  :use-module (language asd reader)
  :use-module (language asd scheme)

  :export (ast-> normstate))

(define (normstate ast)
  (aggregate-on (expand-on (aggregate-guard (flatten-compound (combine-guards (passdown-on ((remove-otherwise '()) (add-skip ast)))))))))

(define ast-> normstate)

(define (aggregate-on ast)
  "Aggregate triggers with matching port and statement into one on-statement."
;; find all ons with matching port and statement
;; push all ons into first on, discard the rest
  (match ast
    (('compound ('on triggers statement) ...)
     (ast:make 'compound
               (let loop ((ons (cdr ast)))
                 (if (null? ons)
                     '()
                     (receive (shared-ons remainder)
                         (partition (lambda (x) (on-equal? (car ons) x)) ons)
                       (let* ((triggers (apply append (map ast:triggers shared-ons)))
                              (statement (ast:statement (car ons)))
                              (aggregated-on (ast:make 'on (list triggers statement))))
                         (cons aggregated-on (loop remainder))))))))
    (('functions f ...) ast)
    ((h ...) (map aggregate-on ast))
    (_ ast)))

(define (on-equal? lhs rhs)
  (and (ast:on? lhs) (ast:on? rhs)
       (and
        (port-equal? (car (ast:triggers lhs)) (car (ast:triggers rhs)))
        (equal? (ast:statement lhs) (ast:statement rhs)))))

(define (expand-on ast)
  "Aggregate triggers with matching port and statement into one on-statement."
  (match ast
    (('compound ('on triggers statement) ...)
     (ast:make 'compound (apply append (map port-split-triggers (cdr ast)))))
    ((h ...) (map expand-on ast))
    (_ ast)))

(define (port-split-triggers ast)
  (match ast
    (('on triggers statement)
     (let loop ((triggers (cadr ast)))
       (if (null? triggers)
           '()
           (receive (shared-triggers remainder)
               (partition (lambda (x) (port-equal? (car triggers) x)) triggers)
             (let* ((triggers (append shared-triggers))
                    (shared-on (ast:make 'on (list triggers statement))))
               (cons shared-on (loop remainder)))))))
    (_ ast)))

(define (port-equal? lhs rhs)
  (port-equal?- lhs rhs))

(define (port-equal?- lhs rhs)
  (or (and (symbol? lhs) (symbol? rhs))
      (and (ast:trigger? lhs) (ast:trigger? lhs)
           (eq? (ast:port-name lhs) (ast:port-name rhs)))))

(define (add-skip ast)
  (match ast
    (('compound) (list 'skip))
    ((h ...) (map add-skip ast))
    (_ ast)))

(define (wrap-compound-as-needed x)
  (if (or (null? x) (>1 (length x)))
      (ast:make 'compound x)
      (car x)))

(define (aggregate-guard ast)
  "Aggregate on-statements with matching guard into one guard."
;; find all ons with matching guards
;; push all ons into first guard, discard the rest
  (match ast
    (('compound ('on triggers stat) ...) ast)
    (('compound guards ...)
     (ast:make 'compound
               (reverse
                (let loop ((guards guards))
                  (if ( null? guards)
                      '()
                      (receive (shared-guards remainder)
                          (partition (lambda (x) (ast:guard-equal? (car guards) x)) guards)
                        (let* ((expression (ast:expression (car shared-guards)))
                               (aggregated-guard (ast:make 'guard
                                                           (list expression
                                                                 (wrap-compound-as-needed (map ast:statement shared-guards))))))
                          (cons aggregated-guard (loop remainder)))))))))
    (('functions f ...) ast)
    ((h ...) (map aggregate-guard ast))
    (_ ast)))

(define (flatten-compound ast)
  (match ast
    (('compound s ...) (ast:make 'compound (apply append (map flatten-compound-stat (cdr ast)))))
    (('on t s) ast)
    ((h ...) (map flatten-compound ast))
    (_ ast)))

(define (flatten-compound-stat stat)
   (let ((res (flatten-compound stat)))
     (match res
       (('compound s ...) (cdr res))
       (_ (list res)))))

(define (guards-not-or statements)
  (let ((guards (map cadr (cdr statements))))
    (list '! (reduce (lambda (g0 g1) (list 'or g0 g1)) '() (delete 'otherwise guards)))))

(define ((remove-otherwise statements) ast)
  (match ast
    (('guard 'otherwise s) (ast:make 'guard (list (guards-not-or statements) ((remove-otherwise '()) s))))
    (('compound s ...) (ast:make 'compound (map (remove-otherwise ast) (cdr ast))))
    ((h ...) (map (remove-otherwise statements) ast))
    (_ ast)))

(define (combine-guards ast)
  (match ast
    (('guard guard statement) ((passdown-guard guard) statement))
    ((h ...) (map combine-guards ast))
    (_ ast)))

(define ((passdown-guard guard) statement)
  (match statement
    (('compound s ...) (ast:make 'compound (map (passdown-guard guard) (cdr statement))))
    (('guard g s) ((passdown-guard (list 'and guard g)) s))
    (_ (ast:make 'guard (list guard statement)))))

(define (passdown-on ast)
  (match ast
    (('on triggers statement) ((passdown-triggers triggers) statement)) ; match on
    ((h ...) (map passdown-on ast))                                     ; match any list
    (_, ast)))                                                          ; match anything

(define ((passdown-triggers triggers) statement)
  (match statement
    (('compound ('guard g s) ...) (ast:make 'compound (map (passdown-triggers triggers) (cdr statement))))
    (('guard g s) (ast:make 'guard (list g ((passdown-triggers triggers) s))))
    (_ (ast:make 'on (list triggers statement)))))
