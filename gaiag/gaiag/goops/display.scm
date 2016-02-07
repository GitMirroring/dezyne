;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(read-set! keywords 'prefix)

(define-module (gaiag goops display)
  :use-module (ice-9 pretty-print)

  :use-module (gaiag goops om)

  :export (
           ast-name
           display-slots
           sdisplay
           star
           ))

(define-method (ast-name (o <ast>))
  (let ((name (string-drop (string-drop-right (symbol->string (class-name (class-of o))) 1) 1)))
    (string->symbol
     (if (string-prefix? "om:" name) (string-drop name 3) name))))

(define-method (ast-name (o <list>))
  (car o))

;; AST printing
(define (star port) (display #\* port))

(define-method (sdisplay (o <ast>) port)
  (display #\space port)
  (display o port))

(define-method (sdisplay (o <ast>) port)
  (display #\space port)
  (display o port))

(define-method (sdisplay (o <top>) port)
  (display #\space port)
  (display o port))

(define-method (display-slots (o <ast>) port)
  (for-each (lambda (slot)
              (let* ((name (slot-definition-name slot))
                     (value (slot-ref o name)))
                (when (not (eq? value '()))
                  (if (eq? name 'elements)
                      (for-each (lambda (x) (sdisplay x port)) value)
                      (sdisplay (slot-ref o name) port)))))
            (class-slots (class-of o))))

(define-method (display-slots (o <expression>) port)
  (if (eq? (.value o) *unspecified*)
      (sdisplay "*unspecified*" port)
      (sdisplay (.value o) port)))

(define-method (display-slots (o <if>) port)
  (sdisplay (.expression o) port)
  (sdisplay (.then o) port)
  (and=> (.else o) (lambda (x) (sdisplay x port))))

(define-method (display-slots (o <return>) port)
  (and=> (.expression o) (lambda (x) (sdisplay x port))))

(define-method (display-slots (o <signature>) port)
  (sdisplay (.type o) port)
  (if (pair? (.elements (.formals o)))
      (sdisplay (.formals o) port)))

(define-method (write (o <ast>) port)
  (display "(" port)
  (display (ast-name o) port)
  (star port)
  (display-slots o port)
  (display #\) port))
