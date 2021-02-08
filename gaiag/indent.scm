;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag indent)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 pretty-print)

  #:use-module (srfi srfi-1)
  #:use-module (ice-9 rdelim)
  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)

  #:export (indent))

(define* (eat-space #:optional (port (current-input-port)))
  (list->string
   (let loop ()
     (let ((c (peek-char port)))
       (cond
        ((or (eq? c *eof*)
             (not (eq? c #\space))) '())
        (else
         (read-char port)
         (cons c (loop))))))))

(define* (indent #:key (indent 2) (open #\{) (close #\}) (no-indent "#") (port (current-input-port)))
  (let ((delims (list->string `(#\newline ,open ,close))))
    (let loop ((level 0) (newline? #f))
      (define* (space #:optional (c level))
        (let ((char (if (=1 indent) #\tab #\space)))
          (display (make-string c char))))
      (let* ((leading-space (eat-space port))
             (string (read-delimited delims port 'peek))
             (c (read-char port)))
        (cond
         ((eq? string *eof*)
          (newline))
         ((eq? c *eof*)
          (space level)
          (display string)
          (newline))
         ((and (eq? c #\newline)
               (string-null? leading-space)
               (string-null? string))
          (display c)
          (loop level #t))
         ((and (eq? c #\newline)
               (string-null? leading-space)
               (string-null? (string-trim string)))
          (loop level #t))
         ((eq? c #\newline)
          (cond
           ((string-null? (string-trim string))
            (loop level #t))
           (else
            (cond ((and (not (string-null? no-indent)) (string-prefix? no-indent string)))
                  (newline? (space))
                  (else (display leading-space)))
            (display string)
            (display c)
            (loop level #t))))
         ((eq? c open)
          (when newline?
            (space))
          (display string)
          (display c)
          (loop (+ level indent) #f))
         ((eq? c close)
          (when newline?
            (if (string-null? string) (space (- level indent))
                (space indent)))
          (display string)
          (display c)
          (loop (- level indent) #f)))))))
