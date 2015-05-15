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

(define-module
   (g norm)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (ice-9 match)
  :use-module (ice-9 curried-definitions)

  :use-module (language dezyne location)

  :use-module (srfi srfi-1)

  :use-module (gaiag misc)


   :use-module (g ast goops)
   :use-module (g ast gom)
   :use-module (g reader)
   :use-module (g resolve)

  :export (
           add-skip
           aggregate-guard-g
           expand-on
           flatten-compound
           guards-not-or
           remove-otherwise
           remove-skip
           ))

(define (remove-skip o)
  (match o
    (('skip) (make <compound>))
    ((? (is? <ast>)) (gom:map remove-skip o))
    ((h t ...) (map remove-skip o))
    (_ o)))

(define* ((expand-on :optional (compare equal?)) o)
  (match o
    (
     ('compound ('on _ ___) ...)
     (make <compound>
       :elements (apply append (map (port-split-triggers compare) (.elements o)))))
    (('on triggers statement)
     (let ((ons ((port-split-triggers compare) o)))
       (if (=1 (length ons))
           o
           (make <compound> :elements ons))))
    ((? (is? <ast>)) (gom:map (expand-on compare) o))
    ((h t ...) (map (expand-on compare) o))
    (_ o)))

(define ((port-split-triggers compare) o)
  (match o
    (('on _ ___)
     (let loop ((triggers (.elements (.triggers o))))
       (if (null? triggers)
           '()
           (receive (shared-triggers remainder)
               (partition (lambda (x) (compare (car triggers) x)) triggers)
             (let* ((triggers (append shared-triggers))
                    (shared-on (make <on>
                                 :triggers (make <triggers> :elements triggers)
                                 :statement (.statement o))))
               (cons shared-on (loop remainder)))))))
    (_ o)))

(define (aggregate-guard-g o)
  "Aggregate on-statements with matching guard into one guard."
;; find all ons with matching guards
;; push all ons into first guard, discard the rest
  (match o
    (
       ('compound ('guard _ ___) ...)
     (make <compound>
       :elements
       (let loop ((guards (.elements o)))
         (if ( null? guards)
             '()
             (receive (shared-guards remainder)
                 (partition (lambda (x) (gom:guard-equal? (car guards) x)) guards)
               (let* ((expression (.expression (car shared-guards)))
                      (aggregated-guard
                       (make <guard>
                         :expression (.expression (car guards))
                         :statement (wrap-compound-as-needed (map .statement shared-guards)))))
                 (cons aggregated-guard (loop remainder))))))))
     (('functions _ ___) o)
     ((? (is? <ast>)) (gom:map aggregate-guard-g o))
     ((h t ...) (map aggregate-guard-g o))
     (_ o)))

(define (wrap-compound-as-needed statements)
  (if (or (null? statements) (>1 (length statements)))
      (make <compound> :elements statements)
      (car statements)))

(define (flatten-compound o)
  (match o
    (('compound _ ___)
     (retain-source-properties
      o 
      (make <compound> :elements 
            (apply append (map flatten-compound-compound (.elements o))))))
    (('on _ ___) o)
    ((? (is? <ast>)) (gom:map flatten-compound o))
    ((h t ...) (map flatten-compound o))
    (_ o)))

(define (flatten-compound-compound o)
  (let ((result (flatten-compound o)))
    (match result
      (('compound statements ___) statements)
      (_ (list result)))))

(define ((remove-otherwise statements) o)
  (define (otherwise? x) (eq? x 'otherwise))
  (match o
    (('guard ('otherwise value ___)) (=> failure)
     (if (or ((negate otherwise?) value) (null? statements))
         (failure)
         (make <guard>
           :expression (guards-not-or statements)
           :statement (gom:map (remove-otherwise '()) (.statement o)))))
    (('compound statements ___)
     (make <compound>
       :elements (map (remove-otherwise statements) statements)))
    ((? (is? <ast>)) (gom:map (remove-otherwise statements) o))
    ((h t ...) (map (remove-otherwise statements) o))
    (_ o)))

(define (guards-not-or o)
  (let* ((expressions (map .expression o))
         (others (remove (is? <otherwise>) expressions))
         (values (map .value others)))
    (make <expression>
      :value (list '! (reduce (lambda (g0 g1)
                                (if (equal? g0 g1) g0 (list 'or g0 g1)))
                              '() values)))))

(define (add-skip o)
  (match o
    (('compound) (list 'skip)) ;; FIXME: not an <AST>
    ((? (is? <ast>)) (gom:map add-skip o))
    ((h t ...) (map add-skip o))
    (_ o)))
