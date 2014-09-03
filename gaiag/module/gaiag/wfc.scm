;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag wfc)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

  :use-module (gaiag ast:)
  :use-module (gaiag misc)
  :use-module (language asd parse)
  :use-module (gaiag reader)

  :export (
           ast-wellformed?
           read-asd-wellformed
           verify-on
           verify-mixing
           ))

(define (ast-> ast)
  (ast-wellformed? ast))

(define (ast-wellformed? ast)
  (and-let* ((errors (apply append
                            (filter null-is-#f (verify-on ast))
                            (filter null-is-#f (verify-mixing ast)))))
            (for-each (lambda (e)
                        (let ((message (car e))
                              (foo (stderr "e: ~a\n" e))
                              (properties (source-location->source-properties
                                           (source-location (cadr e)))))
                          (stderr "~a:~a:~a: error: not well-formed: ~a\n"
                                  (assoc-ref properties 'filename)
                                  (assoc-ref properties 'line)
                                  (assoc-ref properties 'column)
                                  message))) errors)
            ;; (throw 'well-formed "not well-formed")
            (exit 1))
  ast)


(define (read-asd-wellformed file-name)
  (ast-wellformed? (read-asd file-name)))

(define (error message ast) (list message ast))

(define (verify-on ast)
  (and-let* ((statements ((compose ast:body ast:statement ast:interface) ast))
             (error-locations (null-is-#f (filter identity (map statement-on statements)))))
            error-locations))

(define* (statement-on src :key (count 0))
  (match src
    (('on e s) (if (>0 count) (error "double on" src) (statement-on s :count (1+ count))))
    (('guard expr s) (statement-on s :count count))
    (('compound s ...) (null-is-#f
                        (filter identity (map (lambda (x) (statement-on x :count count)) s))))
    (('action b ...) '())
    (('illegal) '())
    (('assign x ...) '())
    (_ (throw 'match-error  (format #f "~a:statement-on: no match: ~a\n" (current-source-location) src)))))

(define (verify-mixing ast)
  (let ((statement ((compose ast:statement ast:interface) ast)))
        (list (mixing statement))))

(define* (mixing s :key (guarded 0) (illegal 0) (imperative 0))
  (stderr "MIXING ~a\n" s)
  (match s
    (('compound) (stderr "MIXING 1\n") '())
    (('compound s1 s2 s3 ...)
     (stderr "TODO: recursive mixing on all s: ~a -->  ~a\n" s (cdr s))
     (let ((first (first-statement (cdr s))))
       (match first
         (('guard e s1) (if (>0 (+ illegal imperative))
                            (list (error "mixing guarded" first))
                            (mixing s :guarded (1+ guarded)
                                    :illegal (1+ illegal)
                                    :imperative (1+ imperative))))
         (('on e s1) (mixing-on s))
         (_ (and (mixing-imperative s) (mixing-illegal s))))))
    (('compound s1)
     (let* ((m1 (mixing s1))
            (m2 (match s1
               (('if e s11 ...) (mixing-imperative s1))
            (_ '()))))
            (and m1 m2)))
    (('on e s) (mixing s))
    (('guard e s) (mixing s))
    (('if e s1 s2) (and (mixing s1) (mixing s2)))
    (_ '())))

(define (first-statement lst)

  (let* ((compound? (lambda (x) (eq? x 'compound)))
         (compounds (filter compound? lst))
         (non-compounds (filter (negate compound?) lst)))
    (if (null? non-compounds)
       (car compounds)
       (car non-compounds))))

(define (mixing-guarded lst) '())
(define (mixing-imperative lst) '())
(define (mixing-illegal lst) '())
(define (mixing-on lst) '())
