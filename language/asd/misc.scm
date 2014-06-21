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

(define-module (language asd misc)
  :use-module (ice-9 match)
  :use-module (ice-9 rdelim)
  :export (
           =0
           >0
           =1
           >1
           >2
           fand
           for
           gulp-text-file
           dump-file
           *eof*
           *eof*-is-#f
           null-is-#f
           one-is-#f
           stderr
           stdout
           symbol<
           ->string
           ))

(define *eof* (call-with-input-string "" read-char))
(define (null-is-#f o) (if (null? o) #f o))
(define (*eof*-is-#f o) (if (eq? *eof* o) #f o))
(define (one-is-#f o) (if (or (null? o) (=1 (length o))) #f o))

(define (=0 x) (= x 0))
(define (>0 x) (> x 0))
(define (=1 x) (= x 1))
(define (>1 x) (> x 1))
(define (>2 x) (> x 2))

(define (symbol< a b) (string< (symbol->string a) (symbol->string b)))

(define (fand . args)
  (eval `(and ,@args) (current-module)))

(define (for . args)
  (eval `(or ,@args) (current-module)))

(define (gulp-text-file name)
  (let* ((file (open-file (->string name) "r"))
	 (text (read-delimited "" file)))
    (close file)
    text))

(define (dump-file name string)
  (let* ((file (open-output-file (->string name))))
    (display string file)
    (close file)))

(define (logf port string . rest)
  (apply format (cons* port string rest))
  (force-output port)
  #t)
  
(define (stderr string . rest)
  (apply logf (cons* (current-error-port) string rest)))

(define (stdout string . rest)
  (apply logf (cons* (current-output-port) string rest)))

(define (->string src)
  (match src
    ((? char?) (make-string 1 src))
    ((? string?) src)
    ((? symbol?) (symbol->string src))
    ((h ... t) (apply string-append (map ->string src)))
    (_ "")))
