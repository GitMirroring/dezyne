;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (g reader)
  :use-module (ice-9 and-let-star)
  :use-module (srfi srfi-1)

  :use-module (system base language)

  :use-module (g misc)
  :use-module (language dezyne location)
  :use-module (language dezyne parse)  
  :use-module (language dezyne tokenize)
  :export (dzn->ast parse-dzn read-dzn read-ast))

(define (dzn->ast x)
  (or (and-let* ((file-name (->string x))
                 ((file-exists? file-name)))
                (read-dzn file-name))
      (parse-dzn x)))

(define (read-and-parse lang port cenv)
  (let ((exp ((language-reader lang) port cenv)))
    (cond
     ((eof-object? exp) exp)
     ((language-parser lang) => (lambda (parse) (parse exp)))
     (else exp))))

(define (dzn-reader port env)
  ((make-parser) (make-tokenizer port) syntax-error-handler))

(define (read-dzn- file-name)
  (dzn-reader (open-file file-name "r") (current-module)))

(define *include-path* '("."))
(define* (find-file file-name)
  (let* ((file-name (components->file-name file-name))
         (resolved (search-path *include-path* file-name))
         (dir (or (and=> resolved dirname)
                  (begin
                    (stderr "No such file or directory: ~a [~a]\n" file-name *include-path*)
                    (exit 2)))))
    (when (not (member dir *include-path*))
      (set! *include-path* (cons dir *include-path*)))
    resolved))

(define* (read-dzn file-name :optional (register (@ (g ast) register)))
  (register (read-dzn- (find-file file-name))))

(define (read-ast- file-name)
  (let* ((file-name (->string file-name))
         (file-name  (if (string= file-name "-") "/dev/stdin" (find-file file-name)))
         (file (open-input-file file-name)))
    (if (eq? (peek-char file) #\()
        (read file)
        (read-dzn- file-name))))

(define* (read-ast file-name :optional (register (@ (g ast) register)))
  "Read contents of FILE-NAME and return the AST.

If FILE-NAME ends with `.scm', assume plain AST scheme content and
only perform a read, otherwise assume ASD content and also invoke
the parser."
  (register (read-ast- file-name)))

(define (parse-dzn- string)
  (read-hash-extend #\{ hash-read-string)
  (with-input-from-string string
    (lambda () (dzn-reader (current-input-port) (current-module)))))

(define* (parse-dzn string :optional (register (@ (g ast) register)))
  (register (parse-dzn- string)))
