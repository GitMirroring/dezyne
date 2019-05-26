;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (dzn indent)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 pretty-print)

  #:use-module (srfi srfi-1)
  #:use-module (ice-9 rdelim)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)

  #:export (indent))

(define* (eat-space #:optional (port (current-input-port)))
  (while (and-let* ((c (peek-char port)) ((or (eq? c #\space) (eq? c #\tab)))) (read-char port))))

(define* (indent #:key (indent 2) (open #\{) (close #\}) (no-indent "#") (port (current-input-port)))
  (let loop ((level 0))
    (define* (space #:optional (c level)) (let ((char (if (=1 indent) #\tab #\space))) (when (not (gdzn:command-line:get 'debug)) (display (make-string c char)))))
    (if (not (and-let* ((s (*eof*-is-#f (read-delimited (list->string `(#\newline ,open ,close)) port 'peek))))
                       (display s)))
        #f
        (let ((c (read-char port)))
          (cond
           ((eq? c *eof*) #f)
           ((eq? c #\newline)
            (display c)
            (eat-space port)
            (let ((c (read-char port)))
              (cond
               ((eq? c *eof*) #f)
               ((eq? c open) (space) (display c) (loop (+ level indent)))
               ((eq? c close) (let ((i (- level indent)))
                              (space i) (display c) (loop i)))
               ((eq? c #\newline) (unread-char c port))
               ((string-index no-indent c) (display c))
               (else (space) (display c)))))
           ((eq? c open) (display c) (set! level (+ level indent)))
           ((eq? c close) (display c) (set! level (- level indent)))
           (else (unread-char c port)))
          (loop level)))))
