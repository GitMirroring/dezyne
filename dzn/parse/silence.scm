;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019 Rob Wieringa <rma.wieringa@gmail.com>
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
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn misc)
  #:export (mark-noisy))

(define-method (mark-noisy (o <behavior>))
  "Set <function>'s #:noisy? to true when it performs, or may perform an
<action>."
  (let ((function-silence (function-silence-fixpoint o)))
    (define (mark-noisy f)
      (let ((silence (assoc-ref function-silence (.name f))))
        (if (eq? silence 'silent) f
            (clone f #:noisy? #t))))
    (let* ((functions (ast:function* o))
           (functions (map mark-noisy functions))
           (functions (clone (.functions o) #:elements functions)))
      (clone o #:functions functions))))

(define-method (function-silence-fixpoint (o <behavior>))
  (define (function-silence alist)
    (map (lambda (f) (cons (.name f) (silence f alist))) (ast:function* o)))
  (let ((fixpoint (let loop ((result '()))
                    (let ((new (function-silence result)))
                      (if (equal? new result) result
                          (loop new))))))
    (map (match-lambda ((f . 'recursive) (cons f 'silent))
                       (x x))
         fixpoint)))

(define-method (silence (o <function>) function-silence)
  (let ((s (assoc-ref function-silence (.name o))))
    (cond ((and (not s) (.recursive? o)) 'recursive)
          ((not s) (silence (.statement o) function-silence))
          ((eq? s 'recursive) (silence (.statement o) function-silence))
          (else s))))

(define-method (silence (o <list>) function-silence)
  (fold (lambda (statement result)
          (let ((silence (silence-sequence
                          result
                          (silence statement function-silence))))
            (if (eq? silence 'noisy) 'noisy
                silence)))
        'silent
        o))

(define-method (silence (o <compound>) function-silence)
  (silence (ast:statement* o) function-silence))

(define-method (silence (o <if>) function-silence)
  (let ((else (if (not (.else o)) 'silent
                  (silence (.else o) function-silence))))
    (silence-parallel o
                      (silence (.then o) function-silence)
                      else)))

(define-method (silence (o <action>) function-silence)
  'noisy)

(define-method (silence (o <call>) function-silence)
  (or (assoc-ref function-silence (.function.name o))
      'recursive))

(define-method (silence (o <expression>) function-silence)
  (let* ((action/call? (disjoin (is? <action>)
                                (is? <call>)))
         (action/call (tree-collect action/call? o)))
    (silence action/call function-silence)))

(define-method (silence (o <assign>) function-silence)
  (if (ast:member? (.variable o)) 'noisy
      (silence (.expression o) function-silence)))

(define-method (silence (o <variable>) function-silence)
  (silence (.expression o) function-silence))

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
        (else o)))

(define (silence-sequence a b)
  (cond ((or (eq? a 'noisy) (eq? b 'noisy)) 'noisy)
        ((and (eq? a 'silent) (eq? b 'silent)) 'silent)
        ((and (or (and (eq? a 'recursive) (eq? a 'silent))
                  (and (eq? b 'recursive) (eq? a 'silent)))) 'recursive)
        ((is-a? a <ast>) a)
        ((is-a? b <ast>) b)))
