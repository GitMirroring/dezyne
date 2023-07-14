;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2023 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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

(define-module (dzn timing)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 format)
  #:use-module (ice-9 match)

  #:export (cute*
            display-duration
            display-runtime
            measure-duration
            seconds-between-stamps))

(define (seconds-between-stamps t1 t2)
  (/ (- t2 t1) internal-time-units-per-second))

(define-syntax measure-duration
  (syntax-rules ()
    ((_ exp)
     (let ((t1 (get-internal-run-time))
           (result ((lambda () exp)))
           (t2 (get-internal-run-time)))
       (values result t1 t2)))
    ((_ variable exp)
     (let ((t1 (get-internal-run-time))
           (result ((lambda () exp)))
           (t2 (get-internal-run-time)))
       (set! variable (+ variable (seconds-between-stamps t1 t2)))
       (values result t1 t2)))))

(define (display-runtime label s)
  (format (current-error-port) "~10,6fs: ~a\n" s label))

(define-syntax display-duration
  (syntax-rules ()
    ((_ label exp)
     (let ((result t1 t2 (measure-duration exp)))
       (display-runtime label (seconds-between-stamps t1 t2))
       result))))

(define (cute* label f)
  (lambda args (display-duration label (apply f args))))

(define-syntax *let*
  (syntax-rules ()
    ((_ ((var val) ...) exp ...)
     (let* ((var (display-duration 'var val)) ...)
       (display-duration '*let* exp ...)))))

(define-syntax *match*
  (syntax-rules ()
    ((_ obj (pat exp ...) ...)
     (match obj
       (pat (begin
              (map display (list "match " 'pat ":"))
              (newline)
              (display-duration 'pat exp ...)))
       ...))))
