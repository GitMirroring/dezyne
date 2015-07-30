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

(define-module (gaiag norm)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (gaiag list match)
  :use-module (ice-9 curried-definitions)

  :use-module (language dezyne location)

  :use-module (srfi srfi-1)

  :use-module (gaiag misc)

  :use-module (gaiag ast)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :export (
           add-skip
           annotate-otherwise
           aggregate-guard-g
           aggregate-on
           combine-guards
           expand-on
           flatten-compound
           guards-not-or
           remove-otherwise
           remove-skip
           ))

(define (remove-skip o)
  (match o
    (('skip) (retain-source-properties o (make <compound>)))
    ((? (is? <ast>)) (om:map remove-skip o))
    ((h t ...) (map remove-skip o))
    (_ o)))

(define* ((aggregate-on :optional (aggregate? om:on-statement-equal?)) o)
  "Aggregate ONs with same statement AND (AGGREGATE? a b) into one ON-statement."
  (match o
    (('compound ($ <on>) ..1)
     (if (=1 (length (cdr o)))
         o
         (make <compound>
           :elements
           (let loop ((ons (cdr o)))
             (if (null? ons)
                 '()
                 (receive (shared-ons remainder)
                     (partition (lambda (x) (aggregate? (car ons) x)) ons)
                   (let ((aggregated-on
                          (if (>1 (length shared-ons))
                              (let* ((triggers
                                      (retain-source-properties
                                       (.triggers (car ons))
                                       (make <triggers>
                                         :elements
                                         (delete-duplicates
                                          (apply append
                                                 (map (compose .elements .triggers) shared-ons))
                                          om:equal?))))
                                     (statement (on-statement (map .statement shared-ons))))
                                (make <on>
                                  :triggers triggers
                                  :statement statement))
                              (car shared-ons))))
                     (cons aggregated-on (loop remainder)))))))))
     (('functions functions ...) o)
     ((? (is? <ast>)) (om:map (aggregate-on aggregate?) o))
     (('skip) o)
     ((h t ...) (map (aggregate-on aggregate?) o))
     (_ o)))

(define (om:on-statement-equal? a b)
  (and (is-a? a <on>) (is-a? b <on>)
       (equal? (om->list (.statement a)) (om->list (.statement b)))))

(define (on-statement statements)
  (if (every identity (map (lambda (x) (equal? (om->list x) (om->list (car statements)))) statements))
      (car statements)
      (make <compound> :elements statements)))


(define* ((expand-on :optional (compare equal?)) o)
  (match o
    (('compound ($ <on>) ..1)
     (make <compound>
       :elements (apply append (map (port-split-triggers compare) (cdr o)))))
    (($ <on> triggers statement)
     (let ((ons ((port-split-triggers compare) o)))
       (if (=1 (length ons))
           o
           (make <compound> :elements ons))))
    ((? (is? <ast>)) (om:map (expand-on compare) o))
    (('skip) o)
    ((h t ...) (map (expand-on compare) o))
    (_ o)))

(define ((port-split-triggers compare) o)
  (match o
    (($ <on>)
     (let loop ((triggers (.elements (.triggers o))))
       (if (null? triggers)
           '()
           (receive (shared-triggers remainder)
               (partition (lambda (x) (compare (car triggers) x)) triggers)
             (let* ((triggers (append shared-triggers))
                    (shared-on
                     (make <on>
                       :triggers
                       (retain-source-properties
                        (.triggers o)
                        (make <triggers> :elements triggers))
                       :statement (.statement o))))
               (cons shared-on (loop remainder)))))))
    (_ o)))

(define (aggregate-guard-g o)
  "Aggregate on-statements with matching guard into one guard."
;; find all ons with matching guards
;; push all ons into first guard, discard the rest
  (match o
    (('compound ($ <guard>) ..1)
     (if (=1 (length (cdr o)))
         o
         (make <compound>
           :elements
           (let loop ((guards (cdr o)))
             (if ( null? guards)
                 '()
                 (receive (shared-guards remainder)
                     (partition (lambda (x) (om:guard-equal? (car guards) x)) guards)
                   (let ((aggregated-guard
                          (if (>1 (length shared-guards))
                              (make <guard>
                                :expression (.expression (car shared-guards))
                                :statement (wrap-compound-as-needed (map .statement shared-guards)))
                              (car shared-guards))))
                     (cons aggregated-guard (loop remainder)))))))))
    (('functions functions ...) o)
    ((? (is? <ast>)) (om:map aggregate-guard-g o))
    (('skip) o)
    ((h t ...) (map aggregate-guard-g o))
    (_ o)))

(define (wrap-compound-as-needed statements)
  (if (or (null? statements) (>1 (length statements)))
      (make <compound> :elements statements)
      (car statements)))

(define (combine-guards o)
  (match o
    (($ <guard>)
     ((passdown-expression (.expression o)) (.statement o)))
    ((? (is? <ast>)) (om:map combine-guards o))
    (('skip) o)
    ((h t ...) (map combine-guards o))
    (_ o)))

(define ((passdown-expression expression) o)
  (match o
    (($ <guard>)
     ((passdown-expression
       (make <expression> :value
             (if (om:equal? (.value expression)
                            (.value (.expression o)))
                 (.value expression)
                 (list 'and
                       (.value expression)
                       (.value (.expression o))))))
      (.statement o)))
    (('compound statements ...)
     (let ((statements statements))
       (retain-source-properties
        o
        (make <compound>
          :elements (map (passdown-expression expression) statements)))))
    (_ (make <guard> :expression expression :statement o))))

(define (flatten-compound o)
  (match o
    (('compound statements ...)
     (let ((top (flatten-compound- o)))
       (retain-source-properties
        o
        (if (is-a? top <compound>)
            top
            (make <compound> :elements (list top))))))
    ((? (is? <ast>)) (om:map flatten-compound o))
    (('skip) o)
    ((h t ...) (map flatten-compound o))
    (_ o)))

(define (flatten-compound- o)
  (match o
    (('compound statement)
     (flatten-compound- statement))
    (('compound statements ...)
     (retain-source-properties
      o
      (make <compound> :elements
            (apply append (map flatten-compound-compound statements)))))
    ((? (is? <ast>)) (om:map flatten-compound- o))
    (('skip) o)
    ((h t ...) (map flatten-compound- o))
    (_ o)))

(define (flatten-compound-compound o)
  (let ((result (flatten-compound- o)))
    (match result
      (('compound statements ...) statements)
      (_ (list result)))))

(define* ((annotate-otherwise :optional (statements '())) o) ;; FIXME *unspecified*
  (define (virgin-otherwise? x) (or (eq? x 'otherwise) (eq? x *unspecified*)))
  (match o
    (($ <guard> ($ <otherwise> value) statement) (=> failure)
     (if (or (not (virgin-otherwise? value)) (null? statements))
         (failure)
         (retain-source-properties
          o
          (make <guard>
            :expression ((annotate-otherwise statements) (.expression o))
            :statement statement))))
    (($ <otherwise>)
     (or (and-let* ((guards ((om:filter <guard>) statements))
                    (value (.value (guards-not-or guards))))
                   (make <otherwise> :value value))
         o))
    (('compound statements ...)
     (retain-source-properties
      o (make <compound>
          :elements (map (annotate-otherwise statements) statements))))
    ((? (is? <ast>)) (om:map (annotate-otherwise statements) o))
    (('skip) o)
    ((h t ...) (map (annotate-otherwise statements) o))
    (_ o)))

(define* ((remove-otherwise :optional (keep-annotated? #t) (statements '())) o)
  (define (virgin-otherwise? x) (or (eq? x 'otherwise) (eq? x *unspecified*))) ;; FIXME *unspecified*
  (match o
    (($ <guard> ($ <otherwise> value) statement) (=> failure)
     ;;(stderr "otherwise[~a] virgin? ~a\n" o (virgin-otherwise? value))
     (if (or (and keep-annotated?
                  (not (virgin-otherwise? value)))
             (null? statements))
         (failure)
         (begin
           ;;(stderr "REMOVING OTHERWISE: ~a\n" o)
           ;;(stderr "STATEMENTS: ~a\n" statements)
           (retain-source-properties
            o
            (make <guard>
              :expression (guards-not-or statements)
              :statement (om:map (remove-otherwise keep-annotated?) statement))))))
    (('compound statements ...)
     (rsp o (make <compound> :elements (map (remove-otherwise keep-annotated? statements) statements))))
    ((? (is? <ast>)) (om:map (remove-otherwise keep-annotated? statements) o))
    (('skip) o)
    ((h t ...) (map (remove-otherwise keep-annotated? statements) o))
    (_ o)))

(define (guards-not-or o)
  (let* ((expressions (map .expression o))
         (others (remove (is? <otherwise>) expressions))
         (values (map .value others))
         (expression (reduce (lambda (g0 g1)
                               (if (equal? g0 g1) g0 (list 'or g0 g1)))
                             '() values)))
    (match expression
      (('! expression)
       (make <expression> :value expression))
      (_ (make <expression> :value (list '! expression))))))

(define (add-skip o)
  (match o
    (('compound) (retain-source-properties o (list 'skip)))
    ((? (is? <ast>)) (om:map add-skip o))
    ((h t ...) (map add-skip o))
    (_ o)))
