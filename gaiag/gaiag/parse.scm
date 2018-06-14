;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

(define-module (gaiag parse)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (system base language)

  #:use-module (gaiag misc)
  #:use-module (gaiag location)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gash job)
  #:use-module (gash pipe)

  #:export (%include-path parse-file try-find-file))

(define ast-> pretty-print)

(define* (parse-file file-name #:key gaiag? (imports '()))
  (if (not gaiag?) (generator-parse-file file-name #:imports imports)
      (gaiag-parse-file file-name)))

(define %include-path '("."))

(define (handle-error job error)
  (let ((status (wait job)))
    (when (not (zero? status))
      (format (current-error-port) "~a" error)
      (exit status))
    status))

(define* (generator-parse-file file-name #:key (imports '()))
  (let ((commands `(("generate" "-l" "scm" "-L" "-o" "-"
                     ,@(append-map (cut list "-I" <>) imports)
                     ,file-name))))
    (receive (job ports)
        (apply pipeline+ #f commands)
      (set-port-encoding! (car ports) "ISO-8859-1")
      (let ((ast (read (car ports)))
            (error (read-string (cadr ports))))
        (handle-error job error)
        ast))))

(define (gaiag-parse-file o)
  (let ((file-name (match o
                     ((and ($ <scope.name>) (= .name name)) (find-model-file name))
                     ((t ...) #f)
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
          (error (format #f ".scm file expected: ~s\n" file-name))))))

(define (find-model-file o)
  (let ((grep (lambda (dir) (gulp-pipe (format #f "grep -El '^(component|interface|enum|extern|int) ~a' ~a/~a.dzn ~a/*.dzn 2>/dev/null ||:" o dir o dir)))))
    (let loop ((path %include-path))
      (if (null? path) #f
          (let* ((name (grep (car path)))
                 (name (and (not (string-null? name))
                            (string-split name #\newline ))))
            (if (pair? name) (string->symbol (string-drop-prefix "./" (car name)))
                (loop (cdr path))))))))

(define (string-drop-prefix prefix string)
  (if (not (string-prefix? prefix string)) string
      (substring string (string-length prefix))))

(define (path-find-file path file-name)
  (search-path path (components->file-name file-name)))

(define* (find-file file-name #:optional (extensions '(.dzn)))
  (let* ((file-name (if (pair? file-name) file-name (list file-name)))
         (resolved
          (or (path-find-file %include-path file-name)
              (let loop ((extensions extensions))
                (if (null? extensions)
                    #f
                    (or (path-find-file %include-path
                                        (append file-name (take extensions 1)))
                        (loop (cdr extensions)))))))
         (resolved (and (string? resolved) (string-drop-prefix "./" resolved)))
         (file-name (components->file-name file-name))
         (dir (or (and=> resolved dirname)
                  (let ((message (format #f "gaiag: No such file or directory: `~a' [~a]\n" file-name %include-path)))
                    (stderr message)
                    (throw 'file-not-found message)))))
    (when (not (member dir %include-path))
      (set! %include-path (cons dir %include-path)))
    resolved))

(define* (try-find-file file-name #:optional (extensions '(.dzn)))
  (catch #t
    (lambda () (with-error-to-port
                   (open-output-file "/dev/null")
                 (lambda ()
                   (find-file file-name extensions))))
    (lambda (key . args) #f)))
