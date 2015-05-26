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

(define-module (gaiag list match)
  #:export (match
            match-lambda
            match-lambda*
            match-let
            match-let*
            match-letrec))

(define (error _ . args)
  ;; Error procedure for run-time "no matching pattern" errors.
  (apply throw 'match-error "match" args))

;; Support for record/goops style matching on plain lists.

(define-syntax slot-ref
  (syntax-rules ()
    ((_ rtd rec n)
     (if (pair? rec)
         (if (< (1+ n) (length rec)) (list-ref rec (1+ n)))
         (struct-ref rec n)))))

(define-syntax slot-set!
  (syntax-rules ()
    ((_ rtd rec n value)
     (if (pair? rec)
         (list-set! rec (1+ n) value)
         (struct-set! rec n value)))))

;; list disguised as records look like
;; (<type> field1 ...)
(define-syntax is-a?
  (syntax-rules ()
    ((_ rec rtd)
     (begin
       ;;(format (current-error-port) "IS-A? rec:~a, rtd:~a\n" rec rtd)
       (or (and (pair? rec)
                (eq? (car rec) rtd))
           (and (struct? rec)
                (eq? (struct-vtable rec) rtd)))))))

(include-from-path "ice-9/match.upstream.scm")
