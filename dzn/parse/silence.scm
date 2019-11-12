;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (dzn parse silence)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn ast)
  #:export (mark-silent))

(define* ((mark-silent #:optional (function-silence '())) o)
  (match o
    (($ <behaviour>) (tree-map (mark-silent (function-silence-fixpoint o)) o))
    ((and ($ <compound>) (? ast:declarative?)) (tree-map (mark-silent function-silence) o))
    ((and ($ <on>) (? any-modeling?))
     (let ((silence (silence (.statement o) function-silence)))
       (if (or (eq? silence 'silent)
               (eq? silence *unspecified*)
               (is-a? silence <ast>)) (clone o #:silent? silence)
               o)))
    (($ <on>) o)
    (($ <guard>) (tree-map (mark-silent function-silence) o))
    (_ o)))

(define (function-silence-fixpoint o)
  (define (function-silence alist)
    (map (lambda (f) (cons (.name f) (silence f alist))) (ast:function* o)))
  (let ((fixpoint (let loop ((result '()))
                    (let ((new (function-silence result)))
                      (if (equal? new result) result
                          (loop new))))))
    (map (lambda (x) (if (eq? (cdr x) 'recursive) (cons (car x) 'silent) x)) fixpoint)))

(define-method (any-modeling? (o <on>))
  (find (compose (cut member <> '("inevitable" "optional")) .event.name) (ast:trigger* o)))

(define-method (silence (o <compound>) function-silence)
  (let loop ((statements (ast:statement* o)) (result 'silent))
    (if (null? statements) result
        (let ((silence (silence-sequence result (silence (car statements) function-silence))))
          (if (eq? silence 'noisy) 'noisy
              (loop (cdr statements) silence))))))

(define-method (silence (o <action>) function-silence)
  'noisy)

(define-method (silence (o <call>) function-silence)
  (or (assoc-ref function-silence (.function.name o))
      'recursive))

(define-method (silence (o <guard>) function-silence)
  (silence (.statement o) function-silence))

(define-method (silence (o <variable>) function-silence)
  (if (or (is-a? (.expression o) <action>)
          (is-a? (.expression o) <call>)) (silence (.expression o) function-silence)
          'silent))

(define-method (silence (o <function>) function-silence)
  (let ((s (assoc-ref function-silence (.name o))))
    (cond ((eq? s 'noisy) s)
          ((eq? s 'silent) s)
          ((eq? s *unspecified*) s)
          ((is-a? s <ast>) s)
          ((and (not s) (.recursive o)) 'recursive)
          (else (silence (.statement o) function-silence)))))

(define-method (silence (o <function>) function-silence)
  (let ((s (assoc-ref function-silence (.name o))))
    (if (not s) (if (.recursive o) 'recursive (silence (.statement o) function-silence))
        (if (or (eq? s 'noisy)
                (eq? s 'silent)
                (eq? s *unspecified*)
                (is-a? s <ast>))
            s
            (silence (.statement o) function-silence)))))

(define-method (silence (o <function>) function-silence)
  (let ((s (assoc-ref function-silence (.name o))))
    (if (not s) (if (.recursive o) 'recursive (silence (.statement o) function-silence))
        (if (eq? s 'recursive) (silence (.statement o) function-silence)
            s))))

(define-method (silence (o <if>) function-silence)
  (if (.else o) (silence-parallel o (silence (.then o) function-silence) (silence (.else o) function-silence))
      (silence-parallel o (silence (.then o) function-silence) 'silent)))

(define-method (silence o function-silence)
  'silent)

(define (silence-parallel o a b)
  (cond ((and (eq? a 'noisy) (eq? b 'noisy)) 'noisy)
        ((and (eq? a 'silent) (eq? b 'silent)) 'silent)
        ((and (eq? a 'recursive) (eq? b 'recursive)) 'recursive)
        ((or (and (eq? a 'recursive) (eq? b 'silent))
             (and (eq? b 'recursive) (eq? a 'silent))) 'recursive)
        ((is-a? a <ast>) a)
        ((is-a? b <ast>) b)
        ((eq? a *unspecified*) *unspecified*)
        ((eq? b *unspecified*) *unspecified*)
        (else o)))

(define (silence-sequence a b)
  (cond ((or (eq? a 'noisy) (eq? b 'noisy)) 'noisy)
        ((and (eq? a 'silent) (eq? b 'silent)) 'silent)
        ((and (or (and (eq? a 'recursive) (eq? a 'silent))
                  (and (eq? b 'recursive) (eq? a 'silent)))) 'recursive)
        ((is-a? a <ast>) a)
        ((is-a? b <ast>) b)))
