;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag display)
  #:use-module (ice-9 pretty-print)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag util))

;; AST printing
(define (ast port) (display #\* port))
(define (ref port) (display #\@ port))

(define-method (sdisplay (o <ast-node>) port)
  (display #\space port)
  (display o port))

(define-method (sdisplay (o <top>) port)
  (display #\space port)
  (display o port))

(define expand? (getenv "GAIAG_EXPAND"))

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
                    (format (current-error-port) "<<barf: elements not a pair>> ")))
               ((and (not expand?)
                     (or (is-a? value <port-node>)
                         (is-a? value <event-node>)
                         (is-a? value <interface-node>)
                         (is-a? value <variable-node>)
                         (is-a? value <formal-node>)
                         (and (is-a? value <type-node>) (not (eq? (class-of value) <type-node>)))
                         (is-a? value <function-node>)
                         (is-a? value <component-node>)
                         (is-a? value <system-node>)
                         (is-a? value <port-node>)
                         (is-a? value <instance-node>))
                     (not (is-a? o <ast-node-list>)))
                (display #\space port)
                (display-ref (and=> value .name) port))
               (else (sdisplay value port))))))
   (class-slots (class-of o))))

(define-method (display-ref (o <top>) port)
  (display o port)
  (ref port))

(define-method (display-ref (o <scope.name-node>) port)
  (display (string-join (map symbol->string (append (.scope o) (list (.name o)))) ".") port)
  (ref port))

(define-method (display-ref (o <variable-node>) port)
  (display (.name o) port)
  (ref port))

(define-method (display-ref (o <type-node>) port)
  (display (.name o) port)
  (ref port))

(define-method (write (o <ast-node>) port)
  (display "(" port)
  (display (ast-name o) port)
  (ast port)
;  (display " " port)
;  (display (.id o) port)
  (display-slots o port)
  (display #\) port))

(define-method (write (o <ast>) port)
  (display "(" port)
  (display (ast-name o) port)
  (ast port)
  (ast port)
  (if (.node o) (display-slots (.node o) port))
  (display #\) port))
