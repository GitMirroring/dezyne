;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

(read-set! keywords 'prefix)

(define-module (g norm)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (ice-9 match)
  :use-module (ice-9 curried-definitions)

  :use-module (srfi srfi-1)

  :use-module (g ast-colon)
  :use-module (g misc)
  :use-module (g reader)

  :export (
           add-skip
           aggregate-guard
           expand-on
           flatten-compound
           guards-not-or
           remove-otherwise
           remove-skip
           ))

(define (remove-skip o)
  (match o
    (('skip) '(compound))
    ((h t ...) (map remove-skip o))
    (_ o)))

(define* ((expand-on :optional (compare equal?)) ast)
  (match ast
    (('compound ('on triggers statement) ...)
     (cons 'compound (apply append (map (port-split-triggers compare) (cdr ast)))))
    ((h ...) (map (expand-on compare) ast))
    (_ ast)))

(define ((port-split-triggers compare) ast)
  (match ast
    (('on ('triggers triggers ...) statement)
     (let loop ((triggers triggers))
       (if (null? triggers)
           '()
           (receive (shared-triggers remainder)
               (partition (lambda (x) (compare (car triggers) x)) triggers)
             (let* ((triggers (append shared-triggers))
                    (shared-on (list 'on (cons 'triggers triggers) statement)))
               (cons shared-on (loop remainder)))))))
    (_ ast)))

(define (aggregate-guard ast)
  "Aggregate on-statements with matching guard into one guard."
;; find all ons with matching guards
;; push all ons into first guard, discard the rest
  (match ast
    (('compound ('on triggers stat) ...) ast)
    (('compound ('guard expression statement) ...)
     (cons 'compound
               (let loop ((guards (cdr ast)))
                 (if ( null? guards)
                     '()
                     (receive (shared-guards remainder)
                         (partition (lambda (x) (ast:guard-equal? (car guards) x)) guards)
                       (let* ((expression (ast:expression (car shared-guards)))
                              (aggregated-guard (list 'guard
                                                      (list expression expression)
                                                      (wrap-compound-as-needed (map ast:statement shared-guards)))))
                         (cons aggregated-guard (loop remainder))))))))
    (('functions f ...) ast)
    ((h ...) (map aggregate-guard ast))
    (_ ast)))

(define (wrap-compound-as-needed x)
  (if (or (null? x) (>1 (length x)))
      (cons 'compound x)
      (car x)))

(define (flatten-compound ast)
  (match ast
    (('compound s ...) (cons 'compound (apply append (map flatten-compound-compound (cdr ast)))))
    (('on t s) ast)
    ((h ...) (map flatten-compound ast))
    (_ ast)))

(define (flatten-compound-compound stat)
   (let ((result (flatten-compound stat)))
     (match result
       (('compound s ...) (cdr result))
       (_ (list result)))))

(define ((remove-otherwise statements) ast)
  (define (otherwise? x) (or (null? x) (eq? x 'otherwise)))
  (match ast
    (('guard ('otherwise value ...) s) (=> failure)
     (if (or ((negate otherwise?) value) (null? statements))
         (failure)
     (list 'guard (guards-not-or statements) ((remove-otherwise '()) s))))
    (('compound s ...) (cons 'compound (map (remove-otherwise ast) (cdr ast))))
    ((h ...) (map (remove-otherwise statements) ast))
    (_ ast)))

(define (guards-not-or statements)
  (let* ((expressions (map ast:expression statements))
         (others (remove (ast:is? 'otherwise) expressions))
         (values (map ast:value others)))
    (list 'expression (list '! (reduce (lambda (g0 g1)
                                         (if (equal? g0 g1) g0 (list 'or g0 g1)) )
                                       '() values)))))

(define (add-skip ast)
  (match ast
    (('compound) (list 'skip))
    ((h ...) (map add-skip ast))
    (_ ast)))
