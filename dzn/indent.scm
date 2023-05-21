;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn indent)
  #:use-module (ice-9 rdelim)

  #:export (indent))

(define* (eat-space #:optional (port (current-input-port)))
  (list->string
   (let loop ()
     (let ((c (peek-char port)))
       (cond
        ((or (eof-object? c)
             (not (eq? c #\space))) '())
        (else
         (read-char port)
         (cons c (loop))))))))

(define* (indent #:key
                 (width 2)
                 (open #\{) (close #\})
                 (gnu? #t)
                 (no-indent "#")
                 (port (current-input-port)))
  (let ((delims (list->string `(#\newline ,open ,close))))
    (let loop ((level 0) (last 'start))
      (define* (space #:optional (c level))
        (let ((char (if (= width 1) #\tab #\space)))
          (display (make-string c char))))
      (let* ((leading-space (eat-space port))
             (string (read-delimited delims port 'peek))
             (c (read-char port)))
        (cond
         ((eof-object? string)
          (newline))
         ((eof-object? c)
          (space level)
          (display string)
          (newline))
         ((and (eq? c #\newline)
               (string-null? leading-space)
               (string-null? string))
          (when (and (eq? last 'newline)
                     (or (not (eq? close #\)))
                         (zero? level)))
            (display c))
          (loop level 'newline))
         ((and (eq? c #\newline)
               (string-null? leading-space)
               (string-null? (string-trim string)))
          (loop level 'newline))
         ((eq? c #\newline)
          (cond
           ((and (eq? last 'start)
                 (string-null? (string-trim string)))
            (loop level 'start))
           ((string-null? (string-trim string))
            (loop level 'newline))
           (else
            (when (eq? last 'newline)
              (newline))
            (cond ((eq? last 'start)
                   #t)
                  ((and (not (string-null? no-indent))
                        (string-prefix? no-indent string))
                   #t)
                  ((eq? last 'newline)
                   (space))
                  (else
                   (display leading-space)))
            (display string)
            (loop level 'newline))))
         ((eq? c open)
          (case last
            ((newline)
             (newline)
             (space))
            ((close)
             (display leading-space)))
          (display string)
          (when (and gnu? (> level 0) (eq? c #\{))
            (space width))
          (display c)
          (loop (+ level width
                         (if (and gnu? (> level 0) (eq? c #\{)) width 0)) #f))
         ((eq? c close)
          (case last
            ((newline)
             (when (or (not (eq? close #\)))
                       (not (string-null? string))
                       (zero? level))
               (newline)
               (if (string-null? string) (space (- level width))
                   (space))))
            ((close)
             (display leading-space)))
          (display string)
          (display c)
          (loop (- level width
                   (if (and gnu? (> level width) (eq? c #\})) width 0))
                'close)))))))
