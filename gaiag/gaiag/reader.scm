;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag reader)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 match)
  :use-module (srfi srfi-1)

  :use-module (system base language)

  :use-module (gaiag misc)
  :use-module (language dezyne parse)
  :use-module (language dezyne location)
  :use-module (language dezyne tokenize)
  :export (dzn->ast find-file try-find-file parse-dzn read-dzn read-ast))

(define *include-path* '("." "examples"))

(define (dzn->ast o)
  (or (and-let* ((file-name (->string o))
                 ((file-exists? file-name)))
                (read-dzn file-name))
      (parse-dzn o)))

(define* (read-ast o :optional (register identity))
  (register (read-ast- o)))

(define read-dzn read-ast)

(define (read-ast- o)
  (let ((file-name (match o
                     (('name scope ... name) (find-model-file name))
                     (_ o))))
    (when (not file-name)
      (let ((m (format #f "cannot find model: `~a'\n" o)))
        (stderr m)
        (throw (cons 'model-not-found m))))
    (let* ((file-name (->string file-name))
           (file-name (if (string= file-name "-") "-"
                          (find-file file-name)))
           (file (if (string= file-name "-") (current-input-port)
                     (open-input-file file-name))))
      (if (eq? (peek-char file) #\()
          (read file)
          (read-dzn- file-name)))))

(define (find-model-file o)
  (let ((grep (lambda (dir) (gulp-pipe (format #f "/bin/grep -El '^(component|interface|enum|extern|int) ~a' ~a/~a.dzn ~a/*.dzn 2>/dev/null" o dir o dir)))))
    (let loop ((path *include-path*))
      (if (null? path) #f
          (let* ((name (grep (car path)))
                 (name (and (not (string-null? name))
                            (string-split name #\newline ))))
            (if (pair? name) (string->symbol (string-drop-prefix "./" (car name)))
                (loop (cdr path))))))))

(define (string-drop-prefix prefix string)
  (if (not (string-prefix? prefix string)) string
      (substring string (string-length prefix))))

(define* (parse-dzn string :optional (register identity))
  (register (parse-dzn- string)))

(define (parse-dzn- string)
  (read-hash-extend #\{ hash-read-string)
  (with-input-from-string string
    (lambda () (dzn-reader (current-input-port) (current-module)))))

(define (dzn-reader port env)
  ((make-parser) (make-tokenizer port) syntax-error-handler))

(define (read-dzn- file-name)
  (dzn-reader (open-file file-name "r") (current-module)))

(define (path-find-file path file-name)
  (search-path path (components->file-name file-name)))

(define* (find-file file-name :optional (extensions '(.dzn)))
  (let* ((file-name (if (pair? file-name) file-name (list file-name)))
         (resolved
          (or (path-find-file *include-path* file-name)
              (let loop ((extensions extensions))
                (if (null? extensions)
                    #f
                    (or (path-find-file *include-path*
                                        (append file-name (take extensions 1)))
                        (loop (cdr extensions)))))))
         (resolved (and (string? resolved) (string-drop-prefix "./" resolved)))
         (file-name (components->file-name file-name))
         (dir (or (and=> resolved dirname)
                  (let ((message (format #f "gaiag: No such file or directory: ~a [~a]\n" file-name *include-path*)))
                    (stderr message)
                    (throw 'file-not-found message)))))
    (when (not (member dir *include-path*))
      (set! *include-path* (cons dir *include-path*)))
    resolved))

(define* (try-find-file file-name :optional (extensions '(.dzn)))
  (catch #t
    (lambda () (with-error-to-port
                   (open-output-file "/dev/null")
                 (lambda ()
                   (find-file file-name extensions))))
    (lambda (key . args) #f)))
