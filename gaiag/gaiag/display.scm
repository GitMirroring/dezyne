;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag display)
  #:use-module (ice-9 pretty-print)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag command-line)
  #:use-module (gaiag goops)
  #:export (display-slots display-slot om->list))

(define-method (sdisplay (o <ast-node>) port)
  (display #\space port)
  (write o port))

(define-method (sdisplay (o <top>) port)
  (display #\space port)
  (display o port))

(define-method (display-slot (o <object>) name port)
  (let* ((value (slot-ref o name)))
    (when (and value
               (or (not (eq? name 'location))
                   (command-line:get 'locations)))
      (cond ((eq? name 'elements)
             (when (pair? value)
               (for-each (lambda (x) (sdisplay x port)) value)))
            ((is-a? value <scope.name-node>)
             (sdisplay #\( port)
             (display name port)
             (sdisplay "." port)
             (display value port)
             (display #\) port))
            (else
             (sdisplay #\( port)
             (display name port)
             (when (not (null? value))
               (sdisplay "." port)
               (sdisplay value port))
             (display #\) port))))))

(define-method (display-slots (o <object>) port)
  (for-each
   (cut display-slot o <> port)
   (map slot-definition-name (class-slots (class-of o)))))

(define (symbol-drop-right o n)
  ((compose string->symbol (cut string-drop-right <> n) symbol->string) o))

(define-method (display (o <location-node>) port)
  (display #\( port)
  (display #\( port)
  (display-slots o port)
  (display #\) port)
  (display #\) port))

(define-method (display (o <scope.name-node>) port)
  (sdisplay (string-join (map symbol->string (append (.scope o) (list (.name o)))) ".") port))

(define-method (write (o <ast-list-node>) port)
  (display #\( port)
  (display-slots o port)
  (display #\) port))

(define-method (write (o <ast>) port)
  (display #\( port)
  (display #\( port)
  (display (symbol-drop-right (ast-name (.node o)) 5) port)
  (display-slots (.node o) port)
  (display #\) port)
  (display #\) port))

(define-method (write (o <ast-node>) port)
  (display #\( port)
  (display #\( port)
  (display (symbol-drop-right (ast-name o) 5) port)
  (display-slots o port)
  (display #\) port)
  (display #\) port))

(define-method (write (o <ast-list>) port)
  (display #\( port)
  (display #\( port)
  (display (ast-name o) port)
  (when (.node o) (display-slots (.node o) port))
  (display #\) port)
  (display #\) port))

(define (om->list om)
  (catch #t
    (lambda ()
      (with-input-from-string
          (with-output-to-string (lambda () (write om)))
        read))
    (lambda (key . args)
      (apply throw (cons key args)))))
