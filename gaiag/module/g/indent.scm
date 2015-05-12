;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (g indent)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

  :use-module (srfi srfi-1)
  :use-module (ice-9 rdelim)

  :use-module (g misc)
  :use-module (g reader)

  :export (indent indent-string))

(define* (eat-space :optional (port (current-input-port)))
  (while (and-let* ((c (peek-char port)) ((eq? c #\space))) (read-char port))))

(define no-indent "#")
(define* (indent :optional (indent 2) (port (current-input-port)))
  (let loop ((level 0))
    (define* (space :optional (c level)) (display (make-string c #\space)))
    (if (not (and-let* ((s (*eof*-is-#f (read-delimited "\n{}" port 'peek))))
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
               ((eq? c #\{) (space) (display c) (loop (+ level indent)))
               ((eq? c #\}) (let ((i (- level indent)))
                              (space i) (display c) (loop i)))
               ((eq? c #\newline) (unread-char c port))
               ((string-index no-indent c) (display c))
               (else (space) (display c)))))
           ((eq? c #\{) (display c) (set! level (+ level indent)))
           ((eq? c #\}) (display c) (set! level (- level indent)))
           (else (unread-char c port)))
          (loop level)))))

(define* (indent-string string :optional (step 2))
  (with-output-to-string
    (lambda () (with-input-from-string string (lambda () (indent step))))))
