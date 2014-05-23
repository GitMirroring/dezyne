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
  :use-module (ice-9 rdelim)
  :export (gulp-text-file dump-file stderr stdout))

(define (gulp-text-file name)
  (let* ((file (open-file name "r"))
	 (text (read-delimited "" file)))
    (close file)
    text))

(define (dump-file name string)
  (let* ((file (open-output-file name)))
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
