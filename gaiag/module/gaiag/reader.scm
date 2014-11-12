;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rob Wieringa <Rob.Wieringa@verum.com>
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

(read-set! keywords 'prefix)

(define-module (gaiag reader)
  :use-module (ice-9 and-let-star)
  :use-module (srfi srfi-1)

  :use-module (system base language)

  :use-module (gaiag misc)
  :use-module (language asd parse)
  :use-module (language asd location)
  :use-module (language asd tokenize)
  :export (asd->ast find-file try-find-file parse-asd read-asd read-ast))

(define (asd->ast x)
  (or (and-let* ((file-name (->string x))
                 ((file-exists? file-name)))
                (read-asd file-name))
      (parse-asd x)))

(define (read-and-parse lang port cenv)
  (let ((exp ((language-reader lang) port cenv)))
    (cond
     ((eof-object? exp) exp)
     ((language-parser lang) => (lambda (parse) (parse exp)))
     (else exp))))

(define (asd-reader port env)
  ((make-parser) (make-tokenizer port) syntax-error-handler))

(define (read-asd- file-name)
  (asd-reader (open-file file-name "r") (current-module)))

(define *include-path* '("." "examples"))
(define (path-find-file path file-name)
  (search-path path (components->file-name file-name)))

(define* (find-file file-name :optional (extensions '(.asdi .asd .asdc .dzn)))
  (let* ((file-name (if (pair? file-name) file-name (list file-name)))
         (resolved
          (or (path-find-file *include-path* file-name)
              (let loop ((extensions extensions))
                (if (null? extensions)
                    #f
                    (or (path-find-file *include-path*
                                        (append file-name (take extensions 1)))
                        (loop (cdr extensions)))))))
         (file-name (components->file-name file-name))
         (dir (or (and=> resolved dirname)
                  (let ((message (format #f "gaiag: No such file or directory: ~a [~a]\n" file-name *include-path*)))
                    (stderr message)
                    (throw 'file-not-found message)))))
    (when (not (member dir *include-path*))
      (set! *include-path* (cons dir *include-path*)))
    resolved))

(define* (try-find-file file-name :optional (extensions '(.asdi .asd .asdc .dzn)))
  (catch #t
    (lambda () (with-error-to-port
                   (open-output-file "/dev/null")
                 (lambda ()
                   (find-file file-name extensions))))
    (lambda (key . args) #f)))

(define* (read-asd file-name :optional (register identity))
  (register (read-asd- (find-file file-name))))

(define (read-ast- file-name)
  (let ((file-name (find-file file-name)))
    (if (string-suffix? ".scm" file-name)
        (read (open-input-file file-name))
        (read-asd- file-name))))

(define* (read-ast file-name :optional (register identity))
  "Read contents of FILE-NAME and return the AST.

If FILE-NAME ends with `.scm', assume plain AST scheme content and
only perform a read, otherwise assume ASD content and also invoke
the parser."
  (register (read-ast- file-name)))

(define (parse-asd- string)
  (read-hash-extend #\{ hash-read-string)
  (with-input-from-string string
    (lambda () (asd-reader (current-input-port) (current-module)))))

(define* (parse-asd string :optional (register identity))
  (register (parse-asd- string)))
