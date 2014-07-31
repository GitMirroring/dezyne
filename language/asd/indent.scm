;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (language asd indent)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

  :use-module (srfi srfi-1)
  :use-module (ice-9 rdelim)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd pretty)
  :use-module (language asd reader)

  :export (indent indent-string))

(define* (eat-space :optional (port (current-input-port)))
  (while (and-let* ((c (peek-char port)) ((eq? c #\space))) (read-char port))))

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
               (else (space) (display c)))))
           ((eq? c #\{) (display c) (set! level (+ level indent)))
           ((eq? c #\}) (display c) (set! level (- level indent)))
           (else (unread-char c port)))
          (loop level)))))

(define* (indent-string string :optional (step 2))
  (with-output-to-string 
    (lambda () (with-input-from-string string (lambda () (indent step))))))
