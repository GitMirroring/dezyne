;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn serialize)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn command-line)
  #:export (ast:serialize))

(define-method (serialize-slot (o <object>) name port)
  (let* ((value (slot-ref o name)))
    (when value
      (cond ((eq? name 'elements)
             (when (pair? value)
               (for-each (lambda (x) (display " " port) (serialize x port) ) value)))
            ((is-a? value <location-node>)
             (display " (" port)
             (serialize name port)
             (serialize value port)
             (display ")" port))
            ((is-a? value <scope.name-node>)
             (display " (" port)
             (serialize name port)
             (display " ." port)
             (serialize value port)
             (display ")" port))
            (else
             (display " (" port)
             (serialize name port)
             (when (not (null? value))
               (display " . " port)
               (serialize value port))
             (display ")" port))))))

(define-method (serialize-slots (o <object>) port)
  (for-each
   (cut serialize-slot o <> port)
   (let ((slots (map slot-definition-name (class-slots (class-of o)))))
     (if (%locations?) slots
         (filter (negate (cut eq? <> 'location)) slots)))))

(define-method (serialize (o <scope.name-node>) port)
  (display " " port)
  (display (string-join (.ids o) ".") port))

(define-method (serialize (o <top>) port)
  (display o port))

(define-method (serialize (o <string>) port)
  (write o port))

(define-method (serialize (o <ast>) port)
  (serialize (.node o) port))

(define (serialize-name o)
  (if (string-suffix? "-node" o) (string-drop-right o 5)
      o))

(define-method (serialize (o <object>) port)
  (display "(" port)
  (display "(" port)
  (serialize (serialize-name (ast-name o)) port)
  (serialize-slots o port)
  (display ")" port)
  (display ")" port))

(define-method (serialize (o <list>) port)
  (display "(" port)
  (for-each (cut serialize <> port) o)
  (display ")" port))

(define-method (serialize (o <pair>) port)
  (display "(" port)
  (serialize (car o) port)
  (when (not (null? (cdr o)))
    (display " . " port)
    (serialize (cdr o) port))
  (display ")" port))

(define-method (serialize (o <root>) port)
  (serialize (.node o) port))

(define (ast:serialize ast)
  (with-input-from-string
      (call-with-output-string (lambda (p) (serialize ast p)))
    read))
