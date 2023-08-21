;;; Snuik --- An IRC bot using guile-8sync
;;; Copyright © 2020, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Snuik.
;;;
;;; Snuik is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Snuik is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Snuik.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn goops serialize)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 regex)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (oop goops)

  #:use-module (dzn misc)
  #:use-module (dzn goops define-method-star)
  #:use-module (dzn goops util)

  #:export (%serialize:constructor-name
            %serialize:skip?
            %serialize:skip-field-name?
            serialize)
  #:re-export (pretty-print))

;; Predicate parameter to skip fields, by default: skip any field that
;; is #false or the empty list.
(define %serialize:skip? (make-parameter (disjoin (negate identity) null?)))

;; Predicate parameter to skip field names altogether to use a
;; position-based representation.
(define %serialize:skip-field-name? (make-parameter (const #f)))

;; Parameter to produce a class's name.
(define-method (serialize:constructor-name (o <object>))
  (constructor-name o))
(define %serialize:constructor-name (make-parameter serialize:constructor-name))


;;;
;;; Serialize.
;;;
(define-method (serialize-slot (o <object>) name port)
  (unless ((%serialize:skip?) o)
    (let ((value (slot-ref o name)))
      (unless ((%serialize:skip?) value)
        (unless ((%serialize:skip-field-name?))
          (display " (" port)
          (display name port))
        (display " " port)
        (cond ((null? value)
               (display "(list)" port))
              ((pair? value)
               (display "(list " port)
               (serialize value port)
               (display ")" port))
              (((%serialize:skip?) value))
              (else
               (serialize value port)))
        (unless ((%serialize:skip-field-name?))
          (display ")" port))))))

(define-method (serialize-slots (o <object>) port)
  (for-each
   (cute serialize-slot o <> port)
   (map slot-definition-name (class-slots (class-of o)))))

(define-method (serialize (o <top>) port)
  (cond ((eq? o *unspecified*)
         (display "*unspecified*" port))
        (else (display o port))))

(define-method (serialize (o <string>) port)
  (write o port))

(define-method (serialize (o <symbol>) port)
  ;; TODO #{foo bar}#
  (display "'" port)
  (display o port))

(define-method (serialize (o <object>) port)
  (unless ((%serialize:skip?) o)
    (display "(" port)
    (display ((%serialize:constructor-name) o) port)
    (serialize-slots o port)
    (display ")" port)))

(define-method (serialize (o <pair>) port)
  (match o
    ((tail)
     (serialize tail port))
    ((head tail ...)
     (unless ((%serialize:skip?) head)
       (serialize head port)
       (display " " port))
     (serialize tail port))))


;;;
;;; Entry points.
;;;
(define-method (serialize (o <top>))
  (with-input-from-string
      (call-with-output-string (cute serialize o <>))
    read))

(define-generic pretty-print)
(define-method* (pretty-print (o <object>)
                              #:optional (port (current-output-port))
                              #:key (width 79))
  (pretty-print (serialize o) port #:width width))
