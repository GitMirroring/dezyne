;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag display)
  #:use-module (ice-9 pretty-print)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag util)

  #:export (
           display-slots
           sdisplay
           star
           ))

;; AST printing
(define (ast port) (display #\* port))
(define (ref port) (display #\@ port))

(define-method (sdisplay (o <ast>) port)
  (display #\space port)
  (display o port))

(define-method (sdisplay (o <ast>) port)
  (display #\space port)
  (display o port))

(define-method (sdisplay (o <top>) port)
  (display #\space port)
  (display o port))

(define expand? (getenv "GAIAG_EXPAND"))

(define-method (display-slots (o <ast>) port)
  (for-each
   (lambda (slot)
     (let* ((name (slot-definition-name slot))
            (value (slot-ref o name)))
       (when (not (eq? value '()))
         (cond ((eq? name 'elements)
                (if (pair? value)
                    (for-each (lambda (x) (sdisplay x port)) value)
                    (begin
                      (format (current-error-port) "<<barf: elements not a pair>> ")
                      barf)))
               ((and (not expand?)
                     (is-a? value <ast>)
                     (not (is-a? o <ast-list>))
                     (or (and (or (is-a? o <port>) ;; REMOVEME after handling all port, type slots, name slots
                                  (is-a? o <action>)
                                  (is-a? o <trigger>)
                                  (is-a? o <port>)
                                  (is-a? o <variable>))
                              (member name '(event port type)))
                         (is-a? o <var>)))
                (display #\space port)
                (display-ref (and=> value .name) port))
               (else (sdisplay value port))))))
   (class-slots (class-of o))))

(define-method (display-ref (o <top>) port)
  (display o port)
  (ref port))

(define-method (display-ref (o <scope.name>) port)
  (display (string-join (map symbol->string (append (.scope o) (list (.name o)))) ".") port)
  (ref port))

(define-method (display-ref (o <variable>) port)
  (display (.name o) port)
  (ref port))

(define-method (display-slots (o <expression>) port)
  (let ((value (.value o)))
    (cond ((eq? value *unspecified*)
           (sdisplay "*unspecified*" port))
          (else (sdisplay value port)))))

(define-method (display-slots (o <return>) port)
  (and=> (.expression o) (lambda (x) (sdisplay x port))))

(define-method (write (o <ast>) port)
  (display "(" port)
  (display (ast-name o) port)
  (ast port)
  (display-slots o port)
  (display #\) port))
