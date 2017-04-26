;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2015, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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


(define-module (gaiag norm)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 match)
  #:use-module (ice-9 curried-definitions)

  #:use-module (language dezyne location)

  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)

  #:use-module (gaiag om)

  #:use-module (gaiag misc)
  #:use-module (gaiag reader)
  #:use-module (gaiag resolve)

  #:export (
            <skip>
           add-skip
           annotate-otherwise
           aggregate-guard-g
           aggregate-on
           append-true-guard
           combine-guards
           expand-on
           flatten-compound
           guards-not-or
           passdown-blocking
           prepend-true-guard
           remove-otherwise
           remove-skip

           norm:on-equal?
           norm:triggers-equal?
           norm:on-statement-equal?
           ))

(define-class <skip> (<ast>))

(define* ((prepend-true-guard #:optional guard-seen?) o)
  (match o
    (($ <guard>) o)
    (($ <on>) (if guard-seen? o
                  (rsp o (make <guard> #:expression 'true #:statement o))))
    ((? (is? <ast>)) (om:map (prepend-true-guard guard-seen?) o))
    (_ o)))

(define* (append-true-guard o)
  (match o
    (($ <on> t ($ <guard>)) o)
    (($ <on> t s)
     (rsp o (make <on> #:triggers t #:statement (make <guard> #:expression 'true #:statement s))))
    ((? (is? <ast>)) (om:map append-true-guard o))
    (_ o)))

(define (remove-skip o)
  (match o
    (($ <skip>) (rsp o (make <compound>)))
    ((? (is? <ast>)) (om:map remove-skip o))
    (_ o)))

(define* ((aggregate-on #:optional (aggregate? norm:triggers-equal?) model) o)
  "Aggregate ONs with same statement AND (AGGREGATE? a b) into one ON-statement."
  (match o
    (($ <compound> (($ <on>) ..1))
     (if (=1 (length (.elements o)))
         o
         (make <compound>
           #:elements
           (let loop ((ons (.elements o)))
             (if (null? ons)
                 '()
                 (receive (shared-ons remainder)
                     (partition (lambda (x) (aggregate? model (car ons) x)) ons)
                   (let ((aggregated-on
                          (if (>1 (length shared-ons))
                              (let* ((triggers
                                      (retain-source-properties
                                       (.triggers (car ons))
                                       (make <triggers>
                                         #:elements
                                         (delete-duplicates
                                          (apply append
                                                 (map (compose .elements .triggers) shared-ons))
                                          om:equal?))))
                                     (statement (on-statement (map .statement shared-ons))))
                                (make <on>
                                  #:triggers triggers
                                  #:statement statement))
                              (car shared-ons))))
                     (cons aggregated-on (loop remainder)))))))))
    (($ <functions> (functions ...)) o)
    ((? (is? <component>)) (om:map (aggregate-on aggregate? o) o))
    ((? (is? <interface>)) (om:map (aggregate-on aggregate? o) o))
    (($ <skip>) o)
    ((? (is? <ast>)) (om:map (aggregate-on aggregate? model) o))
    (_ o)))

(define (norm:on-equal? model a b)
  (equal? a b))

(define (norm:triggers-equal? model l r)
  (om:triggers-equal? l r))

(define (norm:on-statement-equal? model a b)
  (and (is-a? a <on>) (is-a? b <on>)
       (equal? (om->list (.statement a)) (om->list (.statement b)))))

(define (on-statement statements)
  (if (every identity (map (lambda (x) (equal? (om->list x) (om->list (car statements)))) statements))
      (car statements)
      (make <compound> #:elements statements)))

(define* ((expand-on #:optional (compare norm:on-equal?) model) o)
  (match o
    (($ <compound> (($ <on>) ..1))
     (clone o #:elements (append-map (port-split-triggers compare model) (.elements o))))
    (($ <on> triggers statement)
     (let ((ons ((port-split-triggers compare model) o)))
       (if (=1 (length ons))
           o
           (make <compound> #:elements ons))))
    ((? (is? <component>)) (om:map (expand-on compare o) o))
    ((? (is? <interface>)) (om:map (expand-on compare o) o))
    (($ <skip>) o)
    ((? (is? <ast>)) (om:map (expand-on compare model) o))
    (_ o)))

(define ((port-split-triggers compare model) o)
  (match o
    (($ <on>)
     (let loop ((triggers (.elements (.triggers o))))
       (if (null? triggers)
           '()
           (receive (shared-triggers remainder)
               (partition (lambda (x) (compare model (car triggers) x)) triggers)
             (let* ((triggers (append shared-triggers))
                    (shared-on
                     (make <on>
                       #:triggers
                       (retain-source-properties
                        (.triggers o)
                        (make <triggers> #:elements triggers))
                       #:statement (.statement o))))
               (cons shared-on (loop remainder)))))))
    (_ o)))

(define (aggregate-guard-g o)
  "Aggregate on-statements with matching guard into one guard."
;; find all ons with matching guards
;; push all ons into first guard, discard the rest
  (match o
    (($ <compound> (($ <guard>) ..1))
     (if (=1 (length (.elements o)))
         o
         (make <compound>
           #:elements
           (let loop ((guards (.elements o)))
             (if ( null? guards)
                 '()
                 (receive (shared-guards remainder)
                     (partition (lambda (x) (om:guard-equal? (car guards) x)) guards)
                   (let ((aggregated-guard
                          (if (>1 (length shared-guards))
                              (make <guard>
                                #:expression (.expression (car shared-guards))
                                #:statement (wrap-compound-as-needed (map .statement shared-guards)))
                              (car shared-guards))))
                     (cons aggregated-guard (loop remainder)))))))))
    (($ <functions> (functions ...)) o)
    (($ <skip>) o)
    ((? (is? <ast>)) (om:map aggregate-guard-g o))
    (_ o)))

(define (wrap-compound-as-needed statements)
  (if (or (null? statements) (>1 (length statements)))
      (make <compound> #:elements statements)
      (car statements)))

(define (combine-guards o)
  (match o
    (($ <guard>)
     ((passdown-expression (.expression o)) (.statement o)))
    (($ <skip>) o)
    ((? (is? <ast>)) (om:map combine-guards o))
    (_ o)))

(define ((passdown-expression expression) o)
  (match o
    (($ <guard>)
     ((passdown-expression
       (if (om:equal? expression (.expression o)) expression
                 (make <and> #:left expression #:right (.expression o))))
      (.statement o)))
    ((and ($ <compound> (statements ...)) (? om:declarative?))
     (let ((statements statements))
       (retain-source-properties
        o
        (make <compound>
          #:elements (map (passdown-expression expression) statements)))))
    (_ (make <guard> #:expression expression #:statement o))))

(define (flatten-compound o)
  (match o
    ((? om:imperative?) o)
    (($ <compound> (statements ...))
     (let ((top (flatten-compound- o)))
       (retain-source-properties
        o
        (if (is-a? top <compound>)
            top
            (make <compound> #:elements (list top))))))
    (($ <skip>) o)
    ((? (is? <ast>)) (om:map flatten-compound o))
    (_ o)))

(define (flatten-compound- o)
  (match o
    ((? om:imperative?) o)
    (($ <compound> (statement))
     (flatten-compound- statement))
    (($ <compound> (statements ...))
     (retain-source-properties
      o
      (make <compound> #:elements
            (apply append (map flatten-compound-compound statements)))))
    (($ <skip>) o)
    ((? (is? <ast>)) (om:map flatten-compound- o))
    (_ o)))

(define (flatten-compound-compound o)
  (let ((result (flatten-compound- o)))
    (match result
      (($ <compound> (statements ...)) statements)
      (_ (list result)))))

(define* ((annotate-otherwise #:optional (statements '())) o) ;; FIXME *unspecified*
  (define (virgin-otherwise? x) (or (eq? x 'otherwise) (eq? x *unspecified*)))
  (match o
    (($ <guard> ($ <otherwise> value) statement) (=> failure)
     (if (or (not (virgin-otherwise? value)) (null? statements)) (failure)
         (clone o #:expression ((annotate-otherwise statements) (.expression o)))))
    (($ <otherwise>)
     (or (and-let* ((guards ((om:filter:p <guard>) statements))
                    ;;(value (.value (guards-not-or guards))) ;; FIXME
                    (value (guards-not-or guards)))
                   (make <otherwise> #:value value))
         o))
    (($ <compound> (statements ...))
     (clone o #:elements (map (annotate-otherwise statements) statements)))
    (($ <skip>) o)
    ((? (is? <ast>)) (om:map (annotate-otherwise statements) o))
    (_ o)))

(define* ((remove-otherwise #:optional (keep-annotated? #t) (statements '())) o)
  (define (virgin-otherwise? x) (or (eq? x 'otherwise) (eq? x *unspecified*))) ;; FIXME *unspecified*
  (match o
    (($ <guard> ($ <otherwise> value) statement) (=> failure)
     (if (or (and keep-annotated?
                  (not (virgin-otherwise? value)))
             (null? statements))
         (failure)
         (clone o #:expression (guards-not-or statements)
                #:statement ((remove-otherwise keep-annotated?) statement))))
    (($ <compound> (statements ...))
     (clone o #:elements (map (remove-otherwise keep-annotated? statements) statements)))
    (($ <skip>) o)
    ((? (is? <ast>)) (om:map (remove-otherwise keep-annotated? statements) o))
    (_ o)))

(define (guards-not-or o)
  (let* ((expressions (map .expression o))
         (others (remove (is? <otherwise>) expressions))
         (expression (reduce (lambda (g0 g1)
                               (if (equal? g0 g1) g0 (make <or> #:left g0 #:right g1)))
                             '() others)))
    (match expression
      (($ <not> expression) expression)
      (_ (make <not> #:expression expression)))))

(define* ((passdown-blocking #:optional (blocking? #f)) o)
  (define block? (lambda (x) blocking?))
  ;;(if blocking? (stderr "passdown-blocking[~a]: o=~a\n" blocking? o))
  (match o
    (($ <blocking> (and (? om:declarative?) ($ <compound> (statements ...))))
     (make <compound> #:elements (map (passdown-blocking #t) statements)))
    (($ <blocking> ($ <guard> expression statement))
     (make <guard> #:expression expression #:statement ((passdown-blocking #t) statement)))
    (($ <blocking> ($ <on> triggers statement))
     (make <on> #:triggers triggers #:statement ((passdown-blocking #t) statement)))
    (($ <guard> expression statement)
     (rsp o (make <guard> #:expression expression #:statement ((passdown-blocking blocking?) statement))))
    (($ <on> triggers statement)
     (rsp o (make <on> #:triggers triggers #:statement ((passdown-blocking blocking?) statement))))
    ((and ($ <compound> (statements ...)) (? om:declarative?))
     (make <compound> #:elements (map (passdown-blocking blocking?) statements)))
    ((and (? block?) (? om:imperative?))
     (if (not blocking?) o
         (make <blocking> #:statement o)))
    (($ <skip>)
     ;;(stderr "SKIP:\n")
     (if (not blocking?) o
                 (make <blocking> #:statement o)))
    ((? (is? <ast>)) (om:map (passdown-blocking blocking?) o))
    (_ o)))

(define (add-skip o)
  (match o
    (($ <compound> ()) (rsp o (make <skip>)))
    ((? (is? <ast>)) (om:map add-skip o))
    (_ o)))
