;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (dzn display)
  #:use-module (ice-9 pretty-print)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:export (display-slots om->list))

;; AST printing
(define (ast port) (display #\* port))
(define (ref port) (display #\@ port))

(define-method (sdisplay (o <ast-node>) port)
  (display #\space port)
  (write o port))

(define-method (sdisplay (o <top>) port)
  (display #\space port)
  (write o port))

(define-method (sdisplay (o <location-node>) port) #t)

(define-method (display-slots (o <object>) port)
;;  (format (current-error-port) "SLOTS:~a\n" (class-slots (class-of o)))
  (for-each
   (lambda (slot)
     (let* ((name (slot-definition-name slot))
            (value (slot-ref o name)))
       (when (and value
                  (not (null? value))
                  (not (eq? value *unspecified*)))
         (cond ((eq? name 'elements)
                (if (pair? value)
                    (for-each (lambda (x) (sdisplay x port)) value)
                    (format (current-error-port) "<<barf: elements not a pair>> ~a\n" value)))
               (else (sdisplay value port))))))
   (class-slots (class-of o))))

(define-method (write (o <ast-node>) port)
  (display "(" port)
  (display (ast-name o) port)
  (ast port)
  (display-slots o port)
  (display #\) port))

(define-method (write (o <ast>) port)
  (display "(" port)
  (display (ast-name o) port)
  (ast port)
  (ast port)
  (if (.node o) (display-slots (.node o) port))
  (display #\) port))

(define (om->list om)
  (catch #t
    (lambda ()
      (with-input-from-string
          (with-output-to-string (lambda () (write om)))
        read))
    (lambda (key . args)
      (apply throw (cons key args)))))
